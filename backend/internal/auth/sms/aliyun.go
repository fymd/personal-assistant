package sms

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/fymd/personal-assistant/backend/internal/config"
)

// Aliyun 阿里云短信（Dysmsapi SendSms）
type Aliyun struct {
	accessKey    string
	accessSecret string
	signName     string
	templateCode string
	client       *http.Client
}

func NewAliyun(cfg *config.Config) (*Aliyun, error) {
	if cfg.SMSAccessKey == "" || cfg.SMSAccessSecret == "" {
		return nil, fmt.Errorf("aliyun sms: SMS_ACCESS_KEY and SMS_ACCESS_SECRET are required")
	}
	if cfg.SMSSignName == "" || cfg.SMSTemplateCode == "" {
		return nil, fmt.Errorf("aliyun sms: SMS_SIGN_NAME and SMS_TEMPLATE_CODE are required")
	}
	return &Aliyun{
		accessKey:    cfg.SMSAccessKey,
		accessSecret: cfg.SMSAccessSecret,
		signName:     cfg.SMSSignName,
		templateCode: cfg.SMSTemplateCode,
		client:       &http.Client{Timeout: 10 * time.Second},
	}, nil
}

func (a *Aliyun) Name() string { return "aliyun" }

func (a *Aliyun) Send(phone, code string) error {
	params := map[string]string{
		"AccessKeyId":      a.accessKey,
		"Action":           "SendSms",
		"Format":           "JSON",
		"PhoneNumbers":     phone,
		"RegionId":         "cn-hangzhou",
		"SignName":         a.signName,
		"SignatureMethod":  "HMAC-SHA1",
		"SignatureNonce":   fmt.Sprintf("%d", time.Now().UnixNano()),
		"SignatureVersion": "1.0",
		"TemplateCode":     a.templateCode,
		"TemplateParam":    fmt.Sprintf(`{"code":"%s"}`, code),
		"Timestamp":        time.Now().UTC().Format("2006-01-02T15:04:05Z"),
		"Version":          "2017-05-25",
	}

	signature := a.sign(params)
	params["Signature"] = signature

	form := url.Values{}
	for k, v := range params {
		form.Set(k, v)
	}

	req, err := http.NewRequest(http.MethodPost, "https://dysmsapi.aliyuncs.com/", strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := a.client.Do(req)
	if err != nil {
		return fmt.Errorf("aliyun sms request: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result struct {
		Code    string `json:"Code"`
		Message string `json:"Message"`
		BizId   string `json:"BizId"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return fmt.Errorf("aliyun sms decode: %w (body=%s)", err, string(body))
	}
	if !strings.EqualFold(result.Code, "OK") {
		return fmt.Errorf("aliyun sms failed: %s - %s", result.Code, result.Message)
	}
	return nil
}

// 阿里云 RPC 签名（HMAC-SHA1）
func (a *Aliyun) sign(params map[string]string) string {
	keys := make([]string, 0, len(params))
	for k := range params {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	var pairs []string
	for _, k := range keys {
		pairs = append(pairs, percentEncode(k)+"="+percentEncode(params[k]))
	}
	canonical := strings.Join(pairs, "&")
	stringToSign := "POST&" + percentEncode("/") + "&" + percentEncode(canonical)

	mac := hmac.New(sha1.New, []byte(a.accessSecret+"&"))
	mac.Write([]byte(stringToSign))
	return base64.StdEncoding.EncodeToString(mac.Sum(nil))
}

func percentEncode(s string) string {
	// 阿里云要求：空格为 %20，且 * 与 ~ 特殊处理
	encoded := url.QueryEscape(s)
	encoded = strings.ReplaceAll(encoded, "+", "%20")
	encoded = strings.ReplaceAll(encoded, "*", "%2A")
	encoded = strings.ReplaceAll(encoded, "%7E", "~")
	return encoded
}

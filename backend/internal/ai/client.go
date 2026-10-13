package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

const systemPrompt = `你是「个人助理」App 中的 AI 任务助手。你的目标是帮助用户提高工作效率。
能力重点：
1. 总结文字
2. 润色与改写
3. 根据描述生成清晰的待办列表
4. 简短、可执行的对话建议

回答要求：简洁、结构化；生成待办时使用清晰列表；使用用户使用的语言（中文为主）。`

type Client struct {
	apiKey  string
	baseURL string
	model   string
	http    *http.Client
}

func NewClient(apiKey, baseURL, model string) *Client {
	return &Client{
		apiKey:  apiKey,
		baseURL: strings.TrimRight(baseURL, "/"),
		model:   model,
		http:    &http.Client{Timeout: 60 * time.Second},
	}
}

func (c *Client) Enabled() bool {
	return c.apiKey != ""
}

type Message struct {
	Role    string `json:"role"` // system | user | assistant
	Content string `json:"content"`
}

type chatRequest struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
}

type chatResponse struct {
	Choices []struct {
		Message Message `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// Chat 调用云端 Chat Completions（OpenAI 兼容）
func (c *Client) Chat(userMessages []Message) (string, error) {
	if !c.Enabled() {
		return c.mockReply(userMessages), nil
	}

	msgs := make([]Message, 0, len(userMessages)+1)
	msgs = append(msgs, Message{Role: "system", Content: systemPrompt})
	msgs = append(msgs, userMessages...)

	body, _ := json.Marshal(chatRequest{
		Model:    c.model,
		Messages: msgs,
	})

	req, err := http.NewRequest(http.MethodPost, c.baseURL+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	res, err := c.http.Do(req)
	if err != nil {
		return "", fmt.Errorf("ai request failed: %w", err)
	}
	defer res.Body.Close()

	data, _ := io.ReadAll(res.Body)
	var parsed chatResponse
	if err := json.Unmarshal(data, &parsed); err != nil {
		return "", fmt.Errorf("ai parse failed: %w", err)
	}
	if parsed.Error != nil {
		return "", fmt.Errorf("ai error: %s", parsed.Error.Message)
	}
	if len(parsed.Choices) == 0 {
		return "", fmt.Errorf("ai empty response: %s", string(data))
	}
	return parsed.Choices[0].Message.Content, nil
}

func (c *Client) mockReply(msgs []Message) string {
	last := ""
	if len(msgs) > 0 {
		last = msgs[len(msgs)-1].Content
	}
	lower := strings.ToLower(last)
	switch {
	case strings.Contains(last, "待办") || strings.Contains(lower, "todo"):
		return "已为你生成今日待办（演示模式，未配置 AI_API_KEY）：\n\n" +
			"1. 完成项目提案初稿\n" +
			"2. 团队会议（10:00）\n" +
			"3. 阅读行业报告\n" +
			"4. 整理会议纪要\n" +
			"5. 健身 30 分钟\n\n" +
			"配置环境变量 AI_API_KEY 后将调用真实云端模型。"
	case strings.Contains(last, "总结") || strings.Contains(lower, "summar"):
		return "【演示总结】\n你提供的内容可概括为：核心观点已提炼，建议聚焦可执行下一步。\n\n（当前为演示模式，请配置 AI_API_KEY）"
	case strings.Contains(last, "润色") || strings.Contains(lower, "polish"):
		return "【演示润色】\n已对原文进行语气与结构优化（示例）。正式环境将返回完整润色结果。\n\n（当前为演示模式，请配置 AI_API_KEY）"
	default:
		return "你好，我是个人助理 AI（演示模式）。\n\n我可以帮你：总结、润色、生成待办。\n请在服务端配置 AI_API_KEY / AI_BASE_URL / AI_MODEL 后使用真实模型。\n\n你刚才说：「" + truncate(last, 80) + "」"
	}
}

func truncate(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n]) + "…"
}

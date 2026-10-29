package membership

import (
	"database/sql"
	"fmt"
	"time"
)

type Store struct {
	db *sql.DB
}

func NewStore(db *sql.DB) *Store {
	return &Store{db: db}
}

func (s *Store) GetStatus(phone string) (*Status, error) {
	var tier string
	var expireAt sql.NullString
	var theme string
	err := s.db.QueryRow(
		`SELECT membership_tier, membership_expire_at, theme_preference FROM users WHERE phone = ?`,
		phone,
	).Scan(&tier, &expireAt, &theme)
	if err == sql.ErrNoRows {
		return &Status{
			Phone:     phone,
			Tier:      TierFree,
			Active:    false,
			ThemePref: "notion",
		}, nil
	}
	if err != nil {
		return nil, err
	}
	if tier == "" {
		tier = TierFree
	}
	if theme == "" {
		theme = "notion"
	}
	st := &Status{
		Phone:     phone,
		Tier:      tier,
		ThemePref: theme,
	}
	if expireAt.Valid && expireAt.String != "" {
		s := expireAt.String
		st.ExpireAt = &s
		if t, err := time.Parse("2006-01-02 15:04:05", expireAt.String); err == nil {
			st.Active = tier != TierFree && t.After(time.Now())
		} else if t, err := time.Parse(time.RFC3339, expireAt.String); err == nil {
			st.Active = tier != TierFree && t.After(time.Now())
		}
	}
	return st, nil
}

// Activate 开发期直接写入会员等级与过期时间（未对接支付）
func (s *Store) Activate(phone, tier string, days int) (*Status, error) {
	if tier != TierPro && tier != TierPremium {
		return nil, fmt.Errorf("tier must be pro or premium")
	}
	if days <= 0 {
		days = 30
	}
	expire := time.Now().AddDate(0, 0, days).Format("2006-01-02 15:04:05")
	_, err := s.db.Exec(
		`UPDATE users SET membership_tier = ?, membership_expire_at = ? WHERE phone = ?`,
		tier, expire, phone,
	)
	if err != nil {
		return nil, err
	}
	// 若用户尚不存在（理论上登录后必有）
	res, _ := s.db.Exec(`INSERT OR IGNORE INTO users (phone, membership_tier, membership_expire_at) VALUES (?, ?, ?)`, phone, tier, expire)
	if res != nil {
		if n, _ := res.RowsAffected(); n > 0 {
			// inserted
		}
	}
	return s.GetStatus(phone)
}

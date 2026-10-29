package auth

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims JWT 载荷
type Claims struct {
	Phone string `json:"phone"`
	jwt.RegisteredClaims
}

func (s *Service) issueToken(phone string) (string, error) {
	now := time.Now()
	claims := Claims{
		Phone: phone,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   phone,
			Issuer:    "personal-assistant",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.accessTTL)),
		},
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(s.jwtSecret))
}

func (s *Service) parseToken(tokenStr string) (string, error) {
	t, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(s.jwtSecret), nil
	})
	if err != nil {
		return "", err
	}
	claims, ok := t.Claims.(*Claims)
	if !ok || !t.Valid {
		return "", fmt.Errorf("invalid token")
	}
	if claims.Phone == "" {
		return "", fmt.Errorf("missing phone claim")
	}
	return claims.Phone, nil
}

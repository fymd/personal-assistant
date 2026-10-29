package ops

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type Store struct {
	db *sql.DB
}

func NewStore(db *sql.DB) *Store {
	return &Store{db: db}
}

func (s *Store) ListProfiles(phone string) ([]RemoteDesktopProfile, error) {
	rows, err := s.db.Query(
		`SELECT id, name, protocol, host, port, username, note, created_at, updated_at
		 FROM remote_desktop_profiles WHERE user_phone = ? ORDER BY updated_at DESC`,
		phone,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []RemoteDesktopProfile
	for rows.Next() {
		var p RemoteDesktopProfile
		if err := rows.Scan(&p.ID, &p.Name, &p.Protocol, &p.Host, &p.Port, &p.Username, &p.Note, &p.CreatedAt, &p.UpdatedAt); err != nil {
			return nil, err
		}
		list = append(list, p)
	}
	if list == nil {
		list = []RemoteDesktopProfile{}
	}
	return list, rows.Err()
}

func (s *Store) CreateProfile(phone string, req CreateProfileRequest) (*RemoteDesktopProfile, error) {
	if req.Host == "" {
		return nil, fmt.Errorf("host is required")
	}
	name := req.Name
	if name == "" {
		name = req.Host
	}
	protocol := req.Protocol
	if protocol == "" {
		protocol = "RDP"
	}
	port := req.Port
	if port <= 0 {
		switch protocol {
		case "VNC":
			port = 5900
		case "SSH":
			port = 22
		default:
			port = 3389
		}
	}
	now := time.Now().UTC().Format(time.RFC3339)
	id := uuid.NewString()
	_, err := s.db.Exec(
		`INSERT INTO remote_desktop_profiles (id, user_phone, name, protocol, host, port, username, note, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		id, phone, name, protocol, req.Host, port, req.Username, req.Note, now, now,
	)
	if err != nil {
		return nil, err
	}
	return &RemoteDesktopProfile{
		ID: id, Name: name, Protocol: protocol, Host: req.Host, Port: port,
		Username: req.Username, Note: req.Note, CreatedAt: now, UpdatedAt: now,
	}, nil
}

func (s *Store) DeleteProfile(phone, id string) error {
	res, err := s.db.Exec(`DELETE FROM remote_desktop_profiles WHERE id = ? AND user_phone = ?`, id, phone)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("not found")
	}
	return nil
}

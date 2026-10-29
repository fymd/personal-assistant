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

func (s *Store) GetProfile(phone, id string) (*RemoteDesktopProfile, error) {
	var p RemoteDesktopProfile
	err := s.db.QueryRow(
		`SELECT id, name, protocol, host, port, username, note, created_at, updated_at
		 FROM remote_desktop_profiles WHERE id = ? AND user_phone = ?`, id, phone,
	).Scan(&p.ID, &p.Name, &p.Protocol, &p.Host, &p.Port, &p.Username, &p.Note, &p.CreatedAt, &p.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("not found")
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func defaultPort(protocol string) int {
	switch protocol {
	case "VNC":
		return 5900
	case "SSH":
		return 22
	default:
		return 3389
	}
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
		port = defaultPort(protocol)
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

func (s *Store) UpdateProfile(phone, id string, req UpdateProfileRequest) (*RemoteDesktopProfile, error) {
	p, err := s.GetProfile(phone, id)
	if err != nil {
		return nil, err
	}
	if req.Name != nil {
		p.Name = *req.Name
	}
	if req.Protocol != nil && *req.Protocol != "" {
		p.Protocol = *req.Protocol
	}
	if req.Host != nil {
		if *req.Host == "" {
			return nil, fmt.Errorf("host is required")
		}
		p.Host = *req.Host
	}
	if req.Port != nil {
		if *req.Port > 0 {
			p.Port = *req.Port
		} else {
			p.Port = defaultPort(p.Protocol)
		}
	}
	if req.Username != nil {
		p.Username = *req.Username
	}
	if req.Note != nil {
		p.Note = *req.Note
	}
	if p.Name == "" {
		p.Name = p.Host
	}
	now := time.Now().UTC().Format(time.RFC3339)
	_, err = s.db.Exec(
		`UPDATE remote_desktop_profiles SET name=?, protocol=?, host=?, port=?, username=?, note=?, updated_at=?
		 WHERE id=? AND user_phone=?`,
		p.Name, p.Protocol, p.Host, p.Port, p.Username, p.Note, now, id, phone,
	)
	if err != nil {
		return nil, err
	}
	p.UpdatedAt = now
	return p, nil
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

package ops

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

type Store struct {
	db *sql.DB
}

func NewStore(db *sql.DB) *Store {
	return &Store{db: db}
}

const profileSelect = `id, name, protocol, host, port, username, note, connect_mode, gateway_url, created_at, updated_at`

func scanProfile(scanner interface {
	Scan(dest ...interface{}) error
}) (*RemoteDesktopProfile, error) {
	var p RemoteDesktopProfile
	err := scanner.Scan(
		&p.ID, &p.Name, &p.Protocol, &p.Host, &p.Port, &p.Username, &p.Note,
		&p.ConnectMode, &p.GatewayURL, &p.CreatedAt, &p.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	if p.ConnectMode == "" {
		p.ConnectMode = ConnectModeExternal
	}
	return &p, nil
}

func normalizeMode(mode string) string {
	switch strings.ToLower(strings.TrimSpace(mode)) {
	case ConnectModeGateway:
		return ConnectModeGateway
	case ConnectModeNative:
		return ConnectModeNative
	default:
		return ConnectModeExternal
	}
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

func (s *Store) ListProfiles(phone string) ([]RemoteDesktopProfile, error) {
	rows, err := s.db.Query(
		`SELECT `+profileSelect+` FROM remote_desktop_profiles WHERE user_phone = ? ORDER BY updated_at DESC`,
		phone,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []RemoteDesktopProfile
	for rows.Next() {
		p, err := scanProfile(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, *p)
	}
	if list == nil {
		list = []RemoteDesktopProfile{}
	}
	return list, rows.Err()
}

func (s *Store) GetProfile(phone, id string) (*RemoteDesktopProfile, error) {
	row := s.db.QueryRow(
		`SELECT `+profileSelect+` FROM remote_desktop_profiles WHERE id = ? AND user_phone = ?`, id, phone,
	)
	p, err := scanProfile(row)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("not found")
	}
	return p, err
}

func (s *Store) CreateProfile(phone string, req CreateProfileRequest) (*RemoteDesktopProfile, error) {
	if req.Host == "" && normalizeMode(req.ConnectMode) != ConnectModeGateway {
		return nil, fmt.Errorf("host is required")
	}
	mode := normalizeMode(req.ConnectMode)
	if mode == ConnectModeGateway && strings.TrimSpace(req.GatewayURL) == "" {
		return nil, fmt.Errorf("gateway_url is required when connect_mode is gateway")
	}
	name := req.Name
	if name == "" {
		if req.Host != "" {
			name = req.Host
		} else {
			name = "网关连接"
		}
	}
	protocol := req.Protocol
	if protocol == "" {
		protocol = "RDP"
	}
	port := req.Port
	if port <= 0 {
		port = defaultPort(protocol)
	}
	host := req.Host
	if host == "" {
		host = "-"
	}
	now := time.Now().UTC().Format(time.RFC3339)
	id := uuid.NewString()
	_, err := s.db.Exec(
		`INSERT INTO remote_desktop_profiles
		 (id, user_phone, name, protocol, host, port, username, note, connect_mode, gateway_url, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		id, phone, name, protocol, host, port, req.Username, req.Note, mode, req.GatewayURL, now, now,
	)
	if err != nil {
		return nil, err
	}
	return &RemoteDesktopProfile{
		ID: id, Name: name, Protocol: protocol, Host: host, Port: port,
		Username: req.Username, Note: req.Note, ConnectMode: mode, GatewayURL: req.GatewayURL,
		CreatedAt: now, UpdatedAt: now,
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
	if req.ConnectMode != nil {
		p.ConnectMode = normalizeMode(*req.ConnectMode)
	}
	if req.GatewayURL != nil {
		p.GatewayURL = *req.GatewayURL
	}
	if p.ConnectMode == ConnectModeGateway && strings.TrimSpace(p.GatewayURL) == "" {
		return nil, fmt.Errorf("gateway_url is required when connect_mode is gateway")
	}
	if p.ConnectMode != ConnectModeGateway && (p.Host == "" || p.Host == "-") {
		return nil, fmt.Errorf("host is required")
	}
	if p.Name == "" {
		p.Name = p.Host
	}
	now := time.Now().UTC().Format(time.RFC3339)
	_, err = s.db.Exec(
		`UPDATE remote_desktop_profiles SET name=?, protocol=?, host=?, port=?, username=?, note=?, connect_mode=?, gateway_url=?, updated_at=?
		 WHERE id=? AND user_phone=?`,
		p.Name, p.Protocol, p.Host, p.Port, p.Username, p.Note, p.ConnectMode, p.GatewayURL, now, id, phone,
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

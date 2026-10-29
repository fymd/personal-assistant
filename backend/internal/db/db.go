package db

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

// Open 打开 SQLite 并执行迁移
func Open(path string) (*sql.DB, error) {
	dir := filepath.Dir(path)
	if dir != "." && dir != "" {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return nil, fmt.Errorf("create db dir: %w", err)
		}
	}

	database, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, fmt.Errorf("open sqlite: %w", err)
	}

	database.SetMaxOpenConns(1)
	database.SetMaxIdleConns(1)

	if err := database.Ping(); err != nil {
		_ = database.Close()
		return nil, fmt.Errorf("ping sqlite: %w", err)
	}

	if err := migrate(database); err != nil {
		_ = database.Close()
		return nil, err
	}

	return database, nil
}

func migrate(db *sql.DB) error {
	schema := `
CREATE TABLE IF NOT EXISTS users (
    phone                TEXT PRIMARY KEY,
    created_at           TEXT NOT NULL DEFAULT (datetime('now')),
    membership_tier      TEXT NOT NULL DEFAULT 'free',
    membership_expire_at TEXT,
    theme_preference     TEXT NOT NULL DEFAULT 'notion'
);

CREATE TABLE IF NOT EXISTS sessions (
    token      TEXT PRIMARY KEY,
    phone      TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (phone) REFERENCES users(phone)
);

CREATE TABLE IF NOT EXISTS memos (
    id         TEXT PRIMARY KEY,
    user_phone TEXT NOT NULL,
    title      TEXT NOT NULL,
    content    TEXT NOT NULL DEFAULT '',
    tag        TEXT NOT NULL DEFAULT '',
    completed  INTEGER NOT NULL DEFAULT 0,
    starred    INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_phone) REFERENCES users(phone)
);

CREATE TABLE IF NOT EXISTS remote_desktop_profiles (
    id         TEXT PRIMARY KEY,
    user_phone TEXT NOT NULL,
    name       TEXT NOT NULL,
    protocol   TEXT NOT NULL DEFAULT 'RDP',
    host       TEXT NOT NULL,
    port       INTEGER NOT NULL DEFAULT 3389,
    username   TEXT NOT NULL DEFAULT '',
    note       TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_phone) REFERENCES users(phone)
);

CREATE INDEX IF NOT EXISTS idx_memos_user ON memos(user_phone);
CREATE INDEX IF NOT EXISTS idx_memos_updated ON memos(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_phone ON sessions(phone);
CREATE INDEX IF NOT EXISTS idx_rd_profiles_user ON remote_desktop_profiles(user_phone);
`
	if _, err := db.Exec(schema); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	for _, col := range []struct {
		name string
		def  string
	}{
		{"membership_tier", "TEXT NOT NULL DEFAULT 'free'"},
		{"membership_expire_at", "TEXT"},
		{"theme_preference", "TEXT NOT NULL DEFAULT 'notion'"},
	} {
		_, _ = db.Exec(fmt.Sprintf(`ALTER TABLE users ADD COLUMN %s %s`, col.name, col.def))
	}

	return nil
}

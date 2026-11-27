// Package store keeps Cellar's lists: servers and database connections
// (the document that is synced through Shard as one record) and what
// belongs to this device only (pasted SSH keys). Both files are sealed on
// disk with a key from the OS keychain (see seal.go).
package store

import (
	"bytes"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"maps"
	"slices"
	"strings"
	"time"
)

// Auth methods of a server.
const (
	AuthPassword = "password"
	AuthKey      = "key"
	AuthAgent    = "agent"
)

// Key id prefixes: a key of Shard's safe, or one kept on this device.
const (
	SafeKeyPrefix  = "safe:"
	LocalKeyPrefix = "local:"
)

// Server is a machine reached over SSH. With Shard's "servers" scope
// the list lives in Shard (shared with other apps); otherwise in Doc.
type Server struct {
	ID           string            `json:"id"`
	Name         string            `json:"name"`
	Group        string            `json:"group,omitempty"`
	Host         string            `json:"host"`
	Port         int               `json:"port,omitempty"`
	User         string            `json:"user"`
	Auth         string            `json:"auth"`
	Password     string            `json:"password,omitempty"`
	KeyID        string            `json:"key_id,omitempty"`
	HostKeys     []string          `json:"host_keys,omitempty"`
	JumpServerID string            `json:"jump_server_id,omitempty"`
	Notes        string            `json:"notes,omitempty"`
	Extra        map[string][]byte `json:"extra,omitempty"`
	UpdatedMs    int64             `json:"updated_ms"`
	// Shared: the entry lives in Shard's list (not encoded).
	Shared   bool   `json:"-"`
	Revision string `json:"-"`
}

// SSHPort is Port or 22.
func (s Server) SSHPort() int {
	if s.Port == 0 {
		return 22
	}
	return s.Port
}

// Connection is a database endpoint: through a server's SSH connection
// (ServerID) or direct from this device.
type Connection struct {
	ID        string   `json:"id"`
	Name      string   `json:"name"`
	ServerID  string   `json:"server_id,omitempty"`
	Kind      string   `json:"kind"` // "postgres"
	Host      string   `json:"host"`
	Port      int      `json:"port,omitempty"`
	User      string   `json:"user"`
	Password  string   `json:"password,omitempty"`
	Database  string   `json:"database,omitempty"`
	SSLMode   string   `json:"ssl_mode,omitempty"` // disable, prefer, require
	Source    string   `json:"source,omitempty"`
	Color     string   `json:"color,omitempty"`
	Databases []string `json:"databases,omitempty"`
	ReadOnly  bool     `json:"read_only,omitempty"`
	UpdatedMs int64    `json:"updated_ms"`
}

// KindPostgres is the only kind for now.
const KindPostgres = "postgres"

// PGPort is Port or 5432.
func (c Connection) PGPort() int {
	if c.Port == 0 {
		return 5432
	}
	return c.Port
}

// Removed is a tombstone: an item deleted on one device stays deleted
// when another device's older copy is merged in.
type Removed struct {
	ID   string `json:"id"`
	AtMs int64  `json:"at_ms"`
}

// Doc is the synced document (record "cellar.json").
type Doc struct {
	Version     int          `json:"version"`
	Servers     []Server     `json:"servers"`
	Connections []Connection `json:"connections"`
	Removed     []Removed    `json:"removed,omitempty"`
}

// FormatVersion of Doc; only a breaking change bumps it.
const FormatVersion = 1

// TombstoneTTL: tombstones older than this (relative to the newest time in
// the document, so every device prunes alike) are dropped.
const TombstoneTTL = 90 * 24 * time.Hour

// ErrNotFound is returned for an unknown id.
var ErrNotFound = errors.New("not found")

// Decode parses a document; empty input is an empty one.
func Decode(data []byte) (Doc, error) {
	var d Doc
	if len(bytes.TrimSpace(data)) == 0 {
		return Doc{Version: FormatVersion}, nil
	}
	if err := json.Unmarshal(data, &d); err != nil {
		return Doc{}, fmt.Errorf("store: %w", err)
	}
	if d.Version > FormatVersion {
		return Doc{}, fmt.Errorf("store: format %d is newer than this app (%d)", d.Version, FormatVersion)
	}
	return d.normalized(), nil
}

// Encode returns the canonical bytes of d.
func Encode(d Doc) []byte {
	data, err := json.MarshalIndent(d.normalized(), "", "  ")
	if err != nil {
		panic(err) // plain structs
	}
	return append(data, '\n')
}

// Hash of bytes, hex.
func Hash(data []byte) string {
	s := sha256.Sum256(data)
	return hex.EncodeToString(s[:])
}

func (d Doc) normalized() Doc {
	ss := slices.Clone(d.Servers)
	cs := slices.Clone(d.Connections)
	rs := slices.Clone(d.Removed)
	if ss == nil {
		ss = []Server{}
	}
	if cs == nil {
		cs = []Connection{}
	}
	slices.SortFunc(ss, func(a, b Server) int { return strings.Compare(a.ID, b.ID) })
	slices.SortFunc(cs, func(a, b Connection) int { return strings.Compare(a.ID, b.ID) })
	slices.SortFunc(rs, func(a, b Removed) int { return strings.Compare(a.ID, b.ID) })
	if len(rs) == 0 {
		rs = nil
	}
	return Doc{Version: FormatVersion, Servers: ss, Connections: cs, Removed: rs}
}

// Merge folds documents into one. It depends only on the set of inputs
// (not their order), so every device merging the same versions gets the
// same bytes: per id the newest UpdatedMs wins (ties: the larger
// encoding); tombstones are united, and a tombstone at or after an item's
// UpdatedMs removes it (an edit after the removal brings it back).
func Merge(docs ...Doc) Doc {
	servers := map[string]Server{}
	conns := map[string]Connection{}
	dead := map[string]int64{}
	var newest int64
	for _, d := range docs {
		for _, s := range d.Servers {
			newest = max(newest, s.UpdatedMs)
			if cur, ok := servers[s.ID]; !ok || newer(s.UpdatedMs, cur.UpdatedMs, s, cur) {
				servers[s.ID] = s
			}
		}
		for _, c := range d.Connections {
			newest = max(newest, c.UpdatedMs)
			if cur, ok := conns[c.ID]; !ok || newer(c.UpdatedMs, cur.UpdatedMs, c, cur) {
				conns[c.ID] = c
			}
		}
		for _, r := range d.Removed {
			newest = max(newest, r.AtMs)
			dead[r.ID] = max(dead[r.ID], r.AtMs)
		}
	}
	out := Doc{Version: FormatVersion}
	for _, id := range slices.Sorted(maps.Keys(servers)) {
		if at, ok := dead[id]; !ok || at < servers[id].UpdatedMs {
			out.Servers = append(out.Servers, servers[id])
		}
	}
	for _, id := range slices.Sorted(maps.Keys(conns)) {
		if at, ok := dead[id]; !ok || at < conns[id].UpdatedMs {
			out.Connections = append(out.Connections, conns[id])
		}
	}
	cut := newest - TombstoneTTL.Milliseconds()
	for id, at := range dead {
		if at >= cut {
			out.Removed = append(out.Removed, Removed{ID: id, AtMs: at})
		}
	}
	return out.normalized()
}

func newer(ta, tb int64, a, b any) bool {
	if ta != tb {
		return ta > tb
	}
	ea, _ := json.Marshal(a)
	eb, _ := json.Marshal(b)
	return bytes.Compare(ea, eb) > 0
}

// NewID returns a random id.
func NewID() string {
	var b [12]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b[:])
}

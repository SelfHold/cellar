package store

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"
)

// File names in the data dir.
const (
	DocFile    = "dbmanager.json"
	DeviceFile = "device.json"
)

// LocalKey is an SSH private key the user pasted or loaded on this device.
// It is never synced: the UI suggests the CloudSync safe for keys that
// other devices need.
type LocalKey struct {
	ID         string `json:"id"`
	Title      string `json:"title"`
	PrivateKey string `json:"private_key"`
	Passphrase string `json:"passphrase,omitempty"`
	CreatedMs  int64  `json:"created_ms"`
}

// Device is what belongs to this device only.
type Device struct {
	LocalKeys []LocalKey `json:"local_keys,omitempty"`
	// ServerKeys: a local key chosen for a shared server (whose synced
	// entry can only name keys of the safe), server id -> local key id.
	ServerKeys map[string]string `json:"server_keys,omitempty"`
}

// What changed (OnChange).
const (
	ChangedServers     = "servers"
	ChangedConnections = "connections"
	ChangedKeys        = "keys"
)

// Store is the working copy of the document and the device file. The app
// reads and writes it whether or not CloudSync is there.
type Store struct {
	dir   string
	seal  *Sealer
	now   func() time.Time
	mu    sync.Mutex
	doc   Doc
	dev   Device
	hooks []func(what string)
}

// Open loads the files of dir (missing files are empty).
func Open(dir string, seal *Sealer) (*Store, error) {
	s := &Store{dir: dir, seal: seal, now: time.Now}
	data, err := s.read(DocFile)
	if err != nil {
		return nil, err
	}
	if s.doc, err = Decode(data); err != nil {
		return nil, err
	}
	data, err = s.read(DeviceFile)
	if err != nil {
		return nil, err
	}
	if len(bytes.TrimSpace(data)) > 0 {
		if err := json.Unmarshal(data, &s.dev); err != nil {
			return nil, fmt.Errorf("store: %s: %w", DeviceFile, err)
		}
	}
	return s, nil
}

func (s *Store) read(name string) ([]byte, error) {
	data, err := os.ReadFile(filepath.Join(s.dir, name))
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return s.seal.Open(name, data)
}

func (s *Store) write(name string, plain []byte) error {
	return writeAtomic(filepath.Join(s.dir, name), s.seal.Seal(name, plain))
}

// OnChange registers fn, called after every change (local or replaced).
func (s *Store) OnChange(fn func(what string)) {
	s.mu.Lock()
	s.hooks = append(s.hooks, fn)
	s.mu.Unlock()
}

func (s *Store) changed(what ...string) {
	s.mu.Lock()
	fns := slices.Clone(s.hooks)
	s.mu.Unlock()
	for _, w := range what {
		for _, fn := range fns {
			fn(w)
		}
	}
}

// --- the document ------------------------------------------------------

// Doc returns the current document.
func (s *Store) Doc() Doc {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.doc.normalized()
}

// Bytes returns the canonical bytes of the document (what is synced).
func (s *Store) Bytes() []byte {
	s.mu.Lock()
	defer s.mu.Unlock()
	return Encode(s.doc)
}

// Replace writes d as the document (after a merge or a download) and
// reports whether anything changed.
func (s *Store) Replace(d Doc) (bool, error) {
	s.mu.Lock()
	return s.replaceLocked(d)
}

// ReplaceIf is Replace, but only while the document still has the bytes
// old: a sync that read it before a local edit never overwrites the edit.
func (s *Store) ReplaceIf(old []byte, d Doc) (ok, changed bool, err error) {
	s.mu.Lock()
	if !bytes.Equal(Encode(s.doc), old) {
		s.mu.Unlock()
		return false, false, nil
	}
	changed, err = s.replaceLocked(d)
	return err == nil, changed, err
}

// replaceLocked unlocks s.mu.
func (s *Store) replaceLocked(d Doc) (bool, error) {
	old := s.doc
	if bytes.Equal(Encode(d), Encode(old)) {
		s.mu.Unlock()
		return false, nil
	}
	if err := s.write(DocFile, Encode(d)); err != nil {
		s.mu.Unlock()
		return false, err
	}
	s.doc = d.normalized()
	s.mu.Unlock()
	var what []string
	if !jsonEqual(old.Servers, d.Servers) {
		what = append(what, ChangedServers)
	}
	if !jsonEqual(old.Connections, d.Connections) {
		what = append(what, ChangedConnections)
	}
	s.changed(what...)
	return true, nil
}

func jsonEqual(a, b any) bool {
	ea, _ := json.Marshal(a)
	eb, _ := json.Marshal(b)
	return bytes.Equal(ea, eb)
}

// update applies fn to a copy of the document and writes it.
func (s *Store) update(what string, fn func(d *Doc) error) error {
	s.mu.Lock()
	d := s.doc.normalized()
	d.Servers = slices.Clone(d.Servers)
	d.Connections = slices.Clone(d.Connections)
	d.Removed = slices.Clone(d.Removed)
	if err := fn(&d); err != nil {
		s.mu.Unlock()
		return err
	}
	if err := s.write(DocFile, Encode(d)); err != nil {
		s.mu.Unlock()
		return err
	}
	s.doc = d.normalized()
	s.mu.Unlock()
	s.changed(what)
	return nil
}

// stamp is "now", but always after the item's last known time, so an edit
// on a device with a slow clock still wins over the version it replaces.
func (d *Doc) stamp(id string, now time.Time) int64 {
	t := now.UnixMilli()
	for _, x := range d.Servers {
		if x.ID == id && x.UpdatedMs >= t {
			t = x.UpdatedMs + 1
		}
	}
	for _, x := range d.Connections {
		if x.ID == id && x.UpdatedMs >= t {
			t = x.UpdatedMs + 1
		}
	}
	for _, r := range d.Removed {
		if r.ID == id && r.AtMs >= t {
			t = r.AtMs + 1
		}
	}
	return t
}

func (d *Doc) bury(id string, at int64) {
	d.Removed = append(slices.DeleteFunc(d.Removed, func(r Removed) bool { return r.ID == id }), Removed{ID: id, AtMs: at})
}

// --- servers of this app's own list ------------------------------------------

// Servers returns the own servers, sorted by group, then name.
func (s *Store) Servers() []Server {
	s.mu.Lock()
	out := slices.Clone(s.doc.Servers)
	s.mu.Unlock()
	SortServers(out)
	return out
}

// SortServers sorts by group, then name (case-insensitive).
func SortServers(ss []Server) {
	slices.SortFunc(ss, func(a, b Server) int {
		if c := strings.Compare(strings.ToLower(a.Group), strings.ToLower(b.Group)); c != 0 {
			return c
		}
		if c := strings.Compare(strings.ToLower(a.Name), strings.ToLower(b.Name)); c != 0 {
			return c
		}
		return strings.Compare(a.ID, b.ID)
	})
}

// Server returns one own server.
func (s *Store) Server(id string) (Server, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, x := range s.doc.Servers {
		if x.ID == id {
			return x, nil
		}
	}
	return Server{}, ErrNotFound
}

// SaveServer creates (empty id) or replaces an own server.
func (s *Store) SaveServer(x Server) (Server, error) {
	if err := ValidateServer(x); err != nil {
		return Server{}, err
	}
	err := s.update(ChangedServers, func(d *Doc) error {
		if x.ID == "" {
			x.ID = NewID()
		}
		x.Shared, x.Revision = false, ""
		x.UpdatedMs = d.stamp(x.ID, s.now())
		d.Servers = append(slices.DeleteFunc(d.Servers, func(y Server) bool { return y.ID == x.ID }), x)
		d.Removed = slices.DeleteFunc(d.Removed, func(r Removed) bool { return r.ID == x.ID })
		return nil
	})
	return x, err
}

// DeleteServer removes an own server and leaves a tombstone. Connections
// through it are kept (they may belong to a shared server of that id).
func (s *Store) DeleteServer(id string) error {
	return s.update(ChangedServers, func(d *Doc) error {
		n := len(d.Servers)
		at := d.stamp(id, s.now())
		d.Servers = slices.DeleteFunc(d.Servers, func(y Server) bool { return y.ID == id })
		if len(d.Servers) == n {
			return ErrNotFound
		}
		d.bury(id, at)
		return nil
	})
}

// DropServers forgets own servers without tombstones' effect on others:
// used after moving them to the shared list (same ids there), so other
// devices drop their copies too.
func (s *Store) DropServers(ids []string) error {
	return s.update(ChangedServers, func(d *Doc) error {
		for _, id := range ids {
			at := d.stamp(id, s.now())
			d.Servers = slices.DeleteFunc(d.Servers, func(y Server) bool { return y.ID == id })
			d.bury(id, at)
		}
		return nil
	})
}

// ReplaceServerID re-keys connections of server old to new (a server got
// another id when it moved to the shared list).
func (s *Store) ReplaceServerID(old, newID string) error {
	return s.update(ChangedConnections, func(d *Doc) error {
		for i, c := range d.Connections {
			if c.ServerID == old {
				c.ServerID = newID
				c.UpdatedMs = d.stamp(c.ID, s.now())
				d.Connections[i] = c
			}
		}
		return nil
	})
}

// ValidateServer checks what an SSH connection needs.
func ValidateServer(x Server) error {
	switch {
	case strings.TrimSpace(x.Name) == "":
		return errors.New("the server needs a name")
	case strings.TrimSpace(x.Host) == "":
		return errors.New("the server needs an address")
	case x.Port < 0 || x.Port > 65535:
		return errors.New("the port must be 1–65535")
	case strings.TrimSpace(x.User) == "":
		return errors.New("the server needs a user name")
	}
	switch x.Auth {
	case AuthPassword, AuthAgent:
	case AuthKey:
		if x.KeyID != "" && !strings.HasPrefix(x.KeyID, SafeKeyPrefix) && !strings.HasPrefix(x.KeyID, LocalKeyPrefix) {
			return fmt.Errorf("unknown key %q", x.KeyID)
		}
	default:
		return fmt.Errorf("unknown login method %q", x.Auth)
	}
	if x.JumpServerID == x.ID && x.ID != "" {
		return errors.New("a server cannot be its own jump server")
	}
	return nil
}

// --- connections ---------------------------------------------------------------

// Connections returns every connection, sorted by name.
func (s *Store) Connections() []Connection {
	s.mu.Lock()
	out := slices.Clone(s.doc.Connections)
	s.mu.Unlock()
	slices.SortFunc(out, func(a, b Connection) int {
		if c := strings.Compare(strings.ToLower(a.Name), strings.ToLower(b.Name)); c != 0 {
			return c
		}
		return strings.Compare(a.ID, b.ID)
	})
	return out
}

// Connection returns one connection.
func (s *Store) Connection(id string) (Connection, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, c := range s.doc.Connections {
		if c.ID == id {
			return c, nil
		}
	}
	return Connection{}, ErrNotFound
}

// SaveConnection creates (empty id) or replaces a connection.
func (s *Store) SaveConnection(c Connection) (Connection, error) {
	if c.Kind == "" {
		c.Kind = KindPostgres
	}
	if err := ValidateConnection(c); err != nil {
		return Connection{}, err
	}
	err := s.update(ChangedConnections, func(d *Doc) error {
		if c.ID == "" {
			c.ID = NewID()
		}
		c.UpdatedMs = d.stamp(c.ID, s.now())
		d.Connections = append(slices.DeleteFunc(d.Connections, func(y Connection) bool { return y.ID == c.ID }), c)
		d.Removed = slices.DeleteFunc(d.Removed, func(r Removed) bool { return r.ID == c.ID })
		return nil
	})
	return c, err
}

// DeleteConnection removes a connection and leaves a tombstone.
func (s *Store) DeleteConnection(id string) error {
	return s.update(ChangedConnections, func(d *Doc) error {
		n := len(d.Connections)
		at := d.stamp(id, s.now())
		d.Connections = slices.DeleteFunc(d.Connections, func(y Connection) bool { return y.ID == id })
		if len(d.Connections) == n {
			return ErrNotFound
		}
		d.bury(id, at)
		return nil
	})
}

// ValidateConnection checks a connection.
func ValidateConnection(c Connection) error {
	switch {
	case c.Kind != KindPostgres:
		return fmt.Errorf("unknown database kind %q", c.Kind)
	case strings.TrimSpace(c.Name) == "":
		return errors.New("the connection needs a name")
	case strings.TrimSpace(c.Host) == "":
		return errors.New("the connection needs a host")
	case c.Port < 0 || c.Port > 65535:
		return errors.New("the port must be 1–65535")
	case strings.TrimSpace(c.User) == "":
		return errors.New("the connection needs a user name")
	}
	switch c.SSLMode {
	case "", "disable", "prefer", "require":
	default:
		return fmt.Errorf("unknown SSL mode %q", c.SSLMode)
	}
	return nil
}

// --- this device -------------------------------------------------------------

// LocalKeys returns the keys of this device, by title.
func (s *Store) LocalKeys() []LocalKey {
	s.mu.Lock()
	out := slices.Clone(s.dev.LocalKeys)
	s.mu.Unlock()
	slices.SortFunc(out, func(a, b LocalKey) int { return strings.Compare(strings.ToLower(a.Title), strings.ToLower(b.Title)) })
	return out
}

// LocalKey returns one key of this device (id without the "local:" prefix).
func (s *Store) LocalKey(id string) (LocalKey, error) {
	id = strings.TrimPrefix(id, LocalKeyPrefix)
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, k := range s.dev.LocalKeys {
		if k.ID == id {
			return k, nil
		}
	}
	return LocalKey{}, ErrNotFound
}

func (s *Store) updateDevice(fn func(d *Device) error) error {
	s.mu.Lock()
	d := Device{LocalKeys: slices.Clone(s.dev.LocalKeys), ServerKeys: map[string]string{}}
	for k, v := range s.dev.ServerKeys {
		d.ServerKeys[k] = v
	}
	if err := fn(&d); err != nil {
		s.mu.Unlock()
		return err
	}
	if len(d.ServerKeys) == 0 {
		d.ServerKeys = nil
	}
	data, _ := json.MarshalIndent(d, "", "  ")
	if err := s.write(DeviceFile, data); err != nil {
		s.mu.Unlock()
		return err
	}
	s.dev = d
	s.mu.Unlock()
	s.changed(ChangedKeys)
	return nil
}

// SaveLocalKey keeps a key on this device (the caller checked it parses).
func (s *Store) SaveLocalKey(k LocalKey) (LocalKey, error) {
	if strings.TrimSpace(k.PrivateKey) == "" {
		return LocalKey{}, errors.New("the key is empty")
	}
	if k.ID == "" {
		k.ID = NewID()
	}
	if k.CreatedMs == 0 {
		k.CreatedMs = s.now().UnixMilli()
	}
	err := s.updateDevice(func(d *Device) error {
		d.LocalKeys = append(slices.DeleteFunc(d.LocalKeys, func(x LocalKey) bool { return x.ID == k.ID }), k)
		return nil
	})
	return k, err
}

// DeleteLocalKey forgets a key of this device.
func (s *Store) DeleteLocalKey(id string) error {
	id = strings.TrimPrefix(id, LocalKeyPrefix)
	return s.updateDevice(func(d *Device) error {
		n := len(d.LocalKeys)
		d.LocalKeys = slices.DeleteFunc(d.LocalKeys, func(x LocalKey) bool { return x.ID == id })
		if len(d.LocalKeys) == n {
			return ErrNotFound
		}
		for sid, kid := range d.ServerKeys {
			if kid == id {
				delete(d.ServerKeys, sid)
			}
		}
		return nil
	})
}

// ServerKey returns the local key id chosen for a shared server ("" none).
func (s *Store) ServerKey(serverID string) string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.dev.ServerKeys[serverID]
}

// SetServerKey chooses a local key for a shared server ("" = none).
func (s *Store) SetServerKey(serverID, keyID string) error {
	keyID = strings.TrimPrefix(keyID, LocalKeyPrefix)
	if s.ServerKey(serverID) == keyID {
		return nil
	}
	return s.updateDevice(func(d *Device) error {
		if keyID == "" {
			delete(d.ServerKeys, serverID)
		} else {
			d.ServerKeys[serverID] = keyID
		}
		return nil
	})
}

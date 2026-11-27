package cloudsync

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"dbmanager/core/cloudsync/pb"
	"dbmanager/core/keychain"
	"dbmanager/core/store"
)

const (
	// AppID is DB Manager's data in CloudSync: never change it.
	AppID = "dbmanager"
	// RecordKey holds the document (store.Doc) bytes.
	RecordKey = "dbmanager.json"
	// MaxRecord is CloudSync's limit for one record.
	MaxRecord = 256 << 10

	ScopeSSHKeys = "ssh_keys"
	ScopeServers = "servers"

	// ExtraPrefix marks DB Manager's keys in Server.extra.
	ExtraPrefix = AppID + "."
)

// Phase is SyncState.Phase of dbm.proto (same numbers).
type Phase int32

const (
	PhaseOff        Phase = 1
	PhaseNotRunning Phase = 2
	PhaseNoVault    Phase = 3
	PhaseLocked     Phase = 4
	PhasePairing    Phase = 5
	PhaseOffline    Phase = 6
	PhaseSynced     Phase = 7
	PhaseError      Phase = 8
)

// State is what the app shows.
type State struct {
	Phase         Phase
	Enabled       bool
	Available     bool
	PairingCode   string
	Error         string
	Pending       bool
	LastSyncMs    int64
	DeviceName    string
	SharedServers bool // scope "servers" granted
	SafeKeys      bool // scope "ssh_keys" granted
}

// What changed (Options.OnChange).
const (
	ChangedSync    = "sync"
	ChangedServers = "servers"
	ChangedKeys    = "keys"
)

// Options configure a Syncer.
type Options struct {
	Dialer Dialer
	Store  *store.Store
	Seal   *store.Sealer
	// Dir keeps this device's sync state (cloudsync.json, the shared
	// servers cache; the token too when there is no keychain).
	Dir         string
	Keychain    keychain.Keychain
	AppName     string // "DB Manager"
	Description string // "DB Manager 0.1 on linux"
	Log         func(level, msg string)
	OnChange    func(what string)
}

// saved is this device's sync state (CONNECTOR.md § 7); never synced.
type saved struct {
	Enabled    bool   `json:"enabled"`
	VaultID    string `json:"vault_id,omitempty"`
	Base       string `json:"base,omitempty"`
	SyncedHash string `json:"synced_hash,omitempty"`
	SyncedMs   int64  `json:"synced_ms,omitempty"`
}

// SafeKey is an SSH key of CloudSync's safe, without its secrets.
type SafeKey struct {
	ID            string `json:"id"`
	Title         string `json:"title"`
	KeyType       string `json:"key_type"`
	Fingerprint   string `json:"fingerprint"`
	PublicKey     string `json:"public_key"`
	Comment       string `json:"comment,omitempty"`
	Encrypted     bool   `json:"encrypted,omitempty"`
	HasPassphrase bool   `json:"has_passphrase,omitempty"`
	Group         string `json:"group,omitempty"`
}

// cache is what CloudSync gave last, for when it is not running: the
// shared servers (with secrets, sealed on disk) and the safe's key list.
type cache struct {
	VaultID string         `json:"vault_id"`
	Cursor  string         `json:"cursor,omitempty"`
	Scopes  []string       `json:"scopes,omitempty"`
	Servers []cachedServer `json:"servers,omitempty"`
	Keys    []SafeKey      `json:"keys,omitempty"`
}

type cachedServer struct {
	store.Server
	Rev string `json:"revision"`
}

const cacheFile = "cloudsync-cache.json"

// Errors.
var (
	// ErrNoShared: the shared list needs CloudSync running with the
	// "servers" scope.
	ErrNoShared = status.Error(codes.FailedPrecondition, "the shared server list needs CloudSync (running, unlocked, scope \"servers\")")
	// ErrNoSafe: the safe's keys need CloudSync running with "ssh_keys".
	ErrNoSafe = status.Error(codes.FailedPrecondition, "the SSH keys of the CloudSync safe need CloudSync running and unlocked, with the \"ssh_keys\" scope")
)

// Syncer keeps DB Manager's document in CloudSync and serves the shared
// servers and the safe's SSH keys while CloudSync is there.
type Syncer struct {
	o Options

	// Delays (tests shorten them).
	RetryDelay time.Duration
	ProbeDelay time.Duration
	Heartbeat  time.Duration

	kick   chan struct{}
	ctx    context.Context
	cancel context.CancelFunc
	done   chan struct{}

	mu         sync.Mutex
	sv         saved
	token      *string
	st         State
	wantPair   bool
	pairCancel context.CancelFunc
	sessCancel context.CancelFunc
	live       Client // the session's client while it runs
	liveState  pb.VaultState
	cache      cache
}

// New returns a syncer; Start runs it.
func New(o Options) *Syncer {
	s := &Syncer{
		o:          o,
		RetryDelay: 30 * time.Second, ProbeDelay: time.Minute, Heartbeat: 30 * time.Second,
		kick: make(chan struct{}, 1), done: make(chan struct{}),
	}
	s.ctx, s.cancel = context.WithCancel(context.Background())
	s.load()
	s.st = State{Phase: PhaseNotRunning, Enabled: s.sv.Enabled, LastSyncMs: s.sv.SyncedMs}
	if !s.sv.Enabled {
		s.st.Phase = PhaseOff
	}
	if s.sv.Enabled {
		s.st.SharedServers = slices.Contains(s.cache.Scopes, ScopeServers)
		s.st.SafeKeys = slices.Contains(s.cache.Scopes, ScopeSSHKeys)
	}
	return s
}

// Start runs the syncer until Close.
func (s *Syncer) Start() { go s.loop() }

// Close stops it.
func (s *Syncer) Close() {
	s.cancel()
	<-s.done
}

// Kick makes the syncer look at once (the document changed, ...).
func (s *Syncer) Kick() {
	select {
	case s.kick <- struct{}{}:
	default:
	}
}

// State returns what to show.
func (s *Syncer) State() State {
	s.mu.Lock()
	defer s.mu.Unlock()
	st := s.st
	if st.Enabled && st.Phase != PhasePairing {
		st.Pending = store.Hash(s.o.Store.Bytes()) != s.sv.SyncedHash
	}
	return st
}

// Enable switches sync on: it pairs this device when it is not paired (or
// lacks the scopes), then syncs.
func (s *Syncer) Enable() State {
	s.mu.Lock()
	s.wantPair = true
	s.st.Error = ""
	if !s.sv.Enabled {
		s.sv.Base, s.sv.SyncedHash = "", ""
	}
	s.mu.Unlock()
	s.changed(ChangedSync)
	s.Kick()
	return s.State()
}

// Disable switches sync off and unpairs; the local document stays. The
// shared servers stay in CloudSync, but this app no longer sees them.
func (s *Syncer) Disable(ctx context.Context) State {
	s.mu.Lock()
	s.sv = saved{}
	s.wantPair = false
	if s.pairCancel != nil {
		s.pairCancel()
	}
	if s.sessCancel != nil {
		s.sessCancel()
	}
	s.cache = cache{}
	s.st = State{Phase: PhaseOff, Available: s.st.Available, DeviceName: s.st.DeviceName}
	s.mu.Unlock()
	s.save()
	s.saveCache()
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	if c, err := s.o.Dialer.Dial(ctx, s.loadToken()); err == nil {
		if _, err := c.Unpair(ctx, &pb.UnpairRequest{}); err != nil && status.Code(err) != codes.Unauthenticated {
			s.logf("warn", "unpair: "+err.Error())
		}
		c.Close()
	}
	s.clearToken()
	s.logf("info", "sync via CloudSync is off")
	s.changed(ChangedSync, ChangedServers, ChangedKeys)
	s.Kick()
	return s.State()
}

// --- shared servers and safe keys --------------------------------------------

// SharedServers returns the shared list as CloudSync gave it last, and
// whether the list is in use (scope granted, sync on).
func (s *Syncer) SharedServers() ([]store.Server, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.sv.Enabled || !slices.Contains(s.cache.Scopes, ScopeServers) {
		return nil, false
	}
	out := make([]store.Server, 0, len(s.cache.Servers))
	for _, c := range s.cache.Servers {
		x := c.Server
		x.Shared, x.Revision = true, c.Rev
		out = append(out, x)
	}
	store.SortServers(out)
	return out, true
}

// SharedServer returns one shared server.
func (s *Syncer) SharedServer(id string) (store.Server, bool) {
	ss, _ := s.SharedServers()
	for _, x := range ss {
		if x.ID == id {
			return x, true
		}
	}
	return store.Server{}, false
}

// client returns the live client and its vault state, or an error saying
// why there is none.
func (s *Syncer) client(noneErr error) (Client, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.live == nil {
		return nil, noneErr
	}
	switch s.liveState {
	case pb.VaultState_LOCKED:
		return nil, status.Error(codes.FailedPrecondition, "unlock CloudSync first")
	}
	return s.live, nil
}

// PutServer creates or replaces a shared server (x.Revision is the base).
func (s *Syncer) PutServer(ctx context.Context, x store.Server) (store.Server, error) {
	c, err := s.client(ErrNoShared)
	if err != nil {
		return store.Server{}, err
	}
	base := x.Revision
	if x.ID == "" {
		base = ""
	}
	out, err := c.PutServer(ctx, &pb.PutServerRequest{Server: ServerToPB(x), Base: base})
	if status.Code(err) == codes.Aborted && x.ID != "" {
		// Changed meanwhile (another app or device): apply the user's
		// edit to the current version, keeping fields this app does not
		// edit (extra of other apps).
		got, gerr := c.GetServers(ctx, &pb.GetServersRequest{Ids: []string{x.ID}})
		if gerr == nil && len(got.Servers) == 1 {
			cur := got.Servers[0]
			p := ServerToPB(x)
			for k, v := range cur.Extra {
				if !strings.HasPrefix(k, ExtraPrefix) {
					if p.Extra == nil {
						p.Extra = map[string][]byte{}
					}
					p.Extra[k] = v
				}
			}
			out, err = c.PutServer(ctx, &pb.PutServerRequest{Server: p, Base: cur.Revision})
		}
	}
	if err != nil {
		return store.Server{}, explain(err)
	}
	res := ServerFromPB(out)
	s.mu.Lock()
	s.cache.Servers = slices.DeleteFunc(s.cache.Servers, func(c cachedServer) bool { return c.ID == res.ID })
	s.cache.Servers = append(s.cache.Servers, cachedServer{Server: res, Rev: res.Revision})
	s.mu.Unlock()
	s.saveCache()
	s.changed(ChangedServers)
	return res, nil
}

// DeleteServer removes a shared server.
func (s *Syncer) DeleteServer(ctx context.Context, id string) error {
	c, err := s.client(ErrNoShared)
	if err != nil {
		return err
	}
	x, ok := s.SharedServer(id)
	if !ok {
		return status.Error(codes.NotFound, "no such server")
	}
	_, err = c.DeleteServer(ctx, &pb.DeleteServerRequest{Id: id, Base: x.Revision})
	if status.Code(err) == codes.Aborted {
		if got, gerr := c.GetServers(ctx, &pb.GetServersRequest{Ids: []string{id}}); gerr == nil && len(got.Servers) == 1 {
			_, err = c.DeleteServer(ctx, &pb.DeleteServerRequest{Id: id, Base: got.Servers[0].Revision})
		}
	}
	if err != nil && status.Code(err) != codes.NotFound {
		return explain(err)
	}
	s.mu.Lock()
	s.cache.Servers = slices.DeleteFunc(s.cache.Servers, func(c cachedServer) bool { return c.ID == id })
	s.mu.Unlock()
	s.saveCache()
	s.changed(ChangedServers)
	return nil
}

// SafeKeys returns the safe's keys as CloudSync listed them last, and a
// note when they are not available.
func (s *Syncer) SafeKeys() ([]SafeKey, string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	switch {
	case !s.sv.Enabled:
		return nil, "Switch on sync via CloudSync to use the SSH keys of its safe."
	case !slices.Contains(s.cache.Scopes, ScopeSSHKeys):
		return nil, "CloudSync did not grant access to its SSH keys (scope \"ssh_keys\"): switch sync on again to ask."
	}
	return slices.Clone(s.cache.Keys), ""
}

// SafeKeySecret fetches the private key and passphrase of a safe key. It
// is never stored: callers keep it in memory for one connection.
func (s *Syncer) SafeKeySecret(ctx context.Context, id string) (privateKey, passphrase string, err error) {
	c, err := s.client(ErrNoSafe)
	if err != nil {
		return "", "", err
	}
	r, err := c.GetSshKeys(ctx, &pb.GetSshKeysRequest{Ids: []string{id}})
	if err != nil {
		return "", "", explain(err)
	}
	if len(r.Keys) == 0 {
		return "", "", status.Error(codes.NotFound, "the SSH key is not in the CloudSync safe any more")
	}
	return r.Keys[0].PrivateKey, r.Keys[0].Passphrase, nil
}

func explain(err error) error {
	switch status.Code(err) {
	case codes.Unimplemented:
		return status.Error(codes.FailedPrecondition, "this CloudSync does not offer shared servers and SSH keys yet: update CloudSync")
	case codes.PermissionDenied:
		return status.Error(codes.PermissionDenied, "CloudSync did not grant this access: switch sync on again to ask")
	case codes.Unavailable:
		return status.Error(codes.Unavailable, "CloudSync is offline (no storage answers): try again later")
	}
	return err
}

// --- the loop ----------------------------------------------------------------

func (s *Syncer) loop() {
	defer close(s.done)
	for s.ctx.Err() == nil {
		wait := s.session()
		if wait <= 0 {
			continue
		}
		t := time.NewTimer(wait)
		select {
		case <-s.ctx.Done():
		case <-s.kick:
		case <-t.C:
		}
		t.Stop()
	}
}

// session connects, pairs when asked to and syncs until the connection or
// the sync ends. It returns how long to wait before the next one.
func (s *Syncer) session() time.Duration {
	ctx, cancel := context.WithCancel(s.ctx)
	defer cancel()
	s.mu.Lock()
	s.sessCancel = cancel
	enabled, wantPair := s.sv.Enabled, s.wantPair
	s.mu.Unlock()

	c, err := s.o.Dialer.Dial(ctx, s.loadToken())
	if err != nil {
		s.unreachable(err)
		return s.RetryDelay
	}
	defer c.Close()
	hello, err := c.Hello(ctx, &pb.HelloRequest{AppId: AppID})
	if err != nil {
		s.unreachable(err)
		return s.RetryDelay
	}
	if hello.ApiVersion > APIVersion {
		s.unreachable(ErrTooNew)
		return s.ProbeDelay
	}
	s.update(func(st *State) {
		st.Available = hello.State != pb.VaultState_NO_VAULT
		st.DeviceName = hello.DeviceName
	})
	if hello.State == pb.VaultState_NO_VAULT {
		s.setPhase(PhaseNoVault, "Set up CloudSync first.")
		return s.ProbeDelay
	}
	if !enabled && !wantPair {
		s.setPhase(PhaseOff, "")
		return s.ProbeDelay
	}
	missing := !hello.Paired || !slices.Contains(hello.Scopes, ScopeServers) || !slices.Contains(hello.Scopes, ScopeSSHKeys)
	if wantPair && missing {
		if !s.pair(ctx, c) {
			return s.RetryDelay
		}
		if hello, err = c.Hello(ctx, &pb.HelloRequest{AppId: AppID}); err != nil {
			s.unreachable(err)
			return s.RetryDelay
		}
	}
	if !hello.Paired {
		s.unpaired()
		return s.ProbeDelay
	}
	s.mu.Lock()
	s.wantPair = false
	if s.sv.VaultID != "" && s.sv.VaultID != hello.VaultId {
		// Another CloudSync vault: never merge across vaults.
		s.sv = saved{}
		s.cache = cache{}
		s.st.Enabled = false
		s.mu.Unlock()
		s.save()
		s.saveCache()
		s.setPhase(PhaseOff, "CloudSync opened another vault, so sync is off: switch it on to sync with that vault.")
		s.changed(ChangedServers, ChangedKeys)
		return s.ProbeDelay
	}
	s.sv.Enabled = true
	s.sv.VaultID = hello.VaultId
	if s.cache.VaultID != hello.VaultId {
		s.cache = cache{VaultID: hello.VaultId}
	}
	s.st.Enabled = true
	s.live, s.liveState = c, hello.State
	s.mu.Unlock()
	defer func() {
		s.mu.Lock()
		s.live = nil
		s.mu.Unlock()
	}()
	s.save()
	s.setScopes(hello.Scopes)

	next, err := c.Watch(ctx)
	if err != nil {
		s.failed(err)
		return s.RetryDelay
	}
	type change struct {
		c   *pb.Change
		err error
	}
	changes := make(chan change, 16)
	go func() {
		for {
			ch, err := next()
			select {
			case changes <- change{ch, err}:
			case <-ctx.Done():
				return
			}
			if err != nil {
				return
			}
		}
	}()

	state := hello.State
	scopes := hello.Scopes
	for {
		if state == pb.VaultState_LOCKED {
			s.setPhase(PhaseLocked, "Unlock CloudSync to sync.")
		} else {
			s.refreshShared(ctx, c, scopes)
			if err := s.reconcile(ctx, c); err != nil {
				if errors.Is(err, errEnd) {
					return s.ProbeDelay
				}
				if st := status.Code(err); st == codes.Unavailable || st == codes.FailedPrecondition {
					s.setPhase(PhaseOffline, "")
				} else {
					s.failed(err)
				}
			} else if state == pb.VaultState_OFFLINE {
				s.setPhase(PhaseOffline, "")
			} else {
				s.setPhase(PhaseSynced, "")
			}
		}
		t := time.NewTimer(s.Heartbeat)
		select {
		case <-ctx.Done():
			t.Stop()
			return 0
		case <-s.kick:
		case <-t.C:
		case ch := <-changes:
			if ch.err != nil {
				t.Stop()
				if status.Code(ch.err) == codes.Unauthenticated {
					s.unpaired()
					return s.ProbeDelay
				}
				s.setPhase(PhaseNotRunning, "")
				return s.RetryDelay / 6
			}
			switch ch.c.Kind {
			case pb.Change_STATE, pb.Change_SCOPES:
				h, err := c.Hello(ctx, &pb.HelloRequest{AppId: AppID})
				if err != nil {
					t.Stop()
					return s.RetryDelay
				}
				if !h.Paired {
					t.Stop()
					s.unpaired()
					return s.ProbeDelay
				}
				if h.VaultId != hello.VaultId {
					t.Stop()
					return time.Millisecond // the next session turns sync off
				}
				state, scopes = h.State, h.Scopes
				s.mu.Lock()
				s.liveState = state
				s.mu.Unlock()
				s.setScopes(scopes)
			case pb.Change_UNPAIRED:
				t.Stop()
				s.unpaired()
				return s.ProbeDelay
			}
		}
		t.Stop()
	}
}

var errEnd = errors.New("end")

// pair asks CloudSync for the pairing (with both scopes) and waits for
// the user. It reports whether the device is paired now.
func (s *Syncer) pair(ctx context.Context, c Client) bool {
	t, err := c.RequestPairing(ctx, &pb.PairingRequest{
		AppId: AppID, AppName: s.o.AppName, Description: s.o.Description,
		Scopes: []string{ScopeServers, ScopeSSHKeys},
	})
	if status.Code(err) == codes.InvalidArgument {
		// An older CloudSync that knows no such scopes: records only.
		t, err = c.RequestPairing(ctx, &pb.PairingRequest{AppId: AppID, AppName: s.o.AppName, Description: s.o.Description})
	}
	if err != nil {
		s.failed(err)
		return false
	}
	pctx, pcancel := context.WithDeadline(ctx, time.UnixMilli(t.ExpiresUnixMs).Add(5*time.Second))
	defer pcancel()
	s.mu.Lock()
	s.pairCancel = pcancel
	s.mu.Unlock()
	code := t.Code
	if len(code) == 6 {
		code = code[:3] + " " + code[3:]
	}
	s.update(func(st *State) { st.Phase, st.PairingCode, st.Error = PhasePairing, code, "" })
	defer s.update(func(st *State) { st.PairingCode = "" })
	for {
		r, err := c.AwaitPairing(pctx, &pb.AwaitPairingRequest{Ticket: t.Ticket, WaitSeconds: 60})
		if err != nil {
			if pctx.Err() != nil {
				s.mu.Lock()
				s.wantPair = false
				s.mu.Unlock()
				s.setPhase(PhaseOff, "The pairing request expired: switch sync on to try again.")
				return false
			}
			s.failed(err)
			return false
		}
		switch r.Status {
		case pb.PairingStatus_PENDING:
			continue
		case pb.PairingStatus_APPROVED:
			if r.Token != "" {
				s.storeToken(r.Token)
				c.SetToken(r.Token)
			}
			s.logf("info", "paired with CloudSync, scopes: "+strings.Join(r.Scopes, ", "))
			return true
		case pb.PairingStatus_DENIED:
			s.mu.Lock()
			s.wantPair = false
			s.mu.Unlock()
			s.setPhase(PhaseOff, "CloudSync denied the pairing.")
			return false
		default:
			s.mu.Lock()
			s.wantPair = false
			s.mu.Unlock()
			s.setPhase(PhaseOff, "The pairing request expired: switch sync on to try again.")
			return false
		}
	}
}

// reconcile makes the local document and the record the same (CONNECTOR.md § 7): the
// document always merges (union by id with tombstones), so there is
// nothing to ask the user.
func (s *Syncer) reconcile(ctx context.Context, c Client) error {
	for attempt := 0; attempt < 4; attempt++ {
		local := s.o.Store.Bytes()
		h := store.Hash(local)
		s.mu.Lock()
		base, synced := s.sv.Base, s.sv.SyncedHash
		s.mu.Unlock()
		item, err := c.Get(ctx, &pb.GetRequest{Key: RecordKey})
		if status.Code(err) == codes.Unauthenticated {
			s.unpaired()
			return errEnd
		}
		if err != nil {
			return err
		}
		if item.Revision == base && h == synced && base != "" {
			return nil
		}
		docs := []store.Doc{}
		var remote []byte
		for _, v := range item.Versions {
			d, err := store.Decode(v.Data)
			if err != nil {
				return fmt.Errorf("the synced copy does not open (%v): it is left as it is", err)
			}
			docs = append(docs, d)
			remote = v.Data
		}
		localDoc, _ := store.Decode(local)
		merged := store.Merge(append(docs, localDoc)...)
		out := store.Encode(merged)
		ok, _, err := s.o.Store.ReplaceIf(local, merged)
		if err != nil {
			return err
		}
		if !ok {
			continue // edited meanwhile: start over
		}
		rev := item.Revision
		if len(item.Versions) != 1 || string(remote) != string(out) {
			if len(out) > MaxRecord {
				return fmt.Errorf("the server and connection list is too big for CloudSync (%d KiB, at most 256)", len(out)>>10)
			}
			put, err := c.Put(ctx, &pb.PutRequest{Key: RecordKey, Data: out, Base: item.Revision})
			if status.Code(err) == codes.Aborted {
				continue
			}
			if err != nil {
				return err
			}
			rev = put.Revision
		}
		s.mu.Lock()
		s.sv.Base, s.sv.SyncedHash, s.sv.SyncedMs = rev, store.Hash(out), time.Now().UnixMilli()
		s.st.LastSyncMs = s.sv.SyncedMs
		s.mu.Unlock()
		s.save()
		return nil
	}
	return errors.New("the synced copy keeps changing: will try again")
}

// refreshShared brings the shared servers and the safe's key list up to
// date. Errors only log: the document sync goes on without them.
func (s *Syncer) refreshShared(ctx context.Context, c Client, scopes []string) {
	changedServers, changedKeys := false, false
	if slices.Contains(scopes, ScopeServers) {
		ch, err := s.refreshServers(ctx, c)
		if err != nil {
			s.logf("warn", "shared servers: "+err.Error())
		}
		changedServers = ch
	}
	if slices.Contains(scopes, ScopeSSHKeys) {
		r, err := c.ListSshKeys(ctx, &pb.ListSshKeysRequest{})
		if err != nil {
			s.logf("warn", "safe keys: "+err.Error())
		} else {
			keys := make([]SafeKey, 0, len(r.Keys))
			for _, k := range r.Keys {
				keys = append(keys, SafeKey{
					ID: k.Id, Title: k.Title, KeyType: k.KeyType, Fingerprint: k.Fingerprint, PublicKey: k.PublicKey,
					Comment: k.Comment, Encrypted: k.Encrypted, HasPassphrase: k.HasPassphrase, Group: k.Group,
				})
			}
			slices.SortFunc(keys, func(a, b SafeKey) int { return strings.Compare(strings.ToLower(a.Title), strings.ToLower(b.Title)) })
			s.mu.Lock()
			changedKeys = !jsonEqual(keys, s.cache.Keys)
			s.cache.Keys = keys
			s.mu.Unlock()
		}
	}
	if changedServers || changedKeys {
		s.saveCache()
	}
	if changedServers {
		s.changed(ChangedServers)
	}
	if changedKeys {
		s.changed(ChangedKeys)
	}
}

func (s *Syncer) refreshServers(ctx context.Context, c Client) (bool, error) {
	s.mu.Lock()
	cursor := s.cache.Cursor
	s.mu.Unlock()
	if cursor != "" {
		ch, err := c.ListServerChanges(ctx, &pb.ListChangesRequest{Cursor: cursor})
		if err != nil {
			return false, err
		}
		if !ch.Reset_ {
			if len(ch.Changes) == 0 {
				return false, nil
			}
			var ids []string
			gone := map[string]bool{}
			for _, x := range ch.Changes {
				if x.Deleted {
					gone[x.Id] = true
				} else {
					ids = append(ids, x.Id)
					delete(gone, x.Id)
				}
			}
			got := map[string]*pb.Server{}
			for len(ids) > 0 {
				n := min(len(ids), 500)
				r, err := c.GetServers(ctx, &pb.GetServersRequest{Ids: ids[:n]})
				if err != nil {
					return false, err
				}
				for _, x := range r.Servers {
					got[x.Id] = x
				}
				ids = ids[n:]
			}
			s.mu.Lock()
			s.cache.Servers = slices.DeleteFunc(s.cache.Servers, func(c cachedServer) bool { return gone[c.ID] || got[c.ID] != nil })
			for _, x := range got {
				v := ServerFromPB(x)
				s.cache.Servers = append(s.cache.Servers, cachedServer{Server: v, Rev: v.Revision})
			}
			s.cache.Cursor = ch.Cursor
			s.mu.Unlock()
			return true, nil
		}
	}
	var all []cachedServer
	token, newCursor := "", ""
	for {
		r, err := c.ListServers(ctx, &pb.ListServersRequest{Data: true, PageToken: token})
		if err != nil {
			return false, err
		}
		for _, x := range r.Servers {
			v := ServerFromPB(x)
			all = append(all, cachedServer{Server: v, Rev: v.Revision})
		}
		if newCursor == "" {
			newCursor = r.Cursor
		}
		if r.NextPageToken == "" {
			break
		}
		token = r.NextPageToken
	}
	s.mu.Lock()
	changed := !jsonEqual(all, s.cache.Servers)
	s.cache.Servers, s.cache.Cursor = all, newCursor
	s.mu.Unlock()
	return changed, nil
}

// --- conversions -------------------------------------------------------------

// ServerToPB converts for PutServer. A local key ("local:...") is not
// shared: the entry says SSH_KEY with no key id (the device knows which).
func ServerToPB(x store.Server) *pb.Server {
	p := &pb.Server{
		Id: x.ID, Name: x.Name, Group: x.Group, Host: x.Host, Port: uint32(x.Port), User: x.User,
		Password: x.Password, HostKeys: x.HostKeys, JumpServerId: x.JumpServerID, Notes: x.Notes, Extra: x.Extra,
	}
	switch x.Auth {
	case store.AuthPassword:
		p.Auth = pb.Server_PASSWORD
	case store.AuthKey:
		p.Auth = pb.Server_SSH_KEY
		if id, ok := strings.CutPrefix(x.KeyID, store.SafeKeyPrefix); ok {
			p.SshKeyId = id
		}
	case store.AuthAgent:
		p.Auth = pb.Server_AGENT
	}
	return p
}

// ServerFromPB converts a shared server.
func ServerFromPB(p *pb.Server) store.Server {
	x := store.Server{
		ID: p.Id, Name: p.Name, Group: p.Group, Host: p.Host, Port: int(p.Port), User: p.User,
		Password: p.Password, HostKeys: p.HostKeys, JumpServerID: p.JumpServerId, Notes: p.Notes, Extra: p.Extra,
		UpdatedMs: p.ModifiedMs, Shared: true, Revision: p.Revision,
	}
	switch p.Auth {
	case pb.Server_SSH_KEY:
		x.Auth = store.AuthKey
		if p.SshKeyId != "" {
			x.KeyID = store.SafeKeyPrefix + p.SshKeyId
		}
	case pb.Server_AGENT:
		x.Auth = store.AuthAgent
	default:
		x.Auth = store.AuthPassword
	}
	return x
}

// --- state -------------------------------------------------------------------

func (s *Syncer) update(fn func(st *State)) {
	s.mu.Lock()
	before := s.st
	fn(&s.st)
	same := before == s.st
	s.mu.Unlock()
	if !same {
		s.changed(ChangedSync)
	}
}

func (s *Syncer) setPhase(p Phase, msg string) {
	s.update(func(st *State) {
		st.Phase = p
		if p != PhaseError {
			st.Error = msg
		}
	})
}

func (s *Syncer) setScopes(scopes []string) {
	s.mu.Lock()
	changed := !slices.Equal(s.cache.Scopes, scopes)
	s.cache.Scopes = slices.Clone(scopes)
	if !slices.Contains(scopes, ScopeServers) {
		s.cache.Servers, s.cache.Cursor = nil, ""
	}
	if !slices.Contains(scopes, ScopeSSHKeys) {
		s.cache.Keys = nil
	}
	s.mu.Unlock()
	s.update(func(st *State) {
		st.SharedServers = slices.Contains(scopes, ScopeServers)
		st.SafeKeys = slices.Contains(scopes, ScopeSSHKeys)
	})
	if changed {
		s.saveCache()
		s.changed(ChangedServers, ChangedKeys)
	}
}

func (s *Syncer) unreachable(err error) {
	msg := ""
	if errors.Is(err, ErrTooNew) {
		msg = err.Error()
	}
	s.mu.Lock()
	enabled := s.sv.Enabled || s.wantPair
	s.mu.Unlock()
	s.update(func(st *State) {
		st.Available = false
		if enabled {
			st.Phase, st.Error = PhaseNotRunning, msg
		} else {
			st.Phase, st.Error = PhaseOff, msg
		}
	})
}

func (s *Syncer) failed(err error) {
	s.logf("warn", err.Error())
	s.update(func(st *State) { st.Phase, st.Error = PhaseError, err.Error() })
}

func (s *Syncer) unpaired() {
	s.mu.Lock()
	s.sv = saved{}
	s.cache = cache{}
	s.wantPair = false
	s.mu.Unlock()
	s.save()
	s.saveCache()
	s.clearToken()
	s.update(func(st *State) {
		*st = State{Phase: PhaseOff, Available: st.Available, DeviceName: st.DeviceName,
			Error: "The pairing with CloudSync was revoked: switch sync on to pair again."}
	})
	s.changed(ChangedServers, ChangedKeys)
}

func (s *Syncer) changed(what ...string) {
	if s.o.OnChange == nil {
		return
	}
	for _, w := range what {
		s.o.OnChange(w)
	}
}

func (s *Syncer) logf(level, msg string) {
	if s.o.Log != nil {
		s.o.Log(level, msg)
	}
}

// --- files -------------------------------------------------------------------

func (s *Syncer) statePath() string { return filepath.Join(s.o.Dir, "cloudsync.json") }

func (s *Syncer) load() {
	if data, err := os.ReadFile(s.statePath()); err == nil {
		json.Unmarshal(data, &s.sv)
	}
	if data, err := os.ReadFile(filepath.Join(s.o.Dir, cacheFile)); err == nil && s.o.Seal != nil {
		if plain, err := s.o.Seal.Open(cacheFile, data); err == nil {
			json.Unmarshal(plain, &s.cache)
		}
	}
	if s.cache.VaultID != "" && s.cache.VaultID != s.sv.VaultID {
		s.cache = cache{}
	}
}

func (s *Syncer) save() {
	s.mu.Lock()
	data, _ := json.MarshalIndent(s.sv, "", "  ")
	s.mu.Unlock()
	if err := store.WriteAtomic(s.statePath(), data); err != nil {
		s.logf("warn", "save sync state: "+err.Error())
	}
}

func (s *Syncer) saveCache() {
	if s.o.Seal == nil {
		return
	}
	s.mu.Lock()
	data, _ := json.Marshal(s.cache)
	s.mu.Unlock()
	if err := store.WriteAtomic(filepath.Join(s.o.Dir, cacheFile), s.o.Seal.Seal(cacheFile, data)); err != nil {
		s.logf("warn", "save CloudSync cache: "+err.Error())
	}
}

const tokenName = "cloudsync-token"

func (s *Syncer) loadToken() string {
	if !s.o.Dialer.UsesToken() {
		return ""
	}
	s.mu.Lock()
	if s.token != nil {
		t := *s.token
		s.mu.Unlock()
		return t
	}
	s.mu.Unlock()
	t := ""
	if s.o.Keychain != nil {
		if b, err := s.o.Keychain.Get(tokenName); err == nil {
			t = string(b)
		}
	}
	if t == "" {
		if b, err := os.ReadFile(filepath.Join(s.o.Dir, "cloudsync.token")); err == nil {
			t = strings.TrimSpace(string(b))
		}
	}
	s.mu.Lock()
	s.token = &t
	s.mu.Unlock()
	return t
}

func (s *Syncer) storeToken(t string) {
	s.mu.Lock()
	s.token = &t
	s.mu.Unlock()
	if s.o.Keychain != nil && s.o.Keychain.Set(tokenName, []byte(t)) == nil {
		os.Remove(filepath.Join(s.o.Dir, "cloudsync.token"))
		return
	}
	store.WriteAtomic(filepath.Join(s.o.Dir, "cloudsync.token"), []byte(t))
}

func (s *Syncer) clearToken() {
	s.mu.Lock()
	empty := ""
	s.token = &empty
	s.mu.Unlock()
	if s.o.Keychain != nil {
		s.o.Keychain.Delete(tokenName)
	}
	os.Remove(filepath.Join(s.o.Dir, "cloudsync.token"))
}

func jsonEqual(a, b any) bool {
	ea, _ := json.Marshal(a)
	eb, _ := json.Marshal(b)
	return string(ea) == string(eb)
}

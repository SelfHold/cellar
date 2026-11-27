// Package fake is an in-memory CloudSync for tests: records with
// revisions, the shared servers (scope "servers") and SSH keys of the safe
// (scope "ssh_keys", CONNECTOR.md § 13–14), pairing that the test
// approves, and Watch. Several devices (Dialers) share one vault.
package fake

import (
	"context"
	"fmt"
	"slices"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"dbmanager/core/cloudsync"
	"dbmanager/core/cloudsync/pb"
)

// Vault is one CloudSync vault.
type Vault struct {
	mu      sync.Mutex
	rev     int
	records map[string]*pb.Item
	servers map[string]*pb.Server
	gone    map[string]int // deleted server id -> change number
	changes []change       // server changes, in order
	keys    map[string]*pb.SshKey
	// Grant: the scopes a pairing gets (the user's answer).
	Grant []string
	// Old: a CloudSync without the new scopes (UNIMPLEMENTED, and
	// unknown scopes are INVALID_ARGUMENT).
	Old      bool
	State    pb.VaultState
	watchers map[chan *pb.Change]struct{}
	paired   map[string][]string // token -> scopes
}

type change struct {
	id      string
	rev     string
	deleted bool
}

// New returns an empty, unlocked vault that grants both scopes.
func New() *Vault {
	return &Vault{
		records: map[string]*pb.Item{}, servers: map[string]*pb.Server{}, gone: map[string]int{}, keys: map[string]*pb.SshKey{},
		Grant: []string{cloudsync.ScopeServers, cloudsync.ScopeSSHKeys}, State: pb.VaultState_READY,
		watchers: map[chan *pb.Change]struct{}{}, paired: map[string][]string{},
	}
}

// AddKey puts an SSH key into the safe.
func (v *Vault) AddKey(k *pb.SshKey) {
	v.mu.Lock()
	v.rev++
	k.Revision = strconv.Itoa(v.rev)
	v.keys[k.Id] = proto.Clone(k).(*pb.SshKey)
	v.mu.Unlock()
	v.notify(&pb.Change{Kind: pb.Change_SSH_KEY, Key: k.Id, Revision: k.Revision})
}

// Servers returns the shared servers.
func (v *Vault) Servers() []*pb.Server {
	v.mu.Lock()
	defer v.mu.Unlock()
	var out []*pb.Server
	for _, s := range v.servers {
		out = append(out, proto.Clone(s).(*pb.Server))
	}
	slices.SortFunc(out, func(a, b *pb.Server) int { return compare(a.Id, b.Id) })
	return out
}

// PutServerDirect writes a server as another app would.
func (v *Vault) PutServerDirect(s *pb.Server) *pb.Server {
	v.mu.Lock()
	out := v.putServer(s)
	v.mu.Unlock()
	v.notify(&pb.Change{Kind: pb.Change_SERVER, Key: out.Id, Revision: out.Revision})
	return out
}

// Record returns a record's single value.
func (v *Vault) Record(key string) []byte {
	v.mu.Lock()
	defer v.mu.Unlock()
	if it := v.records[key]; it != nil && len(it.Versions) == 1 {
		return it.Versions[0].Data
	}
	return nil
}

func compare(a, b string) int {
	switch {
	case a < b:
		return -1
	case a > b:
		return 1
	}
	return 0
}

func (v *Vault) notify(c *pb.Change) {
	v.mu.Lock()
	defer v.mu.Unlock()
	for ch := range v.watchers {
		select {
		case ch <- c:
		default:
		}
	}
}

func (v *Vault) putServer(s *pb.Server) *pb.Server {
	v.rev++
	s = proto.Clone(s).(*pb.Server)
	if s.Id == "" {
		s.Id = "srv" + strconv.Itoa(v.rev)
		s.CreatedMs = time.Now().UnixMilli()
	}
	s.Revision = strconv.Itoa(v.rev)
	s.ModifiedMs = time.Now().UnixMilli()
	v.servers[s.Id] = s
	delete(v.gone, s.Id)
	v.changes = append(v.changes, change{id: s.Id, rev: s.Revision})
	return proto.Clone(s).(*pb.Server)
}

// Device is a Dialer of one device.
type Device struct {
	V    *Vault
	Name string
	// Down: CloudSync is not running on this device.
	Down atomic.Bool
}

func (*Device) UsesToken() bool { return true }
func (*Device) CanOpen() bool   { return false }

func (d *Device) Dial(_ context.Context, token string) (cloudsync.Client, error) {
	if d.Down.Load() {
		return nil, cloudsync.ErrNotRunning
	}
	return &client{d: d, token: token}, nil
}

type client struct {
	d     *Device
	token string
}

func (c *client) v() *Vault         { return c.d.V }
func (c *client) SetToken(t string) { c.token = t }
func (c *client) Close() error      { return nil }
func (c *client) scopes() []string  { return c.v().paired[c.token] }
func (c *client) isPaired() bool    { _, ok := c.v().paired[c.token]; return ok && c.token != "" }

func (c *client) auth(scope string) error {
	if c.d.Down.Load() {
		return status.Error(codes.Unavailable, "connection refused")
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	if !c.isPaired() {
		return status.Error(codes.Unauthenticated, "not paired")
	}
	if scope != "" {
		if v.Old {
			return status.Error(codes.Unimplemented, "unknown method")
		}
		if !slices.Contains(c.scopes(), scope) {
			return status.Error(codes.PermissionDenied, "scope")
		}
	}
	if v.State == pb.VaultState_LOCKED {
		return status.Error(codes.FailedPrecondition, "locked")
	}
	return nil
}

func (c *client) Hello(context.Context, *pb.HelloRequest) (*pb.HelloReply, error) {
	if c.d.Down.Load() {
		return nil, status.Error(codes.Unavailable, "connection refused")
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	r := &pb.HelloReply{ApiVersion: 1, State: v.State, VaultId: "vault-1", DeviceName: c.d.Name, Paired: c.isPaired()}
	if r.Paired {
		r.AppId, r.Scopes = cloudsync.AppID, slices.Clone(c.scopes())
	}
	return r, nil
}

func (c *client) RequestPairing(_ context.Context, r *pb.PairingRequest) (*pb.PairingTicket, error) {
	v := c.v()
	if v.Old && len(r.Scopes) > 0 {
		return nil, status.Error(codes.InvalidArgument, "unknown scope")
	}
	return &pb.PairingTicket{Ticket: "t-" + c.d.Name + fmt.Sprint(len(r.Scopes)), Code: "123456", ExpiresUnixMs: time.Now().Add(5 * time.Minute).UnixMilli()}, nil
}

func (c *client) AwaitPairing(_ context.Context, r *pb.AwaitPairingRequest) (*pb.PairingResult, error) {
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	token := "tok-" + c.d.Name
	var grant []string
	if r.Ticket[len(r.Ticket)-1] != '0' {
		grant = slices.Clone(v.Grant)
	}
	v.paired[token] = grant
	return &pb.PairingResult{Status: pb.PairingStatus_APPROVED, Token: token, AppId: cloudsync.AppID, Scopes: grant}, nil
}

func (c *client) Get(_ context.Context, r *pb.GetRequest) (*pb.Item, error) {
	if err := c.auth(""); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	if it := v.records[r.Key]; it != nil {
		return proto.Clone(it).(*pb.Item), nil
	}
	return &pb.Item{Key: r.Key}, nil
}

func (c *client) Put(_ context.Context, r *pb.PutRequest) (*pb.Item, error) {
	if err := c.auth(""); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	cur := v.records[r.Key]
	rev := ""
	if cur != nil {
		rev = cur.Revision
	}
	if r.Base != rev {
		v.mu.Unlock()
		return nil, status.Error(codes.Aborted, "base")
	}
	v.rev++
	it := &pb.Item{Key: r.Key, Revision: strconv.Itoa(v.rev), Versions: []*pb.Version{{Id: strconv.Itoa(v.rev), Data: r.Data, DeviceName: c.d.Name}}}
	v.records[r.Key] = it
	v.mu.Unlock()
	v.notify(&pb.Change{Kind: pb.Change_RECORD, Key: r.Key, Revision: it.Revision})
	return proto.Clone(it).(*pb.Item), nil
}

func (c *client) Delete(context.Context, *pb.DeleteRequest) (*pb.Item, error) {
	return nil, status.Error(codes.Unimplemented, "not in the fake")
}

func (c *client) Unpair(context.Context, *pb.UnpairRequest) (*pb.UnpairReply, error) {
	v := c.v()
	v.mu.Lock()
	delete(v.paired, c.token)
	v.mu.Unlock()
	return &pb.UnpairReply{}, nil
}

func (c *client) ListSshKeys(context.Context, *pb.ListSshKeysRequest) (*pb.ListSshKeysReply, error) {
	if err := c.auth(cloudsync.ScopeSSHKeys); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	out := &pb.ListSshKeysReply{}
	for _, k := range v.keys {
		k := proto.Clone(k).(*pb.SshKey)
		k.PrivateKey, k.Passphrase = "", ""
		out.Keys = append(out.Keys, k)
	}
	slices.SortFunc(out.Keys, func(a, b *pb.SshKey) int { return compare(a.Id, b.Id) })
	return out, nil
}

func (c *client) GetSshKeys(_ context.Context, r *pb.GetSshKeysRequest) (*pb.ListSshKeysReply, error) {
	if err := c.auth(cloudsync.ScopeSSHKeys); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	out := &pb.ListSshKeysReply{}
	for _, id := range r.Ids {
		if k := v.keys[id]; k != nil {
			out.Keys = append(out.Keys, proto.Clone(k).(*pb.SshKey))
		}
	}
	return out, nil
}

func (c *client) ListServers(_ context.Context, r *pb.ListServersRequest) (*pb.ListServersReply, error) {
	if err := c.auth(cloudsync.ScopeServers); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	out := &pb.ListServersReply{Cursor: strconv.Itoa(len(v.changes))}
	for _, s := range v.servers {
		s := proto.Clone(s).(*pb.Server)
		if !r.Data {
			s.Password, s.Extra = "", nil
		}
		out.Servers = append(out.Servers, s)
	}
	slices.SortFunc(out.Servers, func(a, b *pb.Server) int { return compare(a.Id, b.Id) })
	return out, nil
}

func (c *client) GetServers(_ context.Context, r *pb.GetServersRequest) (*pb.ListServersReply, error) {
	if err := c.auth(cloudsync.ScopeServers); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	out := &pb.ListServersReply{}
	for _, id := range r.Ids {
		if s := v.servers[id]; s != nil {
			out.Servers = append(out.Servers, proto.Clone(s).(*pb.Server))
		}
	}
	return out, nil
}

func (c *client) PutServer(_ context.Context, r *pb.PutServerRequest) (*pb.Server, error) {
	if err := c.auth(cloudsync.ScopeServers); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	if r.Server.Id != "" {
		cur := v.servers[r.Server.Id]
		if cur == nil {
			v.mu.Unlock()
			return nil, status.Error(codes.NotFound, "no server")
		}
		if cur.Revision != r.Base {
			v.mu.Unlock()
			return nil, status.Error(codes.Aborted, "base")
		}
	} else if r.Base != "" {
		v.mu.Unlock()
		return nil, status.Error(codes.InvalidArgument, "base of a new server")
	}
	out := v.putServer(r.Server)
	v.mu.Unlock()
	v.notify(&pb.Change{Kind: pb.Change_SERVER, Key: out.Id, Revision: out.Revision})
	return out, nil
}

func (c *client) DeleteServer(_ context.Context, r *pb.DeleteServerRequest) (*pb.DeleteServerReply, error) {
	if err := c.auth(cloudsync.ScopeServers); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	cur := v.servers[r.Id]
	if cur == nil {
		v.mu.Unlock()
		return nil, status.Error(codes.NotFound, "no server")
	}
	if cur.Revision != r.Base {
		v.mu.Unlock()
		return nil, status.Error(codes.Aborted, "base")
	}
	delete(v.servers, r.Id)
	v.changes = append(v.changes, change{id: r.Id, deleted: true})
	v.mu.Unlock()
	v.notify(&pb.Change{Kind: pb.Change_SERVER, Key: r.Id, Deleted: true})
	return &pb.DeleteServerReply{}, nil
}

func (c *client) ListServerChanges(_ context.Context, r *pb.ListChangesRequest) (*pb.ListChangesReply, error) {
	if err := c.auth(cloudsync.ScopeServers); err != nil {
		return nil, err
	}
	v := c.v()
	v.mu.Lock()
	defer v.mu.Unlock()
	n, err := strconv.Atoi(r.Cursor)
	if err != nil || n > len(v.changes) {
		return &pb.ListChangesReply{Reset_: true}, nil
	}
	out := &pb.ListChangesReply{Cursor: strconv.Itoa(len(v.changes))}
	for _, ch := range v.changes[n:] {
		out.Changes = append(out.Changes, &pb.LoginChange{Id: ch.id, Revision: ch.rev, Deleted: ch.deleted})
	}
	return out, nil
}

func (c *client) Watch(ctx context.Context) (func() (*pb.Change, error), error) {
	if err := c.auth(""); err != nil {
		return nil, err
	}
	v := c.v()
	ch := make(chan *pb.Change, 64)
	v.mu.Lock()
	v.watchers[ch] = struct{}{}
	v.mu.Unlock()
	stop := func() {
		v.mu.Lock()
		delete(v.watchers, ch)
		v.mu.Unlock()
	}
	return func() (*pb.Change, error) {
		t := time.NewTicker(10 * time.Millisecond)
		defer t.Stop()
		for {
			select {
			case x := <-ch:
				return x, nil
			case <-t.C:
				if c.d.Down.Load() {
					stop()
					return nil, status.Error(codes.Unavailable, "CloudSync stopped")
				}
			case <-ctx.Done():
				stop()
				return nil, ctx.Err()
			}
		}
	}, nil
}

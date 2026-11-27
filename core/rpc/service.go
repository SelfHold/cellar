// Package rpc is the core's gRPC API for the app (proto/dbm.proto): the
// server and connection lists, SSH connections, discovery, the schema
// browser, data viewer, query consoles and CloudSync.
package rpc

import (
	"context"
	"errors"
	"fmt"
	"net"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"dbmanager/core/cloudsync"
	"dbmanager/core/discover"
	"dbmanager/core/pg"
	"dbmanager/core/rpc/pb"
	"dbmanager/core/sshx"
	"dbmanager/core/store"
)

// Version and Build identify the core; make sets them with -ldflags -X.
var (
	Version = "dev"
	Build   = "dev"
)

// Service implements pb.DBManagerServer.
type Service struct {
	pb.UnimplementedDBManagerServer

	Store    *store.Store
	Sync     *cloudsync.Syncer // nil: no CloudSync
	Pool     *sshx.Pool
	PG       *pg.Manager
	Platform string
	Keychain bool // the local files' key is in the OS keychain
	// Log, when set, gets one line per notable event.
	Log func(level, msg string)

	mu          sync.Mutex
	subs        map[*sub]struct{}
	passphrases map[string]string // key id -> passphrase given at connect
}

type sub struct{ ch chan *pb.Event }

// New wires a service. Sync may be set afterwards (before Start).
func New(st *store.Store, platform string) *Service {
	s := &Service{Store: st, Pool: sshx.NewPool(), Platform: platform, subs: map[*sub]struct{}{}, passphrases: map[string]string{}}
	s.PG = pg.NewManager(s.open)
	s.Pool.OnChange = func(id string) { s.publish(pb.Event_SSH, id) }
	st.OnChange(func(what string) {
		switch what {
		case store.ChangedServers:
			s.publish(pb.Event_SERVERS, "")
		case store.ChangedConnections:
			s.publish(pb.Event_CONNECTIONS, "")
		case store.ChangedKeys:
			s.publish(pb.Event_KEYS, "")
		}
		if s.Sync != nil && what != store.ChangedKeys {
			s.Sync.Kick()
		}
	})
	return s
}

// SyncChanged is cloudsync.Options.OnChange.
func (s *Service) SyncChanged(what string) {
	switch what {
	case cloudsync.ChangedSync:
		s.publish(pb.Event_SYNC, "")
	case cloudsync.ChangedServers:
		s.publish(pb.Event_SERVERS, "")
	case cloudsync.ChangedKeys:
		s.publish(pb.Event_KEYS, "")
	}
}

// Close ends every session and SSH connection.
func (s *Service) Close() {
	s.PG.Close()
	s.Pool.CloseAll()
}

// TokenAuth makes the server accept only calls with the bearer token.
func TokenAuth(token string) []grpc.ServerOption {
	check := func(ctx context.Context) error {
		md, _ := metadata.FromIncomingContext(ctx)
		for _, v := range md.Get("authorization") {
			if v == "Bearer "+token {
				return nil
			}
		}
		return status.Error(codes.Unauthenticated, "bad token")
	}
	return []grpc.ServerOption{
		grpc.MaxSendMsgSize(64 << 20),
		grpc.UnaryInterceptor(func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
			if err := check(ctx); err != nil {
				return nil, err
			}
			return h(ctx, req)
		}),
		grpc.StreamInterceptor(func(srv any, ss grpc.ServerStream, _ *grpc.StreamServerInfo, h grpc.StreamHandler) error {
			if err := check(ss.Context()); err != nil {
				return err
			}
			return h(srv, ss)
		}),
	}
}

func (s *Service) logf(level, format string, args ...any) {
	if s.Log != nil {
		s.Log(level, fmt.Sprintf(format, args...))
	}
}

// --- events ------------------------------------------------------------------

func (s *Service) publish(kind pb.Event_Kind, id string) {
	ev := &pb.Event{Kind: kind, Id: id}
	s.mu.Lock()
	defer s.mu.Unlock()
	for sb := range s.subs {
		select {
		case sb.ch <- ev:
		default:
			// Too far behind: cut it off, the app reconnects and reloads.
			close(sb.ch)
			delete(s.subs, sb)
		}
	}
}

func (s *Service) Events(_ *pb.Empty, st grpc.ServerStreamingServer[pb.Event]) error {
	sb := &sub{ch: make(chan *pb.Event, 256)}
	s.mu.Lock()
	s.subs[sb] = struct{}{}
	s.mu.Unlock()
	defer func() {
		s.mu.Lock()
		if _, ok := s.subs[sb]; ok {
			delete(s.subs, sb)
			close(sb.ch)
		}
		s.mu.Unlock()
	}()
	for {
		select {
		case <-st.Context().Done():
			return nil
		case ev, ok := <-sb.ch:
			if !ok {
				return status.Error(codes.ResourceExhausted, "events fell behind: reload")
			}
			if err := st.Send(ev); err != nil {
				return err
			}
		}
	}
}

// --- state -------------------------------------------------------------------

func (s *Service) GetState(context.Context, *pb.Empty) (*pb.State, error) {
	return &pb.State{CoreVersion: Version, CoreBuild: Build, Platform: s.Platform, Sync: s.syncState(), Keychain: s.Keychain}, nil
}

func (s *Service) syncState() *pb.SyncState {
	if s.Sync == nil {
		return &pb.SyncState{Phase: pb.SyncState_OFF}
	}
	st := s.Sync.State()
	out := &pb.SyncState{
		Phase: pb.SyncState_Phase(st.Phase), Enabled: st.Enabled, Available: st.Available, PairingCode: st.PairingCode,
		Error: st.Error, Pending: st.Pending, LastSyncMs: st.LastSyncMs, DeviceName: st.DeviceName,
		SharedServers: st.SharedServers, SafeKeys: st.SafeKeys,
	}
	if _, ok := s.Sync.SharedServers(); ok {
		out.OwnServers = int32(len(s.Store.Servers()))
	}
	return out
}

// --- servers -----------------------------------------------------------------

// servers is the shared list (when in use) and the own list.
func (s *Service) servers() []store.Server {
	var out []store.Server
	if s.Sync != nil {
		if shared, ok := s.Sync.SharedServers(); ok {
			out = append(out, shared...)
		}
	}
	for _, x := range s.Store.Servers() {
		if !slices.ContainsFunc(out, func(y store.Server) bool { return y.ID == x.ID }) {
			out = append(out, x)
		}
	}
	store.SortServers(out)
	return out
}

func (s *Service) server(id string) (store.Server, error) {
	if s.Sync != nil {
		if x, ok := s.Sync.SharedServer(id); ok {
			if k := s.Store.ServerKey(id); k != "" && x.Auth == store.AuthKey && x.KeyID == "" {
				x.KeyID = store.LocalKeyPrefix + k
			}
			return x, nil
		}
	}
	x, err := s.Store.Server(id)
	if err != nil {
		return x, status.Error(codes.NotFound, "no such server")
	}
	return x, nil
}

func (s *Service) serverPB(x store.Server) *pb.Server {
	if x.Shared && x.Auth == store.AuthKey && x.KeyID == "" {
		if k := s.Store.ServerKey(x.ID); k != "" {
			x.KeyID = store.LocalKeyPrefix + k
		}
	}
	p := &pb.Server{
		Id: x.ID, Name: x.Name, Group: x.Group, Host: x.Host, Port: uint32(x.Port), User: x.User,
		Password: x.Password, KeyId: x.KeyID, HostKeys: x.HostKeys, JumpServerId: x.JumpServerID, Notes: x.Notes,
		UpdatedMs: x.UpdatedMs, Shared: x.Shared, Connected: s.Pool.Connected(x.ID),
	}
	switch x.Auth {
	case store.AuthKey:
		p.Auth = pb.Server_KEY
	case store.AuthAgent:
		p.Auth = pb.Server_AGENT
	default:
		p.Auth = pb.Server_PASSWORD
	}
	return p
}

func (s *Service) ListServers(context.Context, *pb.Empty) (*pb.ServerList, error) {
	out := &pb.ServerList{}
	for _, x := range s.servers() {
		out.Servers = append(out.Servers, s.serverPB(x))
	}
	return out, nil
}

func serverFromPB(p *pb.Server) store.Server {
	x := store.Server{
		ID: p.Id, Name: strings.TrimSpace(p.Name), Group: strings.Trim(strings.TrimSpace(p.Group), "/"),
		Host: strings.TrimSpace(p.Host), Port: int(p.Port), User: strings.TrimSpace(p.User),
		Password: p.Password, KeyID: p.KeyId, HostKeys: p.HostKeys, JumpServerID: p.JumpServerId, Notes: p.Notes,
	}
	switch p.Auth {
	case pb.Server_KEY:
		x.Auth = store.AuthKey
	case pb.Server_AGENT:
		x.Auth = store.AuthAgent
	default:
		x.Auth = store.AuthPassword
	}
	if x.Auth != store.AuthKey {
		x.KeyID = ""
	}
	return x
}

func (s *Service) SaveServer(ctx context.Context, p *pb.Server) (*pb.Server, error) {
	x := serverFromPB(p)
	if err := store.ValidateServer(x); err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	if x.JumpServerID != "" {
		if _, err := s.server(x.JumpServerID); err != nil {
			return nil, status.Error(codes.InvalidArgument, "the jump server does not exist")
		}
	}
	shared := false
	var cur store.Server
	if x.ID != "" {
		c, err := s.server(x.ID)
		if err != nil {
			return nil, err
		}
		cur, shared = c, c.Shared
	} else if s.Sync != nil {
		// New servers go to the shared list while it is in use.
		_, shared = s.Sync.SharedServers()
	}
	if x.ID != "" {
		// Trusted host keys change only through TrustHostKey: a form
		// opened before a key was trusted must not drop it.
		x.HostKeys = cur.HostKeys
	}
	var out store.Server
	var err error
	if shared {
		x.Revision, x.Extra = cur.Revision, cur.Extra
		localKey := ""
		if k, ok := strings.CutPrefix(x.KeyID, store.LocalKeyPrefix); ok {
			localKey = k
		}
		out, err = s.Sync.PutServer(ctx, x)
		if err == nil {
			err = s.Store.SetServerKey(out.ID, localKey)
		}
	} else {
		out, err = s.Store.SaveServer(x)
	}
	if err != nil {
		return nil, grpcErr(err)
	}
	if x.ID != "" && sshChanged(cur, out) {
		s.disconnect(x.ID)
	}
	s.logf("info", "server %s saved", out.Name)
	return s.serverPB(out), nil
}

// sshChanged: the edit changes how to connect.
func sshChanged(a, b store.Server) bool {
	return a.Host != b.Host || a.Port != b.Port || a.User != b.User || a.Auth != b.Auth || a.Password != b.Password ||
		a.KeyID != b.KeyID || a.JumpServerID != b.JumpServerID
}

func (s *Service) DeleteServer(ctx context.Context, r *pb.Ref) (*pb.Empty, error) {
	x, err := s.server(r.Id)
	if err != nil {
		return nil, err
	}
	if x.Shared {
		err = s.Sync.DeleteServer(ctx, x.ID)
		if err == nil {
			s.Store.SetServerKey(x.ID, "")
		}
	} else {
		err = s.Store.DeleteServer(x.ID)
	}
	if err != nil {
		return nil, grpcErr(err)
	}
	s.disconnect(x.ID)
	// Its connections go with it.
	for _, c := range s.Store.Connections() {
		if c.ServerID == x.ID {
			s.Store.DeleteConnection(c.ID)
		}
	}
	return &pb.Empty{}, nil
}

// disconnect closes a server's SSH connection and the database sessions
// through it.
func (s *Service) disconnect(serverID string) {
	var ids []string
	for _, c := range s.Store.Connections() {
		if c.ServerID == serverID {
			ids = append(ids, c.ID)
		}
	}
	s.PG.ResetMany(ids)
	s.Pool.Close(serverID)
}

func (s *Service) DisconnectServer(_ context.Context, r *pb.Ref) (*pb.Empty, error) {
	s.disconnect(r.Id)
	return &pb.Empty{}, nil
}

var errNeedPassphrase = status.Error(codes.FailedPrecondition, "the SSH key needs its passphrase")

// spec builds how to reach a server (secrets fetched now, kept in memory).
func (s *Service) spec(ctx context.Context, id string, depth int) (*sshx.Spec, error) {
	if depth > 4 {
		return nil, status.Error(codes.InvalidArgument, "too many jump servers (or a loop)")
	}
	x, err := s.server(id)
	if err != nil {
		return nil, err
	}
	sp := &sshx.Spec{ID: x.ID, Host: x.Host, Port: x.SSHPort(), User: x.User, HostKeys: x.HostKeys}
	switch x.Auth {
	case store.AuthPassword:
		sp.Password = x.Password
		if sp.Password == "" {
			return nil, status.Errorf(codes.FailedPrecondition, "%s has no password: edit the server", x.Name)
		}
	case store.AuthAgent:
		sp.Agent = true
	case store.AuthKey:
		sp.Password = x.Password // a fallback some servers ask for
		var priv, pass string
		switch {
		case strings.HasPrefix(x.KeyID, store.SafeKeyPrefix):
			if s.Sync == nil {
				return nil, cloudsync.ErrNoSafe
			}
			priv, pass, err = s.Sync.SafeKeySecret(ctx, strings.TrimPrefix(x.KeyID, store.SafeKeyPrefix))
			if err != nil {
				return nil, err
			}
		case strings.HasPrefix(x.KeyID, store.LocalKeyPrefix):
			k, err := s.Store.LocalKey(x.KeyID)
			if err != nil {
				return nil, status.Errorf(codes.FailedPrecondition, "the key of %s is not on this device: choose a key", x.Name)
			}
			priv, pass = k.PrivateKey, k.Passphrase
		default:
			return nil, status.Errorf(codes.FailedPrecondition, "%s has no SSH key on this device: choose a key", x.Name)
		}
		if pass == "" {
			s.mu.Lock()
			pass = s.passphrases[x.KeyID]
			s.mu.Unlock()
		}
		signer, err := sshx.ParseKey(priv, pass)
		if errors.Is(err, sshx.ErrPassphrase) {
			s.mu.Lock()
			delete(s.passphrases, x.KeyID)
			s.mu.Unlock()
			return nil, errNeedPassphrase
		}
		if err != nil {
			return nil, status.Error(codes.FailedPrecondition, err.Error())
		}
		sp.Signer = signer
	}
	if x.JumpServerID != "" {
		if sp.Jump, err = s.spec(ctx, x.JumpServerID, depth+1); err != nil {
			return nil, err
		}
	}
	return sp, nil
}

func (s *Service) client(ctx context.Context, id string) (*sshClient, error) {
	sp, err := s.spec(ctx, id, 0)
	if err != nil {
		return nil, err
	}
	c, err := s.Pool.Client(ctx, sp)
	if err != nil {
		return nil, err
	}
	return &sshClient{c}, nil
}

func (s *Service) ConnectServer(ctx context.Context, r *pb.ConnectRequest) (*pb.ConnectReply, error) {
	x, err := s.server(r.Id)
	if err != nil {
		return nil, err
	}
	if r.Passphrase != "" && x.KeyID != "" {
		s.mu.Lock()
		s.passphrases[x.KeyID] = r.Passphrase
		s.mu.Unlock()
	}
	_, err = s.client(ctx, r.Id)
	var hk *sshx.HostKeyError
	switch {
	case errors.As(err, &hk):
		return &pb.ConnectReply{HostKey: &pb.HostKey{
			Status: pb.HostKey_Status(hk.Status), Key: hk.Key, Fingerprint: hk.Fingerprint, Type: hk.Type, ServerId: hk.ServerID,
		}}, nil
	case errors.Is(err, errNeedPassphrase):
		return &pb.ConnectReply{NeedPassphrase: true}, nil
	case err != nil:
		return nil, grpcErr(err)
	}
	return &pb.ConnectReply{Connected: true, ServerBanner: s.Pool.Banner(r.Id)}, nil
}

func (s *Service) TrustHostKey(ctx context.Context, r *pb.TrustRequest) (*pb.Server, error) {
	x, err := s.server(r.Id)
	if err != nil {
		return nil, err
	}
	k, _, _, _, err := sshParse(r.Key)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, "not a host key: "+err.Error())
	}
	line := sshx.AuthorizedLine(k)
	if r.Replace {
		x.HostKeys = []string{line}
	} else if !slices.Contains(x.HostKeys, line) {
		x.HostKeys = append(slices.Clone(x.HostKeys), line)
	}
	var out store.Server
	if x.Shared {
		// A local key stays on this device (ServerToPB leaves it out).
		out, err = s.Sync.PutServer(ctx, x)
	} else {
		out, err = s.Store.SaveServer(x)
	}
	if err != nil {
		return nil, grpcErr(err)
	}
	return s.serverPB(out), nil
}

func (s *Service) Discover(ctx context.Context, r *pb.Ref) (*pb.DiscoverReply, error) {
	c, err := s.client(ctx, r.Id)
	if err != nil {
		var hk *sshx.HostKeyError
		if errors.As(err, &hk) {
			return nil, status.Error(codes.FailedPrecondition, "connect to the server first (its host key is not trusted yet)")
		}
		return nil, grpcErr(err)
	}
	ctx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()
	res, err := discover.Run(ctx,
		func(ctx context.Context, cmd string) (string, error) {
			out, _, err := sshx.Run(ctx, c.Client, cmd, 4<<20)
			return out, err
		},
		func(ctx context.Context, addr string) (net.Conn, error) { return c.DialContext(ctx, "tcp", addr) })
	if err != nil {
		return nil, grpcErr(err)
	}
	out := &pb.DiscoverReply{Warnings: res.Warnings}
	conns := s.Store.Connections()
	for _, sv := range res.Services {
		d := &pb.DiscoveredService{
			Kind: pb.DiscoveredService_POSTGRES, Host: sv.Host, Port: uint32(sv.Port), Source: sv.Source, Title: sv.Title,
			Detail: sv.Detail, Confirmed: sv.Confirmed, UserHint: sv.UserHint, DatabaseHint: sv.DatabaseHint,
		}
		for _, cn := range conns {
			if cn.ServerID == r.Id && sameHost(cn.Host, sv.Host) && cn.PGPort() == sv.Port {
				d.ConnectionId = cn.ID
			}
		}
		out.Services = append(out.Services, d)
	}
	return out, nil
}

func sameHost(a, b string) bool {
	loop := func(h string) string {
		if h == "localhost" || h == "::1" {
			return "127.0.0.1"
		}
		return h
	}
	return loop(a) == loop(b)
}

// --- keys ----------------------------------------------------------------------

func (s *Service) ListKeys(context.Context, *pb.Empty) (*pb.KeyList, error) {
	out := &pb.KeyList{}
	if s.Sync != nil {
		keys, note := s.Sync.SafeKeys()
		out.SafeNote = note
		for _, k := range keys {
			out.Keys = append(out.Keys, &pb.Key{
				Id: store.SafeKeyPrefix + k.ID, Title: k.Title, KeyType: k.KeyType, Fingerprint: k.Fingerprint, PublicKey: k.PublicKey,
				Comment: k.Comment, Encrypted: k.Encrypted, HasPassphrase: k.HasPassphrase, Group: k.Group,
			})
		}
	} else {
		out.SafeNote = "CloudSync is not available in this build."
	}
	for _, k := range s.Store.LocalKeys() {
		info, _ := sshx.DescribeKey(k.PrivateKey, k.Passphrase)
		out.Keys = append(out.Keys, &pb.Key{
			Id: store.LocalKeyPrefix + k.ID, Title: k.Title, KeyType: info.Type, Fingerprint: info.Fingerprint, PublicKey: info.PublicKey,
			Encrypted: info.Encrypted, HasPassphrase: k.Passphrase != "", Local: true,
		})
	}
	return out, nil
}

func (s *Service) SaveLocalKey(_ context.Context, r *pb.LocalKey) (*pb.Key, error) {
	info, err := sshx.DescribeKey(r.PrivateKey, r.Passphrase)
	if err != nil && !(errors.Is(err, sshx.ErrPassphrase) && r.Passphrase == "") {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	title := strings.TrimSpace(r.Title)
	if title == "" {
		title = info.Type + " " + info.Fingerprint
	}
	k, err := s.Store.SaveLocalKey(store.LocalKey{Title: title, PrivateKey: strings.TrimSpace(r.PrivateKey) + "\n", Passphrase: r.Passphrase})
	if err != nil {
		return nil, grpcErr(err)
	}
	return &pb.Key{Id: store.LocalKeyPrefix + k.ID, Title: k.Title, KeyType: info.Type, Fingerprint: info.Fingerprint,
		PublicKey: info.PublicKey, Encrypted: info.Encrypted, HasPassphrase: r.Passphrase != "", Local: true}, nil
}

func (s *Service) DeleteLocalKey(_ context.Context, r *pb.Ref) (*pb.Empty, error) {
	if err := s.Store.DeleteLocalKey(r.Id); err != nil {
		return nil, grpcErr(err)
	}
	return &pb.Empty{}, nil
}

// --- connections ---------------------------------------------------------------

func connPB(c store.Connection) *pb.Connection {
	p := &pb.Connection{
		Id: c.ID, Name: c.Name, ServerId: c.ServerID, Kind: pb.Connection_POSTGRES, Host: c.Host, Port: uint32(c.Port),
		User: c.User, Password: c.Password, Database: c.Database, Source: c.Source, Color: c.Color, UpdatedMs: c.UpdatedMs,
		Databases: c.Databases, ReadOnly: c.ReadOnly,
	}
	switch c.SSLMode {
	case "disable":
		p.SslMode = pb.Connection_DISABLE
	case "require":
		p.SslMode = pb.Connection_REQUIRE
	case "prefer":
		p.SslMode = pb.Connection_PREFER
	}
	return p
}

func connFromPB(p *pb.Connection) store.Connection {
	c := store.Connection{
		ID: p.Id, Name: strings.TrimSpace(p.Name), ServerID: p.ServerId, Kind: store.KindPostgres, Host: strings.TrimSpace(p.Host),
		Port: int(p.Port), User: strings.TrimSpace(p.User), Password: p.Password, Database: strings.TrimSpace(p.Database),
		Source: p.Source, Color: p.Color, Databases: p.Databases, ReadOnly: p.ReadOnly,
	}
	switch p.SslMode {
	case pb.Connection_DISABLE:
		c.SSLMode = "disable"
	case pb.Connection_REQUIRE:
		c.SSLMode = "require"
	case pb.Connection_PREFER:
		c.SSLMode = "prefer"
	}
	if c.Name == "" {
		c.Name = c.User + "@" + c.Host + ":" + strconv.Itoa(c.PGPort())
	}
	return c
}

func (s *Service) ListConnections(context.Context, *pb.Empty) (*pb.ConnectionList, error) {
	out := &pb.ConnectionList{}
	for _, c := range s.Store.Connections() {
		out.Connections = append(out.Connections, connPB(c))
	}
	return out, nil
}

func (s *Service) SaveConnection(_ context.Context, p *pb.Connection) (*pb.Connection, error) {
	c := connFromPB(p)
	if c.ServerID != "" {
		if _, err := s.server(c.ServerID); err != nil {
			return nil, status.Error(codes.InvalidArgument, "the server does not exist")
		}
	}
	if err := store.ValidateConnection(c); err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	out, err := s.Store.SaveConnection(c)
	if err != nil {
		return nil, grpcErr(err)
	}
	s.PG.Reset(out.ID)
	return connPB(out), nil
}

func (s *Service) DeleteConnection(_ context.Context, r *pb.Ref) (*pb.Empty, error) {
	if err := s.Store.DeleteConnection(r.Id); err != nil {
		return nil, grpcErr(err)
	}
	s.PG.Reset(r.Id)
	return &pb.Empty{}, nil
}

// dialer reaches databases from a server (through SSH) or from here.
func (s *Service) dialer(serverID string) pg.Dial {
	if serverID == "" {
		var d net.Dialer
		return func(ctx context.Context, addr string) (net.Conn, error) { return d.DialContext(ctx, "tcp", addr) }
	}
	return func(ctx context.Context, addr string) (net.Conn, error) {
		c, err := s.client(ctx, serverID)
		if err != nil {
			var hk *sshx.HostKeyError
			if errors.As(err, &hk) {
				return nil, errors.New("connect to the server first (its host key is not trusted yet)")
			}
			return nil, err
		}
		conn, err := c.DialContext(ctx, "tcp", addr)
		if err != nil {
			return nil, fmt.Errorf("from the server, %s: %w", addr, err)
		}
		return conn, nil
	}
}

// open is pg.Opener.
func (s *Service) open(_ context.Context, id string) (store.Connection, pg.Dial, error) {
	c, err := s.Store.Connection(id)
	if err != nil {
		return c, nil, status.Error(codes.NotFound, "no such connection")
	}
	return c, s.dialer(c.ServerID), nil
}

func (s *Service) TestConnection(ctx context.Context, p *pb.Connection) (*pb.TestReply, error) {
	c := connFromPB(p)
	if err := store.ValidateConnection(c); err != nil {
		return &pb.TestReply{Error: err.Error()}, nil
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	v, el, err := pg.Test(ctx, c, s.dialer(c.ServerID))
	if err != nil {
		return &pb.TestReply{Error: errText(err)}, nil
	}
	return &pb.TestReply{Ok: true, ServerVersion: v, LatencyMs: el.Milliseconds()}, nil
}

// --- schema and data -------------------------------------------------------------

func (s *Service) ListDatabases(ctx context.Context, r *pb.Ref) (*pb.DatabaseList, error) {
	out, err := s.PG.Databases(ctx, r.Id)
	if err != nil {
		return nil, grpcErr(err)
	}
	if c, err := s.Store.Connection(r.Id); err == nil && len(c.Databases) > 0 {
		out.Databases = slices.DeleteFunc(out.Databases, func(d *pb.Database) bool { return !slices.Contains(c.Databases, d.Name) })
	}
	return out, nil
}

func (s *Service) ListSchemas(ctx context.Context, r *pb.DbRef) (*pb.SchemaList, error) {
	out, err := s.PG.Schemas(ctx, r.ConnectionId, r.Database)
	return out, grpcErr(err)
}

func (s *Service) ListObjects(ctx context.Context, r *pb.SchemaRef) (*pb.ObjectList, error) {
	out, err := s.PG.Objects(ctx, r.ConnectionId, r.Database, r.Schema)
	return out, grpcErr(err)
}

func (s *Service) DescribeObject(ctx context.Context, r *pb.ObjectRef) (*pb.ObjectInfo, error) {
	out, err := s.PG.Describe(ctx, r)
	return out, grpcErr(err)
}

func (s *Service) ReadTable(ctx context.Context, r *pb.ReadTableRequest) (*pb.ResultSet, error) {
	out, err := s.PG.ReadTable(ctx, r)
	return out, grpcErr(err)
}

func (s *Service) ApplyEdits(ctx context.Context, r *pb.EditRequest) (*pb.EditReply, error) {
	out, err := s.PG.ApplyEdits(ctx, r)
	if err == nil {
		s.logf("info", "%d rows changed in %s.%s", out.RowsAffected, r.Schema, r.Table)
	}
	return out, grpcErr(err)
}

// --- consoles --------------------------------------------------------------------

func (s *Service) OpenConsole(ctx context.Context, r *pb.DbRef) (*pb.Console, error) {
	c, err := s.PG.OpenConsole(ctx, r.ConnectionId, r.Database)
	if err != nil {
		return nil, grpcErr(err)
	}
	return c.Info(), nil
}

func (s *Service) CloseConsole(_ context.Context, r *pb.ConsoleRef) (*pb.Empty, error) {
	s.PG.CloseConsole(r.Id)
	return &pb.Empty{}, nil
}

func (s *Service) Execute(ctx context.Context, r *pb.ExecuteRequest) (*pb.ExecuteReply, error) {
	c, err := s.PG.Console(r.ConsoleId)
	if err != nil {
		return nil, status.Error(codes.NotFound, err.Error())
	}
	out, err := c.Execute(ctx, r.Sql, r.All, int(r.Cursor), int(r.MaxRows))
	return out, grpcErr(err)
}

func (s *Service) Cancel(ctx context.Context, r *pb.ConsoleRef) (*pb.Empty, error) {
	c, err := s.PG.Console(r.Id)
	if err != nil {
		return &pb.Empty{}, nil
	}
	return &pb.Empty{}, grpcErr(c.Cancel(ctx))
}

func (s *Service) Statements(_ context.Context, r *pb.StatementsRequest) (*pb.StatementsReply, error) {
	out := &pb.StatementsReply{}
	for _, st := range pg.Split(r.Sql) {
		out.Statements = append(out.Statements, &pb.StatementRange{Start: int32(st.Start16), End: int32(st.End16)})
	}
	return out, nil
}

// --- CloudSync -----------------------------------------------------------------

func (s *Service) noSync() error {
	return status.Error(codes.Unimplemented, "CloudSync is not available in this build")
}

func (s *Service) EnableSync(context.Context, *pb.Empty) (*pb.SyncState, error) {
	if s.Sync == nil {
		return nil, s.noSync()
	}
	s.Sync.Enable()
	return s.syncState(), nil
}

func (s *Service) DisableSync(ctx context.Context, _ *pb.Empty) (*pb.SyncState, error) {
	if s.Sync == nil {
		return nil, s.noSync()
	}
	s.Sync.Disable(ctx)
	return s.syncState(), nil
}

func (s *Service) SyncNow(context.Context, *pb.Empty) (*pb.SyncState, error) {
	if s.Sync == nil {
		return nil, s.noSync()
	}
	s.Sync.Kick()
	return s.syncState(), nil
}

func (s *Service) MoveServersToCloudSync(ctx context.Context, _ *pb.Empty) (*pb.SyncState, error) {
	if s.Sync == nil {
		return nil, s.noSync()
	}
	if _, ok := s.Sync.SharedServers(); !ok {
		return nil, cloudsync.ErrNoShared
	}
	// Jump servers first, so the moved servers can name their new ids.
	own := s.Store.Servers()
	slices.SortStableFunc(own, func(a, b store.Server) int {
		if (a.JumpServerID == "") == (b.JumpServerID == "") {
			return 0
		}
		if a.JumpServerID == "" {
			return -1
		}
		return 1
	})
	ids := map[string]string{}
	var moved []string
	for _, x := range own {
		old := x.ID
		local := ""
		if k, ok := strings.CutPrefix(x.KeyID, store.LocalKeyPrefix); ok {
			local = k
		}
		if n, ok := ids[x.JumpServerID]; ok {
			x.JumpServerID = n
		}
		x.ID, x.Revision = "", ""
		out, err := s.Sync.PutServer(ctx, x)
		if err != nil {
			s.Store.DropServers(moved)
			return nil, grpcErr(fmt.Errorf("moving %s: %w", x.Name, err))
		}
		ids[old] = out.ID
		moved = append(moved, old)
		if local != "" {
			s.Store.SetServerKey(out.ID, local)
		}
		s.Store.ReplaceServerID(old, out.ID)
	}
	if err := s.Store.DropServers(moved); err != nil {
		return nil, grpcErr(err)
	}
	s.logf("info", "%d servers moved to CloudSync", len(moved))
	return s.syncState(), nil
}

// --- errors --------------------------------------------------------------------

func grpcErr(err error) error {
	if err == nil {
		return nil
	}
	if _, ok := status.FromError(err); ok {
		return err
	}
	switch {
	case errors.Is(err, store.ErrNotFound):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, context.Canceled):
		return status.Error(codes.Canceled, "cancelled")
	case errors.Is(err, context.DeadlineExceeded):
		return status.Error(codes.DeadlineExceeded, "timed out")
	}
	return status.Error(codes.Unknown, err.Error())
}

func errText(err error) string {
	if st, ok := status.FromError(err); ok {
		return st.Message()
	}
	return err.Error()
}

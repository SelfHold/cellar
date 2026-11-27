package rpc_test

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/pem"
	"fmt"
	"net"
	"strings"
	"testing"
	"time"

	"golang.org/x/crypto/ssh"

	"dbmanager/core/cloudsync"
	"dbmanager/core/cloudsync/fake"
	cspb "dbmanager/core/cloudsync/pb"
	"dbmanager/core/keychain"
	"dbmanager/core/rpc"
	"dbmanager/core/rpc/pb"
	"dbmanager/core/sshx"
	"dbmanager/core/sshx/sshtest"
	"dbmanager/core/store"
)

var ctx = context.Background()

func newService(t *testing.T, dir string, d cloudsync.Dialer) *rpc.Service {
	t.Helper()
	kc := keychain.NewMemory()
	seal, err := store.LoadSealer(dir, kc)
	if err != nil {
		t.Fatal(err)
	}
	st, err := store.Open(dir, seal)
	if err != nil {
		t.Fatal(err)
	}
	s := rpc.New(st, "test")
	if d != nil {
		sy := cloudsync.New(cloudsync.Options{Dialer: d, Store: st, Seal: seal, Dir: dir, Keychain: kc, AppName: "DB Manager", OnChange: s.SyncChanged})
		sy.RetryDelay, sy.ProbeDelay, sy.Heartbeat = 50*time.Millisecond, 50*time.Millisecond, 50*time.Millisecond
		s.Sync = sy
		sy.Start()
		t.Cleanup(sy.Close)
	}
	t.Cleanup(s.Close)
	return s
}

func waitFor(t *testing.T, what string, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for !cond() {
		if time.Now().After(deadline) {
			t.Fatalf("timed out waiting for %s", what)
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func key(t *testing.T, passphrase string) (string, ssh.PublicKey) {
	pub, priv, _ := ed25519.GenerateKey(rand.Reader)
	var blk *pem.Block
	var err error
	if passphrase == "" {
		blk, err = ssh.MarshalPrivateKey(priv, "")
	} else {
		blk, err = ssh.MarshalPrivateKeyWithPassphrase(priv, "", []byte(passphrase))
	}
	if err != nil {
		t.Fatal(err)
	}
	pk, _ := ssh.NewPublicKey(pub)
	return string(pem.EncodeToMemory(blk)), pk
}

// fakePG answers an SSLRequest like PostgreSQL does.
func fakePG(t *testing.T) int {
	l, _ := net.Listen("tcp", "127.0.0.1:0")
	t.Cleanup(func() { l.Close() })
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			b := make([]byte, 8)
			c.Read(b)
			c.Write([]byte("N"))
			c.Close()
		}
	}()
	return l.Addr().(*net.TCPAddr).Port
}

func sshServer(t *testing.T, keys ...ssh.PublicKey) *sshtest.Server {
	srv := sshtest.Start(t, sshtest.Options{User: "deploy", Password: "pw", Keys: keys})
	return srv
}

func TestStandalone(t *testing.T) {
	s := newService(t, t.TempDir(), nil)
	encPEM, encPub := key(t, "phrase")
	srv := sshServer(t, encPub)
	pgPort := fakePG(t)
	srv.Exec = func(cmd string) (string, int) {
		if !strings.Contains(cmd, "@@ss") {
			return "", 1
		}
		return fmt.Sprintf("@@ss\nLISTEN 0 128 0.0.0.0:22 0.0.0.0:*\nLISTEN 0 244 127.0.0.1:%d 0.0.0.0:*\nLISTEN 0 1 127.0.0.1:1 0.0.0.0:*\n@@end\n", pgPort), 0
	}

	sv, err := s.SaveServer(ctx, &pb.Server{Name: "web", Host: "127.0.0.1", Port: uint32(srv.Port()), User: "deploy", Auth: pb.Server_PASSWORD, Password: "pw", Group: "prod/eu"})
	if err != nil {
		t.Fatal(err)
	}
	if sv.Shared || sv.Group != "prod/eu" {
		t.Fatalf("saved %+v", sv)
	}
	r, err := s.ConnectServer(ctx, &pb.ConnectRequest{Id: sv.Id})
	if err != nil || r.Connected || r.HostKey.GetStatus() != pb.HostKey_UNKNOWN {
		t.Fatalf("first connect %+v %v", r, err)
	}
	if _, err := s.TrustHostKey(ctx, &pb.TrustRequest{Id: sv.Id, Key: r.HostKey.Key}); err != nil {
		t.Fatal(err)
	}
	r, err = s.ConnectServer(ctx, &pb.ConnectRequest{Id: sv.Id})
	if err != nil || !r.Connected {
		t.Fatalf("connect %+v %v", r, err)
	}
	list, _ := s.ListServers(ctx, &pb.Empty{})
	if len(list.Servers) != 1 || !list.Servers[0].Connected || len(list.Servers[0].HostKeys) != 1 {
		t.Fatalf("servers %+v", list.Servers)
	}

	d, err := s.Discover(ctx, &pb.Ref{Id: sv.Id})
	if err != nil {
		t.Fatal(err)
	}
	if len(d.Services) != 1 || !d.Services[0].Confirmed || d.Services[0].Port != uint32(pgPort) {
		t.Fatalf("discovered %+v", d.Services)
	}
	c, err := s.SaveConnection(ctx, &pb.Connection{ServerId: sv.Id, Host: d.Services[0].Host, Port: d.Services[0].Port, User: "postgres", Password: "x"})
	if err != nil || c.Name != fmt.Sprintf("postgres@127.0.0.1:%d", pgPort) {
		t.Fatalf("connection %+v %v", c, err)
	}
	d, _ = s.Discover(ctx, &pb.Ref{Id: sv.Id})
	if d.Services[0].ConnectionId != c.Id {
		t.Fatal("discovery does not mark the added connection")
	}

	// A local encrypted key: the passphrase is asked at connect.
	k, err := s.SaveLocalKey(ctx, &pb.LocalKey{Title: "laptop", PrivateKey: encPEM})
	if err != nil || !k.Encrypted || k.Fingerprint != sshx.Fingerprint(encPub) {
		t.Fatalf("local key %+v %v", k, err)
	}
	sv.Auth, sv.KeyId, sv.Password = pb.Server_KEY, k.Id, ""
	if _, err := s.SaveServer(ctx, sv); err != nil {
		t.Fatal(err)
	}
	if s.Pool.Connected(sv.Id) {
		t.Fatal("changing the login did not close the connection")
	}
	r, err = s.ConnectServer(ctx, &pb.ConnectRequest{Id: sv.Id})
	if err != nil || !r.NeedPassphrase {
		t.Fatalf("want passphrase, got %+v %v", r, err)
	}
	if r, err = s.ConnectServer(ctx, &pb.ConnectRequest{Id: sv.Id, Passphrase: "wrong"}); err != nil || !r.NeedPassphrase {
		t.Fatalf("wrong passphrase %+v %v", r, err)
	}
	if r, err = s.ConnectServer(ctx, &pb.ConnectRequest{Id: sv.Id, Passphrase: "phrase"}); err != nil || !r.Connected {
		t.Fatalf("with passphrase %+v %v", r, err)
	}

	// Removing the server takes its connections along.
	if _, err := s.DeleteServer(ctx, &pb.Ref{Id: sv.Id}); err != nil {
		t.Fatal(err)
	}
	cl, _ := s.ListConnections(ctx, &pb.Empty{})
	if len(cl.Connections) != 0 || s.Pool.Connected(sv.Id) {
		t.Fatalf("left %d connections", len(cl.Connections))
	}
	if _, err := s.SaveServer(ctx, &pb.Server{Name: "x", Host: "h", User: "u", Auth: pb.Server_KEY, KeyId: "bogus"}); err == nil {
		t.Fatal("bad key id accepted")
	}
}

func TestCloudSyncShared(t *testing.T) {
	vault := fake.New()
	safePEM, safePub := key(t, "")
	vault.AddKey(&cspb.SshKey{Id: "k1", Title: "work key", KeyType: "ssh-ed25519", Fingerprint: sshx.Fingerprint(safePub),
		PublicKey: sshx.AuthorizedLine(safePub), PrivateKey: safePEM})
	srv := sshServer(t, safePub)
	hostKey := sshx.AuthorizedLine(srv.HostKey)

	devA := &fake.Device{V: vault, Name: "laptop"}
	a := newService(t, t.TempDir(), devA)
	waitFor(t, "CloudSync found", func() bool { return a.Sync.State().Available })

	// Standalone first: an own server and a connection through it.
	own, err := a.SaveServer(ctx, &pb.Server{Name: "db1", Host: "127.0.0.1", Port: uint32(srv.Port()), User: "deploy", Auth: pb.Server_PASSWORD, Password: "pw", HostKeys: []string{hostKey}})
	if err != nil || own.Shared {
		t.Fatalf("own server %+v %v", own, err)
	}
	conn, _ := a.SaveConnection(ctx, &pb.Connection{ServerId: own.Id, Host: "127.0.0.1", Port: 5432, User: "app", Name: "main"})

	if _, err := a.EnableSync(ctx, &pb.Empty{}); err != nil {
		t.Fatal(err)
	}
	waitFor(t, "synced with scopes", func() bool {
		st, _ := a.GetState(ctx, &pb.Empty{})
		return st.Sync.Phase == pb.SyncState_SYNCED && st.Sync.SharedServers && st.Sync.SafeKeys && st.Sync.OwnServers == 1
	})
	keys, _ := a.ListKeys(ctx, &pb.Empty{})
	if len(keys.Keys) != 1 || keys.Keys[0].Id != "safe:k1" || keys.SafeNote != "" {
		t.Fatalf("keys %+v", keys)
	}

	// Move the own server into the shared list; the connection follows.
	if _, err := a.MoveServersToCloudSync(ctx, &pb.Empty{}); err != nil {
		t.Fatal(err)
	}
	shared := vault.Servers()
	if len(shared) != 1 || shared[0].Name != "db1" || shared[0].Password != "pw" {
		t.Fatalf("vault servers %+v", shared)
	}
	cl, _ := a.ListConnections(ctx, &pb.Empty{})
	if cl.Connections[0].ServerId != shared[0].Id {
		t.Fatalf("connection still on %s", cl.Connections[0].ServerId)
	}
	list, _ := a.ListServers(ctx, &pb.Empty{})
	if len(list.Servers) != 1 || !list.Servers[0].Shared {
		t.Fatalf("servers after move %+v", list.Servers)
	}

	// A new server goes to the shared list and logs in with the safe's key.
	ns, err := a.SaveServer(ctx, &pb.Server{Name: "db2", Host: "127.0.0.1", Port: uint32(srv.Port()), User: "deploy", Auth: pb.Server_KEY, KeyId: "safe:k1", HostKeys: []string{hostKey}})
	if err != nil || !ns.Shared {
		t.Fatalf("new server %+v %v", ns, err)
	}
	if r, err := a.ConnectServer(ctx, &pb.ConnectRequest{Id: ns.Id}); err != nil || !r.Connected {
		t.Fatalf("connect with the safe key: %+v %v", r, err)
	}
	if got := vault.Servers(); len(got) != 2 || got[1].SshKeyId != "k1" && got[0].SshKeyId != "k1" {
		t.Fatalf("vault %+v", got)
	}

	// Another device sees the servers (shared) and the connection (record).
	devB := &fake.Device{V: vault, Name: "phone"}
	b := newService(t, t.TempDir(), devB)
	b.EnableSync(ctx, &pb.Empty{})
	waitFor(t, "device B synced", func() bool {
		l, _ := b.ListServers(ctx, &pb.Empty{})
		c, _ := b.ListConnections(ctx, &pb.Empty{})
		return len(l.Servers) == 2 && len(c.Connections) == 1 && c.Connections[0].Id == conn.Id
	})

	// Another app edits a server: both devices see it; our edit keeps its
	// extra keys.
	cur := vault.Servers()[0]
	cur.Name = "renamed"
	cur.Extra = map[string][]byte{"sshmanager.start_dir": []byte("/srv")}
	vault.PutServerDirect(cur)
	waitFor(t, "rename seen", func() bool {
		l, _ := a.ListServers(ctx, &pb.Empty{})
		for _, x := range l.Servers {
			if x.Name == "renamed" {
				return true
			}
		}
		return false
	})
	l, _ := a.ListServers(ctx, &pb.Empty{})
	var renamed *pb.Server
	for _, x := range l.Servers {
		if x.Name == "renamed" {
			renamed = x
		}
	}
	renamed.Notes = "edited here"
	if _, err := a.SaveServer(ctx, renamed); err != nil {
		t.Fatal(err)
	}
	for _, x := range vault.Servers() {
		if x.Id == renamed.Id && (x.Notes != "edited here" || string(x.Extra["sshmanager.start_dir"]) != "/srv") {
			t.Fatalf("edit lost data: %+v", x)
		}
	}

	// Connections edited on both devices merge.
	b.SaveConnection(ctx, &pb.Connection{Name: "from phone", Host: "10.0.0.5", User: "ro"})
	a.SaveConnection(ctx, &pb.Connection{Name: "from laptop", Host: "10.0.0.6", User: "ro"})
	waitFor(t, "merged connections", func() bool {
		ca, _ := a.ListConnections(ctx, &pb.Empty{})
		cb, _ := b.ListConnections(ctx, &pb.Empty{})
		return len(ca.Connections) == 3 && len(cb.Connections) == 3
	})

	// CloudSync stops: the shared list stays readable from the cache,
	// writes are refused.
	devA.Down.Store(true)
	a.Sync.Kick()
	waitFor(t, "not running", func() bool { return a.Sync.State().Phase == cloudsync.PhaseNotRunning })
	l, _ = a.ListServers(ctx, &pb.Empty{})
	if len(l.Servers) != 2 {
		t.Fatalf("cached servers %d", len(l.Servers))
	}
	if _, err := a.SaveServer(ctx, l.Servers[0]); err == nil {
		t.Fatal("write to the shared list without CloudSync")
	}
}

func TestOldCloudSync(t *testing.T) {
	vault := fake.New()
	vault.Old = true
	s := newService(t, t.TempDir(), &fake.Device{V: vault, Name: "pc"})
	s.SaveServer(ctx, &pb.Server{Name: "own", Host: "h", User: "u", Auth: pb.Server_AGENT})
	s.EnableSync(ctx, &pb.Empty{})
	waitFor(t, "synced records only", func() bool {
		st, _ := s.GetState(ctx, &pb.Empty{})
		return st.Sync.Phase == pb.SyncState_SYNCED && !st.Sync.SharedServers
	})
	if !strings.Contains(string(vault.Record(cloudsync.RecordKey)), `"own"`) {
		t.Fatal("the own servers are not in the record")
	}
	k, _ := s.ListKeys(ctx, &pb.Empty{})
	if k.SafeNote == "" {
		t.Fatal("no note about the safe")
	}
	if _, err := s.MoveServersToCloudSync(ctx, &pb.Empty{}); err == nil {
		t.Fatal("move without the scope")
	}
}

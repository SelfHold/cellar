package sshx_test

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/pem"
	"errors"
	"io"
	"net"
	"strings"
	"testing"
	"time"

	"golang.org/x/crypto/ssh"

	"github.com/SelfHold/cellar/core/sshx"
	"github.com/SelfHold/cellar/core/sshx/sshtest"
)

func newKey(t *testing.T, passphrase string) (string, ssh.PublicKey) {
	t.Helper()
	pub, priv, _ := ed25519.GenerateKey(rand.Reader)
	var blk *pem.Block
	var err error
	if passphrase == "" {
		blk, err = ssh.MarshalPrivateKey(priv, "test")
	} else {
		blk, err = ssh.MarshalPrivateKeyWithPassphrase(priv, "test", []byte(passphrase))
	}
	if err != nil {
		t.Fatal(err)
	}
	pk, _ := ssh.NewPublicKey(pub)
	return string(pem.EncodeToMemory(blk)), pk
}

func host(s *sshtest.Server) (string, int) {
	h, _, _ := net.SplitHostPort(s.Addr)
	return h, s.Port()
}

func TestHostKeyFlowAndPassword(t *testing.T) {
	srv := sshtest.Start(t, sshtest.Options{User: "u", Password: "pw"})
	srv.Exec = func(cmd string) (string, int) { return "ran: " + cmd, 0 }
	h, p := host(srv)
	pool := sshx.NewPool()
	defer pool.CloseAll()
	ctx := context.Background()
	spec := &sshx.Spec{ID: "s1", Host: h, Port: p, User: "u", Password: "pw"}

	_, err := pool.Client(ctx, spec)
	var hk *sshx.HostKeyError
	if !errors.As(err, &hk) || hk.Status != sshx.HostKeyUnknown {
		t.Fatalf("want unknown host key, got %v", err)
	}
	if hk.Fingerprint != sshx.Fingerprint(srv.HostKey) {
		t.Fatalf("fingerprint %s", hk.Fingerprint)
	}
	spec.HostKeys = []string{hk.Key}
	c, err := pool.Client(ctx, spec)
	if err != nil {
		t.Fatal(err)
	}
	out, _, err := sshx.Run(ctx, c, "echo hi", 1<<20)
	if err != nil || out != "ran: echo hi" {
		t.Fatalf("run: %q %v", out, err)
	}
	if !pool.Connected("s1") {
		t.Fatal("not connected")
	}
	// Reused, not dialed again.
	if _, err := pool.Client(ctx, spec); err != nil || srv.Logins.Load() != 1 {
		t.Fatalf("logins %d, %v", srv.Logins.Load(), err)
	}

	// Another server answering with another key: CHANGED.
	other := sshtest.Start(t, sshtest.Options{User: "u", Password: "pw"})
	h2, p2 := host(other)
	_, err = pool.Client(ctx, &sshx.Spec{ID: "s2", Host: h2, Port: p2, User: "u", Password: "pw", HostKeys: spec.HostKeys})
	if !errors.As(err, &hk) || hk.Status != sshx.HostKeyChanged {
		t.Fatalf("want changed host key, got %v", err)
	}

	// Wrong password.
	_, err = pool.Client(ctx, &sshx.Spec{ID: "s3", Host: h, Port: p, User: "u", Password: "bad", HostKeys: spec.HostKeys})
	if err == nil || !strings.Contains(err.Error(), "refused the login") {
		t.Fatalf("want refused login, got %v", err)
	}
}

func TestKeysAndDropAndForward(t *testing.T) {
	keyPEM, pub := newKey(t, "")
	encPEM, encPub := newKey(t, "secret")
	srv := sshtest.Start(t, sshtest.Options{User: "u", Keys: []ssh.PublicKey{pub, encPub}})
	h, p := host(srv)
	known := []string{sshx.AuthorizedLine(srv.HostKey)}
	changes := make(chan string, 10)
	pool := sshx.NewPool()
	pool.Keepalive = 50 * time.Millisecond
	pool.OnChange = func(id string) { changes <- id }
	defer pool.CloseAll()
	ctx := context.Background()

	if _, err := sshx.ParseKey(encPEM, ""); !errors.Is(err, sshx.ErrPassphrase) {
		t.Fatalf("want passphrase error, got %v", err)
	}
	if _, err := sshx.ParseKey(encPEM, "nope"); !errors.Is(err, sshx.ErrPassphrase) {
		t.Fatalf("wrong passphrase: %v", err)
	}
	info, err := sshx.DescribeKey(encPEM, "")
	if !info.Encrypted || info.Fingerprint != sshx.Fingerprint(encPub) {
		t.Fatalf("describe encrypted: %+v %v", info, err)
	}
	signer, err := sshx.ParseKey(encPEM, "secret")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Client(ctx, &sshx.Spec{ID: "enc", Host: h, Port: p, User: "u", Signer: signer, HostKeys: known}); err != nil {
		t.Fatal(err)
	}
	signer, _ = sshx.ParseKey(keyPEM, "")
	c, err := pool.Client(ctx, &sshx.Spec{ID: "k", Host: h, Port: p, User: "u", Signer: signer, HostKeys: known})
	if err != nil {
		t.Fatal(err)
	}

	// A forwarded TCP connection to a local echo server.
	lis, _ := net.Listen("tcp", "127.0.0.1:0")
	defer lis.Close()
	go func() {
		for {
			cn, err := lis.Accept()
			if err != nil {
				return
			}
			go func() { io.Copy(cn, cn); cn.Close() }()
		}
	}()
	fc, err := c.Dial("tcp", lis.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	fc.Write([]byte("ping"))
	buf := make([]byte, 4)
	io.ReadFull(fc, buf)
	fc.Close()
	if string(buf) != "ping" {
		t.Fatalf("echo %q", buf)
	}

	// The server goes away: the pool notices and drops the client.
	drain(changes)
	srv.DropConnections()
	deadline := time.After(5 * time.Second)
	for pool.Connected("k") {
		select {
		case <-deadline:
			t.Fatal("dead connection was kept")
		case <-time.After(20 * time.Millisecond):
		}
	}
}

func TestJump(t *testing.T) {
	jump := sshtest.Start(t, sshtest.Options{User: "j", Password: "jp"})
	target := sshtest.Start(t, sshtest.Options{User: "u", Password: "pw"})
	target.Exec = func(string) (string, int) { return "target", 0 }
	jh, jp := host(jump)
	th, tp := host(target)
	pool := sshx.NewPool()
	defer pool.CloseAll()
	c, err := pool.Client(context.Background(), &sshx.Spec{
		ID: "t", Host: th, Port: tp, User: "u", Password: "pw", HostKeys: []string{sshx.AuthorizedLine(target.HostKey)},
		Jump: &sshx.Spec{ID: "j", Host: jh, Port: jp, User: "j", Password: "jp", HostKeys: []string{sshx.AuthorizedLine(jump.HostKey)}},
	})
	if err != nil {
		t.Fatal(err)
	}
	out, _, _ := sshx.Run(context.Background(), c, "x", 100)
	if out != "target" || jump.Forwarded.Load() != 1 {
		t.Fatalf("out %q, forwarded %d", out, jump.Forwarded.Load())
	}
}

func drain(ch chan string) {
	for {
		select {
		case <-ch:
		default:
			return
		}
	}
}

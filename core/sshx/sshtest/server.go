// Package sshtest is an in-process SSH server for tests: password and
// public key logins, exec through a handler, and direct-tcpip channels to
// real addresses (so a database session can go through it).
package sshtest

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/binary"
	"io"
	"net"
	"strconv"
	"sync"
	"sync/atomic"
	"testing"

	"golang.org/x/crypto/ssh"
)

// Server is a running test server.
type Server struct {
	Addr    string
	HostKey ssh.PublicKey
	// Exec answers a command: stdout and the exit status.
	Exec func(cmd string) (string, int)
	// Forwarded counts direct-tcpip channels.
	Forwarded atomic.Int64
	// Rewrite maps a forwarding target before dialing ("" = as is).
	Rewrite func(addr string) string

	lis     net.Listener
	mu      sync.Mutex
	conns   []net.Conn
	closed  bool
	Logins  atomic.Int64
	allowed []ssh.PublicKey
}

// Options of a test server.
type Options struct {
	User     string
	Password string
	Keys     []ssh.PublicKey // allowed client keys
}

// Start starts a server on 127.0.0.1; t.Cleanup closes it.
func Start(t testing.TB, o Options) *Server {
	t.Helper()
	_, priv, _ := ed25519.GenerateKey(rand.Reader)
	signer, err := ssh.NewSignerFromKey(priv)
	if err != nil {
		t.Fatal(err)
	}
	s := &Server{HostKey: signer.PublicKey(), allowed: o.Keys}
	cfg := &ssh.ServerConfig{
		PasswordCallback: func(c ssh.ConnMetadata, pw []byte) (*ssh.Permissions, error) {
			if c.User() == o.User && o.Password != "" && string(pw) == o.Password {
				return nil, nil
			}
			return nil, errDenied
		},
		PublicKeyCallback: func(c ssh.ConnMetadata, k ssh.PublicKey) (*ssh.Permissions, error) {
			if c.User() != o.User {
				return nil, errDenied
			}
			for _, a := range s.allowed {
				if string(a.Marshal()) == string(k.Marshal()) {
					return nil, nil
				}
			}
			return nil, errDenied
		},
	}
	cfg.AddHostKey(signer)
	s.lis, err = net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	s.Addr = s.lis.Addr().String()
	go s.serve(cfg)
	t.Cleanup(s.Close)
	return s
}

type denied struct{}

func (denied) Error() string { return "denied" }

var errDenied = denied{}

// Port of the server.
func (s *Server) Port() int {
	_, p, _ := net.SplitHostPort(s.Addr)
	n, _ := strconv.Atoi(p)
	return n
}

// Close stops the server and drops every connection.
func (s *Server) Close() {
	s.mu.Lock()
	s.closed = true
	cs := s.conns
	s.conns = nil
	s.mu.Unlock()
	s.lis.Close()
	for _, c := range cs {
		c.Close()
	}
}

// DropConnections cuts every client off (the server keeps listening).
func (s *Server) DropConnections() {
	s.mu.Lock()
	cs := s.conns
	s.conns = nil
	s.mu.Unlock()
	for _, c := range cs {
		c.Close()
	}
}

func (s *Server) serve(cfg *ssh.ServerConfig) {
	for {
		c, err := s.lis.Accept()
		if err != nil {
			return
		}
		s.mu.Lock()
		if s.closed {
			s.mu.Unlock()
			c.Close()
			return
		}
		s.conns = append(s.conns, c)
		s.mu.Unlock()
		go s.handle(c, cfg)
	}
}

func (s *Server) handle(c net.Conn, cfg *ssh.ServerConfig) {
	sc, chans, reqs, err := ssh.NewServerConn(c, cfg)
	if err != nil {
		c.Close()
		return
	}
	s.Logins.Add(1)
	defer sc.Close()
	go func() {
		for r := range reqs {
			if r.WantReply {
				r.Reply(r.Type == "keepalive@openssh.com", nil)
			}
		}
	}()
	for nc := range chans {
		switch nc.ChannelType() {
		case "session":
			go s.session(nc)
		case "direct-tcpip":
			go s.forward(nc)
		default:
			nc.Reject(ssh.UnknownChannelType, "no")
		}
	}
}

func (s *Server) session(nc ssh.NewChannel) {
	ch, reqs, err := nc.Accept()
	if err != nil {
		return
	}
	defer ch.Close()
	for r := range reqs {
		if r.Type != "exec" {
			if r.WantReply {
				r.Reply(false, nil)
			}
			continue
		}
		var p struct{ Cmd string }
		ssh.Unmarshal(r.Payload, &p)
		r.Reply(true, nil)
		out, code := "", 127
		if s.Exec != nil {
			out, code = s.Exec(p.Cmd)
		}
		io.WriteString(ch, out)
		var st [4]byte
		binary.BigEndian.PutUint32(st[:], uint32(code))
		ch.SendRequest("exit-status", false, st[:])
		return
	}
}

func (s *Server) forward(nc ssh.NewChannel) {
	var p struct {
		Host     string
		Port     uint32
		OrigHost string
		OrigPort uint32
	}
	if err := ssh.Unmarshal(nc.ExtraData(), &p); err != nil {
		nc.Reject(ssh.ConnectionFailed, "bad request")
		return
	}
	addr := net.JoinHostPort(p.Host, strconv.Itoa(int(p.Port)))
	if s.Rewrite != nil {
		if a := s.Rewrite(addr); a != "" {
			addr = a
		}
	}
	tc, err := net.Dial("tcp", addr)
	if err != nil {
		nc.Reject(ssh.ConnectionFailed, err.Error())
		return
	}
	ch, reqs, err := nc.Accept()
	if err != nil {
		tc.Close()
		return
	}
	s.Forwarded.Add(1)
	go ssh.DiscardRequests(reqs)
	go func() { io.Copy(ch, tc); ch.CloseWrite(); ch.Close() }()
	io.Copy(tc, ch)
	tc.Close()
}

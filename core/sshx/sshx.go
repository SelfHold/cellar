// Package sshx keeps the SSH connections to servers: one client per server,
// reused by every database session through it (direct-tcpip channels) and
// by discovery (exec). Host keys are checked against the server's trusted
// keys; an unknown or changed key stops the connection until the user
// decides (HostKeyError).
package sshx

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"
)

// Spec says how to reach one server. The caller (rpc) builds it from the
// server entry and the key it points to; secrets live in memory only.
type Spec struct {
	ID       string
	Host     string
	Port     int
	User     string
	Password string
	Signer   ssh.Signer // KEY
	Agent    bool       // use $SSH_AUTH_SOCK
	HostKeys []string   // authorized_keys lines
	Jump     *Spec      // connect through this server first
}

func (s *Spec) addr() string {
	port := s.Port
	if port == 0 {
		port = 22
	}
	return net.JoinHostPort(s.Host, strconv.Itoa(port))
}

// HostKeyStatus of a presented key.
type HostKeyStatus int

const (
	HostKeyKnown HostKeyStatus = iota + 1
	HostKeyUnknown
	HostKeyChanged
)

// HostKeyError: the server presented a key the user has to decide on.
type HostKeyError struct {
	ServerID    string
	Status      HostKeyStatus
	Key         string // authorized_keys format
	Fingerprint string
	Type        string
}

func (e *HostKeyError) Error() string {
	if e.Status == HostKeyChanged {
		return "the server's host key has CHANGED (" + e.Fingerprint + "): check it before trusting"
	}
	return "unknown host key " + e.Fingerprint
}

// ErrPassphrase: the private key is encrypted and no passphrase opens it.
var ErrPassphrase = errors.New("the private key needs a passphrase")

// Fingerprint is SHA256:<base64> like OpenSSH prints it.
func Fingerprint(k ssh.PublicKey) string {
	sum := sha256.Sum256(k.Marshal())
	return "SHA256:" + base64.RawStdEncoding.EncodeToString(sum[:])
}

// AuthorizedLine is the key in authorized_keys format without a newline.
func AuthorizedLine(k ssh.PublicKey) string {
	return strings.TrimSpace(string(ssh.MarshalAuthorizedKey(k)))
}

// KeyInfo describes a private key: type, fingerprint, public line, and
// whether it is encrypted. An encrypted key in the old PEM format does
// not reveal its public half (empty).
type KeyInfo struct {
	Type        string
	Fingerprint string
	PublicKey   string
	Encrypted   bool
}

// DescribeKey parses a private key (passphrase optional).
func DescribeKey(pemText, passphrase string) (KeyInfo, error) {
	s, err := ParseKey(pemText, passphrase)
	if err == nil {
		return KeyInfo{Type: s.PublicKey().Type(), Fingerprint: Fingerprint(s.PublicKey()), PublicKey: AuthorizedLine(s.PublicKey()), Encrypted: passphrase != ""}, nil
	}
	var miss *ssh.PassphraseMissingError
	if errors.As(errors.Unwrap(err), &miss) || errors.Is(err, ErrPassphrase) {
		info := KeyInfo{Encrypted: true}
		if _, err2 := ssh.ParseRawPrivateKey([]byte(pemText)); errors.As(err2, &miss) && miss.PublicKey != nil {
			info.Type, info.Fingerprint, info.PublicKey = miss.PublicKey.Type(), Fingerprint(miss.PublicKey), AuthorizedLine(miss.PublicKey)
		}
		return info, err
	}
	return KeyInfo{}, err
}

// ParseKey returns a signer; ErrPassphrase (wrapped) when it needs one.
func ParseKey(pemText, passphrase string) (ssh.Signer, error) {
	data := []byte(strings.TrimSpace(pemText) + "\n")
	var s ssh.Signer
	var err error
	if passphrase != "" {
		s, err = ssh.ParsePrivateKeyWithPassphrase(data, []byte(passphrase))
		if err != nil && strings.Contains(err.Error(), "not encrypted") {
			s, err = ssh.ParsePrivateKey(data)
		}
	} else {
		s, err = ssh.ParsePrivateKey(data)
	}
	var miss *ssh.PassphraseMissingError
	switch {
	case errors.As(err, &miss):
		return nil, fmt.Errorf("%w (%w)", ErrPassphrase, err)
	case err != nil && passphrase != "" && (strings.Contains(err.Error(), "decryption") || strings.Contains(err.Error(), "incorrect")):
		return nil, fmt.Errorf("%w: wrong passphrase", ErrPassphrase)
	case err != nil:
		return nil, fmt.Errorf("the private key does not parse: %w", err)
	}
	return s, nil
}

// --- pool ----------------------------------------------------------------------

// Pool holds one SSH client per server id.
type Pool struct {
	// DialTimeout for TCP + handshake; Keepalive interval.
	DialTimeout time.Duration
	Keepalive   time.Duration
	// OnChange is called with a server id when its connection opens or
	// closes.
	OnChange func(id string)
	// Dial opens the first TCP hop (tests, Android): nil = net.Dialer.
	Dial func(ctx context.Context, network, addr string) (net.Conn, error)

	mu      sync.Mutex
	clients map[string]*conn
	dialing map[string]*dialing
}

type conn struct {
	c      *ssh.Client
	banner string
	jumps  []*ssh.Client // closed with c
	done   chan struct{}
}

type dialing struct {
	done chan struct{}
	c    *conn
	err  error
}

// NewPool returns an empty pool.
func NewPool() *Pool {
	return &Pool{DialTimeout: 15 * time.Second, Keepalive: 30 * time.Second, clients: map[string]*conn{}, dialing: map[string]*dialing{}}
}

// Connected says whether the server's connection is open.
func (p *Pool) Connected(id string) bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	_, ok := p.clients[id]
	return ok
}

// Banner returns the server's SSH banner (version string).
func (p *Pool) Banner(id string) string {
	p.mu.Lock()
	defer p.mu.Unlock()
	if c, ok := p.clients[id]; ok {
		return c.banner
	}
	return ""
}

// Get returns the open client of a server, without dialing.
func (p *Pool) Get(id string) (*ssh.Client, bool) {
	p.mu.Lock()
	defer p.mu.Unlock()
	c, ok := p.clients[id]
	if !ok {
		return nil, false
	}
	return c.c, true
}

// Client returns the server's client, connecting when there is none. Two
// callers at once share one dial.
func (p *Pool) Client(ctx context.Context, spec *Spec) (*ssh.Client, error) {
	p.mu.Lock()
	if c, ok := p.clients[spec.ID]; ok {
		p.mu.Unlock()
		return c.c, nil
	}
	if d, ok := p.dialing[spec.ID]; ok {
		p.mu.Unlock()
		select {
		case <-d.done:
		case <-ctx.Done():
			return nil, ctx.Err()
		}
		if d.err != nil {
			return nil, d.err
		}
		return d.c.c, nil
	}
	d := &dialing{done: make(chan struct{})}
	p.dialing[spec.ID] = d
	p.mu.Unlock()

	d.c, d.err = p.connect(ctx, spec)
	p.mu.Lock()
	delete(p.dialing, spec.ID)
	if d.err == nil {
		p.clients[spec.ID] = d.c
	}
	p.mu.Unlock()
	close(d.done)
	if d.err != nil {
		return nil, d.err
	}
	go p.watch(spec.ID, d.c)
	p.notify(spec.ID)
	return d.c.c, nil
}

func (p *Pool) connect(ctx context.Context, spec *Spec) (*conn, error) {
	ctx, cancel := context.WithTimeout(ctx, p.DialTimeout)
	defer cancel()
	var raw net.Conn
	var jumps []*ssh.Client
	var err error
	if spec.Jump != nil {
		if spec.Jump.ID == spec.ID {
			return nil, errors.New("a server cannot be its own jump server")
		}
		// The jump hop is a connection of its own (not shared through the
		// pool: closing this server closes it).
		jc, err := p.connect(ctx, spec.Jump)
		if err != nil {
			return nil, fmt.Errorf("jump server: %w", err)
		}
		jumps = append(jc.jumps, jc.c)
		raw, err = jc.c.DialContext(ctx, "tcp", spec.addr())
		if err != nil {
			closeAll(jumps)
			return nil, fmt.Errorf("jump server: cannot reach %s: %w", spec.addr(), err)
		}
	} else {
		dial := p.Dial
		if dial == nil {
			dial = (&net.Dialer{KeepAlive: 30 * time.Second}).DialContext
		}
		raw, err = dial(ctx, "tcp", spec.addr())
		if err != nil {
			return nil, err
		}
	}
	cfg, closeAgent, err := clientConfig(spec)
	if err != nil {
		raw.Close()
		closeAll(jumps)
		return nil, err
	}
	defer closeAgent()
	// The handshake has no context: a deadline on the socket instead.
	if dl, ok := ctx.Deadline(); ok {
		raw.SetDeadline(dl)
	}
	stop := context.AfterFunc(ctx, func() { raw.SetDeadline(time.Unix(1, 0)) })
	sc, chans, reqs, err := ssh.NewClientConn(raw, spec.addr(), cfg)
	stop()
	if err != nil {
		raw.Close()
		closeAll(jumps)
		var hk *HostKeyError
		if errors.As(err, &hk) {
			return nil, hk
		}
		if strings.Contains(err.Error(), "unable to authenticate") {
			return nil, fmt.Errorf("%s refused the login of %q: %w", spec.addr(), spec.User, err)
		}
		return nil, err
	}
	raw.SetDeadline(time.Time{})
	return &conn{c: ssh.NewClient(sc, chans, reqs), banner: string(sc.ServerVersion()), jumps: jumps, done: make(chan struct{})}, nil
}

func clientConfig(spec *Spec) (*ssh.ClientConfig, func(), error) {
	cfg := &ssh.ClientConfig{User: spec.User, Timeout: 15 * time.Second}
	closer := func() {}
	switch {
	case spec.Signer != nil:
		cfg.Auth = append(cfg.Auth, ssh.PublicKeys(spec.Signer))
	case spec.Agent:
		sock := os.Getenv("SSH_AUTH_SOCK")
		if sock == "" {
			return nil, closer, errors.New("no ssh-agent here ($SSH_AUTH_SOCK is not set)")
		}
		ac, err := net.Dial("unix", sock)
		if err != nil {
			return nil, closer, fmt.Errorf("ssh-agent: %w", err)
		}
		closer = func() { ac.Close() }
		cfg.Auth = append(cfg.Auth, ssh.PublicKeysCallback(agent.NewClient(ac).Signers))
	}
	if spec.Password != "" {
		pw := spec.Password
		cfg.Auth = append(cfg.Auth, ssh.Password(pw),
			ssh.KeyboardInteractive(func(_, _ string, qs []string, _ []bool) ([]string, error) {
				ans := make([]string, len(qs))
				for i := range ans {
					ans[i] = pw
				}
				return ans, nil
			}))
	}
	if len(cfg.Auth) == 0 {
		return nil, closer, errors.New("no way to log in: set a password, a key or the agent")
	}
	known, algos := parseKnown(spec.HostKeys)
	if len(algos) > 0 {
		cfg.HostKeyAlgorithms = algos
	}
	cfg.HostKeyCallback = func(_ string, _ net.Addr, key ssh.PublicKey) error {
		for _, k := range known {
			if bytes.Equal(k.Marshal(), key.Marshal()) {
				return nil
			}
		}
		e := &HostKeyError{ServerID: spec.ID, Status: HostKeyUnknown, Key: AuthorizedLine(key), Fingerprint: Fingerprint(key), Type: key.Type()}
		if len(known) > 0 {
			e.Status = HostKeyChanged
		}
		return e
	}
	return cfg, closer, nil
}

// parseKnown parses trusted keys and the host key algorithms to ask for
// (so a server with several keys shows the one on record).
func parseKnown(lines []string) ([]ssh.PublicKey, []string) {
	var keys []ssh.PublicKey
	var algos []string
	for _, l := range lines {
		k, _, _, _, err := ssh.ParseAuthorizedKey([]byte(l))
		if err != nil {
			continue
		}
		keys = append(keys, k)
		t := k.Type()
		if t == ssh.KeyAlgoRSA {
			algos = append(algos, ssh.KeyAlgoRSASHA512, ssh.KeyAlgoRSASHA256)
		}
		algos = append(algos, t)
	}
	slices.Sort(algos)
	return keys, slices.Compact(algos)
}

// watch sends keepalives; a dead connection is dropped.
func (p *Pool) watch(id string, c *conn) {
	t := time.NewTicker(p.Keepalive)
	defer t.Stop()
	wait := make(chan error, 1)
	go func() { wait <- c.c.Wait() }()
	for {
		select {
		case <-wait:
			p.drop(id, c)
			return
		case <-c.done:
			return
		case <-t.C:
			res := make(chan error, 1)
			go func() {
				_, _, err := c.c.SendRequest("keepalive@openssh.com", true, nil)
				res <- err
			}()
			select {
			case err := <-res:
				if err != nil {
					p.drop(id, c)
					return
				}
			case <-time.After(15 * time.Second):
				p.drop(id, c)
				return
			case <-c.done:
				return
			}
		}
	}
}

func (p *Pool) drop(id string, c *conn) {
	p.mu.Lock()
	cur, ok := p.clients[id]
	if ok && cur == c {
		delete(p.clients, id)
	}
	p.mu.Unlock()
	c.close()
	if ok && cur == c {
		p.notify(id)
	}
}

func (c *conn) close() {
	select {
	case <-c.done:
		return
	default:
		close(c.done)
	}
	c.c.Close()
	closeAll(c.jumps)
}

func closeAll(cs []*ssh.Client) {
	for i := len(cs) - 1; i >= 0; i-- {
		cs[i].Close()
	}
}

// Close closes the server's connection (every session through it ends).
func (p *Pool) Close(id string) {
	p.mu.Lock()
	c, ok := p.clients[id]
	delete(p.clients, id)
	p.mu.Unlock()
	if ok {
		c.close()
		p.notify(id)
	}
}

// CloseAll closes every connection.
func (p *Pool) CloseAll() {
	p.mu.Lock()
	cs := p.clients
	p.clients = map[string]*conn{}
	p.mu.Unlock()
	for _, c := range cs {
		c.close()
	}
}

func (p *Pool) notify(id string) {
	if p.OnChange != nil {
		p.OnChange(id)
	}
}

// Run executes a command on the client and returns its stdout (at most
// limit bytes) and stderr; a non-zero exit is not an error when the
// command wrote to stdout (discovery scripts tolerate missing tools).
func Run(ctx context.Context, c *ssh.Client, cmd string, limit int) (stdout, stderr string, err error) {
	s, err := c.NewSession()
	if err != nil {
		return "", "", err
	}
	defer s.Close()
	var out, errb limitedBuffer
	out.limit, errb.limit = limit, 64<<10
	s.Stdout, s.Stderr = &out, &errb
	done := make(chan error, 1)
	go func() { done <- s.Run(cmd) }()
	select {
	case err = <-done:
	case <-ctx.Done():
		s.Signal(ssh.SIGKILL)
		s.Close()
		return out.String(), errb.String(), ctx.Err()
	}
	var exit *ssh.ExitError
	if errors.As(err, &exit) && out.Len() > 0 {
		err = nil
	}
	return out.String(), errb.String(), err
}

type limitedBuffer struct {
	bytes.Buffer
	limit int
}

func (b *limitedBuffer) Write(p []byte) (int, error) {
	n := len(p)
	if room := b.limit - b.Len(); room < len(p) {
		p = p[:max(room, 0)]
	}
	b.Buffer.Write(p)
	return n, nil
}

var _ io.Writer = (*limitedBuffer)(nil)

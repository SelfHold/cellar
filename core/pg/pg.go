// Package pg talks to PostgreSQL servers: connection pools for the schema
// browser and the data viewer, pinned sessions for query consoles, all
// dialed through the server's SSH connection (or directly). Values travel
// in PostgreSQL's text format, the way psql shows them.
package pg

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/SelfHold/cellar/core/store"
)

// Dial opens a TCP connection to addr, from the server the database is
// on (through SSH) or from this device.
type Dial func(ctx context.Context, addr string) (net.Conn, error)

// Opener finds a connection's settings and how to reach it.
type Opener func(ctx context.Context, connectionID string) (store.Connection, Dial, error)

// AppName is sent as application_name.
const AppName = "Cellar"

// Config builds a pgx configuration for one database of c. Host names
// are resolved where dial connects from (the SSH server), never here.
func Config(c store.Connection, database string, dial Dial) (*pgx.ConnConfig, error) {
	if database == "" {
		database = c.Database
	}
	if database == "" {
		database = "postgres"
	}
	ssl := c.SSLMode
	if ssl == "" {
		ssl = "prefer"
	}
	u := url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(c.User, c.Password),
		Host:   net.JoinHostPort(c.Host, strconv.Itoa(c.PGPort())),
		Path:   "/" + database,
	}
	q := url.Values{}
	q.Set("sslmode", ssl)
	q.Set("connect_timeout", "15")
	q.Set("application_name", AppName)
	u.RawQuery = q.Encode()
	cfg, err := pgx.ParseConfig(u.String())
	if err != nil {
		return nil, fmt.Errorf("connection settings: %w", err)
	}
	cfg.LookupFunc = func(_ context.Context, host string) ([]string, error) { return []string{host}, nil }
	cfg.DialFunc = func(ctx context.Context, _, addr string) (net.Conn, error) {
		c, err := dial(ctx, addr)
		if err != nil {
			return nil, err
		}
		// A channel through SSH reports 0.0.0.0:0 as its remote address,
		// and CancelRequest dials the remote address: name the real one.
		return addrConn{c, dialedAddr(addr)}, nil
	}
	// The fallbacks (sslmode=prefer: TLS, then plain) use DialFunc too.
	// Plain text over the simple protocol: any statement, any type.
	cfg.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	if c.ReadOnly {
		cfg.RuntimeParams["default_transaction_read_only"] = "on"
	}
	return cfg, nil
}

type addrConn struct {
	net.Conn
	remote net.Addr
}

func (c addrConn) RemoteAddr() net.Addr { return c.remote }

type dialedAddr string

func (dialedAddr) Network() string  { return "tcp" }
func (a dialedAddr) String() string { return string(a) }

// Manager keeps the pools and consoles.
type Manager struct {
	open Opener

	mu       sync.Mutex
	pools    map[poolKey]*pgxpool.Pool
	consoles map[string]*Console
}

type poolKey struct{ conn, db string }

// NewManager returns a manager.
func NewManager(open Opener) *Manager {
	return &Manager{open: open, pools: map[poolKey]*pgxpool.Pool{}, consoles: map[string]*Console{}}
}

// pool returns the pool of one database, creating it.
func (m *Manager) pool(ctx context.Context, connID, db string) (*pgxpool.Pool, store.Connection, error) {
	c, dial, err := m.open(ctx, connID)
	if err != nil {
		return nil, c, err
	}
	if db == "" {
		db = c.Database
	}
	if db == "" {
		db = "postgres"
	}
	key := poolKey{connID, db}
	m.mu.Lock()
	p := m.pools[key]
	m.mu.Unlock()
	if p != nil {
		return p, c, nil
	}
	cc, err := Config(c, db, dial)
	if err != nil {
		return nil, c, err
	}
	pc, err := pgxpool.ParseConfig("")
	if err != nil {
		return nil, c, err
	}
	pc.ConnConfig = cc
	pc.MaxConns = 3
	pc.MinConns = 0
	pc.MaxConnIdleTime = 5 * time.Minute
	pc.HealthCheckPeriod = time.Minute
	p, err = pgxpool.NewWithConfig(context.WithoutCancel(ctx), pc)
	if err != nil {
		return nil, c, err
	}
	m.mu.Lock()
	if cur := m.pools[key]; cur != nil {
		m.mu.Unlock()
		p.Close()
		return cur, c, nil
	}
	m.pools[key] = p
	m.mu.Unlock()
	return p, c, nil
}

// Acquire runs fn on a pooled connection of the database. A broken
// connection (the SSH connection went away) is retried once on a new one.
func (m *Manager) Acquire(ctx context.Context, connID, db string, fn func(c *pgx.Conn) error) error {
	for attempt := 0; ; attempt++ {
		p, _, err := m.pool(ctx, connID, db)
		if err != nil {
			return err
		}
		pc, err := p.Acquire(ctx)
		if err != nil {
			return Explain(err)
		}
		err = fn(pc.Conn())
		broken := err != nil && pc.Conn().IsClosed()
		pc.Release()
		if broken && attempt == 0 && ctx.Err() == nil {
			continue
		}
		return Explain(err)
	}
}

// Reset closes the pools and consoles of a connection (its settings
// changed, or it was removed); "" = all.
func (m *Manager) Reset(connID string) {
	m.mu.Lock()
	var pools []*pgxpool.Pool
	for k, p := range m.pools {
		if connID == "" || k.conn == connID {
			pools = append(pools, p)
			delete(m.pools, k)
		}
	}
	var cons []*Console
	for id, c := range m.consoles {
		if connID == "" || c.ConnectionID == connID {
			cons = append(cons, c)
			delete(m.consoles, id)
		}
	}
	m.mu.Unlock()
	for _, p := range pools {
		go p.Close()
	}
	for _, c := range cons {
		c.close()
	}
}

// ResetMany closes everything of the given connections.
func (m *Manager) ResetMany(ids []string) {
	for _, id := range ids {
		m.Reset(id)
	}
}

// Close closes everything.
func (m *Manager) Close() { m.Reset("") }

// Test connects once with c (not saved) and returns the server version.
func Test(ctx context.Context, c store.Connection, dial Dial) (string, time.Duration, error) {
	cfg, err := Config(c, "", dial)
	if err != nil {
		return "", 0, err
	}
	start := time.Now()
	conn, err := pgx.ConnectConfig(ctx, cfg)
	if err != nil {
		return "", 0, Explain(err)
	}
	defer conn.Close(context.WithoutCancel(ctx))
	el := time.Since(start)
	return conn.PgConn().ParameterStatus("server_version"), el, nil
}

// Explain turns low-level errors into what the user can act on.
func Explain(err error) error {
	if err == nil {
		return nil
	}
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		switch pe.Code {
		case "28P01", "28000":
			return fmt.Errorf("login refused: %s", pe.Message)
		case "3D000":
			return fmt.Errorf("no such database: %s", pe.Message)
		}
		return err
	}
	msg := err.Error()
	switch {
	case strings.Contains(msg, "connect: connection refused") || strings.Contains(msg, "Connection refused"):
		return fmt.Errorf("nothing answers there (%w)", err)
	case strings.Contains(msg, "administratively prohibited"):
		return fmt.Errorf("the SSH server does not allow forwarding (AllowTcpForwarding): %w", err)
	}
	return err
}

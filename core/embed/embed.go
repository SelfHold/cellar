// Package embed runs the core inside the app's own process: the Flutter app
// on desktops (desktopbind, linked into the executable) and on Android
// (mobilebind). The app talks to it over the gRPC API, through a private
// unix socket (localhost tcp on Windows) and a bearer token.
package embed

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"

	"github.com/SelfHold/cellar/core/keychain"
	"github.com/SelfHold/cellar/core/rpc"
	"github.com/SelfHold/cellar/core/rpc/pb"
	"github.com/SelfHold/cellar/core/shard"
	"github.com/SelfHold/cellar/core/store"
)

// Options say where the core keeps its files and listens.
type Options struct {
	Dir      string // cellar.json, device.json, sync state
	Platform string // runtime.GOOS when empty
	Listen   string // unix:PATH or tcp:HOST:PORT
	// Endpoint, when set, is where address and token are written (readable
	// only by the user). An endpoint there that still answers means another
	// app instance runs the core: Start returns ErrRunning.
	Endpoint string
	LogFile  string
	Log      io.Writer
	// Keychain keeps the local files' key and the Shard token; nil:
	// keychain.System().
	Keychain   keychain.Keychain
	NoKeychain bool
	Shard      shard.Dialer // nil: the desktop daemon
	NoShard    bool
}

// Core is a running core.
type Core struct {
	Service *rpc.Service
	Sync    *shard.Syncer
	Address string
	Token   string

	srv  *grpc.Server
	lis  net.Listener
	opts Options
	logf *os.File
}

// ErrRunning: another process of this user already runs the core.
var ErrRunning = errors.New("Cellar is already running")

// Start opens the files and the socket and serves the API.
func Start(o Options) (*Core, error) {
	if o.Platform == "" {
		o.Platform = runtime.GOOS
	}
	if err := os.MkdirAll(o.Dir, 0o700); err != nil {
		return nil, err
	}
	if o.Endpoint != "" {
		if _, _, ok := ReadEndpoint(o.Endpoint); ok {
			return nil, ErrRunning
		}
	}
	c := &Core{opts: o}
	out := o.Log
	if o.LogFile != "" {
		if f, err := openLog(o.LogFile); err == nil {
			c.logf = f
			if out != nil {
				out = io.MultiWriter(out, f)
			} else {
				out = f
			}
		}
	}
	var logMu sync.Mutex
	logLine := func(level, area, msg string) {
		if out == nil {
			return
		}
		logMu.Lock()
		fmt.Fprintf(out, "%s %-5s %-9s %s\n", time.Now().Format("2006-01-02 15:04:05"), level, area, msg)
		logMu.Unlock()
	}
	kc := o.Keychain
	if kc == nil && !o.NoKeychain {
		kc = keychain.System()
	}
	sealer, err := store.LoadSealer(o.Dir, kc)
	if err != nil {
		c.closeLog()
		return nil, fmt.Errorf("the local key: %w", err)
	}
	st, err := store.Open(o.Dir, sealer)
	if err != nil {
		c.closeLog()
		return nil, err
	}
	lis, err := listenOn(o.Listen)
	if err != nil {
		c.closeLog()
		return nil, err
	}
	svc := rpc.New(st, o.Platform)
	svc.Keychain = sealer.InKeychain
	svc.Log = func(level, msg string) { logLine(level, "core", msg) }
	if !o.NoShard {
		d := o.Shard
		if d == nil {
			d = shard.Desktop{}
		}
		c.Sync = shard.New(shard.Options{
			Dialer: d, Store: st, Seal: sealer, Dir: o.Dir, Keychain: kc,
			AppName:     "Cellar",
			Description: fmt.Sprintf("Cellar %s on %s", rpc.Version, o.Platform),
			Log:         func(level, msg string) { logLine(level, "shard", msg) },
			OnChange:    svc.SyncChanged,
		})
		svc.Sync = c.Sync
	}
	c.Service, c.lis = svc, lis
	c.Token = randomToken()
	c.Address = lis.Addr().String()
	if lis.Addr().Network() == "unix" {
		c.Address = "unix://" + c.Address
	}
	if o.Endpoint != "" {
		if err := writeEndpoint(o.Endpoint, c.Address, c.Token); err != nil {
			lis.Close()
			c.closeLog()
			return nil, err
		}
	}
	c.srv = grpc.NewServer(rpc.TokenAuth(c.Token)...)
	pb.RegisterCellarServer(c.srv, svc)
	go c.srv.Serve(lis)
	if c.Sync != nil {
		c.Sync.Start()
	}
	logLine("info", "core", fmt.Sprintf("started %s (%s), keychain %v", rpc.Version, rpc.Build, sealer.InKeychain))
	return c, nil
}

// Stop closes sessions and connections and stops the server.
func (c *Core) Stop() {
	if c.Sync != nil {
		c.Sync.Close()
	}
	c.Service.Close()
	stopped := make(chan struct{})
	go func() { c.srv.GracefulStop(); close(stopped) }()
	select {
	case <-stopped:
	case <-time.After(3 * time.Second):
		c.srv.Stop()
	}
	if c.opts.Endpoint != "" {
		if addr, _, _ := readEndpointFile(c.opts.Endpoint); addr == c.Address {
			os.Remove(c.opts.Endpoint)
		}
	}
	if strings.HasPrefix(c.opts.Listen, "unix:") {
		os.Remove(strings.TrimPrefix(c.opts.Listen, "unix:"))
	}
	c.closeLog()
}

func (c *Core) closeLog() {
	if c.logf != nil {
		c.logf.Close()
	}
}

func randomToken() string {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b[:])
}

// DefaultDir is <user config dir>/selfhold/cellar (~/.config/selfhold/cellar).
func DefaultDir() string {
	cfg, err := os.UserConfigDir()
	if err != nil {
		cfg = "."
	}
	return filepath.Join(cfg, "selfhold", "cellar")
}

// DefaultListen is $XDG_RUNTIME_DIR/selfhold-cellar.sock, or a localhost port on
// Windows.
func DefaultListen(dir string) string {
	if runtime.GOOS == "windows" {
		return "tcp:127.0.0.1:0"
	}
	d := os.Getenv("XDG_RUNTIME_DIR")
	if d == "" {
		d = dir
	}
	return "unix:" + filepath.Join(d, "selfhold-cellar.sock")
}

// ReadEndpoint reads an endpoint file and says whether the core answers.
func ReadEndpoint(path string) (address, token string, ok bool) {
	address, token, err := readEndpointFile(path)
	if err != nil {
		return "", "", false
	}
	network, addr := "tcp", address
	if strings.HasPrefix(address, "unix://") {
		network, addr = "unix", strings.TrimPrefix(address, "unix://")
	}
	conn, err := net.DialTimeout(network, addr, 2*time.Second)
	if err != nil {
		return address, token, false
	}
	conn.Close()
	return address, token, true
}

func readEndpointFile(path string) (address, token string, err error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", "", err
	}
	var ep struct{ Address, Token string }
	if err := json.Unmarshal(data, &ep); err != nil {
		return "", "", err
	}
	return ep.Address, ep.Token, nil
}

func listenOn(addr string) (net.Listener, error) {
	switch {
	case strings.HasPrefix(addr, "unix:"):
		p := strings.TrimPrefix(addr, "unix:")
		if len(p) > 100 {
			return nil, fmt.Errorf("socket path too long for unix sockets (%d bytes): %s", len(p), p)
		}
		if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
			return nil, err
		}
		if c, err := net.Dial("unix", p); err == nil {
			c.Close()
			return nil, ErrRunning
		}
		os.Remove(p)
		l, err := net.Listen("unix", p)
		if err == nil {
			os.Chmod(p, 0o600)
		}
		return l, err
	case strings.HasPrefix(addr, "tcp:"):
		return net.Listen("tcp", strings.TrimPrefix(addr, "tcp:"))
	}
	return nil, fmt.Errorf("bad listen address %q", addr)
}

func writeEndpoint(path, address, token string) error {
	data, _ := json.MarshalIndent(map[string]string{"address": address, "token": token}, "", "  ")
	return store.WriteAtomic(path, data)
}

// openLog opens the log for appending; a log over 5 MB starts over.
func openLog(path string) (*os.File, error) {
	if fi, err := os.Stat(path); err == nil && fi.Size() > 5<<20 {
		os.Rename(path, path+".1")
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return nil, err
	}
	return os.OpenFile(path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
}

// Package mobilebind runs the core inside the Android app, built with
// "gomobile bind" into an AAR. The Flutter UI talks to it over the same
// gRPC API as on desktops, through a unix socket in the app's private
// files dir (core/embed).
package mobilebind

import (
	"os"
	"sync"

	"github.com/SelfHold/cellar/core/embed"
	"github.com/SelfHold/cellar/core/shard"
)

var (
	mu          sync.Mutex
	core        *embed.Core
	shardBinder ShardBinder
)

// ShardBinder is Shard's bound service (IShardConnector.aidl,
// CONNECTOR.md § 3.2), bound by the Kotlin side. Call returns the
// serialized CallReply; an error means Shard is not installed or the
// binding broke. Calls come from Go's goroutines and may block.
type ShardBinder interface {
	Call(method string, request []byte) ([]byte, error)
	Watch(w ShardWatcher) (int64, error)
	Unwatch(handle int64)
}

// ShardWatcher gets one watch's changes (implemented in Go).
type ShardWatcher interface {
	OnChange(change []byte)
	OnEnd(reply []byte)
}

// SetShard gives the core Shard's binder; call it before Start.
func SetShard(b ShardBinder) {
	mu.Lock()
	defer mu.Unlock()
	shardBinder = b
}

type binder struct{ b ShardBinder }

func (b binder) Call(method string, req []byte) ([]byte, error) { return b.b.Call(method, req) }
func (b binder) Watch(w shard.BinderWatcher) (int64, error)     { return b.b.Watch(w) }
func (b binder) Unwatch(h int64)                                { b.b.Unwatch(h) }

// Start runs the core with its files in dataDir, gRPC on the unix socket
// sock. It returns the bearer token; calling it again returns the same.
func Start(dataDir, cacheDir, sock string) (string, error) {
	mu.Lock()
	defer mu.Unlock()
	if core != nil {
		return core.Token, nil
	}
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		return "", err
	}
	os.Setenv("HOME", dataDir)
	if cacheDir != "" {
		os.MkdirAll(cacheDir, 0o700)
		os.Setenv("TMPDIR", cacheDir)
	}
	os.Remove(sock)
	// No keychain on Android: the local key is a file in the app's
	// private storage, which only this app can read.
	o := embed.Options{Dir: dataDir, Platform: "android", Listen: "unix:" + sock, NoKeychain: true}
	if shardBinder != nil {
		o.Shard = shard.Android{Binder: binder{shardBinder}}
	} else {
		o.NoShard = true
	}
	c, err := embed.Start(o)
	if err != nil {
		return "", err
	}
	core = c
	return c.Token, nil
}

// Stop stops the core.
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	if core != nil {
		core.Stop()
		core = nil
	}
}

// Package mobilebind runs the core inside the Android app, built with
// "gomobile bind" into an AAR. The Flutter UI talks to it over the same
// gRPC API as on desktops, through a unix socket in the app's private
// files dir (core/embed).
package mobilebind

import (
	"os"
	"sync"

	"dbmanager/core/cloudsync"
	"dbmanager/core/embed"
)

var (
	mu        sync.Mutex
	core      *embed.Core
	cloudSync CloudSyncBinder
)

// CloudSyncBinder is CloudSync's bound service (ICloudSyncConnector.aidl,
// CONNECTOR.md § 3.2), bound by the Kotlin side. Call returns the
// serialized CallReply; an error means CloudSync is not installed or the
// binding broke. Calls come from Go's goroutines and may block.
type CloudSyncBinder interface {
	Call(method string, request []byte) ([]byte, error)
	Watch(w CloudSyncWatcher) (int64, error)
	Unwatch(handle int64)
}

// CloudSyncWatcher gets one watch's changes (implemented in Go).
type CloudSyncWatcher interface {
	OnChange(change []byte)
	OnEnd(reply []byte)
}

// SetCloudSync gives the core CloudSync's binder; call it before Start.
func SetCloudSync(b CloudSyncBinder) {
	mu.Lock()
	defer mu.Unlock()
	cloudSync = b
}

type binder struct{ b CloudSyncBinder }

func (b binder) Call(method string, req []byte) ([]byte, error) { return b.b.Call(method, req) }
func (b binder) Watch(w cloudsync.BinderWatcher) (int64, error) { return b.b.Watch(w) }
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
	if cloudSync != nil {
		o.CloudSync = cloudsync.Android{Binder: binder{cloudSync}}
	} else {
		o.NoCloudSync = true
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

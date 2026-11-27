// Command desktopbind is the core of the desktop app, built as a C archive
// linked into the Linux app's executable and called from Dart through FFI
// (app/lib/data/rpc/native_core.dart). The app then talks to it over the
// gRPC API, like the Android app does with mobilebind.
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"time"
	"unsafe"

	"dbmanager/core/embed"
)

var (
	mu   sync.Mutex
	core *embed.Core
)

type reply struct {
	Address  string `json:"address,omitempty"`
	Token    string `json:"token,omitempty"`
	External bool   `json:"external,omitempty"` // another instance runs the core
	Error    string `json:"error,omitempty"`
}

// DbmStart starts the core (again: returns the running one) and returns
// JSON {"address","token"} or {"error"}; free it with DbmFree.
//
//export DbmStart
func DbmStart() *C.char {
	return cjson(start())
}

func start() reply {
	mu.Lock()
	defer mu.Unlock()
	if core != nil {
		return reply{Address: core.Address, Token: core.Token}
	}
	dir := embed.DefaultDir()
	endpoint := filepath.Join(dir, "endpoint.json")
	c, err := embed.Start(embed.Options{
		Dir:      dir,
		Listen:   embed.DefaultListen(dir),
		Endpoint: endpoint,
		LogFile:  filepath.Join(dir, "dbmanager.log"),
		Log:      os.Stderr,
		// Development: keep the local key in a file, leave CloudSync alone.
		NoKeychain:  os.Getenv("DBM_NO_KEYCHAIN") == "1",
		NoCloudSync: os.Getenv("DBM_NO_CLOUDSYNC") == "1",
	})
	if errors.Is(err, embed.ErrRunning) {
		if addr, token, ok := embed.ReadEndpoint(endpoint); ok {
			return reply{Address: addr, Token: token, External: true}
		}
	}
	if err != nil {
		return reply{Error: err.Error()}
	}
	core = c
	return reply{Address: c.Address, Token: c.Token}
}

// DbmStop closes sessions and stops the server, waiting at most 5 s (it
// runs on the UI thread right before the process exits).
//
//export DbmStop
func DbmStop() {
	mu.Lock()
	defer mu.Unlock()
	if core == nil {
		return
	}
	c := core
	core = nil
	done := make(chan struct{})
	go func() { c.Stop(); close(done) }()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
	}
}

// DbmFree frees a string returned by DbmStart.
//
//export DbmFree
func DbmFree(p *C.char) {
	C.free(unsafe.Pointer(p))
}

func cjson(r reply) *C.char {
	b, _ := json.Marshal(r)
	return C.CString(string(b))
}

func main() {}

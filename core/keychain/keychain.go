// Package keychain keeps small secrets in the operating system's store for
// the user's secrets: the Secret Service (GNOME Keyring, KWallet) on Linux,
// the Credential Manager on Windows, the Keychain on macOS. The store is
// unlocked with the user's login, so a secret kept there opens without
// asking ("remember the password on this machine").
package keychain

import (
	"errors"
	"sync"
)

// ErrNotFound: nothing is kept under this name.
var ErrNotFound = errors.New("keychain: not found")

// Keychain keeps secrets by name.
type Keychain interface {
	Get(name string) ([]byte, error)
	Set(name string, secret []byte) error
	// Delete is not an error when nothing is kept under name.
	Delete(name string) error
}

// Memory is a Keychain in memory, for tests.
type Memory struct {
	mu sync.Mutex
	m  map[string][]byte
}

func NewMemory() *Memory { return &Memory{m: map[string][]byte{}} }

func (k *Memory) Get(name string) ([]byte, error) {
	k.mu.Lock()
	defer k.mu.Unlock()
	v, ok := k.m[name]
	if !ok {
		return nil, ErrNotFound
	}
	return append([]byte{}, v...), nil
}

func (k *Memory) Set(name string, secret []byte) error {
	k.mu.Lock()
	defer k.mu.Unlock()
	k.m[name] = append([]byte{}, secret...)
	return nil
}

func (k *Memory) Delete(name string) error {
	k.mu.Lock()
	defer k.mu.Unlock()
	delete(k.m, name)
	return nil
}

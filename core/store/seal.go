package store

import (
	"bytes"
	"crypto/rand"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"golang.org/x/crypto/chacha20poly1305"

	"dbmanager/core/keychain"
)

// The local files hold passwords, so nothing is readable on disk: each is
// XChaCha20-Poly1305 with a random 32-byte key kept in the OS keychain
// (Secret Service, Credential Manager, Keychain). Without a keychain
// (Android, a Linux without Secret Service) the key is a file readable only
// by the user (local.key; on Android inside the app's private storage).

var magic = []byte("DBMSEAL1")

const keychainName = "local-key"

// Sealer seals and opens the local files.
type Sealer struct {
	key [32]byte
	// InKeychain: the key lives in the OS keychain.
	InKeychain bool
}

// LoadSealer finds the key (keychain first, then dir/local.key) or makes
// one. A key file is moved into a keychain that appears later.
func LoadSealer(dir string, kc keychain.Keychain) (*Sealer, error) {
	s := &Sealer{}
	keyFile := filepath.Join(dir, "local.key")
	if kc != nil {
		if k, err := kc.Get(keychainName); err == nil && len(k) == 32 {
			copy(s.key[:], k)
			s.InKeychain = true
			return s, nil
		}
	}
	k, err := os.ReadFile(keyFile)
	switch {
	case err == nil && len(k) == 32:
		copy(s.key[:], k)
	case err == nil:
		return nil, fmt.Errorf("store: %s is damaged", keyFile)
	case errors.Is(err, os.ErrNotExist):
		if _, err := rand.Read(s.key[:]); err != nil {
			return nil, err
		}
		k = s.key[:]
	default:
		return nil, err
	}
	if kc != nil && kc.Set(keychainName, s.key[:]) == nil {
		// Keep the file until the keychain answers with the key: a
		// keychain that accepts and forgets would lose the data.
		if got, err := kc.Get(keychainName); err == nil && bytes.Equal(got, s.key[:]) {
			os.Remove(keyFile)
			s.InKeychain = true
			return s, nil
		}
	}
	if err := writeAtomic(keyFile, k); err != nil {
		return nil, err
	}
	return s, nil
}

// Seal encrypts data; name (the file's base name) is the AD, so files
// cannot be swapped.
func (s *Sealer) Seal(name string, data []byte) []byte {
	aead, _ := chacha20poly1305.NewX(s.key[:])
	nonce := make([]byte, aead.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		panic(err)
	}
	out := append(append(slicesClone(magic), nonce...), aead.Seal(nil, nonce, data, []byte(name))...)
	return out
}

// Open decrypts what Seal made. Plain JSON (a file written by hand, or a
// test) is accepted as is.
func (s *Sealer) Open(name string, data []byte) ([]byte, error) {
	if !bytes.HasPrefix(data, magic) {
		t := bytes.TrimSpace(data)
		if len(t) == 0 || t[0] == '{' {
			return data, nil
		}
		return nil, fmt.Errorf("store: %s is not a DB Manager file", name)
	}
	aead, _ := chacha20poly1305.NewX(s.key[:])
	rest := data[len(magic):]
	if len(rest) < aead.NonceSize() {
		return nil, fmt.Errorf("store: %s is truncated", name)
	}
	plain, err := aead.Open(nil, rest[:aead.NonceSize()], rest[aead.NonceSize():], []byte(name))
	if err != nil {
		return nil, fmt.Errorf("store: %s does not open with this device's key", name)
	}
	return plain, nil
}

func slicesClone(b []byte) []byte { return append([]byte{}, b...) }

// writeAtomic writes data to path through a temp file and a rename.
func writeAtomic(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if err := tmp.Chmod(0o600); err != nil {
		tmp.Close()
		return err
	}
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), path)
}

// WriteAtomic is writeAtomic for other packages (sync state).
func WriteAtomic(path string, data []byte) error { return writeAtomic(path, data) }

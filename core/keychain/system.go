//go:build !android && (linux || windows || darwin)

package keychain

import (
	"encoding/base64"
	"errors"

	"github.com/zalando/go-keyring"
)

const service = "dev.selfhold.cellar"

// System returns the operating system's keychain.
func System() Keychain { return system{} }

type system struct{}

func (system) Get(name string) ([]byte, error) {
	s, err := keyring.Get(service, name)
	if errors.Is(err, keyring.ErrNotFound) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return base64.StdEncoding.DecodeString(s)
}

func (system) Set(name string, secret []byte) error {
	return keyring.Set(service, name, base64.StdEncoding.EncodeToString(secret))
}

func (system) Delete(name string) error {
	if err := keyring.Delete(service, name); err != nil && !errors.Is(err, keyring.ErrNotFound) {
		return err
	}
	return nil
}

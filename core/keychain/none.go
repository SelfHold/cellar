//go:build android || !(linux || windows || darwin)

package keychain

// System returns nil: no keychain here (on Android the core keeps its key
// file in the app's private storage).
func System() Keychain { return nil }

package rpc

import "golang.org/x/crypto/ssh"

// sshClient is an open SSH client of the pool.
type sshClient struct{ *ssh.Client }

// sshParse parses an authorized_keys line.
func sshParse(line string) (ssh.PublicKey, string, []string, []byte, error) {
	return ssh.ParseAuthorizedKey([]byte(line))
}

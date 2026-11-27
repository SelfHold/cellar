package pg

import (
	"crypto/hmac"
	"crypto/md5"
	"crypto/pbkdf2"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"strconv"
	"strings"
	"unicode"

	"golang.org/x/text/unicode/norm"
)

// scramIterations is PostgreSQL's default (scram_iterations).
const scramIterations = 4096

// ScramVerifier hashes a password the way PostgreSQL stores it with
// password_encryption = scram-sha-256, so the clear password never
// reaches the server (nor its statement log).
func ScramVerifier(password string) (string, error) {
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	return scramVerifier(password, salt, scramIterations)
}

func scramVerifier(password string, salt []byte, iter int) (string, error) {
	salted, err := pbkdf2.Key(sha256.New, saslPrep(password), salt, iter, sha256.Size)
	if err != nil {
		return "", err
	}
	clientKey := hmacSHA256(salted, "Client Key")
	stored := sha256.Sum256(clientKey)
	serverKey := hmacSHA256(salted, "Server Key")
	b64 := base64.StdEncoding.EncodeToString
	return "SCRAM-SHA-256$" + strconv.Itoa(iter) + ":" + b64(salt) + "$" + b64(stored[:]) + ":" + b64(serverKey), nil
}

// MD5Verifier is the md5 form (password_encryption = md5): "md5" +
// md5(password + user name).
func MD5Verifier(password, user string) string {
	sum := md5.Sum([]byte(password + user))
	return "md5" + hex.EncodeToString(sum[:])
}

func hmacSHA256(key []byte, msg string) []byte {
	h := hmac.New(sha256.New, key)
	h.Write([]byte(msg))
	return h.Sum(nil)
}

// saslPrep normalizes a password as PostgreSQL does before hashing it
// (RFC 4013: non-ASCII spaces become spaces, "mapped to nothing"
// characters go, then NFKC). ASCII passwords are left as they are; a
// password with prohibited characters is used raw, as the server does.
func saslPrep(s string) string {
	ascii := true
	for i := 0; i < len(s); i++ {
		if s[i] >= 0x80 {
			ascii = false
			break
		}
	}
	if ascii {
		return s
	}
	var b strings.Builder
	for _, r := range s {
		switch {
		case r == 0x00AD || r == 0x034F || r == 0x1806 || r >= 0x180B && r <= 0x180D || r >= 0x200B && r <= 0x200D ||
			r == 0x2060 || r >= 0xFE00 && r <= 0xFE0F || r == 0xFEFF:
			// mapped to nothing
		case r != ' ' && unicode.Is(unicode.Zs, r):
			b.WriteRune(' ')
		default:
			b.WriteRune(r)
		}
	}
	out := norm.NFKC.String(b.String())
	for _, r := range out {
		if unicode.IsControl(r) || unicode.Is(unicode.Co, r) || r >= 0xFDD0 && r <= 0xFDEF || r&0xFFFE == 0xFFFE || unicode.Is(unicode.Cs, r) {
			return s
		}
	}
	return out
}

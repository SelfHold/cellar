package pg

import (
	"strings"
	"unicode/utf16"
	"unicode/utf8"
)

// Stmt is one statement of a script: byte offsets into the text and the
// same in UTF-16 code units (what the app's editor counts).
type Stmt struct {
	Text           string
	Start, End     int // bytes, End exclusive, trimmed
	Start16, End16 int
}

// Split cuts SQL into statements at semicolons outside of strings,
// quoted identifiers, dollar quotes and comments. Empty statements (only
// whitespace or comments) are left out.
func Split(sql string) []Stmt {
	var out []Stmt
	start := 0
	emit := func(end int) {
		seg := sql[start:end]
		if !onlyComments(seg) {
			lt := len(seg) - len(strings.TrimLeft(seg, " \t\r\n"))
			rt := len(strings.TrimRight(seg, " \t\r\n"))
			out = append(out, Stmt{Text: seg[lt:rt], Start: start + lt, End: start + rt})
		}
	}
	i := 0
	n := len(sql)
	for i < n {
		c := sql[i]
		switch {
		case c == '\'':
			// E'' strings use backslash escapes.
			esc := i > 0 && (sql[i-1] == 'E' || sql[i-1] == 'e') && (i < 2 || !isIdent(sql[i-2]))
			i++
			for i < n {
				if esc && sql[i] == '\\' {
					i += 2
					continue
				}
				if sql[i] == '\'' {
					if i+1 < n && sql[i+1] == '\'' {
						i += 2
						continue
					}
					break
				}
				i++
			}
			i++
		case c == '"':
			i++
			for i < n {
				if sql[i] == '"' {
					if i+1 < n && sql[i+1] == '"' {
						i += 2
						continue
					}
					break
				}
				i++
			}
			i++
		case c == '-' && i+1 < n && sql[i+1] == '-':
			for i < n && sql[i] != '\n' {
				i++
			}
		case c == '/' && i+1 < n && sql[i+1] == '*':
			// Block comments nest in PostgreSQL.
			depth := 1
			i += 2
			for i < n && depth > 0 {
				switch {
				case sql[i] == '/' && i+1 < n && sql[i+1] == '*':
					depth++
					i += 2
				case sql[i] == '*' && i+1 < n && sql[i+1] == '/':
					depth--
					i += 2
				default:
					i++
				}
			}
		case c == '$' && (i == 0 || !isIdent(sql[i-1])):
			tag, ok := dollarTag(sql[i:])
			if !ok {
				i++
				continue
			}
			j := strings.Index(sql[i+len(tag):], tag)
			if j < 0 {
				i = n
			} else {
				i += len(tag) + j + len(tag)
			}
		case c == ';':
			emit(i)
			start = i + 1
			i++
		default:
			i++
		}
	}
	if start < n {
		emit(n)
	}
	// UTF-16 offsets in one pass.
	pos16, b := 0, 0
	k := 0
	marks := make([]*int, 0, len(out)*2)
	idx := make([]int, 0, len(out)*2)
	for j := range out {
		marks = append(marks, &out[j].Start16, &out[j].End16)
		idx = append(idx, out[j].Start, out[j].End)
	}
	for k < len(idx) {
		for b < idx[k] && b < n {
			r, size := utf8.DecodeRuneInString(sql[b:])
			b += size
			pos16 += utf16.RuneLen(r)
		}
		*marks[k] = pos16
		k++
	}
	for j := range out {
		out[j].Text = sql[out[j].Start:out[j].End]
	}
	return out
}

// At returns the statement at the UTF-16 offset cursor: the one it is
// inside, else the nearest one before it on the same stretch (a cursor
// right after "select 1;" or on the blank line below runs it), else the
// next one.
func At(stmts []Stmt, cursor int) (Stmt, bool) {
	if len(stmts) == 0 {
		return Stmt{}, false
	}
	for _, s := range stmts {
		if cursor >= s.Start16 && cursor <= s.End16 {
			return s, true
		}
	}
	var before *Stmt
	for i := range stmts {
		if stmts[i].End16 < cursor {
			before = &stmts[i]
		}
	}
	if before != nil {
		return *before, true
	}
	return stmts[0], true
}

// ByteToUTF16 converts a byte offset of s to UTF-16 units.
func ByteToUTF16(s string, off int) int {
	if off > len(s) {
		off = len(s)
	}
	n := 0
	for _, r := range s[:off] {
		n += utf16.RuneLen(r)
	}
	return n
}

func dollarTag(s string) (string, bool) {
	// $$ or $tag$ where tag is an identifier not starting with a digit.
	if len(s) < 2 {
		return "", false
	}
	if s[1] == '$' {
		return "$$", true
	}
	if s[1] >= '0' && s[1] <= '9' {
		return "", false // $1 parameter
	}
	for j := 1; j < len(s); j++ {
		if s[j] == '$' {
			return s[:j+1], true
		}
		if !isIdent(s[j]) {
			return "", false
		}
	}
	return "", false
}

func isIdent(c byte) bool {
	return c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c >= 0x80
}

// onlyComments reports whether s has nothing but blanks and comments.
func onlyComments(s string) bool {
	i := 0
	for i < len(s) {
		switch c := s[i]; {
		case c == ' ' || c == '\t' || c == '\r' || c == '\n':
			i++
		case c == '-' && i+1 < len(s) && s[i+1] == '-':
			for i < len(s) && s[i] != '\n' {
				i++
			}
		case c == '/' && i+1 < len(s) && s[i+1] == '*':
			j := strings.Index(s[i+2:], "*/")
			if j < 0 {
				return true
			}
			i += 2 + j + 2
		default:
			return false
		}
	}
	return true
}

// Package dump runs PostgreSQL's own tools (pg_dump, pg_restore, psql)
// for a connection: on this device, tunnelled to the database through the
// server's SSH connection, or on the server itself over SSH. The file
// always lives on this device; its bytes stream through stdin / stdout.
package dump

import (
	"bufio"
	"bytes"
	"context"
	"crypto/tls"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/ssh"

	"github.com/SelfHold/cellar/core/pg"
	"github.com/SelfHold/cellar/core/store"
)

// Place is where a tool runs.
type Place int

const (
	Auto Place = iota
	Local
	Remote
)

func (p Place) String() string {
	if p == Remote {
		return "on the server"
	}
	return "on this device"
}

// Tool is one pg_dump found; pg_restore and psql are next to it.
type Tool struct {
	Place   Place
	Path    string
	Version string
	Major   int
}

func (t Tool) sibling(name string) string {
	if t.Place == Remote {
		return path.Join(path.Dir(t.Path), name)
	}
	return filepath.Join(filepath.Dir(t.Path), name)
}

var versionRe = regexp.MustCompile(`\(PostgreSQL\)\s+(\d+)(?:\.(\d+))?`)

func parseVersion(out string) (string, int) {
	m := versionRe.FindStringSubmatch(out)
	if m == nil {
		return "", 0
	}
	major, _ := strconv.Atoi(m[1])
	v := m[1]
	if m[2] != "" {
		v += "." + m[2]
	}
	return v, major
}

// localCandidates are where distributions put pg_dump, newest first
// once sorted by version.
var localCandidates = []string{
	"/usr/lib/postgresql/*/bin/pg_dump", // Debian, Ubuntu
	"/usr/pgsql-*/bin/pg_dump",          // PGDG RPMs
	"/usr/local/pgsql/bin/pg_dump",      // source builds
	"/opt/homebrew/opt/postgresql@*/bin/pg_dump",
	"/usr/local/opt/postgresql@*/bin/pg_dump",
	"/Applications/Postgres.app/Contents/Versions/*/bin/pg_dump",
}

// LocalTools finds pg_dump on this device ($CELLAR_PG_BIN first, then
// PATH and the usual install places), newest first.
func LocalTools(ctx context.Context) []Tool {
	var paths []string
	if d := os.Getenv("CELLAR_PG_BIN"); d != "" {
		paths = append(paths, filepath.Join(d, "pg_dump"))
	}
	if p, err := exec.LookPath("pg_dump"); err == nil {
		paths = append(paths, p)
	}
	for _, g := range localCandidates {
		m, _ := filepath.Glob(g)
		paths = append(paths, m...)
	}
	var out []Tool
	seen := map[string]bool{}
	for _, p := range paths {
		real, err := filepath.EvalSymlinks(p)
		if err != nil || seen[real] {
			continue
		}
		seen[real] = true
		cctx, cancel := context.WithTimeout(ctx, 5*time.Second)
		b, err := exec.CommandContext(cctx, p, "--version").Output()
		cancel()
		if err != nil {
			continue
		}
		if v, major := parseVersion(string(b)); major > 0 {
			out = append(out, Tool{Place: Local, Path: p, Version: v, Major: major})
		}
	}
	sortTools(out)
	return out
}

// remoteScript lists pg_dump binaries on the server: "path<TAB>version".
const remoteScript = `for p in "$(command -v pg_dump 2>/dev/null)" /usr/lib/postgresql/*/bin/pg_dump /usr/pgsql-*/bin/pg_dump /usr/local/pgsql/bin/pg_dump /usr/local/bin/pg_dump /usr/bin/pg_dump; do
  [ -n "$p" ] && [ -x "$p" ] && printf '%s\t%s\n' "$p" "$("$p" --version 2>/dev/null)"
done; true`

// RemoteTools finds pg_dump on the server.
func RemoteTools(ctx context.Context, c *ssh.Client) ([]Tool, error) {
	cctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	out, _, err := runSSH(cctx, c, remoteScript)
	if err != nil {
		return nil, err
	}
	var tools []Tool
	seen := map[string]bool{}
	for _, l := range strings.Split(out, "\n") {
		p, ver, ok := strings.Cut(l, "\t")
		if !ok || seen[p] {
			continue
		}
		seen[p] = true
		if v, major := parseVersion(ver); major > 0 {
			// The same binary under two paths (a symlink): keep one per version.
			if slices.ContainsFunc(tools, func(t Tool) bool { return t.Version == v }) {
				continue
			}
			tools = append(tools, Tool{Place: Remote, Path: p, Version: v, Major: major})
		}
	}
	sortTools(tools)
	return tools, nil
}

func runSSH(ctx context.Context, c *ssh.Client, cmd string) (string, string, error) {
	s, err := c.NewSession()
	if err != nil {
		return "", "", err
	}
	defer s.Close()
	var o, e bytes.Buffer
	s.Stdout, s.Stderr = &o, &e
	done := make(chan error, 1)
	go func() { done <- s.Run(cmd) }()
	select {
	case err = <-done:
	case <-ctx.Done():
		s.Close()
		return "", "", ctx.Err()
	}
	return o.String(), e.String(), err
}

func sortTools(ts []Tool) {
	slices.SortStableFunc(ts, func(a, b Tool) int {
		if a.Major != b.Major {
			return b.Major - a.Major
		}
		return strings.Compare(b.Version, a.Version)
	})
}

// Choose picks the tool to run: the place asked for, else this device
// when its pg_dump is not older than the server, else the server's.
// dumping: pg_dump refuses servers newer than itself.
func Choose(tools []Tool, place Place, serverMajor int, dumping bool) (Tool, error) {
	fits := func(t Tool) bool { return !dumping || serverMajor == 0 || t.Major >= serverMajor }
	order := []Place{Local, Remote}
	if place != Auto {
		order = []Place{place}
	}
	for _, p := range order {
		for _, t := range tools {
			if t.Place == p && fits(t) {
				return t, nil
			}
		}
	}
	if len(tools) == 0 {
		return Tool{}, errors.New("no PostgreSQL client tools found: install them on this device (postgresql-client) or on the server")
	}
	var found []string
	for _, t := range tools {
		if place == Auto || t.Place == place {
			found = append(found, fmt.Sprintf("%s %s", t.Version, t.Place))
		}
	}
	if len(found) == 0 {
		return Tool{}, fmt.Errorf("no PostgreSQL client tools %s", place)
	}
	return Tool{}, fmt.Errorf("the server runs PostgreSQL %d, but pg_dump is older (%s): install a newer postgresql-client", serverMajor, strings.Join(found, ", "))
}

// Target is the database a tool works on.
type Target struct {
	Conn     store.Connection
	Database string
	// Dial reaches the database from where Conn.Host is resolved (the
	// server); nil for direct connections.
	Dial pg.Dial
	// SSH is the server's client, for tools running there.
	SSH *ssh.Client
}

func (t Target) database() string {
	return cmp(t.Database, t.Conn.Database, "postgres")
}

func cmp(s ...string) string {
	for _, x := range s {
		if x != "" {
			return x
		}
	}
	return ""
}

// Progress is shared between a running job and whoever reports it.
type Progress struct {
	mu    sync.Mutex
	bytes int64
	total int64
	log   []string
	tail  []string // the last lines, for the error
}

// Take returns the bytes so far, the total and the lines since the last
// call.
func (p *Progress) Take() (int64, int64, []string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	l := p.log
	p.log = nil
	return p.bytes, p.total, l
}

func (p *Progress) add(n int) {
	p.mu.Lock()
	p.bytes += int64(n)
	p.mu.Unlock()
}

func (p *Progress) line(s string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if len(p.log) < 5000 {
		p.log = append(p.log, s)
	}
	p.tail = append(p.tail, s)
	if len(p.tail) > 8 {
		p.tail = p.tail[1:]
	}
}

func (p *Progress) failure(err error) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	for i := len(p.tail) - 1; i >= 0; i-- {
		l := p.tail[i]
		if low := strings.ToLower(l); strings.Contains(low, "error") || strings.Contains(low, "fatal") {
			return fmt.Errorf("%s (%w)", strings.TrimSpace(l), err)
		}
	}
	return err
}

// job is one tool run.
type job struct {
	tool  Tool
	bin   string
	args  []string
	in    io.Reader
	out   io.Writer
	t     Target
	prog  *Progress
	quiet bool // stdout is not data: discard it
}

// env are the libpq variables for the run (the password separately).
func (j *job) env(host string, port int, sslmode string) []string {
	return []string{
		"PGHOST=" + host,
		"PGPORT=" + strconv.Itoa(port),
		"PGUSER=" + j.t.Conn.User,
		"PGDATABASE=" + j.t.database(),
		"PGSSLMODE=" + sslmode,
		"PGAPPNAME=" + pg.AppName,
		"PGCONNECT_TIMEOUT=15",
	}
}

func (j *job) run(ctx context.Context) error {
	if j.tool.Place == Remote {
		return j.runRemote(ctx)
	}
	return j.runLocal(ctx)
}

func (j *job) runLocal(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	c := j.t.Conn
	ssl := cmp(c.SSLMode, "prefer")
	host, port := c.Host, c.PGPort()
	if c.ServerID != "" {
		// Through SSH: a unix socket in a private directory forwards to
		// the database, so no other user of this device can use it.
		dir, err := os.MkdirTemp("", "cellar-pg-")
		if err != nil {
			return err
		}
		defer os.RemoveAll(dir)
		l, err := net.Listen("unix", filepath.Join(dir, ".s.PGSQL.5432"))
		if err != nil {
			return err
		}
		defer l.Close()
		go forward(ctx, l, j.t.Dial, net.JoinHostPort(c.Host, strconv.Itoa(c.PGPort())), ssl == "require")
		host, port, ssl = dir, 5432, "disable"
	}
	cmd := exec.CommandContext(ctx, j.bin, j.args...)
	var env []string
	for _, e := range os.Environ() {
		if !strings.HasPrefix(e, "PG") {
			env = append(env, e)
		}
	}
	cmd.Env = append(append(env, j.env(host, port, ssl)...), "PGPASSWORD="+c.Password)
	cmd.Stdin = j.in
	if j.quiet {
		cmd.Stdout = io.Discard
	} else {
		cmd.Stdout = j.out
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}
	if err := cmd.Start(); err != nil {
		return err
	}
	<-j.lines(stderr) // all of stderr before Wait closes the pipe
	err = cmd.Wait()
	if ctx.Err() != nil {
		return ctx.Err()
	}
	if err != nil {
		return j.prog.failure(fmt.Errorf("%s: %w", path.Base(j.bin), err))
	}
	return nil
}

func (j *job) lines(r io.Reader) chan struct{} {
	done := make(chan struct{})
	go func() {
		defer close(done)
		sc := bufio.NewScanner(r)
		sc.Buffer(make([]byte, 64<<10), 1<<20)
		for sc.Scan() {
			j.prog.line(sc.Text())
		}
	}()
	return done
}

// shellQuote quotes for a POSIX shell.
func shellQuote(s string) string { return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'" }

func (j *job) runRemote(ctx context.Context) error {
	if j.t.SSH == nil {
		return errors.New("this connection has no server to run the tools on")
	}
	c := j.t.Conn
	s, err := j.t.SSH.NewSession()
	if err != nil {
		return err
	}
	defer s.Close()
	// The password comes as the first line of stdin and lives only in the
	// tool's environment: not in the command line, not on disk.
	var cmd strings.Builder
	cmd.WriteString("IFS= read -r PGPASSWORD || exit 97; export PGPASSWORD; exec env")
	for _, e := range j.env(c.Host, c.PGPort(), cmp(c.SSLMode, "prefer")) {
		cmd.WriteString(" " + shellQuote(e))
	}
	cmd.WriteString(" " + shellQuote(j.bin))
	for _, a := range j.args {
		cmd.WriteString(" " + shellQuote(a))
	}
	pw := strings.NewReader(c.Password + "\n")
	if j.in != nil {
		s.Stdin = io.MultiReader(pw, j.in)
	} else {
		s.Stdin = pw
	}
	if j.quiet {
		s.Stdout = io.Discard
	} else {
		s.Stdout = j.out
	}
	stderr, err := s.StderrPipe()
	if err != nil {
		return err
	}
	if err := s.Start(cmd.String()); err != nil {
		return err
	}
	lines := j.lines(stderr)
	done := make(chan error, 1)
	go func() { done <- s.Wait() }()
	select {
	case err = <-done:
	case <-ctx.Done():
		s.Signal(ssh.SIGTERM)
		s.Close()
		<-lines
		return ctx.Err()
	}
	<-lines
	var exit *ssh.ExitError
	if errors.As(err, &exit) && exit.ExitStatus() == 127 {
		return fmt.Errorf("%s is not on the server", path.Base(j.bin))
	}
	if err != nil {
		return j.prog.failure(fmt.Errorf("%s on the server: %w", path.Base(j.bin), err))
	}
	return nil
}

// forward accepts the tool's connections and carries them to addr
// through dial; tls: the database wants TLS, which the tool cannot ask
// for over a unix socket, so it is set up here (sslmode=require: no
// certificate check).
func forward(ctx context.Context, l net.Listener, dial pg.Dial, addr string, useTLS bool) {
	go func() {
		<-ctx.Done()
		l.Close()
	}()
	for {
		in, err := l.Accept()
		if err != nil {
			return
		}
		go func() {
			defer in.Close()
			up, err := dial(ctx, addr)
			if err != nil {
				return
			}
			defer up.Close()
			if useTLS {
				if up, err = startTLS(up); err != nil {
					return
				}
			}
			go func() {
				io.Copy(up, in)
				if cw, ok := up.(interface{ CloseWrite() error }); ok {
					cw.CloseWrite()
				}
			}()
			io.Copy(in, up)
		}()
	}
}

func startTLS(c net.Conn) (net.Conn, error) {
	req := make([]byte, 8)
	binary.BigEndian.PutUint32(req[0:], 8)
	binary.BigEndian.PutUint32(req[4:], 80877103)
	if _, err := c.Write(req); err != nil {
		return nil, err
	}
	b := make([]byte, 1)
	if _, err := io.ReadFull(c, b); err != nil {
		return nil, err
	}
	if b[0] != 'S' {
		return nil, errors.New("the server does not offer TLS")
	}
	t := tls.Client(c, &tls.Config{InsecureSkipVerify: true}) //nolint:gosec // sslmode=require checks no certificate either
	return t, t.Handshake()
}

// --- dump -------------------------------------------------------------------

// Format of a dump file.
type Format int

const (
	Plain Format = iota
	Custom
	Tar
)

func (f Format) String() string {
	return [...]string{"plain", "custom", "tar"}[f]
}

// Table names one table.
type Table struct{ Schema, Name string }

// DumpOptions are pg_dump's.
type DumpOptions struct {
	Format                 Format
	Schemas                []string
	Tables                 []Table
	SchemaOnly, DataOnly   bool
	NoOwner, NoPrivileges  bool
	Clean, Create, Inserts bool
}

// pattern quotes a name for pg_dump's -n / -t: double quotes make it
// exact (no wildcards, case kept).
func pattern(s string) string { return `"` + strings.ReplaceAll(s, `"`, `""`) + `"` }

// DumpArgs are pg_dump's arguments for o.
func DumpArgs(o DumpOptions) []string {
	args := []string{"--verbose", "--format=" + [...]string{"p", "c", "t"}[o.Format]}
	for _, s := range o.Schemas {
		args = append(args, "--schema="+pattern(s))
	}
	for _, t := range o.Tables {
		args = append(args, "--table="+pattern(t.Schema)+"."+pattern(t.Name))
	}
	flags := []struct {
		on   bool
		args []string
	}{
		{o.SchemaOnly, []string{"--schema-only"}},
		{o.DataOnly, []string{"--data-only"}},
		{o.NoOwner, []string{"--no-owner"}},
		{o.NoPrivileges, []string{"--no-privileges"}},
		{o.Clean, []string{"--clean", "--if-exists"}},
		{o.Create, []string{"--create"}},
		{o.Inserts, []string{"--inserts"}},
	}
	for _, f := range flags {
		if f.on {
			args = append(args, f.args...)
		}
	}
	return args
}

// Dump writes the target to file (a sibling ".part" file until it is
// complete; nothing is left behind when it fails).
func Dump(ctx context.Context, tool Tool, t Target, o DumpOptions, file string, prog *Progress) error {
	part := file + ".part"
	f, err := os.OpenFile(part, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	ok := false
	defer func() {
		if !ok {
			f.Close()
			os.Remove(part)
		}
	}()
	w := &countWriter{w: bufio.NewWriterSize(f, 1<<20), prog: prog}
	j := &job{tool: tool, bin: tool.Path, args: DumpArgs(o), out: w, t: t, prog: prog}
	if err := j.run(ctx); err != nil {
		return err
	}
	if err := w.w.(*bufio.Writer).Flush(); err != nil {
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	if err := os.Rename(part, file); err != nil {
		return err
	}
	ok = true
	return nil
}

type countWriter struct {
	w    io.Writer
	prog *Progress
}

func (c *countWriter) Write(p []byte) (int, error) {
	n, err := c.w.Write(p)
	c.prog.add(n)
	return n, err
}

// --- restore ------------------------------------------------------------------

// RestoreOptions are pg_restore's (psql takes only SingleTransaction and
// ExitOnError).
type RestoreOptions struct {
	Clean, NoOwner, NoPrivileges, SingleTransaction bool
	SchemaOnly, DataOnly, Create, ExitOnError       bool
}

// Detect tells a dump file's format from its first bytes.
func Detect(head []byte) Format {
	switch {
	case bytes.HasPrefix(head, []byte("PGDMP")):
		return Custom
	case len(head) >= 262 && string(head[257:262]) == "ustar":
		return Tar
	}
	return Plain
}

// conninfo quotes a value for a libpq connection string.
func conninfo(k, v string) string {
	return k + "='" + strings.ReplaceAll(strings.ReplaceAll(v, `\`, `\\`), `'`, `\'`) + "'"
}

// RestoreArgs are the tool (pg_restore or psql) and its arguments.
func RestoreArgs(f Format, o RestoreOptions, db string) (string, []string) {
	if f == Plain {
		args := []string{"--no-psqlrc", "--quiet", "--dbname=" + conninfo("dbname", db)}
		if o.ExitOnError {
			args = append(args, "--set=ON_ERROR_STOP=1")
		}
		if o.SingleTransaction {
			args = append(args, "--single-transaction")
		}
		return "psql", append(args, "--file=-")
	}
	args := []string{"--verbose", "--format=" + map[Format]string{Custom: "c", Tar: "t"}[f], "--dbname=" + conninfo("dbname", db)}
	flags := []struct {
		on   bool
		args []string
	}{
		{o.Clean, []string{"--clean", "--if-exists"}},
		{o.NoOwner, []string{"--no-owner"}},
		{o.NoPrivileges, []string{"--no-privileges"}},
		{o.SingleTransaction, []string{"--single-transaction"}},
		{o.SchemaOnly, []string{"--schema-only"}},
		{o.DataOnly, []string{"--data-only"}},
		{o.Create, []string{"--create"}},
		{o.ExitOnError, []string{"--exit-on-error"}},
	}
	for _, x := range flags {
		if x.on {
			args = append(args, x.args...)
		}
	}
	return "pg_restore", args
}

// Restore loads file into the target.
func Restore(ctx context.Context, tool Tool, t Target, o RestoreOptions, file string, prog *Progress) (Format, error) {
	f, err := os.Open(file)
	if err != nil {
		return Plain, err
	}
	defer f.Close()
	st, err := f.Stat()
	if err != nil {
		return Plain, err
	}
	prog.mu.Lock()
	prog.total = st.Size()
	prog.mu.Unlock()
	br := bufio.NewReaderSize(f, 1<<20)
	head, _ := br.Peek(512)
	format := Detect(head)
	name, args := RestoreArgs(format, o, t.database())
	j := &job{tool: tool, bin: tool.sibling(name), args: args, in: &countReader{r: br, prog: prog}, t: t, prog: prog, quiet: true}
	return format, j.run(ctx)
}

type countReader struct {
	r    io.Reader
	prog *Progress
}

func (c *countReader) Read(p []byte) (int, error) {
	n, err := c.r.Read(p)
	c.prog.add(n)
	return n, err
}

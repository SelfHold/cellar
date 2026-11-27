// Package discover finds database services running on a server: it runs
// one read-only shell script over SSH (listening sockets, PostgreSQL
// clusters and processes, docker containers), turns the output into
// candidates and checks every candidate port through the SSH connection
// (a PostgreSQL server answers an SSLRequest with 'S' or 'N').
package discover

import (
	"context"
	"fmt"
	"io"
	"net"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Service is one database found.
type Service struct {
	Kind         string // "postgres"
	Host         string // as reached from the server
	Port         int
	Source       string // "cluster", "process", "docker", "port"
	Title        string
	Detail       string
	Confirmed    bool
	UserHint     string
	DatabaseHint string
}

// Addr is host:port.
func (s Service) Addr() string { return net.JoinHostPort(s.Host, strconv.Itoa(s.Port)) }

// Result of a discovery.
type Result struct {
	Services []Service
	Warnings []string
}

// Runner runs a command on the server.
type Runner func(ctx context.Context, cmd string) (string, error)

// Dialer opens a TCP connection from the server.
type Dialer func(ctx context.Context, addr string) (net.Conn, error)

// Script is what runs on the server. It only reads; secrets of
// containers never leave the server (only POSTGRES_USER / POSTGRES_DB
// pass the filter). Missing tools are skipped.
const Script = `export LC_ALL=C PATH="$PATH:/usr/sbin:/sbin:/usr/local/bin"
echo '@@ss'
if command -v ss >/dev/null 2>&1; then ss -Hltnp 2>/dev/null || ss -ltnp 2>/dev/null | tail -n +2; elif command -v netstat >/dev/null 2>&1; then netstat -ltnp 2>/dev/null; fi
echo '@@clusters'
command -v pg_lsclusters >/dev/null 2>&1 && pg_lsclusters -h 2>/dev/null
echo '@@ps'
ps -eo pid=,args= 2>/dev/null | grep -E '(postgres|postmaster)' | grep -v -E 'grep|postgres: '
echo '@@docker'
D=""
if command -v docker >/dev/null 2>&1; then
  if docker ps -q >/dev/null 2>&1; then D="docker"; elif sudo -n docker ps -q >/dev/null 2>&1; then D="sudo -n docker"; else echo '!permission'; fi
fi
if command -v podman >/dev/null 2>&1 && [ -z "$D" ]; then D="podman"; fi
if [ -n "$D" ]; then
  $D ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Ports}}' 2>/dev/null
  echo '@@inspect'
  for id in $($D ps -q 2>/dev/null); do
    $D inspect --format '{{.Id}}|{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}|{{range $p, $v := .Config.ExposedPorts}}{{$p}} {{end}}' "$id" 2>/dev/null
    $D inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$id" 2>/dev/null | grep -E '^(POSTGRES_USER|POSTGRES_DB|PGPORT)=' | sed "s|^|E $id |"
  done
fi
echo '@@end'
`

// Run discovers the services of one server.
func Run(ctx context.Context, run Runner, dial Dialer) (Result, error) {
	out, err := run(ctx, "sh -c "+shellQuote(Script))
	if err != nil && !strings.Contains(out, "@@ss") {
		return Result{}, fmt.Errorf("cannot run the discovery script: %w", err)
	}
	res := Parse(out)
	Probe(ctx, &res, dial)
	return res, nil
}

func shellQuote(s string) string { return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'" }

// listen is one listening socket.
type listen struct {
	host    string
	port    int
	process string
}

type container struct {
	id, name, image, ports string
	ips                    []string
	exposed                []int
	env                    map[string]string
}

var (
	ssProc      = regexp.MustCompile(`users:\(\("([^"]+)"`)
	pgPathVer   = regexp.MustCompile(`postgresql/(\d+(?:\.\d+)?)/bin`)
	pgVerAny    = regexp.MustCompile(`(?:pgsql|postgres(?:ql)?)-?(\d+(?:\.\d+)?)`)
	dataDir     = regexp.MustCompile(`\s-D\s*(\S+)`)
	portArg     = regexp.MustCompile(`\s-p\s*(\d+)`)
	publishedRe = regexp.MustCompile(`(?:([0-9.]+|\[?[0-9a-f:]*\]?)):(\d+)->(\d+)/tcp`)
)

// Parse turns the script's output into candidates (not checked yet).
func Parse(out string) Result {
	var res Result
	sections := map[string][]string{}
	cur := ""
	for _, line := range strings.Split(out, "\n") {
		line = strings.TrimRight(line, "\r")
		if name, ok := strings.CutPrefix(line, "@@"); ok {
			cur = name
			continue
		}
		if strings.TrimSpace(line) != "" && cur != "" {
			sections[cur] = append(sections[cur], line)
		}
	}
	var listens []listen
	for _, l := range sections["ss"] {
		if x, ok := parseListen(l); ok {
			listens = append(listens, x)
		}
	}
	byAddr := map[string]*Service{}
	var order []string
	add := func(s Service) *Service {
		key := s.Addr()
		if cur, ok := byAddr[key]; ok {
			return cur
		}
		byAddr[key] = &s
		order = append(order, key)
		return &s
	}

	// Debian / Ubuntu clusters: version, name, port, status, owner, dir.
	for _, l := range sections["clusters"] {
		f := strings.Fields(l)
		if len(f) < 6 {
			continue
		}
		port, err := strconv.Atoi(f[2])
		if err != nil {
			continue
		}
		s := add(Service{Kind: "postgres", Host: "127.0.0.1", Port: port, Source: "cluster"})
		s.Title = fmt.Sprintf("PostgreSQL %s (%s)", f[0], f[1])
		s.Detail = strings.Join(f[3:], " ")
		if f[3] != "online" {
			s.Title += " — " + f[3]
		}
		s.Host = listenHost(listens, port, "127.0.0.1")
	}

	// postgres main processes (-D datadir).
	for _, l := range sections["ps"] {
		f := strings.Fields(l)
		if len(f) < 2 {
			continue
		}
		args := strings.Join(f[1:], " ")
		if !strings.Contains(args, "-D") && !strings.Contains(args, "postmaster") {
			continue
		}
		if strings.Contains(args, "docker") || strings.Contains(args, "containerd") {
			continue
		}
		port := 0
		if m := portArg.FindStringSubmatch(" " + args); m != nil {
			port, _ = strconv.Atoi(m[1])
		}
		if port == 0 {
			// The socket of this process, else the default.
			for _, x := range listens {
				if strings.Contains(x.process, "postgres") && byAddr[net.JoinHostPort(x.host, strconv.Itoa(x.port))] == nil {
					port = x.port
					break
				}
			}
		}
		if port == 0 {
			port = 5432
		}
		ver := ""
		if m := pgPathVer.FindStringSubmatch(args); m != nil {
			ver = m[1]
		} else if m := pgVerAny.FindStringSubmatch(args); m != nil {
			ver = m[1]
		}
		host := listenHost(listens, port, "127.0.0.1")
		key := net.JoinHostPort(host, strconv.Itoa(port))
		s := byAddr[key]
		if s == nil {
			s = add(Service{Kind: "postgres", Host: host, Port: port, Source: "process"})
			s.Title = strings.TrimSpace("PostgreSQL " + ver)
		}
		if m := dataDir.FindStringSubmatch(" " + args); m != nil && s.Detail == "" {
			s.Detail = "data " + m[1]
		}
	}

	// Containers.
	containers := map[string]*container{}
	var corder []string
	for _, l := range sections["docker"] {
		if l == "!permission" {
			res.Warnings = append(res.Warnings, "docker is installed, but this user may not use it (add the user to the docker group, or allow sudo without a password): containers were not checked")
			continue
		}
		f := strings.SplitN(l, "|", 4)
		if len(f) < 4 {
			continue
		}
		c := &container{id: f[0], name: f[1], image: f[2], ports: f[3], env: map[string]string{}}
		containers[c.id] = c
		corder = append(corder, c.id)
	}
	find := func(full string) *container {
		for id, c := range containers {
			if strings.HasPrefix(full, id) {
				return c
			}
		}
		return nil
	}
	for _, l := range sections["inspect"] {
		if rest, ok := strings.CutPrefix(l, "E "); ok {
			id, kv, _ := strings.Cut(rest, " ")
			k, v, _ := strings.Cut(kv, "=")
			if c := find(id); c != nil {
				c.env[k] = v
			}
			continue
		}
		f := strings.SplitN(l, "|", 3)
		if len(f) < 3 {
			continue
		}
		c := find(f[0])
		if c == nil {
			continue
		}
		c.ips = strings.Fields(f[1])
		for _, p := range strings.Fields(f[2]) {
			if n, ok := strings.CutSuffix(p, "/tcp"); ok {
				if v, err := strconv.Atoi(n); err == nil {
					c.exposed = append(c.exposed, v)
				}
			}
		}
	}
	for _, id := range corder {
		c := containers[id]
		inner := 5432
		if v, err := strconv.Atoi(c.env["PGPORT"]); err == nil && v > 0 {
			inner = v
		}
		img := strings.ToLower(c.image)
		isPG := strings.Contains(img, "postgres") || strings.Contains(img, "postgis") || strings.Contains(img, "timescale") ||
			strings.Contains(img, "pgvector") || strings.Contains(img, "supabase/postgres") || slices.Contains(c.exposed, inner)
		if !isPG {
			continue
		}
		title := fmt.Sprintf("docker: %s (%s)", c.name, c.image)
		detail := "container " + c.id
		published := false
		for _, m := range publishedRe.FindAllStringSubmatch(c.ports, -1) {
			if to, _ := strconv.Atoi(m[3]); to != inner {
				continue
			}
			hp, _ := strconv.Atoi(m[2])
			h := strings.Trim(m[1], "[]")
			switch h {
			case "", "0.0.0.0", "::":
				h = "127.0.0.1"
			}
			key := net.JoinHostPort(h, strconv.Itoa(hp))
			if published && byAddr[key] != nil {
				continue
			}
			published = true
			s := byAddr[key]
			if s == nil {
				s = add(Service{Kind: "postgres", Host: h, Port: hp})
			}
			s.Source, s.Title, s.Detail = "docker", title, detail
			s.UserHint, s.DatabaseHint = c.env["POSTGRES_USER"], c.env["POSTGRES_DB"]
			if h == "127.0.0.1" {
				// The same port on ::1 is the same container.
				delete(byAddr, net.JoinHostPort("::1", strconv.Itoa(hp)))
			}
		}
		if !published {
			for _, ip := range c.ips {
				s := add(Service{Kind: "postgres", Host: ip, Port: inner, Source: "docker", Title: title, Detail: detail + ", not published: through the container network"})
				s.UserHint, s.DatabaseHint = c.env["POSTGRES_USER"], c.env["POSTGRES_DB"]
				break
			}
		}
	}

	// Every other listening port is a candidate too (a PostgreSQL the
	// script could not name, e.g. another user's process).
	for _, x := range listens {
		if x.port == 22 {
			continue
		}
		key := net.JoinHostPort(x.host, strconv.Itoa(x.port))
		if byAddr[key] != nil || x.host != "127.0.0.1" && byAddr[net.JoinHostPort("127.0.0.1", strconv.Itoa(x.port))] != nil {
			continue
		}
		if x.host == "::1" && byAddr[net.JoinHostPort("127.0.0.1", strconv.Itoa(x.port))] != nil {
			continue
		}
		title := ""
		if strings.Contains(x.process, "postgres") {
			title = "PostgreSQL"
		}
		add(Service{Kind: "postgres", Host: x.host, Port: x.port, Source: "port", Title: title, Detail: strings.TrimSpace("listening " + x.process)})
	}
	for _, k := range order {
		if s, ok := byAddr[k]; ok {
			res.Services = append(res.Services, *s)
		}
	}
	return res
}

// parseListen reads a line of `ss -ltnp` or `netstat -ltnp`.
func parseListen(l string) (listen, bool) {
	f := strings.Fields(l)
	var local, proc string
	switch {
	case len(f) >= 4 && f[0] == "LISTEN": // ss
		local = f[3]
		if m := ssProc.FindStringSubmatch(l); m != nil {
			proc = m[1]
		}
	case len(f) >= 6 && strings.HasPrefix(f[0], "tcp") && slices.Contains(f, "LISTEN"): // netstat
		local = f[3]
		if last := f[len(f)-1]; strings.Contains(last, "/") {
			_, proc, _ = strings.Cut(last, "/")
		}
	default:
		return listen{}, false
	}
	i := strings.LastIndex(local, ":")
	if i < 0 {
		return listen{}, false
	}
	port, err := strconv.Atoi(local[i+1:])
	if err != nil {
		return listen{}, false
	}
	h := strings.Trim(local[:i], "[]")
	if j := strings.Index(h, "%"); j >= 0 { // 127.0.0.53%lo
		h = h[:j]
	}
	switch h {
	case "*", "0.0.0.0", "", "::", ":":
		h = "127.0.0.1"
	}
	return listen{host: h, port: port, process: proc}, true
}

// listenHost is the address to reach port on: loopback when it listens
// there or on every address, else the one address it listens on.
func listenHost(ls []listen, port int, def string) string {
	other := ""
	for _, x := range ls {
		if x.port != port {
			continue
		}
		if x.host == "127.0.0.1" {
			return x.host
		}
		if other == "" && x.host != "::1" {
			other = x.host
		}
	}
	if other != "" {
		return other
	}
	return def
}

// sslRequest is PostgreSQL's SSLRequest packet.
var sslRequest = []byte{0, 0, 0, 8, 0x04, 0xd2, 0x16, 0x2f}

// Probe checks every candidate: confirmed ones answered as PostgreSQL;
// "port" candidates that did not are dropped.
func Probe(ctx context.Context, res *Result, dial Dialer) {
	if dial == nil {
		return
	}
	var wg sync.WaitGroup
	sem := make(chan struct{}, 8)
	for i := range res.Services {
		wg.Add(1)
		go func(s *Service) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			s.Confirmed = isPostgres(ctx, dial, s.Addr())
		}(&res.Services[i])
	}
	wg.Wait()
	res.Services = slices.DeleteFunc(res.Services, func(s Service) bool { return s.Source == "port" && !s.Confirmed })
	for i, s := range res.Services {
		if s.Title == "" {
			res.Services[i].Title = "PostgreSQL"
		}
	}
	slices.SortStableFunc(res.Services, func(a, b Service) int {
		if a.Confirmed != b.Confirmed {
			if a.Confirmed {
				return -1
			}
			return 1
		}
		return 0
	})
}

func isPostgres(ctx context.Context, dial Dialer, addr string) bool {
	ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
	defer cancel()
	c, err := dial(ctx, addr)
	if err != nil {
		return false
	}
	defer c.Close()
	// SSH channels ignore deadlines: closing on the context ends a read
	// from a service that never answers.
	stop := context.AfterFunc(ctx, func() { c.Close() })
	defer stop()
	c.SetDeadline(time.Now().Add(3 * time.Second))
	if _, err := c.Write(sslRequest); err != nil {
		return false
	}
	b := make([]byte, 1)
	if _, err := io.ReadFull(c, b); err != nil {
		return false
	}
	return b[0] == 'S' || b[0] == 'N'
}

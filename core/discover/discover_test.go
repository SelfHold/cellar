package discover

import (
	"context"
	"net"
	"strings"
	"testing"
)

const sample = `@@ss
LISTEN 0      4096       127.0.0.53%lo:53         0.0.0.0:*
LISTEN 0      128          0.0.0.0:22          0.0.0.0:*
LISTEN 0      244        127.0.0.1:5432        0.0.0.0:*    users:(("postgres",pid=812,fd=6))
LISTEN 0      244            [::1]:5432           [::]:*    users:(("postgres",pid=812,fd=5))
LISTEN 0      4096         0.0.0.0:5433        0.0.0.0:*
LISTEN 0      4096            [::]:5433           [::]:*
LISTEN 0      511          0.0.0.0:80          0.0.0.0:*
LISTEN 0      244          0.0.0.0:6000        0.0.0.0:*
@@clusters
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
@@ps
    812 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
@@docker
3f2a9c1b2d4e|shop-db|postgres:17-alpine|0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
a1b2c3d4e5f6|cache|redis:7|6379/tcp
9988776655aa|analytics|timescale/timescaledb:latest-pg16|5432/tcp
@@inspect
3f2a9c1b2d4e00000000|172.18.0.2 |5432/tcp
E 3f2a9c1b2d4e00000000 POSTGRES_USER=shop
E 3f2a9c1b2d4e00000000 POSTGRES_DB=shop
a1b2c3d4e5f600000000|172.18.0.3 |6379/tcp
9988776655aa00000000|172.19.0.5 |5432/tcp
@@end
`

func TestParse(t *testing.T) {
	res := Parse(sample)
	got := map[string]Service{}
	for _, s := range res.Services {
		got[s.Addr()] = s
	}
	want := map[string]string{
		"127.0.0.1:5432":  "cluster",
		"127.0.0.1:5433":  "docker",
		"172.19.0.5:5432": "docker",
		"127.0.0.1:80":    "port",
		"127.0.0.1:6000":  "port",
		"127.0.0.53:53":   "port", // dropped by Probe when it does not answer as PostgreSQL
	}
	if len(got) != len(want) {
		t.Fatalf("services: %+v", res.Services)
	}
	for addr, src := range want {
		if got[addr].Source != src {
			t.Errorf("%s: source %q, want %q (%+v)", addr, got[addr].Source, src, got[addr])
		}
	}
	if s := got["127.0.0.1:5432"]; s.Title != "PostgreSQL 16 (main)" {
		t.Errorf("cluster title %q", s.Title)
	}
	if s := got["127.0.0.1:5433"]; s.UserHint != "shop" || s.DatabaseHint != "shop" || !strings.Contains(s.Title, "shop-db") {
		t.Errorf("container %+v", s)
	}
}

func TestParseNetstatAndPermission(t *testing.T) {
	out := "@@ss\ntcp        0      0 0.0.0.0:5432            0.0.0.0:*               LISTEN      901/postgres\n" +
		"tcp6       0      0 :::5432                 :::*                    LISTEN      901/postgres\n" +
		"@@ps\n  901 /usr/pgsql-15/bin/postmaster -D /var/lib/pgsql/15/data\n@@docker\n!permission\n@@end\n"
	res := Parse(out)
	if len(res.Services) != 1 || res.Services[0].Addr() != "127.0.0.1:5432" || res.Services[0].Title != "PostgreSQL 15" {
		t.Fatalf("services %+v", res.Services)
	}
	if len(res.Warnings) != 1 {
		t.Fatalf("warnings %v", res.Warnings)
	}
}

func TestProbe(t *testing.T) {
	// A fake PostgreSQL answering 'N', and a silent service.
	pg, _ := net.Listen("tcp", "127.0.0.1:0")
	defer pg.Close()
	go func() {
		for {
			c, err := pg.Accept()
			if err != nil {
				return
			}
			b := make([]byte, 8)
			c.Read(b)
			c.Write([]byte("N"))
			c.Close()
		}
	}()
	other, _ := net.Listen("tcp", "127.0.0.1:0")
	defer other.Close()
	go func() {
		for {
			c, err := other.Accept()
			if err != nil {
				return
			}
			c.Write([]byte("HTTP/1.1 400 Bad Request\r\n"))
			c.Close()
		}
	}()
	host := func(l net.Listener) (string, int) {
		a := l.Addr().(*net.TCPAddr)
		return a.IP.String(), a.Port
	}
	h1, p1 := host(pg)
	h2, p2 := host(other)
	res := Result{Services: []Service{
		{Host: h2, Port: p2, Source: "port"},
		{Host: h1, Port: p1, Source: "port"},
		{Host: h2, Port: p2, Source: "docker", Title: "docker: x"},
	}}
	var d net.Dialer
	Probe(context.Background(), &res, func(ctx context.Context, addr string) (net.Conn, error) { return d.DialContext(ctx, "tcp", addr) })
	if len(res.Services) != 2 || !res.Services[0].Confirmed || res.Services[0].Port != p1 || res.Services[1].Confirmed {
		t.Fatalf("probed %+v", res.Services)
	}
}

package dump

import (
	"slices"
	"strings"
	"testing"
)

func TestParseVersion(t *testing.T) {
	for in, want := range map[string]struct {
		v string
		m int
	}{
		"pg_dump (PostgreSQL) 17.2 (Debian 17.2-1.pgdg120+1)\n": {"17.2", 17},
		"pg_dump (PostgreSQL) 9.6.24":                           {"9.6", 9},
		"pg_dump (PostgreSQL) 18devel":                          {"18", 18},
		"bash: pg_dump: not found":                              {"", 0},
	} {
		if v, m := parseVersion(in); v != want.v || m != want.m {
			t.Errorf("%q: %q %d", in, v, m)
		}
	}
}

func TestChoose(t *testing.T) {
	tools := []Tool{{Place: Local, Path: "/l16", Major: 16}, {Place: Remote, Path: "/r17", Major: 17}}
	sortTools(tools)
	if tl, err := Choose(tools, Auto, 17, true); err != nil || tl.Path != "/r17" {
		t.Fatal(tl, err)
	}
	if tl, err := Choose(tools, Auto, 15, true); err != nil || tl.Path != "/l16" {
		t.Fatal(tl, err)
	}
	if _, err := Choose(tools, Local, 17, true); err == nil || !strings.Contains(err.Error(), "older") {
		t.Fatal(err)
	}
	// Restoring does not care about the version.
	if tl, err := Choose(tools, Local, 17, false); err != nil || tl.Path != "/l16" {
		t.Fatal(tl, err)
	}
	if _, err := Choose(nil, Auto, 17, true); err == nil {
		t.Fatal("no tools, no error")
	}
	if s := (Tool{Place: Remote, Path: "/usr/lib/postgresql/17/bin/pg_dump"}).sibling("psql"); s != "/usr/lib/postgresql/17/bin/psql" {
		t.Fatal(s)
	}
}

func TestArgs(t *testing.T) {
	a := DumpArgs(DumpOptions{Format: Custom, Schemas: []string{"Sales"}, Tables: []Table{{Schema: "public", Name: `we"ird`}}, Clean: true, NoOwner: true})
	want := []string{"--verbose", "--format=c", `--schema="Sales"`, `--table="public"."we""ird"`, "--no-owner", "--clean", "--if-exists"}
	if !slices.Equal(a, want) {
		t.Fatalf("%q", a)
	}
	name, a := RestoreArgs(Plain, RestoreOptions{ExitOnError: true, SingleTransaction: true, Clean: true}, "it's")
	if name != "psql" || !slices.Equal(a, []string{"--no-psqlrc", "--quiet", `--dbname=dbname='it\'s'`, "--set=ON_ERROR_STOP=1", "--single-transaction", "--file=-"}) {
		t.Fatalf("%s %q", name, a)
	}
	name, a = RestoreArgs(Tar, RestoreOptions{Clean: true, NoOwner: true, Create: true}, "shop")
	if name != "pg_restore" || !slices.Equal(a, []string{"--verbose", "--format=t", "--dbname=dbname='shop'", "--clean", "--if-exists", "--no-owner", "--create"}) {
		t.Fatalf("%s %q", name, a)
	}
}

func TestDetect(t *testing.T) {
	tar := make([]byte, 512)
	copy(tar[257:], "ustar")
	if Detect([]byte("PGDMP\x01\x10")) != Custom || Detect(tar) != Tar || Detect([]byte("--\n-- PostgreSQL database dump")) != Plain {
		t.Fatal("formats")
	}
}

func TestShellQuote(t *testing.T) {
	if q := shellQuote(`a'b c`); q != `'a'\''b c'` {
		t.Fatal(q)
	}
}

package pg_test

import (
	"context"
	"net"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/SelfHold/cellar/core/dump"
	"github.com/SelfHold/cellar/core/pg"
	"github.com/SelfHold/cellar/core/rpc/pb"
	"github.com/SelfHold/cellar/core/sshx"
	"github.com/SelfHold/cellar/core/store"
)

func sqlRun(t *testing.T, m *pg.Manager, ctx context.Context, c store.Connection, db, sql string) {
	t.Helper()
	con, err := m.OpenConsole(ctx, c.ID, db)
	if err != nil {
		t.Fatal(err)
	}
	defer m.CloseConsole(con.ID)
	r, err := con.Execute(ctx, sql, true, 0, 0)
	if err != nil {
		t.Fatal(err)
	}
	for _, rs := range r.Results {
		if rs.Error != "" {
			t.Fatalf("%s: %s", rs.Statement, rs.Error)
		}
	}
}

func apply(t *testing.T, m *pg.Manager, ctx context.Context, ch *pb.Change) []string {
	t.Helper()
	done, err := m.Apply(ctx, ch)
	if err != nil {
		t.Fatalf("%v (ran %q)", err, done)
	}
	return done
}

func TestObjectsAndTypes(t *testing.T) {
	c := pgConn(t)
	m, _, _ := throughSSH(t, c)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	sqlRun(t, m, ctx, c, c.Database, `DROP SCHEMA IF EXISTS kinds CASCADE;
CREATE SCHEMA kinds;
CREATE TYPE kinds.mood AS ENUM ('sad', 'ok', 'happy');
CREATE DOMAIN kinds.positive AS int DEFAULT 1 NOT NULL CONSTRAINT above_zero CHECK (VALUE > 0);
CREATE TYPE kinds.point2 AS (x float8, y float8);
CREATE TYPE kinds.floats AS RANGE (subtype = float8);
CREATE TABLE kinds.t (id int PRIMARY KEY, m kinds.mood, p kinds.positive);
CREATE FUNCTION kinds.touch() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$;
CREATE TRIGGER t_touch BEFORE UPDATE ON kinds.t FOR EACH ROW EXECUTE FUNCTION kinds.touch();`)

	objs, err := m.Objects(ctx, c.ID, c.Database, "kinds")
	if err != nil {
		t.Fatal(err)
	}
	kinds := map[string]pb.DbObject_Kind{}
	for _, o := range objs.Objects {
		kinds[o.Name] = o.Kind
		if o.Name == "mood" && !slices.Equal(o.Labels, []string{"sad", "ok", "happy"}) {
			t.Fatalf("labels %v", o.Labels)
		}
		if o.Name == "positive" && o.BaseType != "integer" {
			t.Fatalf("base %q", o.BaseType)
		}
	}
	for name, k := range map[string]pb.DbObject_Kind{"mood": pb.DbObject_ENUM, "positive": pb.DbObject_DOMAIN, "point2": pb.DbObject_COMPOSITE_TYPE,
		"floats": pb.DbObject_RANGE_TYPE, "t": pb.DbObject_TABLE, "touch": pb.DbObject_FUNCTION} {
		if kinds[name] != k {
			t.Errorf("%s: %v, want %v (all: %v)", name, kinds[name], k, kinds)
		}
	}
	if _, ok := kinds["floats_multirange"]; ok {
		t.Error("the multirange type is listed")
	}

	for name, want := range map[string]string{
		"mood":     "CREATE TYPE kinds.mood AS ENUM (\n    'sad',\n    'ok',\n    'happy'\n);",
		"positive": "CREATE DOMAIN kinds.positive AS integer\n    DEFAULT 1\n    NOT NULL\n    CONSTRAINT above_zero CHECK ((VALUE > 0));",
		"point2":   "CREATE TYPE kinds.point2 AS (\n    x double precision,\n    y double precision\n);",
		"floats":   "CREATE TYPE kinds.floats AS RANGE (\n    SUBTYPE = double precision\n);",
	} {
		info, err := m.Describe(ctx, &pb.ObjectRef{ConnectionId: c.ID, Database: c.Database, Schema: "kinds", Name: name, Kind: kinds[name]})
		if err != nil {
			t.Fatal(err)
		}
		if info.Ddl != want {
			t.Errorf("%s:\n%s\nwant\n%s", name, info.Ddl, want)
		}
	}
	info, err := m.Describe(ctx, &pb.ObjectRef{ConnectionId: c.ID, Database: c.Database, Schema: "kinds", Name: "t", Kind: pb.DbObject_TABLE})
	if err != nil {
		t.Fatal(err)
	}
	if len(info.Triggers) != 1 || info.Triggers[0].Name != "t_touch" || !strings.Contains(info.Ddl, "CREATE TRIGGER t_touch") {
		t.Fatalf("triggers %v\n%s", info.Triggers, info.Ddl)
	}

	// Dropping objects of every kind.
	for _, name := range []string{"t", "mood", "positive", "point2", "floats"} {
		apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Database: c.Database, Op: pb.Change_DROP,
			Object: &pb.Change_Target{Target: &pb.ObjectRef{Schema: "kinds", Name: name, Kind: kinds[name]}}})
	}
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Database: c.Database, Op: pb.Change_DROP, Object: &pb.Change_Target{Target: &pb.ObjectRef{Schema: "kinds", Name: "touch", Kind: pb.DbObject_FUNCTION}}})
	objs, _ = m.Objects(ctx, c.ID, c.Database, "kinds")
	if len(objs.Objects) != 0 {
		t.Fatalf("left: %v", objs.Objects)
	}
}

func TestRolesAndDDL(t *testing.T) {
	c := pgConn(t)
	m, _, _ := throughSSH(t, c)
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	sqlRun(t, m, ctx, c, c.Database, `DROP DATABASE IF EXISTS cellar_new; DROP DATABASE IF EXISTS cellar_renamed;
DROP ROLE IF EXISTS "Cellar App"; DROP ROLE IF EXISTS cellar_app2; DROP ROLE IF EXISTS cellar_readers;`)

	// Roles: create (the password hashed here), log in with it, alter, drop.
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_CREATE, Object: &pb.Change_Role{Role: &pb.Role{Name: "cellar_readers", Inherit: true, ConnectionLimit: -1}}})
	done := apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_CREATE, Object: &pb.Change_Role{Role: &pb.Role{
		Name: "Cellar App", Login: true, Inherit: true, CreateDb: true, ConnectionLimit: 3, Password: "pä ss:wörd", MemberOf: []string{"cellar_readers"}, Comment: "the app"}}})
	if strings.Contains(strings.Join(done, " "), "pä ss") {
		t.Fatalf("the password is in %q", done)
	}
	var d net.Dialer
	direct := func(ctx context.Context, addr string) (net.Conn, error) { return d.DialContext(ctx, "tcp", addr) }
	app := c
	app.User, app.Password = "Cellar App", "pä ss:wörd"
	if _, _, err := pg.Test(ctx, app, direct); err != nil {
		t.Fatalf("log in with the new password: %v", err)
	}
	roles, err := m.Roles(ctx, c.ID)
	if err != nil {
		t.Fatal(err)
	}
	i := slices.IndexFunc(roles.Roles, func(r *pb.Role) bool { return r.Name == "Cellar App" })
	if i < 0 {
		t.Fatal("no role")
	}
	r := roles.Roles[i]
	if !r.Login || !r.CreateDb || r.Superuser || r.ConnectionLimit != 3 || !slices.Equal(r.MemberOf, []string{"cellar_readers"}) || r.Comment != "the app" || r.Password != "" {
		t.Fatalf("role %v", r)
	}
	if !slices.ContainsFunc(roles.Roles, func(r *pb.Role) bool { return r.System && strings.HasPrefix(r.Name, "pg_") }) {
		t.Fatal("no system roles")
	}
	r.Name, r.CreateDb, r.MemberOf, r.Comment, r.Password = "cellar_app2", false, nil, "", "new-pass"
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_ALTER, Original: "Cellar App", Object: &pb.Change_Role{Role: r}})
	app.User, app.Password = "cellar_app2", "new-pass"
	if _, _, err := pg.Test(ctx, app, direct); err != nil {
		t.Fatalf("log in after the change: %v", err)
	}
	plan, err := m.Plan(ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_ALTER, Original: "cellar_app2", Object: &pb.Change_Role{Role: r}}, false)
	if err != nil || len(plan.Show) != 1 || !strings.Contains(plan.Show[0], "'********'") {
		t.Fatalf("plan %v %v", plan, err)
	}

	// Databases: create, rename (our pool on it is closed first), drop.
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_CREATE, Object: &pb.Change_Db{Db: &pb.Database{Name: "cellar_new", Owner: "cellar_app2", ConnectionLimit: -1, Comment: "made here"}}})
	sqlRun(t, m, ctx, c, "cellar_new", "CREATE TABLE x (a int)")
	dbs, _ := m.Databases(ctx, c.ID)
	i = slices.IndexFunc(dbs.Databases, func(d *pb.Database) bool { return d.Name == "cellar_new" })
	if i < 0 || dbs.Databases[i].Owner != "cellar_app2" || dbs.Databases[i].Comment != "made here" || dbs.Databases[i].Encoding == "" {
		t.Fatalf("databases %v", dbs.Databases)
	}
	live := dbs.Databases[i]
	live.Name, live.ConnectionLimit = "cellar_renamed", 7
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_ALTER, Original: "cellar_new", Object: &pb.Change_Db{Db: live}})

	// Schemas and tables in it.
	db := "cellar_renamed"
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Database: db, Op: pb.Change_CREATE, Object: &pb.Change_Schema{Schema: &pb.Schema{Name: "Sales", Comment: "money"}}})
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Database: db, Op: pb.Change_CREATE, Object: &pb.Change_Table{Table: &pb.TableSpec{
		Schema: "Sales", Name: "orders", Comment: "all orders",
		Columns: []*pb.ColumnSpec{
			{Name: "id", Type: "bigint GENERATED ALWAYS AS IDENTITY"},
			{Name: "customer", Type: "text"},
			{Name: "total", Type: "numeric(12,2)", Default: "0", Nullable: true},
		},
		PrimaryKey:  []string{"id"},
		Constraints: []*pb.Constraint{{Name: "total_ok", Definition: "CHECK (total >= 0)"}},
		Indexes:     []*pb.Index{{Name: "orders_customer", Definition: "(customer)"}},
	}}})
	ref := &pb.ObjectRef{ConnectionId: c.ID, Database: db, Schema: "Sales", Name: "orders", Kind: pb.DbObject_TABLE}
	info, err := m.Describe(ctx, ref)
	if err != nil {
		t.Fatal(err)
	}
	if len(info.Columns) != 3 || !slices.Equal(info.PrimaryKey, []string{"id"}) || len(info.Indexes) != 2 || info.Object.Comment != "all orders" {
		t.Fatalf("table %v", info)
	}
	// Modify it the way the dialog does: from what DescribeObject said.
	spec := &pb.TableSpec{Schema: "Sales", Name: "orders", Comment: info.Object.Comment, PrimaryKey: info.PrimaryKey}
	for _, col := range info.Columns {
		spec.Columns = append(spec.Columns, &pb.ColumnSpec{Name: col.Name, Original: col.Name, Type: col.Type, Nullable: col.Nullable, Default: col.Default, Comment: col.Comment})
	}
	for _, k := range info.Constraints {
		if k.Type != "PRIMARY KEY" {
			spec.Constraints = append(spec.Constraints, k)
		}
	}
	for _, ix := range info.Indexes {
		if !ix.Primary {
			spec.Indexes = append(spec.Indexes, ix)
		}
	}
	if p, err := m.Plan(ctx, &pb.Change{ConnectionId: c.ID, Database: db, Op: pb.Change_ALTER, Original: "orders", Object: &pb.Change_Table{Table: spec}}, false); err != nil || len(p.Show) != 0 {
		t.Fatalf("unchanged table: %v %q", err, p.Show)
	}
	spec.Name = "Orders"
	spec.Columns[1].Name = "client"
	spec.Columns[2].Type = "numeric(14,2)"
	spec.Columns = append(spec.Columns, &pb.ColumnSpec{Name: "note", Type: "text", Nullable: true, Comment: "free text"})
	spec.Constraints = nil
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Database: db, Op: pb.Change_ALTER, Original: "orders", Object: &pb.Change_Table{Table: spec}})
	ref.Name = "Orders"
	info, err = m.Describe(ctx, ref)
	if err != nil {
		t.Fatal(err)
	}
	names := []string{}
	for _, col := range info.Columns {
		names = append(names, col.Name+" "+col.Type)
	}
	if !slices.Equal(names, []string{"id bigint", "client text", "total numeric(14,2)", "note text"}) || len(info.Constraints) != 1 || info.Columns[3].Comment != "free text" {
		t.Fatalf("after the change: %v %v", names, info.Constraints)
	}

	// A failing change rolls back as a whole.
	bad := &pb.TableSpec{Schema: "Sales", Name: "Orders", PrimaryKey: info.PrimaryKey}
	for _, col := range info.Columns {
		bad.Columns = append(bad.Columns, &pb.ColumnSpec{Name: col.Name, Original: col.Name, Type: col.Type, Nullable: col.Nullable, Default: col.Default, Comment: col.Comment})
	}
	bad.Columns[3].Name = "note2"
	bad.Columns[1].Type = "nosuchtype"
	if _, err := m.Apply(ctx, &pb.Change{ConnectionId: c.ID, Database: db, Op: pb.Change_ALTER, Original: "Orders", Object: &pb.Change_Table{Table: bad}}); err == nil || !strings.Contains(err.Error(), "nosuchtype") {
		t.Fatalf("bad type: %v", err)
	}
	info, _ = m.Describe(ctx, ref)
	if info.Columns[3].Name != "note" {
		t.Fatal("the rename before the error was kept")
	}

	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Database: db, Op: pb.Change_DROP, Original: "Sales", Cascade: true, Object: &pb.Change_Schema{Schema: &pb.Schema{Name: "Sales"}}})
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_DROP, Original: db, Cascade: true, Object: &pb.Change_Db{Db: &pb.Database{Name: db}}})
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_DROP, Original: "cellar_app2", Object: &pb.Change_Role{Role: &pb.Role{Name: "cellar_app2"}}})
	apply(t, m, ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_DROP, Original: "cellar_readers", Object: &pb.Change_Role{Role: &pb.Role{Name: "cellar_readers"}}})
	dbs, _ = m.Databases(ctx, c.ID)
	if slices.ContainsFunc(dbs.Databases, func(d *pb.Database) bool { return strings.HasPrefix(d.Name, "cellar_") }) {
		t.Fatal("database left")
	}

	// A read-only connection changes nothing.
	ro := c
	ro.ReadOnly = true
	m2 := pg.NewManager(func(context.Context, string) (store.Connection, pg.Dial, error) { return ro, direct, nil })
	defer m2.Close()
	if _, err := m2.Apply(ctx, &pb.Change{ConnectionId: c.ID, Op: pb.Change_CREATE, Object: &pb.Change_Schema{Schema: &pb.Schema{Name: "nope"}}}); err == nil {
		t.Fatal("read-only connection changed")
	}
}

func TestDumpRestoreThroughSSH(t *testing.T) {
	c := pgConn(t)
	tools := dump.LocalTools(context.Background())
	if len(tools) == 0 {
		t.Skip("no pg_dump on this machine")
	}
	m, srv, pool := throughSSH(t, c)
	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()
	sqlRun(t, m, ctx, c, c.Database, `DROP TABLE IF EXISTS dumped; DROP DATABASE IF EXISTS cellar_restored; DROP DATABASE IF EXISTS cellar_plain;
CREATE TABLE dumped (id int PRIMARY KEY, name text);
INSERT INTO dumped SELECT g, 'row ' || g FROM generate_series(1, 500) g;
CREATE DATABASE cellar_restored; CREATE DATABASE cellar_plain;`)
	var major int
	if err := m.Acquire(ctx, c.ID, "", func(cn *pgx.Conn) error { major = pg.Major(cn); return nil }); err != nil {
		t.Fatal(err)
	}
	tool, err := dump.Choose(tools, dump.Local, major, true)
	if err != nil {
		t.Skip(err)
	}
	// The tools on this device reach the database through the SSH server.
	viaSSH := c
	viaSSH.ServerID = "srv"
	h, _, _ := net.SplitHostPort(srv.Addr)
	spec := &sshx.Spec{ID: "srv", Host: h, Port: srv.Port(), User: "u", Password: "pw", HostKeys: []string{sshx.AuthorizedLine(srv.HostKey)}}
	dial := func(ctx context.Context, addr string) (net.Conn, error) {
		cl, err := pool.Client(ctx, spec)
		if err != nil {
			return nil, err
		}
		return cl.DialContext(ctx, "tcp", addr)
	}
	dir := t.TempDir()
	before := srv.Forwarded.Load()
	for _, f := range []dump.Format{dump.Custom, dump.Plain} {
		file := filepath.Join(dir, "shop."+f.String())
		prog := &dump.Progress{}
		err := dump.Dump(ctx, tool, dump.Target{Conn: viaSSH, Database: c.Database, Dial: dial}, dump.DumpOptions{Format: f, Tables: []dump.Table{{Schema: "public", Name: "dumped"}}}, file, prog)
		if err != nil {
			t.Fatalf("dump %v: %v", f, err)
		}
		st, err := os.Stat(file)
		if err != nil || st.Size() == 0 || st.Mode().Perm() != 0o600 {
			t.Fatalf("dump file %v %v", st, err)
		}
		if b, _, log := prog.Take(); b != st.Size() || len(log) == 0 {
			t.Fatalf("progress %d of %d, log %d", b, st.Size(), len(log))
		}
		target := map[dump.Format]string{dump.Custom: "cellar_restored", dump.Plain: "cellar_plain"}[f]
		got, err := dump.Restore(ctx, tool, dump.Target{Conn: viaSSH, Database: target, Dial: dial}, dump.RestoreOptions{ExitOnError: true, NoOwner: true}, file, &dump.Progress{})
		if err != nil || got != f {
			t.Fatalf("restore %v: %v (%v)", f, err, got)
		}
		con, err := m.OpenConsole(ctx, c.ID, target)
		if err != nil {
			t.Fatal(err)
		}
		r, err := con.Execute(ctx, "select count(*) from dumped", true, 0, 0)
		if err != nil || r.Results[0].Error != "" || r.Results[0].Rows[0].Cells[0].Text != "500" {
			t.Fatalf("restored %v %v", r, err)
		}
		m.CloseConsole(con.ID)
	}
	if srv.Forwarded.Load() == before {
		t.Fatal("the tools did not go through SSH")
	}
	// A failing restore says why.
	bad := filepath.Join(dir, "bad.sql")
	os.WriteFile(bad, []byte("select 1;\nselect nosuchthing;\n"), 0o600)
	if _, err := dump.Restore(ctx, tool, dump.Target{Conn: viaSSH, Database: "cellar_plain", Dial: dial}, dump.RestoreOptions{ExitOnError: true}, bad, &dump.Progress{}); err == nil || !strings.Contains(err.Error(), "nosuchthing") {
		t.Fatalf("bad restore: %v", err)
	}
	// Cancelled dumps leave nothing behind.
	cctx, ccancel := context.WithCancel(ctx)
	ccancel()
	file := filepath.Join(dir, "cancelled.sql")
	if err := dump.Dump(cctx, tool, dump.Target{Conn: viaSSH, Database: c.Database, Dial: dial}, dump.DumpOptions{}, file, &dump.Progress{}); err == nil {
		t.Fatal("cancelled dump succeeded")
	}
	if _, err := os.Stat(file + ".part"); !os.IsNotExist(err) {
		t.Fatal("partial file left")
	}
	sqlRun(t, m, ctx, c, c.Database, "DROP TABLE dumped")
	m.Reset("")
	sqlRun(t, m, ctx, c, c.Database, "DROP DATABASE cellar_restored; DROP DATABASE cellar_plain;")
}

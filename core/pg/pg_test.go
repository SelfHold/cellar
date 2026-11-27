package pg_test

import (
	"context"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/SelfHold/cellar/core/pg"
	"github.com/SelfHold/cellar/core/rpc/pb"
	"github.com/SelfHold/cellar/core/sshx"
	"github.com/SelfHold/cellar/core/sshx/sshtest"
	"github.com/SelfHold/cellar/core/store"
)

// pgConn reads CELLAR_PG_DSN (make pg-test starts a PostgreSQL in docker).
func pgConn(t *testing.T) store.Connection {
	dsn := os.Getenv("CELLAR_PG_DSN")
	if dsn == "" {
		t.Skip("CELLAR_PG_DSN is not set (make pg-test)")
	}
	u, err := url.Parse(dsn)
	if err != nil {
		t.Fatal(err)
	}
	pw, _ := u.User.Password()
	port, _ := strconv.Atoi(u.Port())
	return store.Connection{ID: "c1", Name: "test", Kind: store.KindPostgres, Host: u.Hostname(), Port: port,
		User: u.User.Username(), Password: pw, Database: strings.TrimPrefix(u.Path, "/"), SSLMode: "disable"}
}

// throughSSH returns a manager whose connections go through an in-process
// SSH server, and the server.
func throughSSH(t *testing.T, c store.Connection) (*pg.Manager, *sshtest.Server, *sshx.Pool) {
	srv := sshtest.Start(t, sshtest.Options{User: "u", Password: "pw"})
	pool := sshx.NewPool()
	t.Cleanup(pool.CloseAll)
	h, _, _ := net.SplitHostPort(srv.Addr)
	spec := &sshx.Spec{ID: "srv", Host: h, Port: srv.Port(), User: "u", Password: "pw", HostKeys: []string{sshx.AuthorizedLine(srv.HostKey)}}
	dial := func(ctx context.Context, addr string) (net.Conn, error) {
		cl, err := pool.Client(ctx, spec)
		if err != nil {
			return nil, err
		}
		return cl.DialContext(ctx, "tcp", addr)
	}
	m := pg.NewManager(func(context.Context, string) (store.Connection, pg.Dial, error) { return c, dial, nil })
	t.Cleanup(m.Close)
	return m, srv, pool
}

func TestThroughSSH(t *testing.T) {
	c := pgConn(t)
	m, srv, pool := throughSSH(t, c)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	con, err := m.OpenConsole(ctx, c.ID, c.Database)
	if err != nil {
		t.Fatal(err)
	}
	script := `DROP TABLE IF EXISTS items, nokey;
CREATE TABLE items (id serial PRIMARY KEY, name text NOT NULL, price numeric(10,2), tags text[], meta jsonb, created timestamptz DEFAULT now());
COMMENT ON TABLE items IS 'things for sale';
CREATE INDEX items_name ON items (name);
INSERT INTO items (name, price, tags, meta) SELECT 'item ' || g, g * 1.5, ARRAY['a','b'], '{"k": 1}' FROM generate_series(1, 30) g;
CREATE TABLE nokey (a int, b text);
INSERT INTO nokey VALUES (1, 'x'), (1, 'x'), (2, NULL);
CREATE VIEW cheap AS SELECT id, name FROM items WHERE price < 10;`
	r, err := con.Execute(ctx, script, true, 0, 0)
	if err != nil {
		t.Fatal(err)
	}
	for _, rs := range r.Results {
		if rs.Error != "" {
			t.Fatalf("%s: %s", rs.Statement, rs.Error)
		}
	}
	if srv.Forwarded.Load() == 0 {
		t.Fatal("nothing went through SSH")
	}

	// Statement at the cursor, rows, types, truncation.
	text := "select 1;\nselect id, name, price, tags, meta, null::int as n from items order by id;"
	r, err = con.Execute(ctx, text, false, len("select 1;\nsel"), 10)
	if err != nil {
		t.Fatal(err)
	}
	rs := r.Results[0]
	if len(r.Results) != 1 || len(rs.Rows) != 10 || !rs.Truncated || rs.CommandTag != "SELECT 30" {
		t.Fatalf("result %d rows, truncated %v, tag %q", len(rs.Rows), rs.Truncated, rs.CommandTag)
	}
	if rs.Columns[2].Type != "numeric" || rs.Columns[3].Type != "_text" && rs.Columns[3].Type != "text[]" || rs.Rows[0].Cells[3].Text != "{a,b}" || !rs.Rows[0].Cells[5].Null {
		t.Fatalf("columns %v, row %v", rs.Columns, rs.Rows[0])
	}

	// Transactions persist on the console; errors carry their position.
	r, _ = con.Execute(ctx, "begin; select nosuchcolumn from items;", true, 0, 0)
	last := r.Results[len(r.Results)-1]
	if last.Error == "" || last.ErrorOffset != int32(strings.Index("begin; select nosuchcolumn from items;", "nosuchcolumn")) || r.TxStatus != "failed" {
		t.Fatalf("error %q at %d, tx %q", last.Error, last.ErrorOffset, r.TxStatus)
	}
	r, _ = con.Execute(ctx, "rollback", true, 0, 0)
	if r.TxStatus != "idle" {
		t.Fatalf("tx %q", r.TxStatus)
	}

	// Notices.
	r, _ = con.Execute(ctx, "do $$ begin raise notice 'hello %', 42; end $$", true, 0, 0)
	if len(r.Results[0].Notices) != 1 || !strings.Contains(r.Results[0].Notices[0], "hello 42") {
		t.Fatalf("notices %v", r.Results[0].Notices)
	}

	// Cancel a long statement.
	go func() {
		time.Sleep(500 * time.Millisecond)
		con.Cancel(ctx)
	}()
	r, _ = con.Execute(ctx, "select pg_sleep(30)", true, 0, 0)
	if !strings.Contains(r.Results[0].Error, "cancel") {
		t.Fatalf("cancel: %q", r.Results[0].Error)
	}

	// Browser.
	dbs, err := m.Databases(ctx, c.ID)
	if err != nil || len(dbs.Databases) == 0 {
		t.Fatalf("databases %v %v", dbs, err)
	}
	schemas, err := m.Schemas(ctx, c.ID, c.Database)
	if err != nil || schemas.Schemas[0].Name != "public" {
		t.Fatalf("schemas %v %v", schemas, err)
	}
	objs, err := m.Objects(ctx, c.ID, c.Database, "public")
	if err != nil {
		t.Fatal(err)
	}
	kinds := map[string]pb.DbObject_Kind{}
	for _, o := range objs.Objects {
		kinds[o.Name] = o.Kind
	}
	if kinds["items"] != pb.DbObject_TABLE || kinds["cheap"] != pb.DbObject_VIEW || kinds["items_id_seq"] != pb.DbObject_SEQUENCE {
		t.Fatalf("objects %v", kinds)
	}
	info, err := m.Describe(ctx, &pb.ObjectRef{ConnectionId: c.ID, Database: c.Database, Schema: "public", Name: "items", Kind: pb.DbObject_TABLE})
	if err != nil {
		t.Fatal(err)
	}
	if len(info.PrimaryKey) != 1 || info.PrimaryKey[0] != "id" || !info.Columns[0].Identity || len(info.Indexes) != 2 ||
		!strings.Contains(info.Ddl, "CREATE INDEX items_name") || !strings.Contains(info.Ddl, "things for sale") {
		t.Fatalf("describe: pk %v, idx %d\n%s", info.PrimaryKey, len(info.Indexes), info.Ddl)
	}
	view, err := m.Describe(ctx, &pb.ObjectRef{ConnectionId: c.ID, Database: c.Database, Schema: "public", Name: "cheap", Kind: pb.DbObject_VIEW})
	if err != nil || !strings.HasPrefix(view.Ddl, "CREATE VIEW public.cheap AS") {
		t.Fatalf("view ddl %q %v", view.GetDdl(), err)
	}

	// Data viewer: page, sort, filter (a comment cannot hide the LIMIT).
	page, err := m.ReadTable(ctx, &pb.ReadTableRequest{ConnectionId: c.ID, Database: c.Database, Schema: "public", Table: "items",
		Limit: 5, Offset: 5, Sort: []*pb.Sort{{Column: "id", Desc: true}}, Filter: "price > 3 -- comment"})
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Rows) != 5 || !page.Truncated || page.Rows[0].Cells[0].Text != "25" || page.KeyColumns[0] != "id" {
		t.Fatalf("page: %d rows, first %v, keys %v", len(page.Rows), page.Rows[0], page.KeyColumns)
	}
	if _, err := m.ReadTable(ctx, &pb.ReadTableRequest{ConnectionId: c.ID, Database: c.Database, Schema: "public", Table: "items", Sort: []*pb.Sort{{Column: "x; drop"}}}); err == nil {
		t.Fatal("unknown sort column accepted")
	}

	// Edits: insert (default id), update, delete; a key hitting two rows
	// rolls back.
	_, err = m.ApplyEdits(ctx, &pb.EditRequest{ConnectionId: c.ID, Database: c.Database, Schema: "public", Table: "items", Edits: []*pb.RowEdit{
		{Op: pb.RowEdit_INSERT, Values: []*pb.EditValue{{Column: "id", UseDefault: true}, {Column: "name", Value: &pb.Cell{Text: "new"}}, {Column: "price", Value: &pb.Cell{Null: true}}}},
		{Op: pb.RowEdit_UPDATE, Key: []*pb.EditValue{{Column: "id", Value: &pb.Cell{Text: "1"}}}, Values: []*pb.EditValue{{Column: "price", Value: &pb.Cell{Text: "99.90"}}, {Column: "tags", Value: &pb.Cell{Text: "{x,\"y z\"}"}}}},
		{Op: pb.RowEdit_DELETE, Key: []*pb.EditValue{{Column: "id", Value: &pb.Cell{Text: "2"}}}},
	}})
	if err != nil {
		t.Fatal(err)
	}
	r, _ = con.Execute(ctx, "select (select price from items where id = 1), (select tags[2] from items where id = 1), (select count(*) from items), (select count(*) from items where name = 'new' and price is null)", true, 0, 0)
	if got := cells(r.Results[0].Rows[0]); got != "99.90|y z|30|1" {
		t.Fatalf("after edits: %s (%s)", got, r.Results[0].Error)
	}
	nk, err := m.ReadTable(ctx, &pb.ReadTableRequest{ConnectionId: c.ID, Database: c.Database, Schema: "public", Table: "nokey"})
	if err != nil || !nk.HasCtid || nk.Columns[0].Name != "ctid" {
		t.Fatalf("nokey: %v %v", nk, err)
	}
	_, err = m.ApplyEdits(ctx, &pb.EditRequest{ConnectionId: c.ID, Database: c.Database, Schema: "public", Table: "nokey", Edits: []*pb.RowEdit{
		{Op: pb.RowEdit_UPDATE, Key: []*pb.EditValue{{Column: "ctid", Value: nk.Rows[0].Cells[0]}}, Values: []*pb.EditValue{{Column: "b", Value: &pb.Cell{Text: "changed"}}}},
		{Op: pb.RowEdit_DELETE, Key: []*pb.EditValue{{Column: "a", Value: &pb.Cell{Text: "1"}}}}, // two rows: rolls back
	}})
	if err == nil || !strings.Contains(err.Error(), "2 rows") {
		t.Fatalf("want rollback, got %v", err)
	}
	r, _ = con.Execute(ctx, "select count(*) from nokey where b = 'changed'", true, 0, 0)
	if r.Results[0].Rows[0].Cells[0].Text != "0" {
		t.Fatal("rolled-back edit was kept")
	}

	// The SSH connection drops: the pool and the console reconnect.
	pool.CloseAll()
	if _, err := m.Schemas(ctx, c.ID, c.Database); err != nil {
		t.Fatalf("after SSH drop: %v", err)
	}
	r, err = con.Execute(ctx, "select 42", true, 0, 0)
	if err != nil || r.Results[0].Error != "" || r.Results[0].Rows[0].Cells[0].Text != "42" || len(r.Results[0].Notices) == 0 {
		t.Fatalf("console after SSH drop: %v %v", r, err)
	}

	// Test(): wrong password.
	bad := c
	bad.Password = "nope"
	var d net.Dialer
	if _, _, err := pg.Test(ctx, bad, func(ctx context.Context, addr string) (net.Conn, error) { return d.DialContext(ctx, "tcp", addr) }); err == nil || !strings.Contains(err.Error(), "login refused") {
		t.Fatalf("bad password: %v", err)
	}
}

func cells(r *pb.Row) string {
	var s []string
	for _, c := range r.Cells {
		s = append(s, c.Text)
	}
	return strings.Join(s, "|")
}

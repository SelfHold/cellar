package pg

import (
	"strings"
	"testing"

	"github.com/SelfHold/cellar/core/rpc/pb"
)

func joined(p *Plan) string { return strings.Join(p.Show, "\n") }

func noHash(pw, user string) (string, error) { return "'hashed'", nil }

func TestRolePlan(t *testing.T) {
	p, err := RolePlan(pb.Change_CREATE, nil, &pb.Role{Name: "App User", Login: true, Inherit: true, ConnectionLimit: 5, Password: "s3cret", MemberOf: []string{"readers"}, Comment: "it's the app"}, false, noHash)
	if err != nil {
		t.Fatal(err)
	}
	want := "CREATE ROLE \"App User\" WITH\n    LOGIN\n    CONNECTION LIMIT 5\n    PASSWORD '********'\n    IN ROLE readers;\nCOMMENT ON ROLE \"App User\" IS 'it''s the app';"
	if joined(p) != want {
		t.Fatalf("got\n%s\nwant\n%s", joined(p), want)
	}
	if !strings.Contains(p.Run[0], "PASSWORD 'hashed'") || strings.Contains(strings.Join(p.Show, ""), "s3cret") || strings.Contains(strings.Join(p.Run, ""), "s3cret") {
		t.Fatalf("password handling: %q / %q", p.Run, p.Show)
	}

	live := &pb.Role{Name: "app", Login: true, Inherit: true, ConnectionLimit: -1, MemberOf: []string{"readers", "old"}, Comment: "x"}
	p, err = RolePlan(pb.Change_ALTER, live, &pb.Role{Name: "app2", Login: true, Superuser: true, Inherit: true, ConnectionLimit: -1, ValidUntil: "2030-01-01", MemberOf: []string{"readers", "writers"}}, false, noHash)
	if err != nil {
		t.Fatal(err)
	}
	want = `ALTER ROLE app RENAME TO app2;
ALTER ROLE app2 WITH SUPERUSER VALID UNTIL '2030-01-01';
GRANT writers TO app2;
REVOKE old FROM app2;
COMMENT ON ROLE app2 IS NULL;`
	if joined(p) != want {
		t.Fatalf("got\n%s\nwant\n%s", joined(p), want)
	}
	p, _ = RolePlan(pb.Change_ALTER, live, live, false, noHash)
	if len(p.Run) != 0 {
		t.Fatalf("no change, got %q", p.Run)
	}
	p, _ = RolePlan(pb.Change_DROP, live, nil, true, noHash)
	if joined(p) != "REASSIGN OWNED BY app TO CURRENT_USER;\nDROP OWNED BY app;\nDROP ROLE app;" {
		t.Fatal(joined(p))
	}
	if _, err := RolePlan(pb.Change_CREATE, nil, &pb.Role{Name: "x", Password: "a\nb"}, false, noHash); err == nil {
		t.Fatal("a password with a line break was taken")
	}
}

func TestDatabasePlan(t *testing.T) {
	p, err := DatabasePlan(pb.Change_CREATE, nil, &pb.Database{Name: "shop", Owner: "app", Encoding: "UTF8", ConnectionLimit: -1, Comment: "the shop"}, false, 17)
	if err != nil {
		t.Fatal(err)
	}
	if p.Transactional || joined(p) != "CREATE DATABASE shop WITH\n    OWNER = app\n    TEMPLATE = template0\n    ENCODING = 'UTF8';\nCOMMENT ON DATABASE shop IS 'the shop';" {
		t.Fatalf("%v\n%s", p.Transactional, joined(p))
	}
	live := &pb.Database{Name: "shop", Owner: "postgres", ConnectionLimit: -1}
	p, _ = DatabasePlan(pb.Change_ALTER, live, &pb.Database{Name: "store", Owner: "app", ConnectionLimit: 10}, false, 17)
	if joined(p) != "ALTER DATABASE shop RENAME TO store;\nALTER DATABASE store OWNER TO app;\nALTER DATABASE store WITH CONNECTION LIMIT = 10;" || len(p.Closes) != 1 {
		t.Fatal(joined(p))
	}
	p, _ = DatabasePlan(pb.Change_DROP, live, nil, true, 17)
	if joined(p) != "DROP DATABASE shop WITH (FORCE);" || p.Closes[0] != "shop" {
		t.Fatal(joined(p))
	}
	p, _ = DatabasePlan(pb.Change_DROP, live, nil, true, 12)
	if len(p.Run) != 2 || !strings.Contains(p.Run[0], "pg_terminate_backend") {
		t.Fatal(joined(p))
	}
}

func TestSchemaAndDropPlans(t *testing.T) {
	p, _ := SchemaPlan(pb.Change_CREATE, nil, &pb.Schema{Name: "Sales", Owner: "app"}, false)
	if joined(p) != `CREATE SCHEMA "Sales" AUTHORIZATION app;` {
		t.Fatal(joined(p))
	}
	p, _ = SchemaPlan(pb.Change_ALTER, &pb.Schema{Name: "a", Owner: "x", Comment: "c"}, &pb.Schema{Name: "b", Owner: "x", Comment: "c"}, false)
	if joined(p) != "ALTER SCHEMA a RENAME TO b;" {
		t.Fatal(joined(p))
	}
	p, _ = SchemaPlan(pb.Change_DROP, &pb.Schema{Name: "a"}, nil, true)
	if joined(p) != "DROP SCHEMA a CASCADE;" {
		t.Fatal(joined(p))
	}
	for k, want := range map[pb.DbObject_Kind]string{
		pb.DbObject_TABLE:             "DROP TABLE public.t;",
		pb.DbObject_MATERIALIZED_VIEW: "DROP MATERIALIZED VIEW public.t;",
		pb.DbObject_FUNCTION:          "DROP FUNCTION public.t(integer, text);",
		pb.DbObject_ENUM:              "DROP TYPE public.t;",
		pb.DbObject_DOMAIN:            "DROP DOMAIN public.t;",
	} {
		p, err := DropObjectPlan(&pb.ObjectRef{Schema: "public", Name: "t", Kind: k, Signature: "integer, text"}, false)
		if err != nil || joined(p) != want {
			t.Fatalf("%v: %v %s", k, err, joined(p))
		}
	}
}

func TestTablePlanCreate(t *testing.T) {
	p, err := TablePlan(nil, &pb.TableSpec{
		Schema: "public", Name: "items", Comment: "things",
		Columns: []*pb.ColumnSpec{
			{Name: "id", Type: "bigint", Default: "", Nullable: false},
			{Name: "name", Type: "text", Nullable: false, Comment: "shown"},
			{Name: "price", Type: "numeric(10,2)", Nullable: true, Default: "0"},
		},
		PrimaryKey:  []string{"id"},
		Constraints: []*pb.Constraint{{Name: "price_positive", Definition: "CHECK (price >= 0)"}},
		Indexes:     []*pb.Index{{Name: "items_name", Definition: "(name)"}},
	})
	if err != nil {
		t.Fatal(err)
	}
	want := `CREATE TABLE public.items (
    id bigint NOT NULL,
    name text NOT NULL,
    price numeric(10,2) DEFAULT 0,
    PRIMARY KEY (id),
    CONSTRAINT price_positive CHECK (price >= 0)
);
CREATE INDEX items_name ON public.items (name);
COMMENT ON TABLE public.items IS 'things';
COMMENT ON COLUMN public.items.name IS 'shown';`
	if joined(p) != want {
		t.Fatalf("got\n%s\nwant\n%s", joined(p), want)
	}
	for _, bad := range []*pb.TableSpec{
		{Schema: "s", Name: ""},
		{Schema: "s", Name: "t", Columns: []*pb.ColumnSpec{{Name: "a"}}},
		{Schema: "s", Name: "t", Columns: []*pb.ColumnSpec{{Name: "a", Type: "int"}, {Name: "a", Type: "int"}}},
		{Schema: "s", Name: "t", Columns: []*pb.ColumnSpec{{Name: "a", Type: "int"}}, PrimaryKey: []string{"b"}},
	} {
		if _, err := TablePlan(nil, bad); err == nil {
			t.Fatalf("%v was taken", bad)
		}
	}
}

func TestTablePlanAlter(t *testing.T) {
	live := &pb.ObjectInfo{
		Object: &pb.DbObject{Name: "items", Comment: "things"},
		Owner:  "postgres",
		Columns: []*pb.Column{
			{Name: "id", Type: "integer", PrimaryKey: true, Identity: true, Default: "nextval('items_id_seq'::regclass)"},
			{Name: "name", Type: "text", Nullable: false},
			{Name: "price", Type: "numeric(10,2)", Nullable: true},
			{Name: "old", Type: "text", Nullable: true},
		},
		PrimaryKey: []string{"id"},
		Constraints: []*pb.Constraint{
			{Name: "items_pkey", Type: "PRIMARY KEY", Definition: "PRIMARY KEY (id)"},
			{Name: "price_positive", Type: "CHECK", Definition: "CHECK ((price >= (0)::numeric))"},
			{Name: "gone", Type: "CHECK", Definition: "CHECK ((length(name) > 0))"},
		},
		Indexes: []*pb.Index{
			{Name: "items_pkey", Definition: "CREATE UNIQUE INDEX items_pkey ON public.items USING btree (id)", Primary: true, Unique: true},
			{Name: "items_name", Definition: "CREATE INDEX items_name ON public.items USING btree (name)"},
			{Name: "items_price", Definition: "CREATE INDEX items_price ON public.items USING btree (price)"},
		},
	}
	want := &pb.TableSpec{
		Schema: "public", Name: "items",
		Comment: "things",
		Columns: []*pb.ColumnSpec{
			{Name: "id", Original: "id", Type: "int", Default: "nextval('items_id_seq'::regclass)"},
			{Name: "title", Original: "name", Type: "varchar(200)", Nullable: true},
			{Name: "price", Original: "price", Type: "numeric(10,2)", Nullable: false, Default: "0", Comment: "EUR"},
			{Name: "added", Type: "timestamptz", Nullable: false, Default: "now()"},
		},
		PrimaryKey: []string{"id"},
		Constraints: []*pb.Constraint{
			{Name: "price_positive", Definition: "CHECK ((price >= (0)::numeric))"},
			{Name: "", Definition: "UNIQUE (title)"},
		},
		Indexes: []*pb.Index{
			{Name: "items_name", Definition: "CREATE INDEX items_name ON public.items USING btree (name)"},
			{Name: "items_added", Definition: "USING brin (added)"},
		},
	}
	p, err := TablePlan(live, want)
	if err != nil {
		t.Fatal(err)
	}
	exp := `ALTER TABLE public.items DROP CONSTRAINT gone;
DROP INDEX public.items_price;
ALTER TABLE public.items DROP COLUMN old;
ALTER TABLE public.items RENAME COLUMN name TO title;
ALTER TABLE public.items ALTER COLUMN title TYPE varchar(200);
ALTER TABLE public.items ALTER COLUMN title DROP NOT NULL;
ALTER TABLE public.items ALTER COLUMN price SET DEFAULT 0;
ALTER TABLE public.items ALTER COLUMN price SET NOT NULL;
ALTER TABLE public.items ADD COLUMN added timestamptz DEFAULT now() NOT NULL;
ALTER TABLE public.items ADD UNIQUE (title);
CREATE INDEX items_added ON public.items USING brin (added);
COMMENT ON COLUMN public.items.price IS 'EUR';`
	if joined(p) != exp {
		t.Fatalf("got\n%s\nwant\n%s", joined(p), exp)
	}

	// The same table back: nothing to do.
	same := &pb.TableSpec{Schema: "public", Name: "items", Comment: "things", PrimaryKey: []string{"id"}}
	for _, c := range live.Columns {
		same.Columns = append(same.Columns, &pb.ColumnSpec{Name: c.Name, Original: c.Name, Type: c.Type, Nullable: c.Nullable, Default: c.Default})
	}
	for _, k := range live.Constraints {
		if k.Type != "PRIMARY KEY" {
			same.Constraints = append(same.Constraints, k)
		}
	}
	same.Indexes = live.Indexes[1:]
	p, err = TablePlan(live, same)
	if err != nil || len(p.Run) != 0 {
		t.Fatalf("%v %q", err, p.Run)
	}

	// Rename and a new primary key.
	same.Name, same.PrimaryKey = "goods", []string{"id", "name"}
	p, _ = TablePlan(live, same)
	exp = `ALTER TABLE public.items RENAME TO goods;
ALTER TABLE public.goods DROP CONSTRAINT items_pkey;
ALTER TABLE public.goods ADD PRIMARY KEY (id, name);`
	if joined(p) != exp {
		t.Fatalf("got\n%s\nwant\n%s", joined(p), exp)
	}
}

func TestSameType(t *testing.T) {
	for _, c := range [][2]string{{"int", "integer"}, {"varchar(20)", "character varying(20)"}, {"timestamptz", "timestamp with time zone"}, {"TEXT", "text"}} {
		if !sameType(c[0], c[1]) {
			t.Errorf("%s != %s", c[0], c[1])
		}
	}
	if sameType("int", "bigint") {
		t.Error("int == bigint")
	}
}

func TestScramVerifier(t *testing.T) {
	// RFC 7677's test vector: user "user", password "pencil".
	salt := []byte{0x41, 0x25, 0xc2, 0x47, 0xe4, 0x3a, 0xb1, 0xe9, 0x3c, 0x6d, 0xff, 0x76}
	v, err := scramVerifier("pencil", salt, 4096)
	if err != nil {
		t.Fatal(err)
	}
	if v != "SCRAM-SHA-256$4096:QSXCR+Q6sek8bf92$FO+9jBb3MUukt6jJnzjPZOWc5ow/Pu6JtPyju0aqaE8=:qxJ1SbmSAi5EcS0J5Ck/cKAm/+Ixa+Kwp63f4OHDgzo=" {
		t.Fatal(v)
	}
	if MD5Verifier("pw", "bob") != "md59e8b47dd245ed6fdb3fd1657224800c4" {
		t.Fatal(MD5Verifier("pw", "bob"))
	}
	if saslPrep("pass word­") != "pass word" {
		t.Fatalf("%q", saslPrep("pass word­"))
	}
}

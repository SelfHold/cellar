package pg

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/SelfHold/cellar/core/rpc/pb"
)

// Plan is a change worked out into statements.
type Plan struct {
	// Run are the statements as they run; Show the same with passwords
	// masked (for the preview and the log).
	Run, Show []string
	Warnings  []string
	// Transactional: all statements run in one transaction.
	Transactional bool
	// Database the statements run in ("" = the connection's own).
	Database string
	// Closes are databases whose pools must be closed first (they are
	// renamed or dropped).
	Closes []string
}

func (p *Plan) add(s ...string) {
	p.Run = append(p.Run, s...)
	p.Show = append(p.Show, s...)
}

func (p *Plan) warn(format string, args ...any) {
	p.Warnings = append(p.Warnings, fmt.Sprintf(format, args...))
}

// masked stands for a password in the preview.
const masked = "'********'"

// ErrNoChange is returned by Apply when there is nothing to run.
var ErrNoChange = errors.New("nothing to change")

// Plan works out a change. reveal=false masks passwords (the preview),
// and does not hash them.
func (m *Manager) Plan(ctx context.Context, ch *pb.Change, reveal bool) (*Plan, error) {
	if ch.Op == pb.Change_OP_UNSPECIFIED {
		return nil, errors.New("no operation")
	}
	switch o := ch.Object.(type) {
	case *pb.Change_Role:
		return m.planRole(ctx, ch, o.Role, reveal)
	case *pb.Change_Db:
		return m.planDatabase(ctx, ch, o.Db)
	case *pb.Change_Schema:
		var live *pb.Schema
		if ch.Op != pb.Change_CREATE {
			list, err := m.Schemas(ctx, ch.ConnectionId, ch.Database)
			if err != nil {
				return nil, err
			}
			for _, x := range list.Schemas {
				if x.Name == ch.Original {
					live = x
				}
			}
			if live == nil {
				return nil, fmt.Errorf("schema %s does not exist (any more)", ch.Original)
			}
		}
		p, err := SchemaPlan(ch.Op, live, o.Schema, ch.Cascade)
		if p != nil {
			p.Database = ch.Database
		}
		return p, err
	case *pb.Change_Table:
		var live *pb.ObjectInfo
		if ch.Op == pb.Change_ALTER {
			var err error
			live, err = m.Describe(ctx, &pb.ObjectRef{ConnectionId: ch.ConnectionId, Database: ch.Database, Schema: o.Table.Schema, Name: ch.Original, Kind: pb.DbObject_TABLE})
			if err != nil {
				return nil, err
			}
		}
		if ch.Op == pb.Change_DROP {
			return nil, errors.New("drop a table through its object reference")
		}
		p, err := TablePlan(live, o.Table)
		if p != nil {
			p.Database = ch.Database
		}
		return p, err
	case *pb.Change_Target:
		if ch.Op != pb.Change_DROP {
			return nil, errors.New("objects can only be dropped here")
		}
		p, err := DropObjectPlan(o.Target, ch.Cascade)
		if p != nil {
			p.Database = ch.Database
		}
		return p, err
	}
	return nil, errors.New("no object")
}

// Apply runs a change and returns the statements run (masked).
func (m *Manager) Apply(ctx context.Context, ch *pb.Change) ([]string, error) {
	c, _, err := m.open(ctx, ch.ConnectionId)
	if err != nil {
		return nil, err
	}
	if c.ReadOnly {
		return nil, errors.New("the connection is read-only: change it in its settings first")
	}
	p, err := m.Plan(ctx, ch, true)
	if err != nil {
		return nil, err
	}
	if len(p.Run) == 0 {
		return nil, ErrNoChange
	}
	db := p.Database
	for _, d := range p.Closes {
		m.ResetDatabase(ch.ConnectionId, d)
		// A database cannot be renamed or dropped from a session on it.
		if own := cmp(db, c.Database, "postgres"); own == d {
			db = "postgres"
			if d == "postgres" {
				db = "template1"
			}
		}
	}
	var done []string
	err = m.Acquire(ctx, ch.ConnectionId, db, func(conn *pgx.Conn) error {
		done = done[:0]
		if !p.Transactional {
			for i, s := range p.Run {
				if _, err := conn.Exec(ctx, s); err != nil {
					return stmtErr(p.Show[i], err)
				}
				done = append(done, p.Show[i])
			}
			return nil
		}
		tx, err := conn.Begin(ctx)
		if err != nil {
			return err
		}
		defer tx.Rollback(context.WithoutCancel(ctx))
		for i, s := range p.Run {
			if _, err := tx.Exec(ctx, s); err != nil {
				return stmtErr(p.Show[i], err)
			}
			done = append(done, p.Show[i])
		}
		return tx.Commit(ctx)
	})
	if err != nil {
		return done, err
	}
	return done, nil
}

// cmp returns the first non-empty string.
func cmp(s ...string) string {
	for _, x := range s {
		if x != "" {
			return x
		}
	}
	return ""
}

func stmtErr(stmt string, err error) error {
	first, _, _ := strings.Cut(stmt, "\n")
	if len(first) > 80 {
		first = first[:80] + "…"
	}
	return fmt.Errorf("%s: %w", first, Explain(err))
}

// ResetDatabase closes the pools and consoles on one database of a
// connection.
func (m *Manager) ResetDatabase(connID, db string) {
	m.mu.Lock()
	var pools []*pgxpool.Pool
	var cons []*Console
	for k, p := range m.pools {
		if k.conn == connID && k.db == db {
			delete(m.pools, k)
			pools = append(pools, p)
		}
	}
	for id, c := range m.consoles {
		if c.ConnectionID == connID && c.Database == db {
			cons = append(cons, c)
			delete(m.consoles, id)
		}
	}
	m.mu.Unlock()
	for _, c := range cons {
		c.close()
	}
	// Synchronously: the server must see the sessions end before the
	// database is renamed or dropped.
	for _, p := range pools {
		p.Close()
	}
}

func need(what, name string) error {
	if strings.TrimSpace(name) == "" {
		return fmt.Errorf("the %s needs a name", what)
	}
	return nil
}

func comment(on, target, old, new string) string {
	if old == new {
		return ""
	}
	if new == "" {
		return "COMMENT ON " + on + " " + target + " IS NULL;"
	}
	return "COMMENT ON " + on + " " + target + " IS " + Literal(new) + ";"
}

func addIf(p *Plan, s string) {
	if s != "" {
		p.add(s)
	}
}

// --- roles ---------------------------------------------------------------

func (m *Manager) planRole(ctx context.Context, ch *pb.Change, want *pb.Role, reveal bool) (*Plan, error) {
	var live *pb.Role
	if ch.Op != pb.Change_CREATE {
		list, err := m.Roles(ctx, ch.ConnectionId)
		if err != nil {
			return nil, err
		}
		for _, r := range list.Roles {
			if r.Name == ch.Original {
				live = r
			}
		}
		if live == nil {
			return nil, fmt.Errorf("role %s does not exist (any more)", ch.Original)
		}
	}
	hash := func(pw, user string) (string, error) { return masked, nil }
	if reveal {
		hash = func(pw, user string) (string, error) {
			var enc string
			err := m.Acquire(ctx, ch.ConnectionId, "", func(c *pgx.Conn) error {
				return c.QueryRow(ctx, "SHOW password_encryption").Scan(&enc)
			})
			if err != nil {
				return "", err
			}
			if enc == "md5" || enc == "on" {
				return Literal(MD5Verifier(pw, user)), nil
			}
			v, err := ScramVerifier(pw)
			return Literal(v), err
		}
	}
	return RolePlan(ch.Op, live, want, ch.Cascade, hash)
}

// RolePlan works out a role change; hash turns a new password into the
// literal to send (masked in previews).
func RolePlan(op pb.Change_Op, live, want *pb.Role, cascade bool, hash func(pw, user string) (string, error)) (*Plan, error) {
	p := &Plan{Transactional: true}
	if op == pb.Change_DROP {
		n := Ident(live.Name)
		if cascade {
			p.add("REASSIGN OWNED BY " + n + " TO CURRENT_USER;")
			p.add("DROP OWNED BY " + n + ";")
			p.warn("REASSIGN / DROP OWNED act on the connection's own database only: objects and privileges in other databases still keep the role")
		}
		p.add("DROP ROLE " + n + ";")
		return p, nil
	}
	if err := need("role", want.Name); err != nil {
		return nil, err
	}
	if strings.ContainsAny(want.Password, "\r\n\x00") {
		return nil, errors.New("the password cannot contain line breaks")
	}
	if want.ConnectionLimit < -1 {
		want.ConnectionLimit = -1
	}
	n := Ident(want.Name)
	flag := func(on bool, yes string) string {
		if on {
			return yes
		}
		return "NO" + yes
	}
	type opt struct {
		old, new bool
		word     string
	}
	if op == pb.Change_CREATE {
		var opts []string
		for _, o := range []opt{{false, want.Login, "LOGIN"}, {false, want.Superuser, "SUPERUSER"}, {false, want.CreateDb, "CREATEDB"},
			{false, want.CreateRole, "CREATEROLE"}, {true, want.Inherit, "INHERIT"}, {false, want.Replication, "REPLICATION"}, {false, want.BypassRls, "BYPASSRLS"}} {
			if o.new != o.old {
				opts = append(opts, flag(o.new, o.word))
			}
		}
		if want.ConnectionLimit >= 0 {
			opts = append(opts, fmt.Sprintf("CONNECTION LIMIT %d", want.ConnectionLimit))
		}
		run, show := slices.Clone(opts), slices.Clone(opts)
		if want.Password != "" {
			h, err := hash(want.Password, want.Name)
			if err != nil {
				return nil, err
			}
			run, show = append(run, "PASSWORD "+h), append(show, "PASSWORD "+masked)
		}
		if want.ValidUntil != "" {
			v := "VALID UNTIL " + Literal(want.ValidUntil)
			run, show = append(run, v), append(show, v)
		}
		if len(want.MemberOf) > 0 {
			var gs []string
			for _, g := range want.MemberOf {
				gs = append(gs, Ident(g))
			}
			v := "IN ROLE " + strings.Join(gs, ", ")
			run, show = append(run, v), append(show, v)
		}
		stmt := func(opts []string) string {
			if len(opts) == 0 {
				return "CREATE ROLE " + n + ";"
			}
			return "CREATE ROLE " + n + " WITH\n    " + strings.Join(opts, "\n    ") + ";"
		}
		p.Run, p.Show = append(p.Run, stmt(run)), append(p.Show, stmt(show))
		addIf(p, comment("ROLE", n, "", want.Comment))
		if want.Password != "" && !want.Login {
			p.warn("the role cannot log in (LOGIN is off): its password is not used")
		}
		return p, nil
	}
	// ALTER
	if want.Name != live.Name {
		p.add("ALTER ROLE " + Ident(live.Name) + " RENAME TO " + n + ";")
		if want.Password == "" {
			p.warn("renaming a role clears an md5 password: set the password again if it was md5")
		}
	}
	var opts []string
	for _, o := range []opt{{live.Login, want.Login, "LOGIN"}, {live.Superuser, want.Superuser, "SUPERUSER"}, {live.CreateDb, want.CreateDb, "CREATEDB"},
		{live.CreateRole, want.CreateRole, "CREATEROLE"}, {live.Inherit, want.Inherit, "INHERIT"}, {live.Replication, want.Replication, "REPLICATION"}, {live.BypassRls, want.BypassRls, "BYPASSRLS"}} {
		if o.new != o.old {
			opts = append(opts, flag(o.new, o.word))
		}
	}
	if want.ConnectionLimit != live.ConnectionLimit {
		opts = append(opts, fmt.Sprintf("CONNECTION LIMIT %d", want.ConnectionLimit))
	}
	if want.ValidUntil != live.ValidUntil {
		v := want.ValidUntil
		if v == "" {
			v = "infinity"
		}
		opts = append(opts, "VALID UNTIL "+Literal(v))
	}
	if len(opts) > 0 {
		p.add("ALTER ROLE " + n + " WITH " + strings.Join(opts, " ") + ";")
	}
	if want.Password != "" {
		h, err := hash(want.Password, want.Name)
		if err != nil {
			return nil, err
		}
		p.Run = append(p.Run, "ALTER ROLE "+n+" WITH PASSWORD "+h+";")
		p.Show = append(p.Show, "ALTER ROLE "+n+" WITH PASSWORD "+masked+";")
	}
	for _, g := range want.MemberOf {
		if !slices.Contains(live.MemberOf, g) {
			p.add("GRANT " + Ident(g) + " TO " + n + ";")
		}
	}
	for _, g := range live.MemberOf {
		if !slices.Contains(want.MemberOf, g) {
			p.add("REVOKE " + Ident(g) + " FROM " + n + ";")
		}
	}
	addIf(p, comment("ROLE", n, live.Comment, want.Comment))
	return p, nil
}

// --- databases --------------------------------------------------------------

func (m *Manager) planDatabase(ctx context.Context, ch *pb.Change, want *pb.Database) (*Plan, error) {
	var live *pb.Database
	major := 0
	err := m.Acquire(ctx, ch.ConnectionId, "", func(c *pgx.Conn) error {
		major = Major(c)
		return nil
	})
	if err != nil {
		return nil, err
	}
	if ch.Op != pb.Change_CREATE {
		list, err := m.Databases(ctx, ch.ConnectionId)
		if err != nil {
			return nil, err
		}
		for _, d := range list.Databases {
			if d.Name == ch.Original {
				live = d
			}
		}
		if live == nil {
			return nil, fmt.Errorf("database %s does not exist (any more)", ch.Original)
		}
	}
	return DatabasePlan(ch.Op, live, want, ch.Cascade, major)
}

// DatabasePlan works out a database change (major: the server's version).
func DatabasePlan(op pb.Change_Op, live, want *pb.Database, cascade bool, major int) (*Plan, error) {
	p := &Plan{}
	switch op {
	case pb.Change_DROP:
		n := Ident(live.Name)
		p.Closes = []string{live.Name}
		switch {
		case cascade && major >= 13:
			p.add("DROP DATABASE " + n + " WITH (FORCE);")
		case cascade:
			p.add("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = " + Literal(live.Name) + " AND pid <> pg_backend_pid();")
			p.add("DROP DATABASE " + n + ";")
		default:
			p.add("DROP DATABASE " + n + ";")
		}
		return p, nil
	case pb.Change_CREATE:
		if err := need("database", want.Name); err != nil {
			return nil, err
		}
		n := Ident(want.Name)
		var opts []string
		if want.Owner != "" {
			opts = append(opts, "OWNER = "+Ident(want.Owner))
		}
		tpl := want.Template
		if tpl == "" && (want.Encoding != "" || want.Collate != "" || want.Ctype != "") {
			tpl = "template0" // template1 may have another encoding / locale
		}
		if tpl != "" {
			opts = append(opts, "TEMPLATE = "+Ident(tpl))
		}
		if want.Encoding != "" {
			opts = append(opts, "ENCODING = "+Literal(want.Encoding))
		}
		if want.Collate != "" {
			opts = append(opts, "LC_COLLATE = "+Literal(want.Collate))
		}
		if want.Ctype != "" {
			opts = append(opts, "LC_CTYPE = "+Literal(want.Ctype))
		}
		if want.ConnectionLimit >= 0 {
			opts = append(opts, fmt.Sprintf("CONNECTION LIMIT = %d", want.ConnectionLimit))
		}
		if len(opts) == 0 {
			p.add("CREATE DATABASE " + n + ";")
		} else {
			p.add("CREATE DATABASE " + n + " WITH\n    " + strings.Join(opts, "\n    ") + ";")
		}
		addIf(p, comment("DATABASE", n, "", want.Comment))
		return p, nil
	}
	if err := need("database", want.Name); err != nil {
		return nil, err
	}
	p.Transactional = true
	n := Ident(want.Name)
	if want.Name != live.Name {
		p.add("ALTER DATABASE " + Ident(live.Name) + " RENAME TO " + n + ";")
		p.Closes = []string{live.Name}
		p.warn("renaming needs every other session on %s to end first", live.Name)
	}
	if want.Owner != "" && want.Owner != live.Owner {
		p.add("ALTER DATABASE " + n + " OWNER TO " + Ident(want.Owner) + ";")
	}
	if want.ConnectionLimit < -1 {
		want.ConnectionLimit = -1
	}
	if want.ConnectionLimit != live.ConnectionLimit {
		p.add(fmt.Sprintf("ALTER DATABASE %s WITH CONNECTION LIMIT = %d;", n, want.ConnectionLimit))
	}
	addIf(p, comment("DATABASE", n, live.Comment, want.Comment))
	if want.Encoding != "" && want.Encoding != live.Encoding || want.Collate != "" && want.Collate != live.Collate || want.Ctype != "" && want.Ctype != live.Ctype {
		p.warn("the encoding and locale of an existing database cannot be changed")
	}
	return p, nil
}

// --- schemas ------------------------------------------------------------------

// SchemaPlan works out a schema change.
func SchemaPlan(op pb.Change_Op, live, want *pb.Schema, cascade bool) (*Plan, error) {
	p := &Plan{Transactional: true}
	switch op {
	case pb.Change_DROP:
		s := "DROP SCHEMA " + Ident(live.Name)
		if cascade {
			s += " CASCADE"
		}
		p.add(s + ";")
		return p, nil
	case pb.Change_CREATE:
		if err := need("schema", want.Name); err != nil {
			return nil, err
		}
		n := Ident(want.Name)
		s := "CREATE SCHEMA " + n
		if want.Owner != "" {
			s += " AUTHORIZATION " + Ident(want.Owner)
		}
		p.add(s + ";")
		addIf(p, comment("SCHEMA", n, "", want.Comment))
		return p, nil
	}
	if err := need("schema", want.Name); err != nil {
		return nil, err
	}
	n := Ident(want.Name)
	if want.Name != live.Name {
		p.add("ALTER SCHEMA " + Ident(live.Name) + " RENAME TO " + n + ";")
	}
	if want.Owner != "" && want.Owner != live.Owner {
		p.add("ALTER SCHEMA " + n + " OWNER TO " + Ident(want.Owner) + ";")
	}
	addIf(p, comment("SCHEMA", n, live.Comment, want.Comment))
	return p, nil
}

// --- objects ------------------------------------------------------------------

// DropObjectPlan drops one schema object.
func DropObjectPlan(r *pb.ObjectRef, cascade bool) (*Plan, error) {
	if err := need("object", r.Name); err != nil {
		return nil, err
	}
	qn := Ident(r.Schema) + "." + Ident(r.Name)
	var what string
	switch r.Kind {
	case pb.DbObject_TABLE, pb.DbObject_PARTITIONED_TABLE:
		what = "TABLE " + qn
	case pb.DbObject_VIEW:
		what = "VIEW " + qn
	case pb.DbObject_MATERIALIZED_VIEW:
		what = "MATERIALIZED VIEW " + qn
	case pb.DbObject_FOREIGN_TABLE:
		what = "FOREIGN TABLE " + qn
	case pb.DbObject_SEQUENCE:
		what = "SEQUENCE " + qn
	case pb.DbObject_FUNCTION:
		what = "FUNCTION " + qn + "(" + r.Signature + ")"
	case pb.DbObject_PROCEDURE:
		what = "PROCEDURE " + qn + "(" + r.Signature + ")"
	case pb.DbObject_DOMAIN:
		what = "DOMAIN " + qn
	case pb.DbObject_ENUM, pb.DbObject_COMPOSITE_TYPE, pb.DbObject_RANGE_TYPE:
		what = "TYPE " + qn
	default:
		return nil, errors.New("this kind of object cannot be dropped here")
	}
	s := "DROP " + what
	if cascade {
		s += " CASCADE"
	}
	p := &Plan{Transactional: true}
	p.add(s + ";")
	return p, nil
}

// --- tables -------------------------------------------------------------------

func columnDef(c *pb.ColumnSpec) string {
	s := Ident(c.Name) + " " + strings.TrimSpace(c.Type)
	if d := strings.TrimSpace(c.Default); d != "" {
		s += " DEFAULT " + d
	}
	if !c.Nullable {
		s += " NOT NULL"
	}
	return s
}

func indexStmt(qn string, ix *pb.Index) string {
	def := strings.TrimSpace(strings.TrimSuffix(strings.TrimSpace(ix.Definition), ";"))
	if strings.HasPrefix(strings.ToUpper(def), "CREATE ") {
		return def + ";"
	}
	s := "CREATE "
	if ix.Unique {
		s += "UNIQUE "
	}
	s += "INDEX "
	if ix.Name != "" {
		s += Ident(ix.Name) + " "
	}
	return s + "ON " + qn + " " + def + ";"
}

func sameType(a, b string) bool {
	norm := func(s string) string { return strings.Join(strings.Fields(strings.ToLower(s)), " ") }
	a, b = norm(a), norm(b)
	if a == b {
		return true
	}
	alias := map[string]string{
		"int": "integer", "int4": "integer", "int8": "bigint", "int2": "smallint", "bool": "boolean", "float8": "double precision",
		"float4": "real", "varchar": "character varying", "timestamp": "timestamp without time zone", "timestamptz": "timestamp with time zone",
		"time": "time without time zone", "timetz": "time with time zone", "decimal": "numeric", "char": "character",
	}
	conv := func(s string) string {
		base, rest, _ := strings.Cut(s, "(")
		if v, ok := alias[strings.TrimSpace(base)]; ok {
			if rest != "" {
				// varchar(10) -> character varying(10)
				return v + "(" + rest
			}
			return v
		}
		return s
	}
	return conv(a) == conv(b)
}

func sameDef(a, b string) bool {
	return strings.Join(strings.Fields(a), " ") == strings.Join(strings.Fields(b), " ")
}

// TablePlan works out creating a table (live = nil) or changing one to
// look like want.
func TablePlan(live *pb.ObjectInfo, want *pb.TableSpec) (*Plan, error) {
	if err := need("table", want.Name); err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	for _, c := range want.Columns {
		if err := need("column", c.Name); err != nil {
			return nil, err
		}
		if strings.TrimSpace(c.Type) == "" {
			return nil, fmt.Errorf("column %s needs a type", c.Name)
		}
		if seen[c.Name] {
			return nil, fmt.Errorf("two columns are named %s", c.Name)
		}
		seen[c.Name] = true
	}
	for _, k := range want.PrimaryKey {
		if !seen[k] {
			return nil, fmt.Errorf("the primary key column %s is not in the table", k)
		}
	}
	p := &Plan{Transactional: true}
	qn := Ident(want.Schema) + "." + Ident(want.Name)
	if live == nil {
		var lines []string
		for _, c := range want.Columns {
			lines = append(lines, "    "+columnDef(c))
		}
		if len(want.PrimaryKey) > 0 {
			lines = append(lines, "    PRIMARY KEY ("+identList(want.PrimaryKey)+")")
		}
		for _, k := range want.Constraints {
			if strings.TrimSpace(k.Definition) == "" {
				continue
			}
			l := "    "
			if k.Name != "" {
				l += "CONSTRAINT " + Ident(k.Name) + " "
			}
			lines = append(lines, l+strings.TrimSpace(k.Definition))
		}
		p.add("CREATE TABLE " + qn + " (\n" + strings.Join(lines, ",\n") + "\n);")
		for _, ix := range want.Indexes {
			if strings.TrimSpace(ix.Definition) != "" {
				p.add(indexStmt(qn, ix))
			}
		}
		addIf(p, comment("TABLE", qn, "", want.Comment))
		for _, c := range want.Columns {
			addIf(p, comment("COLUMN", qn+"."+Ident(c.Name), "", c.Comment))
		}
		if want.Owner != "" {
			p.add("ALTER TABLE " + qn + " OWNER TO " + Ident(want.Owner) + ";")
		}
		return p, nil
	}

	// ALTER: rename first, then work on the new name.
	if live.Object.Name != want.Name {
		p.add("ALTER TABLE " + Ident(want.Schema) + "." + Ident(live.Object.Name) + " RENAME TO " + Ident(want.Name) + ";")
	}
	alter := "ALTER TABLE " + qn + " "
	liveCols := map[string]*pb.Column{}
	for _, c := range live.Columns {
		liveCols[c.Name] = c
	}
	kept := map[string]bool{}
	for _, c := range want.Columns {
		if c.Original != "" {
			if liveCols[c.Original] == nil {
				return nil, fmt.Errorf("column %s does not exist (any more)", c.Original)
			}
			kept[c.Original] = true
		}
	}
	pkChanged := !slices.Equal(live.PrimaryKey, want.PrimaryKey)
	// Drops: constraints and indexes that go or change, then columns.
	liveCons := map[string]*pb.Constraint{}
	for _, k := range live.Constraints {
		liveCons[k.Name] = k
		switch {
		case k.Type == "TRIGGER":
		case k.Type == "PRIMARY KEY":
			if pkChanged {
				p.add(alter + "DROP CONSTRAINT " + Ident(k.Name) + ";")
			}
		default:
			i := slices.IndexFunc(want.Constraints, func(w *pb.Constraint) bool { return w.Name == k.Name })
			if i < 0 || !sameDef(want.Constraints[i].Definition, k.Definition) {
				p.add(alter + "DROP CONSTRAINT " + Ident(k.Name) + ";")
			}
		}
	}
	liveIdx := map[string]*pb.Index{}
	for _, ix := range live.Indexes {
		if liveCons[ix.Name] != nil {
			continue // a constraint's own index
		}
		liveIdx[ix.Name] = ix
		i := slices.IndexFunc(want.Indexes, func(w *pb.Index) bool { return w.Name == ix.Name })
		if i < 0 || !sameDef(want.Indexes[i].Definition, ix.Definition) {
			p.add("DROP INDEX " + Ident(want.Schema) + "." + Ident(ix.Name) + ";")
			delete(liveIdx, ix.Name) // created again below when it changed
		}
	}
	for _, c := range live.Columns {
		if !kept[c.Name] {
			p.add(alter + "DROP COLUMN " + Ident(c.Name) + ";")
		}
	}
	for _, c := range want.Columns {
		if c.Original != "" && c.Original != c.Name {
			p.add(alter + "RENAME COLUMN " + Ident(c.Original) + " TO " + Ident(c.Name) + ";")
		}
	}
	for _, c := range want.Columns {
		col := Ident(c.Name)
		if c.Original == "" {
			p.add(alter + "ADD COLUMN " + columnDef(c) + ";")
			continue
		}
		old := liveCols[c.Original]
		if !sameType(old.Type, c.Type) {
			p.add(alter + "ALTER COLUMN " + col + " TYPE " + strings.TrimSpace(c.Type) + ";")
		}
		if !old.Generated && !old.Identity || old.Identity && old.Default != "" {
			// identity columns have no default of their own; serial ones do
			if d := strings.TrimSpace(c.Default); !sameDef(d, old.Default) {
				if d == "" {
					p.add(alter + "ALTER COLUMN " + col + " DROP DEFAULT;")
				} else {
					p.add(alter + "ALTER COLUMN " + col + " SET DEFAULT " + d + ";")
				}
			}
		}
		if c.Nullable != old.Nullable && !(slices.Contains(want.PrimaryKey, c.Name) && c.Nullable) {
			if c.Nullable {
				p.add(alter + "ALTER COLUMN " + col + " DROP NOT NULL;")
			} else {
				p.add(alter + "ALTER COLUMN " + col + " SET NOT NULL;")
			}
		}
	}
	if pkChanged && len(want.PrimaryKey) > 0 {
		p.add(alter + "ADD PRIMARY KEY (" + identList(want.PrimaryKey) + ");")
	}
	for _, k := range want.Constraints {
		if strings.TrimSpace(k.Definition) == "" {
			continue
		}
		if o := liveCons[k.Name]; o != nil && k.Name != "" && sameDef(o.Definition, k.Definition) {
			continue
		}
		s := alter + "ADD "
		if k.Name != "" {
			s += "CONSTRAINT " + Ident(k.Name) + " "
		}
		p.add(s + strings.TrimSpace(k.Definition) + ";")
	}
	for _, ix := range want.Indexes {
		if strings.TrimSpace(ix.Definition) == "" {
			continue
		}
		if ix.Name != "" && liveIdx[ix.Name] != nil {
			continue
		}
		p.add(indexStmt(qn, ix))
	}
	addIf(p, comment("TABLE", qn, live.Object.Comment, want.Comment))
	for _, c := range want.Columns {
		old := ""
		if c.Original != "" {
			old = liveCols[c.Original].Comment
		}
		addIf(p, comment("COLUMN", qn+"."+Ident(c.Name), old, c.Comment))
	}
	if want.Owner != "" && want.Owner != live.Owner {
		p.add(alter + "OWNER TO " + Ident(want.Owner) + ";")
	}
	return p, nil
}

func identList(names []string) string {
	var out []string
	for _, n := range names {
		out = append(out, Ident(n))
	}
	return strings.Join(out, ", ")
}

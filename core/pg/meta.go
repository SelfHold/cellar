package pg

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"

	"github.com/SelfHold/cellar/core/rpc/pb"
)

// Major is the server's major version (16 for "16.4 (Debian ...)", 9
// for "9.6.24").
func Major(c *pgx.Conn) int {
	v := c.PgConn().ParameterStatus("server_version")
	n := 0
	for _, r := range v {
		if r < '0' || r > '9' {
			break
		}
		n = n*10 + int(r-'0')
	}
	return n
}

// Ident quotes an identifier when it needs quotes (upper case, special
// characters, a reserved word).
func Ident(s string) string {
	plain := s != ""
	for i, r := range s {
		if !(r == '_' || r >= 'a' && r <= 'z' || i > 0 && (r >= '0' && r <= '9' || r == '$')) {
			plain = false
			break
		}
	}
	if plain && !reserved[s] {
		return s
	}
	return pgx.Identifier{s}.Sanitize()
}

// reserved are PostgreSQL's reserved key words (and those reserved as
// names of columns and tables).
var reserved = map[string]bool{}

func init() {
	for _, w := range strings.Fields(`all analyse analyze and any array as asc asymmetric authorization binary both case cast check
		collate collation column concurrently constraint create cross current_catalog current_date current_role current_schema
		current_time current_timestamp current_user default deferrable desc distinct do else end except false fetch for foreign
		freeze from full grant group having ilike in initially inner intersect into is isnull join lateral leading left like limit
		localtime localtimestamp natural not notnull null offset on only or order outer overlaps placing primary references
		returning right select session_user similar some symmetric system_user table tablesample then to trailing true union
		unique user using variadic verbose when where window with`) {
		reserved[w] = true
	}
}

// Literal quotes a string literal.
func Literal(s string) string { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }

// Databases lists the databases of the server.
func (m *Manager) Databases(ctx context.Context, connID string) (*pb.DatabaseList, error) {
	out := &pb.DatabaseList{}
	err := m.Acquire(ctx, connID, "", func(c *pgx.Conn) error {
		out.Databases = nil
		out.ServerVersion = c.PgConn().ParameterStatus("server_version")
		rows, err := c.Query(ctx, `SELECT datname, pg_get_userbyid(datdba),
			CASE WHEN has_database_privilege(oid, 'CONNECT') THEN pg_database_size(oid) ELSE -1 END,
			datistemplate, datallowconn AND has_database_privilege(oid, 'CONNECT'),
			pg_encoding_to_char(encoding), datcollate::text, datctype::text, datconnlimit::int4,
			coalesce(shobj_description(oid, 'pg_database'), '')
			FROM pg_database ORDER BY datistemplate, datname`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			d := &pb.Database{}
			if err := rows.Scan(&d.Name, &d.Owner, &d.SizeBytes, &d.IsTemplate, &d.CanConnect,
				&d.Encoding, &d.Collate, &d.Ctype, &d.ConnectionLimit, &d.Comment); err != nil {
				return err
			}
			out.Databases = append(out.Databases, d)
		}
		return rows.Err()
	})
	return out, err
}

// Schemas lists the schemas of a database.
func (m *Manager) Schemas(ctx context.Context, connID, db string) (*pb.SchemaList, error) {
	out := &pb.SchemaList{}
	err := m.Acquire(ctx, connID, db, func(c *pgx.Conn) error {
		out.Schemas = nil
		rows, err := c.Query(ctx, `SELECT nspname, pg_get_userbyid(nspowner),
			coalesce(obj_description(oid, 'pg_namespace'), ''),
			nspname IN ('pg_catalog', 'information_schema') OR nspname LIKE 'pg\_toast%' OR nspname LIKE 'pg\_temp\_%'
			FROM pg_namespace
			WHERE nspname NOT LIKE 'pg\_toast\_temp\_%'
			ORDER BY 4, nspname <> 'public', nspname`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			s := &pb.Schema{}
			if err := rows.Scan(&s.Name, &s.Owner, &s.Comment, &s.System); err != nil {
				return err
			}
			out.Schemas = append(out.Schemas, s)
		}
		return rows.Err()
	})
	return out, err
}

var relKinds = map[string]pb.DbObject_Kind{
	"r": pb.DbObject_TABLE, "v": pb.DbObject_VIEW, "m": pb.DbObject_MATERIALIZED_VIEW,
	"S": pb.DbObject_SEQUENCE, "f": pb.DbObject_FOREIGN_TABLE, "p": pb.DbObject_PARTITIONED_TABLE,
}

// Objects lists the tables, views, sequences and routines of a schema.
func (m *Manager) Objects(ctx context.Context, connID, db, schema string) (*pb.ObjectList, error) {
	out := &pb.ObjectList{}
	err := m.Acquire(ctx, connID, db, func(c *pgx.Conn) error {
		out.Objects = nil
		rows, err := c.Query(ctx, `SELECT c.relname, c.relkind::text, coalesce(obj_description(c.oid, 'pg_class'), ''),
			c.reltuples::int8
			FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
			WHERE n.nspname = `+Literal(schema)+` AND c.relkind IN ('r','v','m','S','f','p') AND NOT c.relispartition
			ORDER BY c.relname`)
		if err != nil {
			return err
		}
		for rows.Next() {
			var name, kind, comment string
			var tuples int64
			if err := rows.Scan(&name, &kind, &comment, &tuples); err != nil {
				rows.Close()
				return err
			}
			out.Objects = append(out.Objects, &pb.DbObject{Kind: relKinds[kind], Name: name, Comment: comment, RowsEstimate: tuples})
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return err
		}
		types, err := userTypes(ctx, c, schema)
		if err != nil {
			return err
		}
		out.Objects = append(out.Objects, types...)
		// prokind: 11+; older servers have only functions.
		prokind := "CASE WHEN p.prokind = 'p' THEN 'p' ELSE 'f' END"
		filter := "p.prokind IN ('f','p','w')"
		if Major(c) < 11 {
			prokind, filter = "'f'", "NOT p.proisagg"
		}
		rows, err = c.Query(ctx, `SELECT p.proname, `+prokind+`, pg_get_function_identity_arguments(p.oid),
			coalesce(obj_description(p.oid, 'pg_proc'), '')
			FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
			WHERE n.nspname = `+Literal(schema)+` AND `+filter+`
			AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.classid = 'pg_proc'::regclass AND d.objid = p.oid AND d.deptype = 'i')
			ORDER BY p.proname, 3`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			var name, kind, sig, comment string
			if err := rows.Scan(&name, &kind, &sig, &comment); err != nil {
				return err
			}
			k := pb.DbObject_FUNCTION
			if kind == "p" {
				k = pb.DbObject_PROCEDURE
			}
			out.Objects = append(out.Objects, &pb.DbObject{Kind: k, Name: name, Signature: sig, Comment: comment, RowsEstimate: -1})
		}
		return rows.Err()
	})
	return out, err
}

var typeKinds = map[string]pb.DbObject_Kind{"e": pb.DbObject_ENUM, "d": pb.DbObject_DOMAIN, "c": pb.DbObject_COMPOSITE_TYPE, "r": pb.DbObject_RANGE_TYPE}

// userTypes lists the enums, domains, composite and range types of a
// schema (not the row types of tables, nor array types).
func userTypes(ctx context.Context, c *pgx.Conn, schema string, name ...string) ([]*pb.DbObject, error) {
	where := ""
	if len(name) > 0 {
		where = " AND t.typname = " + Literal(name[0])
	}
	rows, err := c.Query(ctx, `SELECT t.typname, t.typtype::text, coalesce(obj_description(t.oid, 'pg_type'), ''),
		coalesce((SELECT array_agg(e.enumlabel::text ORDER BY e.enumsortorder) FROM pg_enum e WHERE e.enumtypid = t.oid), '{}'),
		CASE t.typtype WHEN 'd' THEN format_type(t.typbasetype, t.typtypmod)
			WHEN 'r' THEN coalesce((SELECT format_type(r.rngsubtype, NULL) FROM pg_range r WHERE r.rngtypid = t.oid), '')
			ELSE '' END
		FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
		WHERE n.nspname = `+Literal(schema)+where+` AND t.typtype IN ('e','d','c','r')
		AND (t.typtype <> 'c' OR (SELECT cl.relkind FROM pg_class cl WHERE cl.oid = t.typrelid) = 'c')
		ORDER BY t.typname`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*pb.DbObject
	for rows.Next() {
		o := &pb.DbObject{RowsEstimate: -1}
		var kind string
		if err := rows.Scan(&o.Name, &kind, &o.Comment, &o.Labels, &o.BaseType); err != nil {
			return nil, err
		}
		o.Kind = typeKinds[kind]
		out = append(out, o)
	}
	return out, rows.Err()
}

// typeDDL describes a user type: its CREATE statement and, for composite
// types, its attributes as columns.
func typeDDL(ctx context.Context, c *pgx.Conn, r *pb.ObjectRef, out *pb.ObjectInfo) error {
	qn := Ident(r.Schema) + "." + Ident(r.Name)
	ts, err := userTypes(ctx, c, r.Schema, r.Name)
	if err != nil {
		return err
	}
	if len(ts) == 0 {
		return fmt.Errorf("%s does not exist (any more)", qn)
	}
	t := ts[0]
	out.Object = t
	if err := c.QueryRow(ctx, `SELECT pg_get_userbyid(t.typowner) FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
		WHERE n.nspname = `+Literal(r.Schema)+` AND t.typname = `+Literal(r.Name)).Scan(&out.Owner); err != nil {
		return err
	}
	var b strings.Builder
	switch t.Kind {
	case pb.DbObject_ENUM:
		var ls []string
		for _, l := range t.Labels {
			ls = append(ls, "    "+Literal(l))
		}
		b.WriteString("CREATE TYPE " + qn + " AS ENUM (\n" + strings.Join(ls, ",\n") + "\n);")
	case pb.DbObject_DOMAIN:
		var def string
		var notNull bool
		if err := c.QueryRow(ctx, `SELECT coalesce(t.typdefault, ''), t.typnotnull FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND t.typname = `+Literal(r.Name)).Scan(&def, &notNull); err != nil {
			return err
		}
		b.WriteString("CREATE DOMAIN " + qn + " AS " + t.BaseType)
		if def != "" {
			b.WriteString("\n    DEFAULT " + def)
		}
		if notNull {
			b.WriteString("\n    NOT NULL")
		}
		rows, err := c.Query(ctx, `SELECT co.conname, pg_get_constraintdef(co.oid) FROM pg_constraint co
			JOIN pg_type t ON t.oid = co.contypid JOIN pg_namespace n ON n.oid = t.typnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND t.typname = `+Literal(r.Name)+` AND co.contype = 'c' ORDER BY co.conname`)
		if err != nil {
			return err
		}
		for rows.Next() {
			k := &pb.Constraint{Type: "CHECK"}
			if err := rows.Scan(&k.Name, &k.Definition); err != nil {
				rows.Close()
				return err
			}
			out.Constraints = append(out.Constraints, k)
			b.WriteString("\n    CONSTRAINT " + Ident(k.Name) + " " + k.Definition)
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return err
		}
		b.WriteString(";")
	case pb.DbObject_RANGE_TYPE:
		b.WriteString("CREATE TYPE " + qn + " AS RANGE (\n    SUBTYPE = " + t.BaseType + "\n);")
	case pb.DbObject_COMPOSITE_TYPE:
		cols, _, err := columns(ctx, c, r.Schema, r.Name)
		if err != nil {
			return err
		}
		out.Columns = cols
		var ls []string
		for _, col := range cols {
			ls = append(ls, "    "+Ident(col.Name)+" "+col.Type)
		}
		b.WriteString("CREATE TYPE " + qn + " AS (\n" + strings.Join(ls, ",\n") + "\n);")
	}
	if t.Comment != "" {
		kw := "TYPE"
		if t.Kind == pb.DbObject_DOMAIN {
			kw = "DOMAIN"
		}
		b.WriteString("\n\nCOMMENT ON " + kw + " " + qn + " IS " + Literal(t.Comment) + ";")
	}
	out.Ddl = b.String()
	return nil
}

// Roles lists the roles of the server.
func (m *Manager) Roles(ctx context.Context, connID string) (*pb.RoleList, error) {
	out := &pb.RoleList{}
	err := m.Acquire(ctx, connID, "", func(c *pgx.Conn) error {
		out.Roles = nil
		bypass := "r.rolbypassrls"
		if Major(c) < 10 { // 9.5 and 9.6 have it too, older servers do not
			bypass = "false"
		}
		rows, err := c.Query(ctx, `SELECT r.rolname, r.rolcanlogin, r.rolsuper, r.rolcreatedb, r.rolcreaterole, r.rolinherit,
			r.rolreplication, `+bypass+`, r.rolconnlimit::int4, coalesce(r.rolvaliduntil::text, ''),
			coalesce((SELECT array_agg(g.rolname::text ORDER BY g.rolname) FROM pg_auth_members am JOIN pg_roles g ON g.oid = am.roleid
				WHERE am.member = r.oid), '{}'),
			coalesce(shobj_description(r.oid, 'pg_authid'), ''),
			r.rolname LIKE 'pg\_%'
			FROM pg_roles r ORDER BY r.rolname LIKE 'pg\_%', r.rolname`)
		if err != nil {
			return err
		}
		defer rows.Close()
		for rows.Next() {
			x := &pb.Role{}
			if err := rows.Scan(&x.Name, &x.Login, &x.Superuser, &x.CreateDb, &x.CreateRole, &x.Inherit, &x.Replication, &x.BypassRls,
				&x.ConnectionLimit, &x.ValidUntil, &x.MemberOf, &x.Comment, &x.System); err != nil {
				return err
			}
			if x.ValidUntil == "infinity" {
				x.ValidUntil = ""
			}
			out.Roles = append(out.Roles, x)
		}
		return rows.Err()
	})
	return out, err
}

// Columns returns a relation's columns (empty: no such relation).
func columns(ctx context.Context, c *pgx.Conn, schema, name string) ([]*pb.Column, []string, error) {
	generated := "a.attgenerated <> ''"
	if Major(c) < 12 {
		generated = "false"
	}
	rows, err := c.Query(ctx, `SELECT a.attname, format_type(a.atttypid, a.atttypmod), NOT a.attnotnull,
		coalesce(pg_get_expr(d.adbin, d.adrelid), ''), coalesce(col_description(a.attrelid, a.attnum), ''),
		a.atttypid::int8, a.attnum::int4,
		a.attidentity <> '' OR coalesce(pg_get_expr(d.adbin, d.adrelid), '') LIKE 'nextval(%',
		`+generated+`,
		coalesce(a.attnum = ANY(i.indkey), false)
		FROM pg_attribute a
		JOIN pg_class cl ON cl.oid = a.attrelid
		JOIN pg_namespace n ON n.oid = cl.relnamespace
		LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
		LEFT JOIN pg_index i ON i.indrelid = cl.oid AND i.indisprimary
		WHERE n.nspname = `+Literal(schema)+` AND cl.relname = `+Literal(name)+` AND a.attnum > 0 AND NOT a.attisdropped
		ORDER BY a.attnum`)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()
	var cols []*pb.Column
	var pk []string
	for rows.Next() {
		col := &pb.Column{}
		var oid int64
		if err := rows.Scan(&col.Name, &col.Type, &col.Nullable, &col.Default, &col.Comment, &oid, &col.Position, &col.Identity, &col.Generated, &col.PrimaryKey); err != nil {
			return nil, nil, err
		}
		col.TypeOid = uint32(oid)
		if col.PrimaryKey {
			pk = append(pk, col.Name)
		}
		cols = append(cols, col)
	}
	return cols, pk, rows.Err()
}

// Describe returns a relation's or routine's details and DDL.
func (m *Manager) Describe(ctx context.Context, r *pb.ObjectRef) (*pb.ObjectInfo, error) {
	out := &pb.ObjectInfo{}
	err := m.Acquire(ctx, r.ConnectionId, r.Database, func(c *pgx.Conn) error {
		*out = pb.ObjectInfo{Object: &pb.DbObject{Kind: r.Kind, Name: r.Name, Signature: r.Signature}}
		qn := Ident(r.Schema) + "." + Ident(r.Name)
		switch r.Kind {
		case pb.DbObject_FUNCTION, pb.DbObject_PROCEDURE:
			return c.QueryRow(ctx, `SELECT pg_get_functiondef(p.oid), pg_get_userbyid(p.proowner)
				FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
				WHERE n.nspname = `+Literal(r.Schema)+` AND p.proname = `+Literal(r.Name)+`
				AND pg_get_function_identity_arguments(p.oid) = `+Literal(r.Signature)+` LIMIT 1`).Scan(&out.Ddl, &out.Owner)
		case pb.DbObject_SEQUENCE:
			var start, inc, minv, maxv int64
			var cycle bool
			var typ string
			err := c.QueryRow(ctx, `SELECT format_type(s.seqtypid, NULL), s.seqstart, s.seqincrement, s.seqmin, s.seqmax, s.seqcycle,
				pg_get_userbyid(cl.relowner)
				FROM pg_sequence s JOIN pg_class cl ON cl.oid = s.seqrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
				WHERE n.nspname = `+Literal(r.Schema)+` AND cl.relname = `+Literal(r.Name)).Scan(&typ, &start, &inc, &minv, &maxv, &cycle, &out.Owner)
			if err != nil {
				return err
			}
			cyc := "NO CYCLE"
			if cycle {
				cyc = "CYCLE"
			}
			out.Ddl = fmt.Sprintf("CREATE SEQUENCE %s\n    AS %s\n    START WITH %d\n    INCREMENT BY %d\n    MINVALUE %d\n    MAXVALUE %d\n    %s;", qn, typ, start, inc, minv, maxv, cyc)
			return nil
		case pb.DbObject_ENUM, pb.DbObject_DOMAIN, pb.DbObject_COMPOSITE_TYPE, pb.DbObject_RANGE_TYPE:
			return typeDDL(ctx, c, r, out)
		}
		var kind, comment string
		var size int64
		var tuples int64
		err := c.QueryRow(ctx, `SELECT cl.relkind::text, pg_get_userbyid(cl.relowner), coalesce(obj_description(cl.oid, 'pg_class'), ''),
			pg_total_relation_size(cl.oid), cl.reltuples::int8
			FROM pg_class cl JOIN pg_namespace n ON n.oid = cl.relnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND cl.relname = `+Literal(r.Name)).Scan(&kind, &out.Owner, &comment, &size, &tuples)
		if err != nil {
			if err == pgx.ErrNoRows {
				return fmt.Errorf("%s does not exist (any more)", qn)
			}
			return err
		}
		out.Object.Kind, out.Object.Comment, out.Object.RowsEstimate, out.SizeBytes = relKinds[kind], comment, tuples, size
		cols, pk, err := columns(ctx, c, r.Schema, r.Name)
		if err != nil {
			return err
		}
		out.Columns, out.PrimaryKey = cols, pk
		rows, err := c.Query(ctx, `SELECT ic.relname, pg_get_indexdef(i.indexrelid), i.indisunique, i.indisprimary
			FROM pg_index i JOIN pg_class ic ON ic.oid = i.indexrelid
			JOIN pg_class cl ON cl.oid = i.indrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND cl.relname = `+Literal(r.Name)+` ORDER BY i.indisprimary DESC, ic.relname`)
		if err != nil {
			return err
		}
		for rows.Next() {
			ix := &pb.Index{}
			if err := rows.Scan(&ix.Name, &ix.Definition, &ix.Unique, &ix.Primary); err != nil {
				rows.Close()
				return err
			}
			out.Indexes = append(out.Indexes, ix)
		}
		rows.Close()
		rows, err = c.Query(ctx, `SELECT co.conname, co.contype::text, pg_get_constraintdef(co.oid)
			FROM pg_constraint co JOIN pg_class cl ON cl.oid = co.conrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND cl.relname = `+Literal(r.Name)+`
			ORDER BY CASE co.contype WHEN 'p' THEN 0 WHEN 'u' THEN 1 WHEN 'f' THEN 2 ELSE 3 END, co.conname`)
		if err != nil {
			return err
		}
		for rows.Next() {
			k := &pb.Constraint{}
			var t string
			if err := rows.Scan(&k.Name, &t, &k.Definition); err != nil {
				rows.Close()
				return err
			}
			k.Type = map[string]string{"p": "PRIMARY KEY", "f": "FOREIGN KEY", "u": "UNIQUE", "c": "CHECK", "x": "EXCLUDE", "t": "TRIGGER", "n": "NOT NULL"}[t]
			if k.Type == "NOT NULL" {
				continue // shown on the column
			}
			out.Constraints = append(out.Constraints, k)
		}
		rows.Close()
		rows, err = c.Query(ctx, `SELECT t.tgname, pg_get_triggerdef(t.oid, true), t.tgenabled <> 'D'
			FROM pg_trigger t JOIN pg_class cl ON cl.oid = t.tgrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND cl.relname = `+Literal(r.Name)+` AND NOT t.tgisinternal ORDER BY t.tgname`)
		if err != nil {
			return err
		}
		for rows.Next() {
			tg := &pb.Trigger{}
			if err := rows.Scan(&tg.Name, &tg.Definition, &tg.Enabled); err != nil {
				rows.Close()
				return err
			}
			out.Triggers = append(out.Triggers, tg)
		}
		rows.Close()
		switch kind {
		case "v", "m":
			var def string
			if err := c.QueryRow(ctx, `SELECT pg_get_viewdef(`+Literal(qn)+`::regclass, true)`).Scan(&def); err != nil {
				return err
			}
			mat := ""
			if kind == "m" {
				mat = "MATERIALIZED "
			}
			out.Ddl = "CREATE " + mat + "VIEW " + qn + " AS\n" + strings.TrimRight(def, "\n; ") + ";"
		default:
			out.Ddl = tableDDL(qn, kind, out)
		}
		return nil
	})
	return out, err
}

func tableDDL(qn, kind string, info *pb.ObjectInfo) string {
	var b strings.Builder
	switch kind {
	case "f":
		b.WriteString("CREATE FOREIGN TABLE ")
	default:
		b.WriteString("CREATE TABLE ")
	}
	b.WriteString(qn + " (\n")
	var lines []string
	for _, c := range info.Columns {
		l := "    " + Ident(c.Name) + " " + c.Type
		if c.Default != "" && !c.Generated {
			l += " DEFAULT " + c.Default
		}
		if c.Generated {
			l += " GENERATED ALWAYS AS (" + c.Default + ") STORED"
		}
		if !c.Nullable {
			l += " NOT NULL"
		}
		lines = append(lines, l)
	}
	for _, k := range info.Constraints {
		if k.Type == "TRIGGER" {
			continue
		}
		lines = append(lines, "    CONSTRAINT "+Ident(k.Name)+" "+k.Definition)
	}
	b.WriteString(strings.Join(lines, ",\n"))
	b.WriteString("\n);")
	for _, ix := range info.Indexes {
		owned := false
		for _, k := range info.Constraints {
			if k.Name == ix.Name {
				owned = true
			}
		}
		if !owned {
			b.WriteString("\n\n" + ix.Definition + ";")
		}
	}
	if info.Object.Comment != "" {
		b.WriteString("\n\nCOMMENT ON TABLE " + qn + " IS " + Literal(info.Object.Comment) + ";")
	}
	for _, c := range info.Columns {
		if c.Comment != "" {
			b.WriteString("\nCOMMENT ON COLUMN " + qn + "." + Ident(c.Name) + " IS " + Literal(c.Comment) + ";")
		}
	}
	for i, t := range info.Triggers {
		if i == 0 {
			b.WriteString("\n")
		}
		b.WriteString("\n" + t.Definition + ";")
	}
	return b.String()
}

package pg

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"dbmanager/core/rpc/pb"
)

// ReadTable returns one page of a table or view. Rows of a table without a
// primary key carry their ctid (a hidden first column) so edits can name
// them.
func (m *Manager) ReadTable(ctx context.Context, r *pb.ReadTableRequest) (*pb.ResultSet, error) {
	limit := int(r.Limit)
	if limit <= 0 {
		limit = 500
	}
	limit = min(limit, 10000)
	var out *pb.ResultSet
	err := m.Acquire(ctx, r.ConnectionId, r.Database, func(c *pgx.Conn) error {
		cols, pk, err := columns(ctx, c, r.Schema, r.Table)
		if err != nil {
			return err
		}
		if len(cols) == 0 {
			return fmt.Errorf("%s.%s does not exist (any more)", r.Schema, r.Table)
		}
		var kind string
		var tuples int64
		if err := c.QueryRow(ctx, `SELECT cl.relkind::text, cl.reltuples::int8 FROM pg_class cl JOIN pg_namespace n ON n.oid = cl.relnamespace
			WHERE n.nspname = `+Literal(r.Schema)+` AND cl.relname = `+Literal(r.Table)).Scan(&kind, &tuples); err != nil {
			return err
		}
		known := map[string]bool{}
		for _, col := range cols {
			known[col.Name] = true
		}
		// ctid only where rows have one (tables, matviews).
		useCtid := len(pk) == 0 && (kind == "r" || kind == "m" || kind == "p")
		sel := "SELECT "
		if useCtid {
			sel += "ctid, "
		}
		names := make([]string, len(cols))
		for i, col := range cols {
			names[i] = Ident(col.Name)
		}
		q := sel + strings.Join(names, ", ") + " FROM " + Ident(r.Schema) + "." + Ident(r.Table)
		if f := strings.TrimSpace(r.Filter); f != "" {
			if strings.Contains(f, ";") && len(Split(f)) > 1 {
				return errors.New("the filter must be one condition")
			}
			// A "--" comment in the filter ends at the newline, so it
			// cannot hide the LIMIT.
			q += " WHERE (" + f + "\n)"
		}
		var order []string
		for _, s := range r.Sort {
			if !known[s.Column] {
				return fmt.Errorf("no column %q", s.Column)
			}
			o := Ident(s.Column)
			if s.Desc {
				o += " DESC"
			}
			order = append(order, o)
		}
		if len(order) == 0 && len(pk) > 0 {
			for _, k := range pk {
				order = append(order, Ident(k))
			}
		}
		if len(order) > 0 {
			q += " ORDER BY " + strings.Join(order, ", ")
		}
		q += " LIMIT " + strconv.Itoa(limit+1)
		if r.Offset > 0 {
			q += " OFFSET " + strconv.FormatInt(r.Offset, 10)
		}
		t0 := time.Now()
		res := c.PgConn().Exec(ctx, q)
		results, err := res.ReadAll()
		if err != nil {
			return err
		}
		if len(results) != 1 {
			return errors.New("unexpected answer")
		}
		rr := results[0]
		if rr.Err != nil {
			return rr.Err
		}
		out = &pb.ResultSet{Statement: q, DurationMs: time.Since(t0).Milliseconds(), TotalEstimate: tuples, KeyColumns: pk, HasCtid: useCtid, ErrorOffset: -1}
		if useCtid {
			out.KeyColumns = []string{"ctid"}
			out.Columns = append(out.Columns, &pb.ResultColumn{Name: "ctid", Type: "tid", TypeOid: 27})
		}
		for _, col := range cols {
			out.Columns = append(out.Columns, &pb.ResultColumn{Name: col.Name, Type: col.Type, TypeOid: col.TypeOid, TableColumn: col.Name})
		}
		for i, row := range rr.Rows {
			if i == limit {
				out.Truncated = true
				break
			}
			out.Rows = append(out.Rows, rowOf(row))
		}
		out.CommandTag = rr.CommandTag.String()
		if kind == "v" || tuples < 0 {
			out.TotalEstimate = -1
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// ApplyEdits runs the edits in one transaction. An UPDATE or DELETE that
// does not hit exactly one row rolls everything back: the row changed or
// its key is not unique.
func (m *Manager) ApplyEdits(ctx context.Context, r *pb.EditRequest) (*pb.EditReply, error) {
	if len(r.Edits) == 0 {
		return &pb.EditReply{}, nil
	}
	out := &pb.EditReply{}
	err := m.Acquire(ctx, r.ConnectionId, r.Database, func(c *pgx.Conn) error {
		out.Statements, out.RowsAffected = nil, 0
		pc := c.PgConn()
		if _, err := pc.Exec(ctx, "BEGIN").ReadAll(); err != nil {
			return err
		}
		ok := false
		defer func() {
			if !ok {
				pc.Exec(context.WithoutCancel(ctx), "ROLLBACK").ReadAll()
			}
		}()
		table := Ident(r.Schema) + "." + Ident(r.Table)
		for i, e := range r.Edits {
			q, args, err := editSQL(table, e)
			if err != nil {
				return fmt.Errorf("change %d: %w", i+1, err)
			}
			res := pc.ExecParams(ctx, q, args, nil, nil, nil).Read()
			if res.Err != nil {
				return fmt.Errorf("change %d (%s): %w", i+1, q, res.Err)
			}
			n := res.CommandTag.RowsAffected()
			if e.Op != pb.RowEdit_INSERT && n != 1 {
				return fmt.Errorf("change %d hit %d rows instead of one: the row changed meanwhile, or its key is not unique; nothing was saved", i+1, n)
			}
			out.RowsAffected += n
			out.Statements = append(out.Statements, q)
		}
		if _, err := pc.Exec(ctx, "COMMIT").ReadAll(); err != nil {
			return err
		}
		ok = true
		return nil
	})
	return out, err
}

func editSQL(table string, e *pb.RowEdit) (string, [][]byte, error) {
	var args [][]byte
	param := func(v *pb.Cell) string {
		if v == nil || v.Null {
			args = append(args, nil)
		} else {
			args = append(args, []byte(v.Text))
		}
		return "$" + strconv.Itoa(len(args))
	}
	where := func() (string, error) {
		if len(e.Key) == 0 {
			return "", errors.New("the row has no key")
		}
		var parts []string
		for _, k := range e.Key {
			if k.Column == "ctid" {
				parts = append(parts, "ctid = "+param(k.Value)+"::tid")
				continue
			}
			if k.Value == nil || k.Value.Null {
				parts = append(parts, Ident(k.Column)+" IS NULL")
				continue
			}
			parts = append(parts, Ident(k.Column)+" = "+param(k.Value))
		}
		return strings.Join(parts, " AND "), nil
	}
	switch e.Op {
	case pb.RowEdit_INSERT:
		var cols, vals []string
		for _, v := range e.Values {
			cols = append(cols, Ident(v.Column))
			if v.UseDefault {
				vals = append(vals, "DEFAULT")
			} else {
				vals = append(vals, param(v.Value))
			}
		}
		if len(cols) == 0 {
			return "INSERT INTO " + table + " DEFAULT VALUES", nil, nil
		}
		return "INSERT INTO " + table + " (" + strings.Join(cols, ", ") + ") VALUES (" + strings.Join(vals, ", ") + ")", args, nil
	case pb.RowEdit_UPDATE:
		if len(e.Values) == 0 {
			return "", nil, errors.New("nothing to change")
		}
		var sets []string
		for _, v := range e.Values {
			if v.UseDefault {
				sets = append(sets, Ident(v.Column)+" = DEFAULT")
			} else {
				sets = append(sets, Ident(v.Column)+" = "+param(v.Value))
			}
		}
		w, err := where()
		if err != nil {
			return "", nil, err
		}
		return "UPDATE " + table + " SET " + strings.Join(sets, ", ") + " WHERE " + w, args, nil
	case pb.RowEdit_DELETE:
		w, err := where()
		if err != nil {
			return "", nil, err
		}
		return "DELETE FROM " + table + " WHERE " + w, args, nil
	}
	return "", nil, fmt.Errorf("unknown change %v", e.Op)
}

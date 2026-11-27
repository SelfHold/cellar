package pg

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"sync"
	"time"
	"unicode/utf16"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/SelfHold/cellar/core/rpc/pb"
	"github.com/SelfHold/cellar/core/store"
)

// Console is one pinned session: what a statement leaves behind
// (transactions, SET, temporary tables) stays for the next one.
type Console struct {
	ID           string
	ConnectionID string
	Database     string

	m       *Manager
	mu      sync.Mutex // one statement at a time
	cmu     sync.Mutex // conn, notices
	conn    *pgx.Conn
	notices []string
	closed  bool
	types   map[uint32]string
}

// OpenConsole starts a session on a database.
func (m *Manager) OpenConsole(ctx context.Context, connID, db string) (*Console, error) {
	c := &Console{ID: store.NewID(), ConnectionID: connID, Database: db, m: m, types: map[uint32]string{}}
	if _, err := c.connect(ctx); err != nil {
		return nil, err
	}
	m.mu.Lock()
	m.consoles[c.ID] = c
	m.mu.Unlock()
	return c, nil
}

// Console returns an open console.
func (m *Manager) Console(id string) (*Console, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	c, ok := m.consoles[id]
	if !ok {
		return nil, errors.New("the console is closed: open it again")
	}
	return c, nil
}

// CloseConsole ends a console's session.
func (m *Manager) CloseConsole(id string) {
	m.mu.Lock()
	c := m.consoles[id]
	delete(m.consoles, id)
	m.mu.Unlock()
	if c != nil {
		c.close()
	}
}

func (c *Console) connect(ctx context.Context) (*pgx.Conn, error) {
	sc, dial, err := c.m.open(ctx, c.ConnectionID)
	if err != nil {
		return nil, err
	}
	db := c.Database
	if db == "" {
		db = sc.Database
	}
	cfg, err := Config(sc, db, dial)
	if err != nil {
		return nil, err
	}
	cfg.OnNotice = func(_ *pgconn.PgConn, n *pgconn.Notice) {
		c.cmu.Lock()
		if len(c.notices) < 200 {
			c.notices = append(c.notices, n.Severity+": "+n.Message)
		}
		c.cmu.Unlock()
	}
	conn, err := pgx.ConnectConfig(ctx, cfg)
	if err != nil {
		return nil, Explain(err)
	}
	c.cmu.Lock()
	if c.closed {
		c.cmu.Unlock()
		conn.Close(context.Background())
		return nil, errors.New("the console is closed")
	}
	c.conn = conn
	c.cmu.Unlock()
	return conn, nil
}

// Info describes the session.
func (c *Console) Info() *pb.Console {
	c.cmu.Lock()
	defer c.cmu.Unlock()
	out := &pb.Console{Id: c.ID, ConnectionId: c.ConnectionID, Database: c.Database}
	if c.conn != nil {
		out.ServerVersion = c.conn.PgConn().ParameterStatus("server_version")
		out.BackendPid = int32(c.conn.PgConn().PID())
	}
	return out
}

func (c *Console) close() {
	c.cmu.Lock()
	c.closed = true
	conn := c.conn
	c.conn = nil
	c.cmu.Unlock()
	if conn != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		conn.Close(ctx)
		cancel()
	}
}

// Cancel asks the server to stop the running statement.
func (c *Console) Cancel(ctx context.Context) error {
	c.cmu.Lock()
	conn := c.conn
	c.cmu.Unlock()
	if conn == nil {
		return nil
	}
	return conn.PgConn().CancelRequest(ctx)
}

// Execute runs statements of sql: all of them (stopping at the first
// error), or the one at cursor (UTF-16 offset).
func (c *Console) Execute(ctx context.Context, sql string, all bool, cursor int, maxRows int) (*pb.ExecuteReply, error) {
	if maxRows <= 0 {
		maxRows = 1000
	}
	stmts := Split(sql)
	if !all {
		s, ok := At(stmts, cursor)
		if !ok {
			return nil, errors.New("there is no statement to run")
		}
		stmts = []Stmt{s}
	}
	if len(stmts) == 0 {
		return nil, errors.New("there is no statement to run")
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	c.cmu.Lock()
	conn := c.conn
	c.cmu.Unlock()
	reply := &pb.ExecuteReply{}
	start := time.Now()
	var reconnected bool
	if conn == nil || conn.IsClosed() {
		var err error
		if conn, err = c.connect(ctx); err != nil {
			return nil, err
		}
		reconnected = true
	}
	for i, st := range stmts {
		rs, err := c.run(ctx, conn, st, maxRows)
		if err != nil && i == 0 && !reconnected && conn.IsClosed() && pgconn.SafeToRetry(err) {
			// The session was gone before the statement left (the SSH
			// connection dropped): open it again and run it there.
			if conn, err = c.connect(ctx); err != nil {
				return nil, err
			}
			reconnected = true
			rs, _ = c.run(ctx, conn, st, maxRows)
		}
		if i == 0 && reconnected {
			rs.Notices = append([]string{"NOTICE: the session was opened again (the previous one was lost): transactions and settings of it are gone"}, rs.Notices...)
		}
		reply.Results = append(reply.Results, rs)
		if rs.Error != "" {
			break
		}
	}
	c.fillTypes(ctx, conn, reply.Results)
	reply.DurationMs = time.Since(start).Milliseconds()
	switch conn.PgConn().TxStatus() {
	case 'T':
		reply.TxStatus = "transaction"
	case 'E':
		reply.TxStatus = "failed"
	default:
		reply.TxStatus = "idle"
	}
	return reply, nil
}

func (c *Console) run(ctx context.Context, conn *pgx.Conn, st Stmt, maxRows int) (*pb.ResultSet, error) {
	rs := &pb.ResultSet{Statement: st.Text, StatementStart: int32(st.Start16), StatementEnd: int32(st.End16), ErrorOffset: -1}
	t0 := time.Now()
	mrr := conn.PgConn().Exec(ctx, st.Text)
	var tags []string
	var affected int64
	var first error
	for mrr.NextResult() {
		rr := mrr.ResultReader()
		fds := rr.FieldDescriptions()
		if len(fds) > 0 {
			// A later result with rows replaces an earlier one.
			rs.Columns, rs.Rows, rs.Truncated = columnsOf(fds), nil, false
		}
		var n int
		for rr.NextRow() {
			if n < maxRows {
				rs.Rows = append(rs.Rows, rowOf(rr.Values()))
			} else {
				rs.Truncated = true
			}
			n++
		}
		tag, err := rr.Close()
		if err != nil {
			setError(rs, err, st)
			first = err
			break
		}
		tags = append(tags, tag.String())
		affected += tag.RowsAffected()
	}
	if err := mrr.Close(); err != nil && rs.Error == "" {
		setError(rs, err, st)
		first = err
	}
	if len(tags) > 0 {
		rs.CommandTag = tags[len(tags)-1]
	}
	rs.RowsAffected = affected
	rs.DurationMs = time.Since(t0).Milliseconds()
	c.cmu.Lock()
	rs.Notices = append(rs.Notices, c.notices...)
	c.notices = nil
	c.cmu.Unlock()
	return rs, first
}

func setError(rs *pb.ResultSet, err error, st Stmt) {
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		rs.Error = pe.Severity + ": " + pe.Message
		if pe.Code != "" {
			rs.Error += " (" + pe.Code + ")"
		}
		detail := ""
		if pe.Detail != "" {
			detail += "Detail: " + pe.Detail + "\n"
		}
		if pe.Hint != "" {
			detail += "Hint: " + pe.Hint + "\n"
		}
		if pe.Where != "" {
			detail += "Where: " + pe.Where + "\n"
		}
		rs.ErrorDetail = trimNL(detail)
		if pe.Position > 0 {
			// Position counts characters of the statement, from 1.
			off16, chars := 0, 0
			for _, r := range st.Text {
				if chars >= int(pe.Position)-1 {
					break
				}
				off16 += utf16.RuneLen(r)
				chars++
			}
			rs.ErrorOffset = int32(st.Start16 + off16)
		}
		return
	}
	rs.Error = Explain(err).Error()
}

func trimNL(s string) string {
	for len(s) > 0 && s[len(s)-1] == '\n' {
		s = s[:len(s)-1]
	}
	return s
}

func columnsOf(fds []pgconn.FieldDescription) []*pb.ResultColumn {
	out := make([]*pb.ResultColumn, len(fds))
	for i, f := range fds {
		out[i] = &pb.ResultColumn{Name: f.Name, TypeOid: f.DataTypeOID}
	}
	return out
}

func rowOf(vals [][]byte) *pb.Row {
	r := &pb.Row{Cells: make([]*pb.Cell, len(vals))}
	for i, v := range vals {
		if v == nil {
			r.Cells[i] = &pb.Cell{Null: true}
		} else {
			r.Cells[i] = &pb.Cell{Text: string(v)}
		}
	}
	return r
}

// fillTypes names the column types (format_type), cached per session.
func (c *Console) fillTypes(ctx context.Context, conn *pgx.Conn, results []*pb.ResultSet) {
	nameTypes(ctx, conn, c.types, results)
}

func nameTypes(ctx context.Context, conn *pgx.Conn, cache map[uint32]string, results []*pb.ResultSet) {
	var missing []uint32
	seen := map[uint32]bool{}
	for _, rs := range results {
		for _, col := range rs.Columns {
			if _, ok := cache[col.TypeOid]; !ok && !seen[col.TypeOid] {
				if t, ok := conn.TypeMap().TypeForOID(col.TypeOid); ok {
					cache[col.TypeOid] = t.Name
					continue
				}
				seen[col.TypeOid] = true
				missing = append(missing, col.TypeOid)
			}
		}
	}
	if len(missing) > 0 && conn.PgConn().TxStatus() != 'E' {
		q := "SELECT oid::int8, format_type(oid, NULL) FROM pg_type WHERE oid IN ("
		for i, o := range missing {
			if i > 0 {
				q += ","
			}
			q += strconv.FormatUint(uint64(o), 10)
		}
		q += ")"
		rows, err := conn.Query(ctx, q)
		if err == nil {
			for rows.Next() {
				var oid int64
				var name string
				if rows.Scan(&oid, &name) == nil {
					cache[uint32(oid)] = name
				}
			}
			rows.Close()
		}
	}
	for _, rs := range results {
		for _, col := range rs.Columns {
			if n, ok := cache[col.TypeOid]; ok {
				col.Type = n
			} else {
				col.Type = fmt.Sprintf("oid %d", col.TypeOid)
			}
		}
	}
}

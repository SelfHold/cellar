package rpc

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/jackc/pgx/v5"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/SelfHold/cellar/core/dump"
	"github.com/SelfHold/cellar/core/pg"
	"github.com/SelfHold/cellar/core/rpc/pb"
	"github.com/SelfHold/cellar/core/store"
)

// LocalTools finds the tools on this device; tests replace it.
var LocalTools = dump.LocalTools

// serverMajor is the database server's major version.
func (s *Service) serverMajor(ctx context.Context, connID, db string) (int, string, error) {
	var major int
	var ver string
	err := s.PG.Acquire(ctx, connID, db, func(c *pgx.Conn) error {
		major, ver = pg.Major(c), c.PgConn().ParameterStatus("server_version")
		return nil
	})
	return major, ver, err
}

// tools lists the tools of this device and, for a connection through a
// server, of the server. A server that cannot be asked is a note.
func (s *Service) tools(ctx context.Context, c store.Connection) ([]dump.Tool, string) {
	tools := LocalTools(ctx)
	note := ""
	if c.ServerID != "" {
		cl, err := s.client(ctx, c.ServerID)
		if err == nil {
			var rt []dump.Tool
			if rt, err = dump.RemoteTools(ctx, cl.Client); err == nil {
				tools = append(tools, rt...)
			}
		}
		if err != nil {
			note = "the server's tools: " + errText(err)
		}
	}
	return tools, note
}

func toolPB(t dump.Tool, major int) *pb.DumpTool {
	place := pb.ToolPlace_LOCAL
	if t.Place == dump.Remote {
		place = pb.ToolPlace_REMOTE
	}
	return &pb.DumpTool{Place: place, Path: t.Path, Version: t.Version, Major: int32(t.Major), Fits: major == 0 || t.Major >= major}
}

func placeOf(p pb.ToolPlace) dump.Place {
	switch p {
	case pb.ToolPlace_LOCAL:
		return dump.Local
	case pb.ToolPlace_REMOTE:
		return dump.Remote
	}
	return dump.Auto
}

func (s *Service) DumpTools(ctx context.Context, r *pb.Ref) (*pb.DumpToolsReply, error) {
	c, err := s.Store.Connection(r.Id)
	if err != nil {
		return nil, status.Error(codes.NotFound, "no such connection")
	}
	major, ver, err := s.serverMajor(ctx, r.Id, "")
	if err != nil {
		return nil, grpcErr(err)
	}
	tools, note := s.tools(ctx, c)
	out := &pb.DumpToolsReply{ServerVersion: ver, Note: note}
	for _, t := range tools {
		out.Tools = append(out.Tools, toolPB(t, major))
	}
	if _, err := dump.Choose(tools, dump.Auto, major, true); err != nil {
		out.Note = err.Error()
	}
	return out, nil
}

// target prepares a run: the connection, where its tools run.
func (s *Service) target(ctx context.Context, connID, db string, place pb.ToolPlace, dumping bool) (dump.Tool, dump.Target, error) {
	c, err := s.Store.Connection(connID)
	if err != nil {
		return dump.Tool{}, dump.Target{}, status.Error(codes.NotFound, "no such connection")
	}
	major, _, err := s.serverMajor(ctx, connID, db)
	if err != nil {
		return dump.Tool{}, dump.Target{}, err
	}
	tools, note := s.tools(ctx, c)
	tool, err := dump.Choose(tools, placeOf(place), major, dumping)
	if err != nil {
		if note != "" && placeOf(place) != dump.Local {
			err = fmt.Errorf("%w; %s", err, note)
		}
		return dump.Tool{}, dump.Target{}, status.Error(codes.FailedPrecondition, err.Error())
	}
	t := dump.Target{Conn: c, Database: db}
	if c.ServerID != "" {
		t.Dial = s.dialer(c.ServerID)
		if tool.Place == dump.Remote {
			cl, err := s.client(ctx, c.ServerID)
			if err != nil {
				return dump.Tool{}, dump.Target{}, err
			}
			t.SSH = cl.Client
		}
	}
	return tool, t, nil
}

// stream reports a job's progress until it ends; the job's error goes in
// the last message (the log above it explains it).
func stream(ctx context.Context, st grpc.ServerStreamingServer[pb.DumpProgress], first *pb.DumpProgress, prog *dump.Progress, run func(context.Context) error) error {
	if err := st.Send(first); err != nil {
		return err
	}
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	done := make(chan error, 1)
	go func() { done <- run(ctx) }()
	tick := time.NewTicker(300 * time.Millisecond)
	defer tick.Stop()
	var last int64 = -1
	for {
		select {
		case err := <-done:
			b, total, log := prog.Take()
			msg := &pb.DumpProgress{Bytes: b, Total: total, Log: log, Done: true}
			if err != nil {
				if errors.Is(err, context.Canceled) {
					return status.Error(codes.Canceled, "cancelled")
				}
				msg.Error = pg.Explain(err).Error()
			}
			return st.Send(msg)
		case <-tick.C:
			b, total, log := prog.Take()
			if b == last && len(log) == 0 {
				continue
			}
			last = b
			if err := st.Send(&pb.DumpProgress{Bytes: b, Total: total, Log: log}); err != nil {
				cancel()
				<-done
				return err
			}
		}
	}
}

func describe(t dump.Tool, name string) string {
	return fmt.Sprintf("%s %s %s", name, t.Version, t.Place)
}

func (s *Service) Dump(r *pb.DumpRequest, st grpc.ServerStreamingServer[pb.DumpProgress]) error {
	ctx := st.Context()
	if !filepath.IsAbs(r.Path) {
		return status.Error(codes.InvalidArgument, "choose where to save the dump")
	}
	tool, t, err := s.target(ctx, r.ConnectionId, r.Database, r.Place, true)
	if err != nil {
		return grpcErr(err)
	}
	o := dump.DumpOptions{
		Format:  map[pb.DumpRequest_Format]dump.Format{pb.DumpRequest_CUSTOM: dump.Custom, pb.DumpRequest_TAR: dump.Tar}[r.Format],
		Schemas: r.Schemas, SchemaOnly: r.SchemaOnly, DataOnly: r.DataOnly, NoOwner: r.NoOwner, NoPrivileges: r.NoPrivileges,
		Clean: r.Clean, Create: r.CreateDatabase, Inserts: r.Inserts,
	}
	for _, x := range r.Tables {
		o.Tables = append(o.Tables, dump.Table{Schema: x.Schema, Name: x.Name})
	}
	prog := &dump.Progress{}
	s.logf("info", "dump of %s/%s with %s", r.ConnectionId, r.Database, describe(tool, "pg_dump"))
	return stream(ctx, st, &pb.DumpProgress{Tool: describe(tool, "pg_dump"), Format: o.Format.String()}, prog, func(ctx context.Context) error {
		return dump.Dump(ctx, tool, t, o, r.Path, prog)
	})
}

func (s *Service) Restore(r *pb.RestoreRequest, st grpc.ServerStreamingServer[pb.DumpProgress]) error {
	ctx := st.Context()
	if c, err := s.Store.Connection(r.ConnectionId); err == nil && c.ReadOnly {
		return status.Error(codes.FailedPrecondition, "the connection is read-only: change it in its settings first")
	}
	if !filepath.IsAbs(r.Path) {
		return status.Error(codes.InvalidArgument, "choose the dump file")
	}
	head, err := readHead(r.Path)
	if err != nil {
		return status.Error(codes.InvalidArgument, err.Error())
	}
	format := dump.Detect(head)
	tool, t, err := s.target(ctx, r.ConnectionId, r.Database, r.Place, false)
	if err != nil {
		return grpcErr(err)
	}
	o := dump.RestoreOptions{Clean: r.Clean, NoOwner: r.NoOwner, NoPrivileges: r.NoPrivileges, SingleTransaction: r.SingleTransaction,
		SchemaOnly: r.SchemaOnly, DataOnly: r.DataOnly, Create: r.CreateDatabase, ExitOnError: r.ExitOnError}
	name, _ := dump.RestoreArgs(format, o, "")
	prog := &dump.Progress{}
	s.logf("info", "restore into %s/%s with %s", r.ConnectionId, r.Database, describe(tool, name))
	return stream(ctx, st, &pb.DumpProgress{Tool: describe(tool, name), Format: format.String()}, prog, func(ctx context.Context) error {
		_, err := dump.Restore(ctx, tool, t, o, r.Path, prog)
		return err
	})
}

// readHead reads the first bytes of a file (its format).
func readHead(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	b := make([]byte, 512)
	n, err := io.ReadFull(f, b)
	if err != nil && !errors.Is(err, io.ErrUnexpectedEOF) && !errors.Is(err, io.EOF) {
		return nil, err
	}
	if n == 0 {
		return nil, errors.New("the file is empty")
	}
	return b[:n], nil
}

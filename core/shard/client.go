// Package shard connects Cellar to Shard (CONNECTOR.md,
// § 13–14 for the scopes below): a client of Shard's Connector API — gRPC over
// Shard's socket on desktops, its bound service on Android (through
// the app, Binder) — and the Syncer that keeps the app's document in a
// record, reads the shared server list (scope "servers") and the SSH keys
// of the safe (scope "ssh_keys"). Shard is a separate program that may
// be missing, stopped or locked at any moment: the app works without it.
package shard

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"github.com/SelfHold/cellar/core/shard/pb"
)

// APIVersion is the Connector API version this client speaks.
const APIVersion = 1

// ErrNotRunning: Shard is not installed or not running here.
var ErrNotRunning = errors.New("Shard is not running")

// Client is one connection to Shard.
type Client interface {
	Hello(ctx context.Context, r *pb.HelloRequest) (*pb.HelloReply, error)
	RequestPairing(ctx context.Context, r *pb.PairingRequest) (*pb.PairingTicket, error)
	AwaitPairing(ctx context.Context, r *pb.AwaitPairingRequest) (*pb.PairingResult, error)
	Get(ctx context.Context, r *pb.GetRequest) (*pb.Item, error)
	Put(ctx context.Context, r *pb.PutRequest) (*pb.Item, error)
	Delete(ctx context.Context, r *pb.DeleteRequest) (*pb.Item, error)
	Unpair(ctx context.Context, r *pb.UnpairRequest) (*pb.UnpairReply, error)
	// Scope "ssh_keys".
	ListSshKeys(ctx context.Context, r *pb.ListSshKeysRequest) (*pb.ListSshKeysReply, error)
	GetSshKeys(ctx context.Context, r *pb.GetSshKeysRequest) (*pb.ListSshKeysReply, error)
	// Scope "servers".
	ListServers(ctx context.Context, r *pb.ListServersRequest) (*pb.ListServersReply, error)
	GetServers(ctx context.Context, r *pb.GetServersRequest) (*pb.ListServersReply, error)
	PutServer(ctx context.Context, r *pb.PutServerRequest) (*pb.Server, error)
	DeleteServer(ctx context.Context, r *pb.DeleteServerRequest) (*pb.DeleteServerReply, error)
	ListServerChanges(ctx context.Context, r *pb.ListChangesRequest) (*pb.ListChangesReply, error)
	// Watch streams changes until ctx ends or the stream breaks: next
	// returns the following change, or the error that ended it.
	Watch(ctx context.Context) (next func() (*pb.Change, error), err error)
	// SetToken sets the bearer token of later calls (desktops).
	SetToken(token string)
	Close() error
}

// Dialer connects to Shard. A missing Shard is ErrNotRunning.
type Dialer interface {
	Dial(ctx context.Context, token string) (Client, error)
	// UsesToken: the pairing gives a bearer token to keep (desktops).
	// Android knows the caller from Binder and has none.
	UsesToken() bool
	// CanOpen: the app can open Shard for the user (Android).
	CanOpen() bool
}

// --- desktops: gRPC on Shard's socket ------------------------------------

// EndpointFile is where Shard's daemon writes its connector address:
// <user config dir>/selfhold/shard/connector.json.
func EndpointFile() string {
	dir, err := os.UserConfigDir()
	if err != nil {
		dir = "."
	}
	return filepath.Join(dir, "selfhold", "shard", "connector.json")
}

// Desktop dials the daemon whose address is in File (EndpointFile when
// empty).
type Desktop struct{ File string }

func (Desktop) UsesToken() bool { return true }
func (Desktop) CanOpen() bool   { return false }

func (d Desktop) Dial(ctx context.Context, token string) (Client, error) {
	file := d.File
	if file == "" {
		file = EndpointFile()
	}
	data, err := os.ReadFile(file)
	if err != nil {
		return nil, ErrNotRunning
	}
	var ep struct {
		Address    string `json:"address"`
		APIVersion int    `json:"api_version"`
	}
	if json.Unmarshal(data, &ep) != nil || ep.Address == "" {
		return nil, ErrNotRunning
	}
	if ep.APIVersion > APIVersion {
		return nil, ErrTooNew
	}
	network, addr := "tcp", ep.Address
	if strings.HasPrefix(addr, "unix://") {
		network, addr = "unix", strings.TrimPrefix(addr, "unix://")
	}
	// The file outlives a killed daemon: dial before saying it runs.
	conn, err := (&net.Dialer{}).DialContext(ctx, network, addr)
	if err != nil {
		return nil, ErrNotRunning
	}
	conn.Close()
	c := &grpcClient{}
	c.token.Store(token)
	auth := func(ctx context.Context) context.Context {
		if t := c.token.Load().(string); t != "" {
			return metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+t)
		}
		return ctx
	}
	cc, err := grpc.NewClient("passthrough:///shard",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, network, addr)
		}),
		grpc.WithUnaryInterceptor(func(ctx context.Context, method string, req, reply any, cc *grpc.ClientConn, invoker grpc.UnaryInvoker, opts ...grpc.CallOption) error {
			return invoker(auth(ctx), method, req, reply, cc, opts...)
		}),
		grpc.WithStreamInterceptor(func(ctx context.Context, desc *grpc.StreamDesc, cc *grpc.ClientConn, method string, streamer grpc.Streamer, opts ...grpc.CallOption) (grpc.ClientStream, error) {
			return streamer(auth(ctx), desc, cc, method, opts...)
		}),
	)
	if err != nil {
		return nil, err
	}
	c.cc, c.api = cc, pb.NewConnectorClient(cc)
	return c, nil
}

// ErrTooNew: Shard speaks a newer, incompatible API.
var ErrTooNew = errors.New("Shard is newer than this Cellar: update Cellar")

type grpcClient struct {
	cc    *grpc.ClientConn
	api   pb.ConnectorClient
	token atomic.Value // string
}

func (c *grpcClient) SetToken(t string) { c.token.Store(t) }
func (c *grpcClient) Close() error      { return c.cc.Close() }

func (c *grpcClient) Hello(ctx context.Context, r *pb.HelloRequest) (*pb.HelloReply, error) {
	return wrap(c.api.Hello(ctx, r))
}
func (c *grpcClient) RequestPairing(ctx context.Context, r *pb.PairingRequest) (*pb.PairingTicket, error) {
	return wrap(c.api.RequestPairing(ctx, r))
}
func (c *grpcClient) AwaitPairing(ctx context.Context, r *pb.AwaitPairingRequest) (*pb.PairingResult, error) {
	return wrap(c.api.AwaitPairing(ctx, r))
}
func (c *grpcClient) Get(ctx context.Context, r *pb.GetRequest) (*pb.Item, error) {
	return wrap(c.api.Get(ctx, r))
}
func (c *grpcClient) Put(ctx context.Context, r *pb.PutRequest) (*pb.Item, error) {
	return wrap(c.api.Put(ctx, r))
}
func (c *grpcClient) Delete(ctx context.Context, r *pb.DeleteRequest) (*pb.Item, error) {
	return wrap(c.api.Delete(ctx, r))
}
func (c *grpcClient) Unpair(ctx context.Context, r *pb.UnpairRequest) (*pb.UnpairReply, error) {
	return wrap(c.api.Unpair(ctx, r))
}

func (c *grpcClient) ListSshKeys(ctx context.Context, r *pb.ListSshKeysRequest) (*pb.ListSshKeysReply, error) {
	return c.api.ListSshKeys(ctx, r)
}
func (c *grpcClient) GetSshKeys(ctx context.Context, r *pb.GetSshKeysRequest) (*pb.ListSshKeysReply, error) {
	return c.api.GetSshKeys(ctx, r)
}
func (c *grpcClient) ListServers(ctx context.Context, r *pb.ListServersRequest) (*pb.ListServersReply, error) {
	return c.api.ListServers(ctx, r)
}
func (c *grpcClient) GetServers(ctx context.Context, r *pb.GetServersRequest) (*pb.ListServersReply, error) {
	return c.api.GetServers(ctx, r)
}
func (c *grpcClient) PutServer(ctx context.Context, r *pb.PutServerRequest) (*pb.Server, error) {
	return c.api.PutServer(ctx, r)
}
func (c *grpcClient) DeleteServer(ctx context.Context, r *pb.DeleteServerRequest) (*pb.DeleteServerReply, error) {
	return c.api.DeleteServer(ctx, r)
}
func (c *grpcClient) ListServerChanges(ctx context.Context, r *pb.ListChangesRequest) (*pb.ListChangesReply, error) {
	return c.api.ListServerChanges(ctx, r)
}

func (c *grpcClient) Watch(ctx context.Context) (func() (*pb.Change, error), error) {
	st, err := c.api.Watch(ctx, &pb.WatchRequest{})
	if err != nil {
		return nil, transport(err)
	}
	return func() (*pb.Change, error) {
		ch, err := st.Recv()
		return ch, transport(err)
	}, nil
}

// wrap keeps Shard's answers as they are. A broken connection is
// UNAVAILABLE too, like "offline": the syncer retries either way, and a
// Shard that stopped ends the Watch, so the syncer dials again and
// finds it gone.
func wrap[T any](v T, err error) (T, error) { return v, err }

func transport(err error) error { return err }

// --- Android: Shard's bound service, through the app ----------------------

// Binder is Shard's bound service (IShardConnector.aidl), bound by
// the app's Kotlin side. Calls fail with an error when Shard is not
// installed or the binding broke.
type Binder interface {
	// Call runs one unary method; the answer is a serialized CallReply.
	Call(method string, request []byte) ([]byte, error)
	// Watch starts a watch: w gets serialized Change messages, then one
	// OnEnd with a serialized CallReply. It returns a handle for Unwatch.
	Watch(w BinderWatcher) (int64, error)
	Unwatch(handle int64)
}

// BinderWatcher gets the changes of one Binder watch.
type BinderWatcher interface {
	OnChange(change []byte)
	OnEnd(reply []byte)
}

// Android dials Shard through the app's Binder.
type Android struct{ Binder Binder }

func (Android) UsesToken() bool { return false }
func (Android) CanOpen() bool   { return true }

func (a Android) Dial(context.Context, string) (Client, error) {
	if a.Binder == nil {
		return nil, ErrNotRunning
	}
	return &binderClient{b: a.Binder}, nil
}

type binderClient struct{ b Binder }

func (*binderClient) SetToken(string) {}
func (*binderClient) Close() error    { return nil }

// call runs method on the binder; the binder blocks, so ctx is honoured
// only before and after it (AwaitPairing waits at most 60 s).
func call[T proto.Message](ctx context.Context, b *binderClient, method string, req proto.Message, reply T) (T, error) {
	var zero T
	in, err := proto.Marshal(req)
	if err != nil {
		return zero, err
	}
	if err := ctx.Err(); err != nil {
		return zero, err
	}
	out, err := b.b.Call(method, in)
	if err != nil {
		return zero, fmt.Errorf("%w: %v", ErrNotRunning, err)
	}
	if err := ctx.Err(); err != nil {
		return zero, err
	}
	var cr pb.CallReply
	if err := proto.Unmarshal(out, &cr); err != nil {
		return zero, fmt.Errorf("shard: bad reply: %w", err)
	}
	if cr.Code != 0 {
		if codes.Code(cr.Code) == codes.Unavailable && strings.Contains(cr.Message, "not running") {
			return zero, fmt.Errorf("%w: %s", ErrNotRunning, cr.Message)
		}
		return zero, status.Error(codes.Code(cr.Code), cr.Message)
	}
	if err := proto.Unmarshal(cr.Payload, reply); err != nil {
		return zero, fmt.Errorf("shard: bad reply: %w", err)
	}
	return reply, nil
}

func (b *binderClient) Hello(ctx context.Context, r *pb.HelloRequest) (*pb.HelloReply, error) {
	return call(ctx, b, "Hello", r, &pb.HelloReply{})
}
func (b *binderClient) RequestPairing(ctx context.Context, r *pb.PairingRequest) (*pb.PairingTicket, error) {
	return call(ctx, b, "RequestPairing", r, &pb.PairingTicket{})
}
func (b *binderClient) AwaitPairing(ctx context.Context, r *pb.AwaitPairingRequest) (*pb.PairingResult, error) {
	return call(ctx, b, "AwaitPairing", r, &pb.PairingResult{})
}
func (b *binderClient) Get(ctx context.Context, r *pb.GetRequest) (*pb.Item, error) {
	return call(ctx, b, "Get", r, &pb.Item{})
}
func (b *binderClient) Put(ctx context.Context, r *pb.PutRequest) (*pb.Item, error) {
	return call(ctx, b, "Put", r, &pb.Item{})
}
func (b *binderClient) Delete(ctx context.Context, r *pb.DeleteRequest) (*pb.Item, error) {
	return call(ctx, b, "Delete", r, &pb.Item{})
}
func (b *binderClient) Unpair(ctx context.Context, r *pb.UnpairRequest) (*pb.UnpairReply, error) {
	return call(ctx, b, "Unpair", r, &pb.UnpairReply{})
}

func (b *binderClient) ListSshKeys(ctx context.Context, r *pb.ListSshKeysRequest) (*pb.ListSshKeysReply, error) {
	return call(ctx, b, "ListSshKeys", r, &pb.ListSshKeysReply{})
}
func (b *binderClient) GetSshKeys(ctx context.Context, r *pb.GetSshKeysRequest) (*pb.ListSshKeysReply, error) {
	return call(ctx, b, "GetSshKeys", r, &pb.ListSshKeysReply{})
}
func (b *binderClient) ListServers(ctx context.Context, r *pb.ListServersRequest) (*pb.ListServersReply, error) {
	return call(ctx, b, "ListServers", r, &pb.ListServersReply{})
}
func (b *binderClient) GetServers(ctx context.Context, r *pb.GetServersRequest) (*pb.ListServersReply, error) {
	return call(ctx, b, "GetServers", r, &pb.ListServersReply{})
}
func (b *binderClient) PutServer(ctx context.Context, r *pb.PutServerRequest) (*pb.Server, error) {
	return call(ctx, b, "PutServer", r, &pb.Server{})
}
func (b *binderClient) DeleteServer(ctx context.Context, r *pb.DeleteServerRequest) (*pb.DeleteServerReply, error) {
	return call(ctx, b, "DeleteServer", r, &pb.DeleteServerReply{})
}
func (b *binderClient) ListServerChanges(ctx context.Context, r *pb.ListChangesRequest) (*pb.ListChangesReply, error) {
	return call(ctx, b, "ListServerChanges", r, &pb.ListChangesReply{})
}

func (b *binderClient) Watch(ctx context.Context) (func() (*pb.Change, error), error) {
	w := &binderWatch{ch: make(chan []byte, 64), end: make(chan error, 1)}
	h, err := b.b.Watch(w)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrNotRunning, err)
	}
	stop := sync.OnceFunc(func() { b.b.Unwatch(h) })
	return func() (*pb.Change, error) {
		select {
		case data := <-w.ch:
			var c pb.Change
			if err := proto.Unmarshal(data, &c); err != nil {
				stop()
				return nil, fmt.Errorf("shard: bad change: %w", err)
			}
			return &c, nil
		case err := <-w.end:
			return nil, err
		case <-ctx.Done():
			stop()
			return nil, ctx.Err()
		}
	}, nil
}

type binderWatch struct {
	ch    chan []byte
	end   chan error
	ended atomic.Bool
}

func (w *binderWatch) OnChange(change []byte) {
	select {
	case w.ch <- append([]byte{}, change...):
	default:
		// Too far behind: end the watch, the syncer reconnects and reads
		// everything again.
		w.OnEnd(nil)
	}
}

func (w *binderWatch) OnEnd(reply []byte) {
	if w.ended.Swap(true) {
		return
	}
	var cr pb.CallReply
	err := ErrNotRunning
	if proto.Unmarshal(reply, &cr) == nil && cr.Code != 0 {
		err = status.Error(codes.Code(cr.Code), cr.Message)
	}
	w.end <- err
}

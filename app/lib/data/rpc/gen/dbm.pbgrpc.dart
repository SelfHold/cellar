// This is a generated file - do not edit.
//
// Generated from dbm.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'dbm.pb.dart' as $0;

export 'dbm.pb.dart';

@$pb.GrpcServiceName('dbm.v1.DBManager')
class DBManagerClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DBManagerClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.State> getState(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getState, request, options: options);
  }

  /// Events streams changes (servers, connections, keys, sync, SSH state).
  /// The app keeps one open and reloads what an event names.
  $grpc.ResponseStream<$0.Event> events(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$events, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// --- servers (shared through CloudSync when its "servers" scope is on) ---
  $grpc.ResponseFuture<$0.ServerList> listServers(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listServers, request, options: options);
  }

  /// SaveServer creates (id = "") or replaces a server.
  $grpc.ResponseFuture<$0.Server> saveServer(
    $0.Server request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteServer(
    $0.Ref request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteServer, request, options: options);
  }

  /// ConnectServer opens (or reuses) the SSH connection. An unknown or
  /// changed host key comes back in `host_key` (status != KNOWN) and the
  /// connection is not opened: the app asks, then calls TrustHostKey.
  $grpc.ResponseFuture<$0.ConnectReply> connectServer(
    $0.ConnectRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$connectServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.Server> trustHostKey(
    $0.TrustRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$trustHostKey, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> disconnectServer(
    $0.Ref request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$disconnectServer, request, options: options);
  }

  /// Discover looks for database services running on the server (processes,
  /// listening ports, docker containers) and checks each candidate port.
  $grpc.ResponseFuture<$0.DiscoverReply> discover(
    $0.Ref request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$discover, request, options: options);
  }

  /// --- SSH keys: CloudSync's safe (scope "ssh_keys") + keys of this device --
  $grpc.ResponseFuture<$0.KeyList> listKeys(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listKeys, request, options: options);
  }

  /// SaveLocalKey keeps a pasted / loaded private key on this device only.
  $grpc.ResponseFuture<$0.Key> saveLocalKey(
    $0.LocalKey request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveLocalKey, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteLocalKey(
    $0.Ref request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteLocalKey, request, options: options);
  }

  /// --- connections: a database endpoint, through a server or direct ------
  $grpc.ResponseFuture<$0.ConnectionList> listConnections(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listConnections, request, options: options);
  }

  $grpc.ResponseFuture<$0.Connection> saveConnection(
    $0.Connection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveConnection, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> deleteConnection(
    $0.Ref request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteConnection, request, options: options);
  }

  /// TestConnection connects with the given settings (not saved) and says
  /// what answered.
  $grpc.ResponseFuture<$0.TestReply> testConnection(
    $0.Connection request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$testConnection, request, options: options);
  }

  /// --- schema browser -----------------------------------------------------
  $grpc.ResponseFuture<$0.DatabaseList> listDatabases(
    $0.Ref request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDatabases, request, options: options);
  }

  $grpc.ResponseFuture<$0.SchemaList> listSchemas(
    $0.DbRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSchemas, request, options: options);
  }

  /// ListObjects returns tables, views, sequences, functions of one schema.
  $grpc.ResponseFuture<$0.ObjectList> listObjects(
    $0.SchemaRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listObjects, request, options: options);
  }

  $grpc.ResponseFuture<$0.ObjectInfo> describeObject(
    $0.ObjectRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$describeObject, request, options: options);
  }

  /// --- data ---------------------------------------------------------------
  /// ReadTable returns one page of a table or view.
  $grpc.ResponseFuture<$0.ResultSet> readTable(
    $0.ReadTableRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$readTable, request, options: options);
  }

  /// ApplyEdits inserts, updates and deletes rows of a table in one
  /// transaction (the data editor's "Submit").
  $grpc.ResponseFuture<$0.EditReply> applyEdits(
    $0.EditRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyEdits, request, options: options);
  }

  /// --- query console ------------------------------------------------------
  /// OpenConsole pins one database session (transactions, SET, temp tables
  /// live as long as the console).
  $grpc.ResponseFuture<$0.Console> openConsole(
    $0.DbRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$openConsole, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> closeConsole(
    $0.ConsoleRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$closeConsole, request, options: options);
  }

  /// Execute runs the text (one or several statements) on the console's
  /// session and returns one result per statement.
  $grpc.ResponseFuture<$0.ExecuteReply> execute(
    $0.ExecuteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$execute, request, options: options);
  }

  /// Cancel stops the statement running on the console.
  $grpc.ResponseFuture<$0.Empty> cancel(
    $0.ConsoleRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancel, request, options: options);
  }

  /// Statements splits a console's text into statements (UTF-16 offsets),
  /// for highlighting the one at the cursor.
  $grpc.ResponseFuture<$0.StatementsReply> statements(
    $0.StatementsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$statements, request, options: options);
  }

  /// --- CloudSync ----------------------------------------------------------
  /// EnableSync pairs (if needed) and returns the code to show; the result
  /// comes as a SYNC event.
  $grpc.ResponseFuture<$0.SyncState> enableSync(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$enableSync, request, options: options);
  }

  $grpc.ResponseFuture<$0.SyncState> disableSync(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$disableSync, request, options: options);
  }

  $grpc.ResponseFuture<$0.SyncState> syncNow(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$syncNow, request, options: options);
  }

  /// MoveServersToCloudSync copies this app's own servers into the shared
  /// list (once the "servers" scope is granted) and drops the own copy.
  $grpc.ResponseFuture<$0.SyncState> moveServersToCloudSync(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$moveServersToCloudSync, request,
        options: options);
  }

  // method descriptors

  static final _$getState = $grpc.ClientMethod<$0.Empty, $0.State>(
      '/dbm.v1.DBManager/GetState',
      ($0.Empty value) => value.writeToBuffer(),
      $0.State.fromBuffer);
  static final _$events = $grpc.ClientMethod<$0.Empty, $0.Event>(
      '/dbm.v1.DBManager/Events',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Event.fromBuffer);
  static final _$listServers = $grpc.ClientMethod<$0.Empty, $0.ServerList>(
      '/dbm.v1.DBManager/ListServers',
      ($0.Empty value) => value.writeToBuffer(),
      $0.ServerList.fromBuffer);
  static final _$saveServer = $grpc.ClientMethod<$0.Server, $0.Server>(
      '/dbm.v1.DBManager/SaveServer',
      ($0.Server value) => value.writeToBuffer(),
      $0.Server.fromBuffer);
  static final _$deleteServer = $grpc.ClientMethod<$0.Ref, $0.Empty>(
      '/dbm.v1.DBManager/DeleteServer',
      ($0.Ref value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$connectServer =
      $grpc.ClientMethod<$0.ConnectRequest, $0.ConnectReply>(
          '/dbm.v1.DBManager/ConnectServer',
          ($0.ConnectRequest value) => value.writeToBuffer(),
          $0.ConnectReply.fromBuffer);
  static final _$trustHostKey = $grpc.ClientMethod<$0.TrustRequest, $0.Server>(
      '/dbm.v1.DBManager/TrustHostKey',
      ($0.TrustRequest value) => value.writeToBuffer(),
      $0.Server.fromBuffer);
  static final _$disconnectServer = $grpc.ClientMethod<$0.Ref, $0.Empty>(
      '/dbm.v1.DBManager/DisconnectServer',
      ($0.Ref value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$discover = $grpc.ClientMethod<$0.Ref, $0.DiscoverReply>(
      '/dbm.v1.DBManager/Discover',
      ($0.Ref value) => value.writeToBuffer(),
      $0.DiscoverReply.fromBuffer);
  static final _$listKeys = $grpc.ClientMethod<$0.Empty, $0.KeyList>(
      '/dbm.v1.DBManager/ListKeys',
      ($0.Empty value) => value.writeToBuffer(),
      $0.KeyList.fromBuffer);
  static final _$saveLocalKey = $grpc.ClientMethod<$0.LocalKey, $0.Key>(
      '/dbm.v1.DBManager/SaveLocalKey',
      ($0.LocalKey value) => value.writeToBuffer(),
      $0.Key.fromBuffer);
  static final _$deleteLocalKey = $grpc.ClientMethod<$0.Ref, $0.Empty>(
      '/dbm.v1.DBManager/DeleteLocalKey',
      ($0.Ref value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$listConnections =
      $grpc.ClientMethod<$0.Empty, $0.ConnectionList>(
          '/dbm.v1.DBManager/ListConnections',
          ($0.Empty value) => value.writeToBuffer(),
          $0.ConnectionList.fromBuffer);
  static final _$saveConnection =
      $grpc.ClientMethod<$0.Connection, $0.Connection>(
          '/dbm.v1.DBManager/SaveConnection',
          ($0.Connection value) => value.writeToBuffer(),
          $0.Connection.fromBuffer);
  static final _$deleteConnection = $grpc.ClientMethod<$0.Ref, $0.Empty>(
      '/dbm.v1.DBManager/DeleteConnection',
      ($0.Ref value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$testConnection =
      $grpc.ClientMethod<$0.Connection, $0.TestReply>(
          '/dbm.v1.DBManager/TestConnection',
          ($0.Connection value) => value.writeToBuffer(),
          $0.TestReply.fromBuffer);
  static final _$listDatabases = $grpc.ClientMethod<$0.Ref, $0.DatabaseList>(
      '/dbm.v1.DBManager/ListDatabases',
      ($0.Ref value) => value.writeToBuffer(),
      $0.DatabaseList.fromBuffer);
  static final _$listSchemas = $grpc.ClientMethod<$0.DbRef, $0.SchemaList>(
      '/dbm.v1.DBManager/ListSchemas',
      ($0.DbRef value) => value.writeToBuffer(),
      $0.SchemaList.fromBuffer);
  static final _$listObjects = $grpc.ClientMethod<$0.SchemaRef, $0.ObjectList>(
      '/dbm.v1.DBManager/ListObjects',
      ($0.SchemaRef value) => value.writeToBuffer(),
      $0.ObjectList.fromBuffer);
  static final _$describeObject =
      $grpc.ClientMethod<$0.ObjectRef, $0.ObjectInfo>(
          '/dbm.v1.DBManager/DescribeObject',
          ($0.ObjectRef value) => value.writeToBuffer(),
          $0.ObjectInfo.fromBuffer);
  static final _$readTable =
      $grpc.ClientMethod<$0.ReadTableRequest, $0.ResultSet>(
          '/dbm.v1.DBManager/ReadTable',
          ($0.ReadTableRequest value) => value.writeToBuffer(),
          $0.ResultSet.fromBuffer);
  static final _$applyEdits = $grpc.ClientMethod<$0.EditRequest, $0.EditReply>(
      '/dbm.v1.DBManager/ApplyEdits',
      ($0.EditRequest value) => value.writeToBuffer(),
      $0.EditReply.fromBuffer);
  static final _$openConsole = $grpc.ClientMethod<$0.DbRef, $0.Console>(
      '/dbm.v1.DBManager/OpenConsole',
      ($0.DbRef value) => value.writeToBuffer(),
      $0.Console.fromBuffer);
  static final _$closeConsole = $grpc.ClientMethod<$0.ConsoleRef, $0.Empty>(
      '/dbm.v1.DBManager/CloseConsole',
      ($0.ConsoleRef value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$execute =
      $grpc.ClientMethod<$0.ExecuteRequest, $0.ExecuteReply>(
          '/dbm.v1.DBManager/Execute',
          ($0.ExecuteRequest value) => value.writeToBuffer(),
          $0.ExecuteReply.fromBuffer);
  static final _$cancel = $grpc.ClientMethod<$0.ConsoleRef, $0.Empty>(
      '/dbm.v1.DBManager/Cancel',
      ($0.ConsoleRef value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$statements =
      $grpc.ClientMethod<$0.StatementsRequest, $0.StatementsReply>(
          '/dbm.v1.DBManager/Statements',
          ($0.StatementsRequest value) => value.writeToBuffer(),
          $0.StatementsReply.fromBuffer);
  static final _$enableSync = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/dbm.v1.DBManager/EnableSync',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$disableSync = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/dbm.v1.DBManager/DisableSync',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$syncNow = $grpc.ClientMethod<$0.Empty, $0.SyncState>(
      '/dbm.v1.DBManager/SyncNow',
      ($0.Empty value) => value.writeToBuffer(),
      $0.SyncState.fromBuffer);
  static final _$moveServersToCloudSync =
      $grpc.ClientMethod<$0.Empty, $0.SyncState>(
          '/dbm.v1.DBManager/MoveServersToCloudSync',
          ($0.Empty value) => value.writeToBuffer(),
          $0.SyncState.fromBuffer);
}

@$pb.GrpcServiceName('dbm.v1.DBManager')
abstract class DBManagerServiceBase extends $grpc.Service {
  $core.String get $name => 'dbm.v1.DBManager';

  DBManagerServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.State>(
        'GetState',
        getState_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.State value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Event>(
        'Events',
        events_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Event value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.ServerList>(
        'ListServers',
        listServers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.ServerList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Server, $0.Server>(
        'SaveServer',
        saveServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Server.fromBuffer(value),
        ($0.Server value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Ref, $0.Empty>(
        'DeleteServer',
        deleteServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Ref.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.ConnectReply>(
        'ConnectServer',
        connectServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.ConnectReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TrustRequest, $0.Server>(
        'TrustHostKey',
        trustHostKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TrustRequest.fromBuffer(value),
        ($0.Server value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Ref, $0.Empty>(
        'DisconnectServer',
        disconnectServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Ref.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Ref, $0.DiscoverReply>(
        'Discover',
        discover_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Ref.fromBuffer(value),
        ($0.DiscoverReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.KeyList>(
        'ListKeys',
        listKeys_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.KeyList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LocalKey, $0.Key>(
        'SaveLocalKey',
        saveLocalKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LocalKey.fromBuffer(value),
        ($0.Key value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Ref, $0.Empty>(
        'DeleteLocalKey',
        deleteLocalKey_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Ref.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.ConnectionList>(
        'ListConnections',
        listConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.ConnectionList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Connection, $0.Connection>(
        'SaveConnection',
        saveConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Connection.fromBuffer(value),
        ($0.Connection value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Ref, $0.Empty>(
        'DeleteConnection',
        deleteConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Ref.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Connection, $0.TestReply>(
        'TestConnection',
        testConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Connection.fromBuffer(value),
        ($0.TestReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Ref, $0.DatabaseList>(
        'ListDatabases',
        listDatabases_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Ref.fromBuffer(value),
        ($0.DatabaseList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DbRef, $0.SchemaList>(
        'ListSchemas',
        listSchemas_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DbRef.fromBuffer(value),
        ($0.SchemaList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SchemaRef, $0.ObjectList>(
        'ListObjects',
        listObjects_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SchemaRef.fromBuffer(value),
        ($0.ObjectList value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ObjectRef, $0.ObjectInfo>(
        'DescribeObject',
        describeObject_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ObjectRef.fromBuffer(value),
        ($0.ObjectInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReadTableRequest, $0.ResultSet>(
        'ReadTable',
        readTable_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReadTableRequest.fromBuffer(value),
        ($0.ResultSet value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EditRequest, $0.EditReply>(
        'ApplyEdits',
        applyEdits_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.EditRequest.fromBuffer(value),
        ($0.EditReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DbRef, $0.Console>(
        'OpenConsole',
        openConsole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DbRef.fromBuffer(value),
        ($0.Console value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ConsoleRef, $0.Empty>(
        'CloseConsole',
        closeConsole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConsoleRef.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExecuteRequest, $0.ExecuteReply>(
        'Execute',
        execute_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExecuteRequest.fromBuffer(value),
        ($0.ExecuteReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ConsoleRef, $0.Empty>(
        'Cancel',
        cancel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConsoleRef.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StatementsRequest, $0.StatementsReply>(
        'Statements',
        statements_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StatementsRequest.fromBuffer(value),
        ($0.StatementsReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'EnableSync',
        enableSync_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'DisableSync',
        disableSync_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'SyncNow',
        syncNow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.SyncState>(
        'MoveServersToCloudSync',
        moveServersToCloudSync_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.SyncState value) => value.writeToBuffer()));
  }

  $async.Future<$0.State> getState_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getState($call, await $request);
  }

  $async.Future<$0.State> getState($grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$0.Event> events_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* events($call, await $request);
  }

  $async.Stream<$0.Event> events($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.ServerList> listServers_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listServers($call, await $request);
  }

  $async.Future<$0.ServerList> listServers(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Server> saveServer_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Server> $request) async {
    return saveServer($call, await $request);
  }

  $async.Future<$0.Server> saveServer(
      $grpc.ServiceCall call, $0.Server request);

  $async.Future<$0.Empty> deleteServer_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Ref> $request) async {
    return deleteServer($call, await $request);
  }

  $async.Future<$0.Empty> deleteServer($grpc.ServiceCall call, $0.Ref request);

  $async.Future<$0.ConnectReply> connectServer_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ConnectRequest> $request) async {
    return connectServer($call, await $request);
  }

  $async.Future<$0.ConnectReply> connectServer(
      $grpc.ServiceCall call, $0.ConnectRequest request);

  $async.Future<$0.Server> trustHostKey_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.TrustRequest> $request) async {
    return trustHostKey($call, await $request);
  }

  $async.Future<$0.Server> trustHostKey(
      $grpc.ServiceCall call, $0.TrustRequest request);

  $async.Future<$0.Empty> disconnectServer_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Ref> $request) async {
    return disconnectServer($call, await $request);
  }

  $async.Future<$0.Empty> disconnectServer(
      $grpc.ServiceCall call, $0.Ref request);

  $async.Future<$0.DiscoverReply> discover_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Ref> $request) async {
    return discover($call, await $request);
  }

  $async.Future<$0.DiscoverReply> discover(
      $grpc.ServiceCall call, $0.Ref request);

  $async.Future<$0.KeyList> listKeys_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listKeys($call, await $request);
  }

  $async.Future<$0.KeyList> listKeys($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Key> saveLocalKey_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LocalKey> $request) async {
    return saveLocalKey($call, await $request);
  }

  $async.Future<$0.Key> saveLocalKey(
      $grpc.ServiceCall call, $0.LocalKey request);

  $async.Future<$0.Empty> deleteLocalKey_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Ref> $request) async {
    return deleteLocalKey($call, await $request);
  }

  $async.Future<$0.Empty> deleteLocalKey(
      $grpc.ServiceCall call, $0.Ref request);

  $async.Future<$0.ConnectionList> listConnections_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return listConnections($call, await $request);
  }

  $async.Future<$0.ConnectionList> listConnections(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Connection> saveConnection_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Connection> $request) async {
    return saveConnection($call, await $request);
  }

  $async.Future<$0.Connection> saveConnection(
      $grpc.ServiceCall call, $0.Connection request);

  $async.Future<$0.Empty> deleteConnection_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Ref> $request) async {
    return deleteConnection($call, await $request);
  }

  $async.Future<$0.Empty> deleteConnection(
      $grpc.ServiceCall call, $0.Ref request);

  $async.Future<$0.TestReply> testConnection_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Connection> $request) async {
    return testConnection($call, await $request);
  }

  $async.Future<$0.TestReply> testConnection(
      $grpc.ServiceCall call, $0.Connection request);

  $async.Future<$0.DatabaseList> listDatabases_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Ref> $request) async {
    return listDatabases($call, await $request);
  }

  $async.Future<$0.DatabaseList> listDatabases(
      $grpc.ServiceCall call, $0.Ref request);

  $async.Future<$0.SchemaList> listSchemas_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DbRef> $request) async {
    return listSchemas($call, await $request);
  }

  $async.Future<$0.SchemaList> listSchemas(
      $grpc.ServiceCall call, $0.DbRef request);

  $async.Future<$0.ObjectList> listObjects_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SchemaRef> $request) async {
    return listObjects($call, await $request);
  }

  $async.Future<$0.ObjectList> listObjects(
      $grpc.ServiceCall call, $0.SchemaRef request);

  $async.Future<$0.ObjectInfo> describeObject_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ObjectRef> $request) async {
    return describeObject($call, await $request);
  }

  $async.Future<$0.ObjectInfo> describeObject(
      $grpc.ServiceCall call, $0.ObjectRef request);

  $async.Future<$0.ResultSet> readTable_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReadTableRequest> $request) async {
    return readTable($call, await $request);
  }

  $async.Future<$0.ResultSet> readTable(
      $grpc.ServiceCall call, $0.ReadTableRequest request);

  $async.Future<$0.EditReply> applyEdits_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.EditRequest> $request) async {
    return applyEdits($call, await $request);
  }

  $async.Future<$0.EditReply> applyEdits(
      $grpc.ServiceCall call, $0.EditRequest request);

  $async.Future<$0.Console> openConsole_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DbRef> $request) async {
    return openConsole($call, await $request);
  }

  $async.Future<$0.Console> openConsole(
      $grpc.ServiceCall call, $0.DbRef request);

  $async.Future<$0.Empty> closeConsole_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ConsoleRef> $request) async {
    return closeConsole($call, await $request);
  }

  $async.Future<$0.Empty> closeConsole(
      $grpc.ServiceCall call, $0.ConsoleRef request);

  $async.Future<$0.ExecuteReply> execute_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ExecuteRequest> $request) async {
    return execute($call, await $request);
  }

  $async.Future<$0.ExecuteReply> execute(
      $grpc.ServiceCall call, $0.ExecuteRequest request);

  $async.Future<$0.Empty> cancel_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ConsoleRef> $request) async {
    return cancel($call, await $request);
  }

  $async.Future<$0.Empty> cancel($grpc.ServiceCall call, $0.ConsoleRef request);

  $async.Future<$0.StatementsReply> statements_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StatementsRequest> $request) async {
    return statements($call, await $request);
  }

  $async.Future<$0.StatementsReply> statements(
      $grpc.ServiceCall call, $0.StatementsRequest request);

  $async.Future<$0.SyncState> enableSync_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return enableSync($call, await $request);
  }

  $async.Future<$0.SyncState> enableSync(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SyncState> disableSync_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return disableSync($call, await $request);
  }

  $async.Future<$0.SyncState> disableSync(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SyncState> syncNow_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return syncNow($call, await $request);
  }

  $async.Future<$0.SyncState> syncNow($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.SyncState> moveServersToCloudSync_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return moveServersToCloudSync($call, await $request);
  }

  $async.Future<$0.SyncState> moveServersToCloudSync(
      $grpc.ServiceCall call, $0.Empty request);
}

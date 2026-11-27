// This is a generated file - do not edit.
//
// Generated from cellar.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cellar.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'cellar.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  factory Empty() => Empty._();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Empty.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Empty() / Empty.new instead')
  static Empty create() => Empty._();
  static $pb.GeneratedMessage $_createMessage() => Empty._();
  @$core.override
  Empty createEmptyInstance() => Empty._();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Empty>(Empty.$_createMessage);
  static Empty? _defaultInstance;
}

class Ref extends $pb.GeneratedMessage {
  factory Ref({
    $core.String? id,
  }) {
    final result = Ref._();
    if (id != null) result.id = id;
    return result;
  }

  Ref._();

  factory Ref.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ref()..mergeFromBuffer(data, registry);
  factory Ref.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Ref()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Ref',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Ref.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ref clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Ref copyWith(void Function(Ref) updates) =>
      super.copyWith((message) => updates(message as Ref)) as Ref;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Ref() / Ref.new instead')
  static Ref create() => Ref._();
  static $pb.GeneratedMessage $_createMessage() => Ref._();
  @$core.override
  Ref createEmptyInstance() => Ref._();
  @$core.pragma('dart2js:noInline')
  static Ref getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Ref>(Ref.$_createMessage);
  static Ref? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class State extends $pb.GeneratedMessage {
  factory State({
    $core.String? coreVersion,
    $core.String? coreBuild,
    $core.String? platform,
    SyncState? sync,
    $core.bool? keychain,
  }) {
    final result = State._();
    if (coreVersion != null) result.coreVersion = coreVersion;
    if (coreBuild != null) result.coreBuild = coreBuild;
    if (platform != null) result.platform = platform;
    if (sync != null) result.sync = sync;
    if (keychain != null) result.keychain = keychain;
    return result;
  }

  State._();

  factory State.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      State()..mergeFromBuffer(data, registry);
  factory State.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      State()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'State',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: State.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'coreVersion')
    ..aOS(2, _omitFieldNames ? '' : 'coreBuild')
    ..aOS(3, _omitFieldNames ? '' : 'platform')
    ..aOM<SyncState>(4, _omitFieldNames ? '' : 'sync',
        subBuilder: SyncState.$_createMessage)
    ..aOB(5, _omitFieldNames ? '' : 'keychain')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  State clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  State copyWith(void Function(State) updates) =>
      super.copyWith((message) => updates(message as State)) as State;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use State() / State.new instead')
  static State create() => State._();
  static $pb.GeneratedMessage $_createMessage() => State._();
  @$core.override
  State createEmptyInstance() => State._();
  @$core.pragma('dart2js:noInline')
  static State getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<State>(State.$_createMessage);
  static State? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get coreVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set coreVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCoreVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoreVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get coreBuild => $_getSZ(1);
  @$pb.TagNumber(2)
  set coreBuild($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCoreBuild() => $_has(1);
  @$pb.TagNumber(2)
  void clearCoreBuild() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get platform => $_getSZ(2);
  @$pb.TagNumber(3)
  set platform($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlatform() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlatform() => $_clearField(3);

  @$pb.TagNumber(4)
  SyncState get sync => $_getN(3);
  @$pb.TagNumber(4)
  set sync(SyncState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSync() => $_has(3);
  @$pb.TagNumber(4)
  void clearSync() => $_clearField(4);
  @$pb.TagNumber(4)
  SyncState ensureSync() => $_ensure(3);

  /// The local files are sealed with a key from the OS keychain; false: a
  /// key file next to them (no keychain on this machine).
  @$pb.TagNumber(5)
  $core.bool get keychain => $_getBF(4);
  @$pb.TagNumber(5)
  set keychain($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKeychain() => $_has(4);
  @$pb.TagNumber(5)
  void clearKeychain() => $_clearField(5);
}

class SyncState extends $pb.GeneratedMessage {
  factory SyncState({
    SyncState_Phase? phase,
    $core.bool? enabled,
    $core.bool? available,
    $core.String? pairingCode,
    $core.String? error,
    $core.bool? pending,
    $fixnum.Int64? lastSyncMs,
    $core.String? deviceName,
    $core.bool? sharedServers,
    $core.bool? safeKeys,
    $core.int? ownServers,
  }) {
    final result = SyncState._();
    if (phase != null) result.phase = phase;
    if (enabled != null) result.enabled = enabled;
    if (available != null) result.available = available;
    if (pairingCode != null) result.pairingCode = pairingCode;
    if (error != null) result.error = error;
    if (pending != null) result.pending = pending;
    if (lastSyncMs != null) result.lastSyncMs = lastSyncMs;
    if (deviceName != null) result.deviceName = deviceName;
    if (sharedServers != null) result.sharedServers = sharedServers;
    if (safeKeys != null) result.safeKeys = safeKeys;
    if (ownServers != null) result.ownServers = ownServers;
    return result;
  }

  SyncState._();

  factory SyncState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncState()..mergeFromBuffer(data, registry);
  factory SyncState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: SyncState.$_createMessage)
    ..aE<SyncState_Phase>(1, _omitFieldNames ? '' : 'phase',
        enumValues: SyncState_Phase.values)
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOB(3, _omitFieldNames ? '' : 'available')
    ..aOS(4, _omitFieldNames ? '' : 'pairingCode')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..aOB(6, _omitFieldNames ? '' : 'pending')
    ..aInt64(7, _omitFieldNames ? '' : 'lastSyncMs')
    ..aOS(8, _omitFieldNames ? '' : 'deviceName')
    ..aOB(9, _omitFieldNames ? '' : 'sharedServers')
    ..aOB(10, _omitFieldNames ? '' : 'safeKeys')
    ..aI(11, _omitFieldNames ? '' : 'ownServers')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncState copyWith(void Function(SyncState) updates) =>
      super.copyWith((message) => updates(message as SyncState)) as SyncState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncState() / SyncState.new instead')
  static SyncState create() => SyncState._();
  static $pb.GeneratedMessage $_createMessage() => SyncState._();
  @$core.override
  SyncState createEmptyInstance() => SyncState._();
  @$core.pragma('dart2js:noInline')
  static SyncState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncState>(SyncState.$_createMessage);
  static SyncState? _defaultInstance;

  @$pb.TagNumber(1)
  SyncState_Phase get phase => $_getN(0);
  @$pb.TagNumber(1)
  set phase(SyncState_Phase value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPhase() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhase() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get available => $_getBF(2);
  @$pb.TagNumber(3)
  set available($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvailable() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvailable() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get pairingCode => $_getSZ(3);
  @$pb.TagNumber(4)
  set pairingCode($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPairingCode() => $_has(3);
  @$pb.TagNumber(4)
  void clearPairingCode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get pending => $_getBF(5);
  @$pb.TagNumber(6)
  set pending($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPending() => $_has(5);
  @$pb.TagNumber(6)
  void clearPending() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get lastSyncMs => $_getI64(6);
  @$pb.TagNumber(7)
  set lastSyncMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastSyncMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastSyncMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get deviceName => $_getSZ(7);
  @$pb.TagNumber(8)
  set deviceName($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeviceName() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeviceName() => $_clearField(8);

  /// Granted scopes: shared servers, SSH keys of the safe.
  @$pb.TagNumber(9)
  $core.bool get sharedServers => $_getBF(8);
  @$pb.TagNumber(9)
  set sharedServers($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSharedServers() => $_has(8);
  @$pb.TagNumber(9)
  void clearSharedServers() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get safeKeys => $_getBF(9);
  @$pb.TagNumber(10)
  set safeKeys($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSafeKeys() => $_has(9);
  @$pb.TagNumber(10)
  void clearSafeKeys() => $_clearField(10);

  /// This app still keeps servers of its own while the shared list is
  /// available: offer MoveServersToShard.
  @$pb.TagNumber(11)
  $core.int get ownServers => $_getIZ(10);
  @$pb.TagNumber(11)
  set ownServers($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasOwnServers() => $_has(10);
  @$pb.TagNumber(11)
  void clearOwnServers() => $_clearField(11);
}

class Event extends $pb.GeneratedMessage {
  factory Event({
    Event_Kind? kind,
    $core.String? id,
    $core.String? message,
  }) {
    final result = Event._();
    if (kind != null) result.kind = kind;
    if (id != null) result.id = id;
    if (message != null) result.message = message;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..aE<Event_Kind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: Event_Kind.values)
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(1)
  Event_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(Event_Kind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class Server extends $pb.GeneratedMessage {
  factory Server({
    $core.String? id,
    $core.String? name,
    $core.String? group,
    $core.String? host,
    $core.int? port,
    $core.String? user,
    Server_Auth? auth,
    $core.String? password,
    $core.String? keyId,
    $core.Iterable<$core.String>? hostKeys,
    $core.String? jumpServerId,
    $core.String? notes,
    $fixnum.Int64? updatedMs,
    $core.bool? shared,
    $core.bool? connected,
  }) {
    final result = Server._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (group != null) result.group = group;
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    if (user != null) result.user = user;
    if (auth != null) result.auth = auth;
    if (password != null) result.password = password;
    if (keyId != null) result.keyId = keyId;
    if (hostKeys != null) result.hostKeys.addAll(hostKeys);
    if (jumpServerId != null) result.jumpServerId = jumpServerId;
    if (notes != null) result.notes = notes;
    if (updatedMs != null) result.updatedMs = updatedMs;
    if (shared != null) result.shared = shared;
    if (connected != null) result.connected = connected;
    return result;
  }

  Server._();

  factory Server.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Server()..mergeFromBuffer(data, registry);
  factory Server.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Server()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Server',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Server.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'group')
    ..aOS(4, _omitFieldNames ? '' : 'host')
    ..aI(5, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'user')
    ..aE<Server_Auth>(7, _omitFieldNames ? '' : 'auth',
        enumValues: Server_Auth.values)
    ..aOS(8, _omitFieldNames ? '' : 'password')
    ..aOS(9, _omitFieldNames ? '' : 'keyId')
    ..pPS(10, _omitFieldNames ? '' : 'hostKeys')
    ..aOS(11, _omitFieldNames ? '' : 'jumpServerId')
    ..aOS(12, _omitFieldNames ? '' : 'notes')
    ..aInt64(13, _omitFieldNames ? '' : 'updatedMs')
    ..aOB(14, _omitFieldNames ? '' : 'shared')
    ..aOB(15, _omitFieldNames ? '' : 'connected')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Server clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Server copyWith(void Function(Server) updates) =>
      super.copyWith((message) => updates(message as Server)) as Server;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Server() / Server.new instead')
  static Server create() => Server._();
  static $pb.GeneratedMessage $_createMessage() => Server._();
  @$core.override
  Server createEmptyInstance() => Server._();
  @$core.pragma('dart2js:noInline')
  static Server getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Server>(Server.$_createMessage);
  static Server? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get group => $_getSZ(2);
  @$pb.TagNumber(3)
  set group($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroup() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroup() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get host => $_getSZ(3);
  @$pb.TagNumber(4)
  set host($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHost() => $_has(3);
  @$pb.TagNumber(4)
  void clearHost() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get port => $_getIZ(4);
  @$pb.TagNumber(5)
  set port($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get user => $_getSZ(5);
  @$pb.TagNumber(6)
  set user($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUser() => $_has(5);
  @$pb.TagNumber(6)
  void clearUser() => $_clearField(6);

  @$pb.TagNumber(7)
  Server_Auth get auth => $_getN(6);
  @$pb.TagNumber(7)
  set auth(Server_Auth value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAuth() => $_has(6);
  @$pb.TagNumber(7)
  void clearAuth() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get password => $_getSZ(7);
  @$pb.TagNumber(8)
  set password($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPassword() => $_has(7);
  @$pb.TagNumber(8)
  void clearPassword() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get keyId => $_getSZ(8);
  @$pb.TagNumber(9)
  set keyId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasKeyId() => $_has(8);
  @$pb.TagNumber(9)
  void clearKeyId() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get hostKeys => $_getList(9);

  @$pb.TagNumber(11)
  $core.String get jumpServerId => $_getSZ(10);
  @$pb.TagNumber(11)
  set jumpServerId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasJumpServerId() => $_has(10);
  @$pb.TagNumber(11)
  void clearJumpServerId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get notes => $_getSZ(11);
  @$pb.TagNumber(12)
  set notes($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasNotes() => $_has(11);
  @$pb.TagNumber(12)
  void clearNotes() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get updatedMs => $_getI64(12);
  @$pb.TagNumber(13)
  set updatedMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasUpdatedMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearUpdatedMs() => $_clearField(13);

  /// Where it lives: the shared Shard list, or this app's own list.
  @$pb.TagNumber(14)
  $core.bool get shared => $_getBF(13);
  @$pb.TagNumber(14)
  set shared($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasShared() => $_has(13);
  @$pb.TagNumber(14)
  void clearShared() => $_clearField(14);

  /// Live: the SSH connection is open.
  @$pb.TagNumber(15)
  $core.bool get connected => $_getBF(14);
  @$pb.TagNumber(15)
  set connected($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasConnected() => $_has(14);
  @$pb.TagNumber(15)
  void clearConnected() => $_clearField(15);
}

class ServerList extends $pb.GeneratedMessage {
  factory ServerList({
    $core.Iterable<Server>? servers,
  }) {
    final result = ServerList._();
    if (servers != null) result.servers.addAll(servers);
    return result;
  }

  ServerList._();

  factory ServerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerList()..mergeFromBuffer(data, registry);
  factory ServerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ServerList.$_createMessage)
    ..pPM<Server>(1, _omitFieldNames ? '' : 'servers',
        subBuilder: Server.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerList copyWith(void Function(ServerList) updates) =>
      super.copyWith((message) => updates(message as ServerList)) as ServerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ServerList() / ServerList.new instead')
  static ServerList create() => ServerList._();
  static $pb.GeneratedMessage $_createMessage() => ServerList._();
  @$core.override
  ServerList createEmptyInstance() => ServerList._();
  @$core.pragma('dart2js:noInline')
  static ServerList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerList>(ServerList.$_createMessage);
  static ServerList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Server> get servers => $_getList(0);
}

class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest({
    $core.String? id,
    $core.String? passphrase,
  }) {
    final result = ConnectRequest._();
    if (id != null) result.id = id;
    if (passphrase != null) result.passphrase = passphrase;
    return result;
  }

  ConnectRequest._();

  factory ConnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromBuffer(data, registry);
  factory ConnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ConnectRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'passphrase')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectRequest))
          as ConnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectRequest() / ConnectRequest.new instead')
  static ConnectRequest create() => ConnectRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectRequest._();
  @$core.override
  ConnectRequest createEmptyInstance() => ConnectRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(
          ConnectRequest.$_createMessage);
  static ConnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Passphrase of an encrypted key the safe does not keep; kept in memory
  /// until the app quits.
  @$pb.TagNumber(2)
  $core.String get passphrase => $_getSZ(1);
  @$pb.TagNumber(2)
  set passphrase($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassphrase() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassphrase() => $_clearField(2);
}

class HostKey extends $pb.GeneratedMessage {
  factory HostKey({
    HostKey_Status? status,
    $core.String? key,
    $core.String? fingerprint,
    $core.String? type,
    $core.String? serverId,
  }) {
    final result = HostKey._();
    if (status != null) result.status = status;
    if (key != null) result.key = key;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (type != null) result.type = type;
    if (serverId != null) result.serverId = serverId;
    return result;
  }

  HostKey._();

  factory HostKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostKey()..mergeFromBuffer(data, registry);
  factory HostKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HostKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HostKey',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: HostKey.$_createMessage)
    ..aE<HostKey_Status>(1, _omitFieldNames ? '' : 'status',
        enumValues: HostKey_Status.values)
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOS(3, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(4, _omitFieldNames ? '' : 'type')
    ..aOS(5, _omitFieldNames ? '' : 'serverId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HostKey copyWith(void Function(HostKey) updates) =>
      super.copyWith((message) => updates(message as HostKey)) as HostKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HostKey() / HostKey.new instead')
  static HostKey create() => HostKey._();
  static $pb.GeneratedMessage $_createMessage() => HostKey._();
  @$core.override
  HostKey createEmptyInstance() => HostKey._();
  @$core.pragma('dart2js:noInline')
  static HostKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HostKey>(HostKey.$_createMessage);
  static HostKey? _defaultInstance;

  @$pb.TagNumber(1)
  HostKey_Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(HostKey_Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fingerprint => $_getSZ(2);
  @$pb.TagNumber(3)
  set fingerprint($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFingerprint() => $_has(2);
  @$pb.TagNumber(3)
  void clearFingerprint() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get type => $_getSZ(3);
  @$pb.TagNumber(4)
  set type($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get serverId => $_getSZ(4);
  @$pb.TagNumber(5)
  set serverId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasServerId() => $_has(4);
  @$pb.TagNumber(5)
  void clearServerId() => $_clearField(5);
}

class ConnectReply extends $pb.GeneratedMessage {
  factory ConnectReply({
    $core.bool? connected,
    HostKey? hostKey,
    $core.bool? needPassphrase,
    $core.String? serverBanner,
  }) {
    final result = ConnectReply._();
    if (connected != null) result.connected = connected;
    if (hostKey != null) result.hostKey = hostKey;
    if (needPassphrase != null) result.needPassphrase = needPassphrase;
    if (serverBanner != null) result.serverBanner = serverBanner;
    return result;
  }

  ConnectReply._();

  factory ConnectReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectReply()..mergeFromBuffer(data, registry);
  factory ConnectReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ConnectReply.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'connected')
    ..aOM<HostKey>(2, _omitFieldNames ? '' : 'hostKey',
        subBuilder: HostKey.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'needPassphrase')
    ..aOS(4, _omitFieldNames ? '' : 'serverBanner')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectReply copyWith(void Function(ConnectReply) updates) =>
      super.copyWith((message) => updates(message as ConnectReply))
          as ConnectReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectReply() / ConnectReply.new instead')
  static ConnectReply create() => ConnectReply._();
  static $pb.GeneratedMessage $_createMessage() => ConnectReply._();
  @$core.override
  ConnectReply createEmptyInstance() => ConnectReply._();
  @$core.pragma('dart2js:noInline')
  static ConnectReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectReply>(
          ConnectReply.$_createMessage);
  static ConnectReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get connected => $_getBF(0);
  @$pb.TagNumber(1)
  set connected($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnected() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnected() => $_clearField(1);

  @$pb.TagNumber(2)
  HostKey get hostKey => $_getN(1);
  @$pb.TagNumber(2)
  set hostKey(HostKey value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasHostKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearHostKey() => $_clearField(2);
  @$pb.TagNumber(2)
  HostKey ensureHostKey() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.bool get needPassphrase => $_getBF(2);
  @$pb.TagNumber(3)
  set needPassphrase($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNeedPassphrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearNeedPassphrase() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get serverBanner => $_getSZ(3);
  @$pb.TagNumber(4)
  set serverBanner($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServerBanner() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerBanner() => $_clearField(4);
}

class TrustRequest extends $pb.GeneratedMessage {
  factory TrustRequest({
    $core.String? id,
    $core.String? key,
    $core.bool? replace,
  }) {
    final result = TrustRequest._();
    if (id != null) result.id = id;
    if (key != null) result.key = key;
    if (replace != null) result.replace = replace;
    return result;
  }

  TrustRequest._();

  factory TrustRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrustRequest()..mergeFromBuffer(data, registry);
  factory TrustRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrustRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrustRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: TrustRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOB(3, _omitFieldNames ? '' : 'replace')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustRequest copyWith(void Function(TrustRequest) updates) =>
      super.copyWith((message) => updates(message as TrustRequest))
          as TrustRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TrustRequest() / TrustRequest.new instead')
  static TrustRequest create() => TrustRequest._();
  static $pb.GeneratedMessage $_createMessage() => TrustRequest._();
  @$core.override
  TrustRequest createEmptyInstance() => TrustRequest._();
  @$core.pragma('dart2js:noInline')
  static TrustRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrustRequest>(
          TrustRequest.$_createMessage);
  static TrustRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  /// CHANGED: drop the keys on record and keep only this one.
  @$pb.TagNumber(3)
  $core.bool get replace => $_getBF(2);
  @$pb.TagNumber(3)
  set replace($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReplace() => $_has(2);
  @$pb.TagNumber(3)
  void clearReplace() => $_clearField(3);
}

class DiscoveredService extends $pb.GeneratedMessage {
  factory DiscoveredService({
    DiscoveredService_Kind? kind,
    $core.String? host,
    $core.int? port,
    $core.String? source,
    $core.String? title,
    $core.String? detail,
    $core.bool? confirmed,
    $core.String? connectionId,
    $core.String? userHint,
    $core.String? databaseHint,
  }) {
    final result = DiscoveredService._();
    if (kind != null) result.kind = kind;
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    if (source != null) result.source = source;
    if (title != null) result.title = title;
    if (detail != null) result.detail = detail;
    if (confirmed != null) result.confirmed = confirmed;
    if (connectionId != null) result.connectionId = connectionId;
    if (userHint != null) result.userHint = userHint;
    if (databaseHint != null) result.databaseHint = databaseHint;
    return result;
  }

  DiscoveredService._();

  factory DiscoveredService.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiscoveredService()..mergeFromBuffer(data, registry);
  factory DiscoveredService.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiscoveredService()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscoveredService',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: DiscoveredService.$_createMessage)
    ..aE<DiscoveredService_Kind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: DiscoveredService_Kind.values)
    ..aOS(2, _omitFieldNames ? '' : 'host')
    ..aI(3, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(4, _omitFieldNames ? '' : 'source')
    ..aOS(5, _omitFieldNames ? '' : 'title')
    ..aOS(6, _omitFieldNames ? '' : 'detail')
    ..aOB(7, _omitFieldNames ? '' : 'confirmed')
    ..aOS(8, _omitFieldNames ? '' : 'connectionId')
    ..aOS(9, _omitFieldNames ? '' : 'userHint')
    ..aOS(10, _omitFieldNames ? '' : 'databaseHint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoveredService clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoveredService copyWith(void Function(DiscoveredService) updates) =>
      super.copyWith((message) => updates(message as DiscoveredService))
          as DiscoveredService;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiscoveredService() / DiscoveredService.new instead')
  static DiscoveredService create() => DiscoveredService._();
  static $pb.GeneratedMessage $_createMessage() => DiscoveredService._();
  @$core.override
  DiscoveredService createEmptyInstance() => DiscoveredService._();
  @$core.pragma('dart2js:noInline')
  static DiscoveredService getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiscoveredService>(
          DiscoveredService.$_createMessage);
  static DiscoveredService? _defaultInstance;

  @$pb.TagNumber(1)
  DiscoveredService_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(DiscoveredService_Kind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get host => $_getSZ(1);
  @$pb.TagNumber(2)
  set host($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHost() => $_has(1);
  @$pb.TagNumber(2)
  void clearHost() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get port => $_getIZ(2);
  @$pb.TagNumber(3)
  set port($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearPort() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get source => $_getSZ(3);
  @$pb.TagNumber(4)
  set source($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(5)
  set title($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(5)
  void clearTitle() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get detail => $_getSZ(5);
  @$pb.TagNumber(6)
  set detail($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDetail() => $_has(5);
  @$pb.TagNumber(6)
  void clearDetail() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get confirmed => $_getBF(6);
  @$pb.TagNumber(7)
  set confirmed($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConfirmed() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfirmed() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get connectionId => $_getSZ(7);
  @$pb.TagNumber(8)
  set connectionId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasConnectionId() => $_has(7);
  @$pb.TagNumber(8)
  void clearConnectionId() => $_clearField(8);

  /// Credentials found where the server keeps them (a container's
  /// POSTGRES_USER / POSTGRES_DB): a hint for the form, not a secret.
  @$pb.TagNumber(9)
  $core.String get userHint => $_getSZ(8);
  @$pb.TagNumber(9)
  set userHint($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUserHint() => $_has(8);
  @$pb.TagNumber(9)
  void clearUserHint() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get databaseHint => $_getSZ(9);
  @$pb.TagNumber(10)
  set databaseHint($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDatabaseHint() => $_has(9);
  @$pb.TagNumber(10)
  void clearDatabaseHint() => $_clearField(10);
}

class DiscoverReply extends $pb.GeneratedMessage {
  factory DiscoverReply({
    $core.Iterable<DiscoveredService>? services,
    $core.Iterable<$core.String>? warnings,
  }) {
    final result = DiscoverReply._();
    if (services != null) result.services.addAll(services);
    if (warnings != null) result.warnings.addAll(warnings);
    return result;
  }

  DiscoverReply._();

  factory DiscoverReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiscoverReply()..mergeFromBuffer(data, registry);
  factory DiscoverReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiscoverReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DiscoverReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: DiscoverReply.$_createMessage)
    ..pPM<DiscoveredService>(1, _omitFieldNames ? '' : 'services',
        subBuilder: DiscoveredService.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'warnings')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoverReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiscoverReply copyWith(void Function(DiscoverReply) updates) =>
      super.copyWith((message) => updates(message as DiscoverReply))
          as DiscoverReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiscoverReply() / DiscoverReply.new instead')
  static DiscoverReply create() => DiscoverReply._();
  static $pb.GeneratedMessage $_createMessage() => DiscoverReply._();
  @$core.override
  DiscoverReply createEmptyInstance() => DiscoverReply._();
  @$core.pragma('dart2js:noInline')
  static DiscoverReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiscoverReply>(
          DiscoverReply.$_createMessage);
  static DiscoverReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DiscoveredService> get services => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get warnings => $_getList(1);
}

class Key extends $pb.GeneratedMessage {
  factory Key({
    $core.String? id,
    $core.String? title,
    $core.String? keyType,
    $core.String? fingerprint,
    $core.String? publicKey,
    $core.String? comment,
    $core.bool? encrypted,
    $core.bool? hasPassphrase,
    $core.bool? local,
    $core.String? group,
  }) {
    final result = Key._();
    if (id != null) result.id = id;
    if (title != null) result.title = title;
    if (keyType != null) result.keyType = keyType;
    if (fingerprint != null) result.fingerprint = fingerprint;
    if (publicKey != null) result.publicKey = publicKey;
    if (comment != null) result.comment = comment;
    if (encrypted != null) result.encrypted = encrypted;
    if (hasPassphrase != null) result.hasPassphrase = hasPassphrase;
    if (local != null) result.local = local;
    if (group != null) result.group = group;
    return result;
  }

  Key._();

  factory Key.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Key()..mergeFromBuffer(data, registry);
  factory Key.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Key()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Key',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Key.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'keyType')
    ..aOS(4, _omitFieldNames ? '' : 'fingerprint')
    ..aOS(5, _omitFieldNames ? '' : 'publicKey')
    ..aOS(6, _omitFieldNames ? '' : 'comment')
    ..aOB(7, _omitFieldNames ? '' : 'encrypted')
    ..aOB(8, _omitFieldNames ? '' : 'hasPassphrase')
    ..aOB(9, _omitFieldNames ? '' : 'local')
    ..aOS(10, _omitFieldNames ? '' : 'group')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Key clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Key copyWith(void Function(Key) updates) =>
      super.copyWith((message) => updates(message as Key)) as Key;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Key() / Key.new instead')
  static Key create() => Key._();
  static $pb.GeneratedMessage $_createMessage() => Key._();
  @$core.override
  Key createEmptyInstance() => Key._();
  @$core.pragma('dart2js:noInline')
  static Key getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Key>(Key.$_createMessage);
  static Key? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get keyType => $_getSZ(2);
  @$pb.TagNumber(3)
  set keyType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKeyType() => $_has(2);
  @$pb.TagNumber(3)
  void clearKeyType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get fingerprint => $_getSZ(3);
  @$pb.TagNumber(4)
  set fingerprint($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFingerprint() => $_has(3);
  @$pb.TagNumber(4)
  void clearFingerprint() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get publicKey => $_getSZ(4);
  @$pb.TagNumber(5)
  set publicKey($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPublicKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearPublicKey() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get comment => $_getSZ(5);
  @$pb.TagNumber(6)
  set comment($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasComment() => $_has(5);
  @$pb.TagNumber(6)
  void clearComment() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get encrypted => $_getBF(6);
  @$pb.TagNumber(7)
  set encrypted($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEncrypted() => $_has(6);
  @$pb.TagNumber(7)
  void clearEncrypted() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get hasPassphrase => $_getBF(7);
  @$pb.TagNumber(8)
  set hasPassphrase($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasPassphrase() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasPassphrase() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get local => $_getBF(8);
  @$pb.TagNumber(9)
  set local($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLocal() => $_has(8);
  @$pb.TagNumber(9)
  void clearLocal() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get group => $_getSZ(9);
  @$pb.TagNumber(10)
  set group($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasGroup() => $_has(9);
  @$pb.TagNumber(10)
  void clearGroup() => $_clearField(10);
}

class KeyList extends $pb.GeneratedMessage {
  factory KeyList({
    $core.Iterable<Key>? keys,
    $core.String? safeNote,
  }) {
    final result = KeyList._();
    if (keys != null) result.keys.addAll(keys);
    if (safeNote != null) result.safeNote = safeNote;
    return result;
  }

  KeyList._();

  factory KeyList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyList()..mergeFromBuffer(data, registry);
  factory KeyList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: KeyList.$_createMessage)
    ..pPM<Key>(1, _omitFieldNames ? '' : 'keys',
        subBuilder: Key.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'safeNote')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyList copyWith(void Function(KeyList) updates) =>
      super.copyWith((message) => updates(message as KeyList)) as KeyList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KeyList() / KeyList.new instead')
  static KeyList create() => KeyList._();
  static $pb.GeneratedMessage $_createMessage() => KeyList._();
  @$core.override
  KeyList createEmptyInstance() => KeyList._();
  @$core.pragma('dart2js:noInline')
  static KeyList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeyList>(KeyList.$_createMessage);
  static KeyList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Key> get keys => $_getList(0);

  /// The safe's keys are not available: why ("" = they are listed).
  @$pb.TagNumber(2)
  $core.String get safeNote => $_getSZ(1);
  @$pb.TagNumber(2)
  set safeNote($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSafeNote() => $_has(1);
  @$pb.TagNumber(2)
  void clearSafeNote() => $_clearField(2);
}

class LocalKey extends $pb.GeneratedMessage {
  factory LocalKey({
    $core.String? title,
    $core.String? privateKey,
    $core.String? passphrase,
  }) {
    final result = LocalKey._();
    if (title != null) result.title = title;
    if (privateKey != null) result.privateKey = privateKey;
    if (passphrase != null) result.passphrase = passphrase;
    return result;
  }

  LocalKey._();

  factory LocalKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalKey()..mergeFromBuffer(data, registry);
  factory LocalKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalKey()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocalKey',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: LocalKey.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'privateKey')
    ..aOS(3, _omitFieldNames ? '' : 'passphrase')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalKey copyWith(void Function(LocalKey) updates) =>
      super.copyWith((message) => updates(message as LocalKey)) as LocalKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LocalKey() / LocalKey.new instead')
  static LocalKey create() => LocalKey._();
  static $pb.GeneratedMessage $_createMessage() => LocalKey._();
  @$core.override
  LocalKey createEmptyInstance() => LocalKey._();
  @$core.pragma('dart2js:noInline')
  static LocalKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocalKey>(LocalKey.$_createMessage);
  static LocalKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get privateKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set privateKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrivateKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrivateKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get passphrase => $_getSZ(2);
  @$pb.TagNumber(3)
  set passphrase($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassphrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassphrase() => $_clearField(3);
}

class Connection extends $pb.GeneratedMessage {
  factory Connection({
    $core.String? id,
    $core.String? name,
    $core.String? serverId,
    Connection_Kind? kind,
    $core.String? host,
    $core.int? port,
    $core.String? user,
    $core.String? password,
    $core.String? database,
    Connection_SslMode? sslMode,
    $core.String? source,
    $core.String? color,
    $fixnum.Int64? updatedMs,
    $core.Iterable<$core.String>? databases,
    $core.bool? readOnly,
  }) {
    final result = Connection._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (serverId != null) result.serverId = serverId;
    if (kind != null) result.kind = kind;
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    if (user != null) result.user = user;
    if (password != null) result.password = password;
    if (database != null) result.database = database;
    if (sslMode != null) result.sslMode = sslMode;
    if (source != null) result.source = source;
    if (color != null) result.color = color;
    if (updatedMs != null) result.updatedMs = updatedMs;
    if (databases != null) result.databases.addAll(databases);
    if (readOnly != null) result.readOnly = readOnly;
    return result;
  }

  Connection._();

  factory Connection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Connection()..mergeFromBuffer(data, registry);
  factory Connection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Connection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Connection',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Connection.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'serverId')
    ..aE<Connection_Kind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: Connection_Kind.values)
    ..aOS(5, _omitFieldNames ? '' : 'host')
    ..aI(6, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(7, _omitFieldNames ? '' : 'user')
    ..aOS(8, _omitFieldNames ? '' : 'password')
    ..aOS(9, _omitFieldNames ? '' : 'database')
    ..aE<Connection_SslMode>(10, _omitFieldNames ? '' : 'sslMode',
        enumValues: Connection_SslMode.values)
    ..aOS(11, _omitFieldNames ? '' : 'source')
    ..aOS(12, _omitFieldNames ? '' : 'color')
    ..aInt64(13, _omitFieldNames ? '' : 'updatedMs')
    ..pPS(14, _omitFieldNames ? '' : 'databases')
    ..aOB(15, _omitFieldNames ? '' : 'readOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection copyWith(void Function(Connection) updates) =>
      super.copyWith((message) => updates(message as Connection)) as Connection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Connection() / Connection.new instead')
  static Connection create() => Connection._();
  static $pb.GeneratedMessage $_createMessage() => Connection._();
  @$core.override
  Connection createEmptyInstance() => Connection._();
  @$core.pragma('dart2js:noInline')
  static Connection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Connection>(Connection.$_createMessage);
  static Connection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serverId => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerId() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerId() => $_clearField(3);

  @$pb.TagNumber(4)
  Connection_Kind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(Connection_Kind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get host => $_getSZ(4);
  @$pb.TagNumber(5)
  set host($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHost() => $_has(4);
  @$pb.TagNumber(5)
  void clearHost() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get port => $_getIZ(5);
  @$pb.TagNumber(6)
  set port($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPort() => $_has(5);
  @$pb.TagNumber(6)
  void clearPort() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get user => $_getSZ(6);
  @$pb.TagNumber(7)
  set user($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUser() => $_has(6);
  @$pb.TagNumber(7)
  void clearUser() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get password => $_getSZ(7);
  @$pb.TagNumber(8)
  set password($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPassword() => $_has(7);
  @$pb.TagNumber(8)
  void clearPassword() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get database => $_getSZ(8);
  @$pb.TagNumber(9)
  set database($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDatabase() => $_has(8);
  @$pb.TagNumber(9)
  void clearDatabase() => $_clearField(9);

  @$pb.TagNumber(10)
  Connection_SslMode get sslMode => $_getN(9);
  @$pb.TagNumber(10)
  set sslMode(Connection_SslMode value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSslMode() => $_has(9);
  @$pb.TagNumber(10)
  void clearSslMode() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get source => $_getSZ(10);
  @$pb.TagNumber(11)
  set source($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSource() => $_has(10);
  @$pb.TagNumber(11)
  void clearSource() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get color => $_getSZ(11);
  @$pb.TagNumber(12)
  set color($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasColor() => $_has(11);
  @$pb.TagNumber(12)
  void clearColor() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get updatedMs => $_getI64(12);
  @$pb.TagNumber(13)
  set updatedMs($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasUpdatedMs() => $_has(12);
  @$pb.TagNumber(13)
  void clearUpdatedMs() => $_clearField(13);

  /// Show these databases only ("" = all).
  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get databases => $_getList(13);

  @$pb.TagNumber(15)
  $core.bool get readOnly => $_getBF(14);
  @$pb.TagNumber(15)
  set readOnly($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasReadOnly() => $_has(14);
  @$pb.TagNumber(15)
  void clearReadOnly() => $_clearField(15);
}

class ConnectionList extends $pb.GeneratedMessage {
  factory ConnectionList({
    $core.Iterable<Connection>? connections,
  }) {
    final result = ConnectionList._();
    if (connections != null) result.connections.addAll(connections);
    return result;
  }

  ConnectionList._();

  factory ConnectionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionList()..mergeFromBuffer(data, registry);
  factory ConnectionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectionList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ConnectionList.$_createMessage)
    ..pPM<Connection>(1, _omitFieldNames ? '' : 'connections',
        subBuilder: Connection.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionList copyWith(void Function(ConnectionList) updates) =>
      super.copyWith((message) => updates(message as ConnectionList))
          as ConnectionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectionList() / ConnectionList.new instead')
  static ConnectionList create() => ConnectionList._();
  static $pb.GeneratedMessage $_createMessage() => ConnectionList._();
  @$core.override
  ConnectionList createEmptyInstance() => ConnectionList._();
  @$core.pragma('dart2js:noInline')
  static ConnectionList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectionList>(
          ConnectionList.$_createMessage);
  static ConnectionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Connection> get connections => $_getList(0);
}

class TestReply extends $pb.GeneratedMessage {
  factory TestReply({
    $core.bool? ok,
    $core.String? serverVersion,
    $core.String? error,
    $fixnum.Int64? latencyMs,
  }) {
    final result = TestReply._();
    if (ok != null) result.ok = ok;
    if (serverVersion != null) result.serverVersion = serverVersion;
    if (error != null) result.error = error;
    if (latencyMs != null) result.latencyMs = latencyMs;
    return result;
  }

  TestReply._();

  factory TestReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TestReply()..mergeFromBuffer(data, registry);
  factory TestReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TestReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TestReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: TestReply.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'serverVersion')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..aInt64(4, _omitFieldNames ? '' : 'latencyMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestReply copyWith(void Function(TestReply) updates) =>
      super.copyWith((message) => updates(message as TestReply)) as TestReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TestReply() / TestReply.new instead')
  static TestReply create() => TestReply._();
  static $pb.GeneratedMessage $_createMessage() => TestReply._();
  @$core.override
  TestReply createEmptyInstance() => TestReply._();
  @$core.pragma('dart2js:noInline')
  static TestReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestReply>(TestReply.$_createMessage);
  static TestReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serverVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get latencyMs => $_getI64(3);
  @$pb.TagNumber(4)
  set latencyMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLatencyMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatencyMs() => $_clearField(4);
}

class Database extends $pb.GeneratedMessage {
  factory Database({
    $core.String? name,
    $core.String? owner,
    $fixnum.Int64? sizeBytes,
    $core.bool? isTemplate,
    $core.bool? canConnect,
  }) {
    final result = Database._();
    if (name != null) result.name = name;
    if (owner != null) result.owner = owner;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (isTemplate != null) result.isTemplate = isTemplate;
    if (canConnect != null) result.canConnect = canConnect;
    return result;
  }

  Database._();

  factory Database.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Database()..mergeFromBuffer(data, registry);
  factory Database.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Database()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Database',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Database.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'owner')
    ..aInt64(3, _omitFieldNames ? '' : 'sizeBytes')
    ..aOB(4, _omitFieldNames ? '' : 'isTemplate')
    ..aOB(5, _omitFieldNames ? '' : 'canConnect')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Database clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Database copyWith(void Function(Database) updates) =>
      super.copyWith((message) => updates(message as Database)) as Database;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Database() / Database.new instead')
  static Database create() => Database._();
  static $pb.GeneratedMessage $_createMessage() => Database._();
  @$core.override
  Database createEmptyInstance() => Database._();
  @$core.pragma('dart2js:noInline')
  static Database getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Database>(Database.$_createMessage);
  static Database? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get owner => $_getSZ(1);
  @$pb.TagNumber(2)
  set owner($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwner() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwner() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearSizeBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isTemplate => $_getBF(3);
  @$pb.TagNumber(4)
  set isTemplate($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsTemplate() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsTemplate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get canConnect => $_getBF(4);
  @$pb.TagNumber(5)
  set canConnect($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCanConnect() => $_has(4);
  @$pb.TagNumber(5)
  void clearCanConnect() => $_clearField(5);
}

class DatabaseList extends $pb.GeneratedMessage {
  factory DatabaseList({
    $core.Iterable<Database>? databases,
    $core.String? serverVersion,
  }) {
    final result = DatabaseList._();
    if (databases != null) result.databases.addAll(databases);
    if (serverVersion != null) result.serverVersion = serverVersion;
    return result;
  }

  DatabaseList._();

  factory DatabaseList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DatabaseList()..mergeFromBuffer(data, registry);
  factory DatabaseList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DatabaseList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DatabaseList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: DatabaseList.$_createMessage)
    ..pPM<Database>(1, _omitFieldNames ? '' : 'databases',
        subBuilder: Database.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'serverVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DatabaseList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DatabaseList copyWith(void Function(DatabaseList) updates) =>
      super.copyWith((message) => updates(message as DatabaseList))
          as DatabaseList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DatabaseList() / DatabaseList.new instead')
  static DatabaseList create() => DatabaseList._();
  static $pb.GeneratedMessage $_createMessage() => DatabaseList._();
  @$core.override
  DatabaseList createEmptyInstance() => DatabaseList._();
  @$core.pragma('dart2js:noInline')
  static DatabaseList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DatabaseList>(
          DatabaseList.$_createMessage);
  static DatabaseList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Database> get databases => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get serverVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set serverVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerVersion() => $_clearField(2);
}

class DbRef extends $pb.GeneratedMessage {
  factory DbRef({
    $core.String? connectionId,
    $core.String? database,
  }) {
    final result = DbRef._();
    if (connectionId != null) result.connectionId = connectionId;
    if (database != null) result.database = database;
    return result;
  }

  DbRef._();

  factory DbRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DbRef()..mergeFromBuffer(data, registry);
  factory DbRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DbRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DbRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: DbRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DbRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DbRef copyWith(void Function(DbRef) updates) =>
      super.copyWith((message) => updates(message as DbRef)) as DbRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DbRef() / DbRef.new instead')
  static DbRef create() => DbRef._();
  static $pb.GeneratedMessage $_createMessage() => DbRef._();
  @$core.override
  DbRef createEmptyInstance() => DbRef._();
  @$core.pragma('dart2js:noInline')
  static DbRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DbRef>(DbRef.$_createMessage);
  static DbRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);
}

class Schema extends $pb.GeneratedMessage {
  factory Schema({
    $core.String? name,
    $core.String? owner,
    $core.bool? system,
  }) {
    final result = Schema._();
    if (name != null) result.name = name;
    if (owner != null) result.owner = owner;
    if (system != null) result.system = system;
    return result;
  }

  Schema._();

  factory Schema.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Schema()..mergeFromBuffer(data, registry);
  factory Schema.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Schema()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Schema',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Schema.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'owner')
    ..aOB(3, _omitFieldNames ? '' : 'system')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Schema clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Schema copyWith(void Function(Schema) updates) =>
      super.copyWith((message) => updates(message as Schema)) as Schema;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Schema() / Schema.new instead')
  static Schema create() => Schema._();
  static $pb.GeneratedMessage $_createMessage() => Schema._();
  @$core.override
  Schema createEmptyInstance() => Schema._();
  @$core.pragma('dart2js:noInline')
  static Schema getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Schema>(Schema.$_createMessage);
  static Schema? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get owner => $_getSZ(1);
  @$pb.TagNumber(2)
  set owner($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOwner() => $_has(1);
  @$pb.TagNumber(2)
  void clearOwner() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get system => $_getBF(2);
  @$pb.TagNumber(3)
  set system($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSystem() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystem() => $_clearField(3);
}

class SchemaList extends $pb.GeneratedMessage {
  factory SchemaList({
    $core.Iterable<Schema>? schemas,
  }) {
    final result = SchemaList._();
    if (schemas != null) result.schemas.addAll(schemas);
    return result;
  }

  SchemaList._();

  factory SchemaList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SchemaList()..mergeFromBuffer(data, registry);
  factory SchemaList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SchemaList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SchemaList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: SchemaList.$_createMessage)
    ..pPM<Schema>(1, _omitFieldNames ? '' : 'schemas',
        subBuilder: Schema.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaList copyWith(void Function(SchemaList) updates) =>
      super.copyWith((message) => updates(message as SchemaList)) as SchemaList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SchemaList() / SchemaList.new instead')
  static SchemaList create() => SchemaList._();
  static $pb.GeneratedMessage $_createMessage() => SchemaList._();
  @$core.override
  SchemaList createEmptyInstance() => SchemaList._();
  @$core.pragma('dart2js:noInline')
  static SchemaList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SchemaList>(SchemaList.$_createMessage);
  static SchemaList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Schema> get schemas => $_getList(0);
}

class SchemaRef extends $pb.GeneratedMessage {
  factory SchemaRef({
    $core.String? connectionId,
    $core.String? database,
    $core.String? schema,
  }) {
    final result = SchemaRef._();
    if (connectionId != null) result.connectionId = connectionId;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    return result;
  }

  SchemaRef._();

  factory SchemaRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SchemaRef()..mergeFromBuffer(data, registry);
  factory SchemaRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SchemaRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SchemaRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: SchemaRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'schema')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaRef copyWith(void Function(SchemaRef) updates) =>
      super.copyWith((message) => updates(message as SchemaRef)) as SchemaRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SchemaRef() / SchemaRef.new instead')
  static SchemaRef create() => SchemaRef._();
  static $pb.GeneratedMessage $_createMessage() => SchemaRef._();
  @$core.override
  SchemaRef createEmptyInstance() => SchemaRef._();
  @$core.pragma('dart2js:noInline')
  static SchemaRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SchemaRef>(SchemaRef.$_createMessage);
  static SchemaRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get schema => $_getSZ(2);
  @$pb.TagNumber(3)
  set schema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);
}

class DbObject extends $pb.GeneratedMessage {
  factory DbObject({
    DbObject_Kind? kind,
    $core.String? name,
    $core.String? comment,
    $fixnum.Int64? rowsEstimate,
    $core.String? signature,
  }) {
    final result = DbObject._();
    if (kind != null) result.kind = kind;
    if (name != null) result.name = name;
    if (comment != null) result.comment = comment;
    if (rowsEstimate != null) result.rowsEstimate = rowsEstimate;
    if (signature != null) result.signature = signature;
    return result;
  }

  DbObject._();

  factory DbObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DbObject()..mergeFromBuffer(data, registry);
  factory DbObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DbObject()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DbObject',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: DbObject.$_createMessage)
    ..aE<DbObject_Kind>(1, _omitFieldNames ? '' : 'kind',
        enumValues: DbObject_Kind.values)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'comment')
    ..aInt64(4, _omitFieldNames ? '' : 'rowsEstimate')
    ..aOS(5, _omitFieldNames ? '' : 'signature')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DbObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DbObject copyWith(void Function(DbObject) updates) =>
      super.copyWith((message) => updates(message as DbObject)) as DbObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DbObject() / DbObject.new instead')
  static DbObject create() => DbObject._();
  static $pb.GeneratedMessage $_createMessage() => DbObject._();
  @$core.override
  DbObject createEmptyInstance() => DbObject._();
  @$core.pragma('dart2js:noInline')
  static DbObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DbObject>(DbObject.$_createMessage);
  static DbObject? _defaultInstance;

  @$pb.TagNumber(1)
  DbObject_Kind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(DbObject_Kind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get comment => $_getSZ(2);
  @$pb.TagNumber(3)
  set comment($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasComment() => $_has(2);
  @$pb.TagNumber(3)
  void clearComment() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get rowsEstimate => $_getI64(3);
  @$pb.TagNumber(4)
  set rowsEstimate($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRowsEstimate() => $_has(3);
  @$pb.TagNumber(4)
  void clearRowsEstimate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get signature => $_getSZ(4);
  @$pb.TagNumber(5)
  set signature($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearSignature() => $_clearField(5);
}

class ObjectList extends $pb.GeneratedMessage {
  factory ObjectList({
    $core.Iterable<DbObject>? objects,
  }) {
    final result = ObjectList._();
    if (objects != null) result.objects.addAll(objects);
    return result;
  }

  ObjectList._();

  factory ObjectList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectList()..mergeFromBuffer(data, registry);
  factory ObjectList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ObjectList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ObjectList.$_createMessage)
    ..pPM<DbObject>(1, _omitFieldNames ? '' : 'objects',
        subBuilder: DbObject.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectList copyWith(void Function(ObjectList) updates) =>
      super.copyWith((message) => updates(message as ObjectList)) as ObjectList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ObjectList() / ObjectList.new instead')
  static ObjectList create() => ObjectList._();
  static $pb.GeneratedMessage $_createMessage() => ObjectList._();
  @$core.override
  ObjectList createEmptyInstance() => ObjectList._();
  @$core.pragma('dart2js:noInline')
  static ObjectList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ObjectList>(ObjectList.$_createMessage);
  static ObjectList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DbObject> get objects => $_getList(0);
}

class ObjectRef extends $pb.GeneratedMessage {
  factory ObjectRef({
    $core.String? connectionId,
    $core.String? database,
    $core.String? schema,
    $core.String? name,
    DbObject_Kind? kind,
    $core.String? signature,
  }) {
    final result = ObjectRef._();
    if (connectionId != null) result.connectionId = connectionId;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (signature != null) result.signature = signature;
    return result;
  }

  ObjectRef._();

  factory ObjectRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectRef()..mergeFromBuffer(data, registry);
  factory ObjectRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ObjectRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ObjectRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'schema')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aE<DbObject_Kind>(5, _omitFieldNames ? '' : 'kind',
        enumValues: DbObject_Kind.values)
    ..aOS(6, _omitFieldNames ? '' : 'signature')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectRef copyWith(void Function(ObjectRef) updates) =>
      super.copyWith((message) => updates(message as ObjectRef)) as ObjectRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ObjectRef() / ObjectRef.new instead')
  static ObjectRef create() => ObjectRef._();
  static $pb.GeneratedMessage $_createMessage() => ObjectRef._();
  @$core.override
  ObjectRef createEmptyInstance() => ObjectRef._();
  @$core.pragma('dart2js:noInline')
  static ObjectRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ObjectRef>(ObjectRef.$_createMessage);
  static ObjectRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get schema => $_getSZ(2);
  @$pb.TagNumber(3)
  set schema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  DbObject_Kind get kind => $_getN(4);
  @$pb.TagNumber(5)
  set kind(DbObject_Kind value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get signature => $_getSZ(5);
  @$pb.TagNumber(6)
  set signature($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSignature() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignature() => $_clearField(6);
}

class Column extends $pb.GeneratedMessage {
  factory Column({
    $core.String? name,
    $core.String? type,
    $core.bool? nullable,
    $core.String? default_4,
    $core.String? comment,
    $core.bool? primaryKey,
    $core.int? typeOid,
    $core.int? position,
    $core.bool? identity,
    $core.bool? generated,
  }) {
    final result = Column._();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (nullable != null) result.nullable = nullable;
    if (default_4 != null) result.default_4 = default_4;
    if (comment != null) result.comment = comment;
    if (primaryKey != null) result.primaryKey = primaryKey;
    if (typeOid != null) result.typeOid = typeOid;
    if (position != null) result.position = position;
    if (identity != null) result.identity = identity;
    if (generated != null) result.generated = generated;
    return result;
  }

  Column._();

  factory Column.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Column()..mergeFromBuffer(data, registry);
  factory Column.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Column()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Column',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Column.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOB(3, _omitFieldNames ? '' : 'nullable')
    ..aOS(4, _omitFieldNames ? '' : 'default')
    ..aOS(5, _omitFieldNames ? '' : 'comment')
    ..aOB(6, _omitFieldNames ? '' : 'primaryKey')
    ..aI(7, _omitFieldNames ? '' : 'typeOid', fieldType: $pb.PbFieldType.OU3)
    ..aI(8, _omitFieldNames ? '' : 'position')
    ..aOB(9, _omitFieldNames ? '' : 'identity')
    ..aOB(10, _omitFieldNames ? '' : 'generated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Column clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Column copyWith(void Function(Column) updates) =>
      super.copyWith((message) => updates(message as Column)) as Column;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Column() / Column.new instead')
  static Column create() => Column._();
  static $pb.GeneratedMessage $_createMessage() => Column._();
  @$core.override
  Column createEmptyInstance() => Column._();
  @$core.pragma('dart2js:noInline')
  static Column getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Column>(Column.$_createMessage);
  static Column? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get nullable => $_getBF(2);
  @$pb.TagNumber(3)
  set nullable($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNullable() => $_has(2);
  @$pb.TagNumber(3)
  void clearNullable() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get default_4 => $_getSZ(3);
  @$pb.TagNumber(4)
  set default_4($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDefault_4() => $_has(3);
  @$pb.TagNumber(4)
  void clearDefault_4() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get comment => $_getSZ(4);
  @$pb.TagNumber(5)
  set comment($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasComment() => $_has(4);
  @$pb.TagNumber(5)
  void clearComment() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get primaryKey => $_getBF(5);
  @$pb.TagNumber(6)
  set primaryKey($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPrimaryKey() => $_has(5);
  @$pb.TagNumber(6)
  void clearPrimaryKey() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get typeOid => $_getIZ(6);
  @$pb.TagNumber(7)
  set typeOid($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTypeOid() => $_has(6);
  @$pb.TagNumber(7)
  void clearTypeOid() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get position => $_getIZ(7);
  @$pb.TagNumber(8)
  set position($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasPosition() => $_has(7);
  @$pb.TagNumber(8)
  void clearPosition() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get identity => $_getBF(8);
  @$pb.TagNumber(9)
  set identity($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIdentity() => $_has(8);
  @$pb.TagNumber(9)
  void clearIdentity() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get generated => $_getBF(9);
  @$pb.TagNumber(10)
  set generated($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasGenerated() => $_has(9);
  @$pb.TagNumber(10)
  void clearGenerated() => $_clearField(10);
}

class Index extends $pb.GeneratedMessage {
  factory Index({
    $core.String? name,
    $core.String? definition,
    $core.bool? unique,
    $core.bool? primary,
  }) {
    final result = Index._();
    if (name != null) result.name = name;
    if (definition != null) result.definition = definition;
    if (unique != null) result.unique = unique;
    if (primary != null) result.primary = primary;
    return result;
  }

  Index._();

  factory Index.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Index()..mergeFromBuffer(data, registry);
  factory Index.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Index()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Index',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Index.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'definition')
    ..aOB(3, _omitFieldNames ? '' : 'unique')
    ..aOB(4, _omitFieldNames ? '' : 'primary')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Index clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Index copyWith(void Function(Index) updates) =>
      super.copyWith((message) => updates(message as Index)) as Index;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Index() / Index.new instead')
  static Index create() => Index._();
  static $pb.GeneratedMessage $_createMessage() => Index._();
  @$core.override
  Index createEmptyInstance() => Index._();
  @$core.pragma('dart2js:noInline')
  static Index getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Index>(Index.$_createMessage);
  static Index? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get definition => $_getSZ(1);
  @$pb.TagNumber(2)
  set definition($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDefinition() => $_has(1);
  @$pb.TagNumber(2)
  void clearDefinition() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get unique => $_getBF(2);
  @$pb.TagNumber(3)
  set unique($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnique() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnique() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get primary => $_getBF(3);
  @$pb.TagNumber(4)
  set primary($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPrimary() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrimary() => $_clearField(4);
}

class Constraint extends $pb.GeneratedMessage {
  factory Constraint({
    $core.String? name,
    $core.String? type,
    $core.String? definition,
  }) {
    final result = Constraint._();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (definition != null) result.definition = definition;
    return result;
  }

  Constraint._();

  factory Constraint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Constraint()..mergeFromBuffer(data, registry);
  factory Constraint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Constraint()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Constraint',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Constraint.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'type')
    ..aOS(3, _omitFieldNames ? '' : 'definition')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Constraint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Constraint copyWith(void Function(Constraint) updates) =>
      super.copyWith((message) => updates(message as Constraint)) as Constraint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Constraint() / Constraint.new instead')
  static Constraint create() => Constraint._();
  static $pb.GeneratedMessage $_createMessage() => Constraint._();
  @$core.override
  Constraint createEmptyInstance() => Constraint._();
  @$core.pragma('dart2js:noInline')
  static Constraint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Constraint>(Constraint.$_createMessage);
  static Constraint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get type => $_getSZ(1);
  @$pb.TagNumber(2)
  set type($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get definition => $_getSZ(2);
  @$pb.TagNumber(3)
  set definition($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDefinition() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefinition() => $_clearField(3);
}

class ObjectInfo extends $pb.GeneratedMessage {
  factory ObjectInfo({
    DbObject? object,
    $core.Iterable<Column>? columns,
    $core.Iterable<Index>? indexes,
    $core.Iterable<Constraint>? constraints,
    $core.String? ddl,
    $core.Iterable<$core.String>? primaryKey,
    $core.String? owner,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = ObjectInfo._();
    if (object != null) result.object = object;
    if (columns != null) result.columns.addAll(columns);
    if (indexes != null) result.indexes.addAll(indexes);
    if (constraints != null) result.constraints.addAll(constraints);
    if (ddl != null) result.ddl = ddl;
    if (primaryKey != null) result.primaryKey.addAll(primaryKey);
    if (owner != null) result.owner = owner;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  ObjectInfo._();

  factory ObjectInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectInfo()..mergeFromBuffer(data, registry);
  factory ObjectInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObjectInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ObjectInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ObjectInfo.$_createMessage)
    ..aOM<DbObject>(1, _omitFieldNames ? '' : 'object',
        subBuilder: DbObject.$_createMessage)
    ..pPM<Column>(2, _omitFieldNames ? '' : 'columns',
        subBuilder: Column.$_createMessage)
    ..pPM<Index>(3, _omitFieldNames ? '' : 'indexes',
        subBuilder: Index.$_createMessage)
    ..pPM<Constraint>(4, _omitFieldNames ? '' : 'constraints',
        subBuilder: Constraint.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'ddl')
    ..pPS(6, _omitFieldNames ? '' : 'primaryKey')
    ..aOS(7, _omitFieldNames ? '' : 'owner')
    ..aInt64(8, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObjectInfo copyWith(void Function(ObjectInfo) updates) =>
      super.copyWith((message) => updates(message as ObjectInfo)) as ObjectInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ObjectInfo() / ObjectInfo.new instead')
  static ObjectInfo create() => ObjectInfo._();
  static $pb.GeneratedMessage $_createMessage() => ObjectInfo._();
  @$core.override
  ObjectInfo createEmptyInstance() => ObjectInfo._();
  @$core.pragma('dart2js:noInline')
  static ObjectInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ObjectInfo>(ObjectInfo.$_createMessage);
  static ObjectInfo? _defaultInstance;

  @$pb.TagNumber(1)
  DbObject get object => $_getN(0);
  @$pb.TagNumber(1)
  set object(DbObject value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasObject() => $_has(0);
  @$pb.TagNumber(1)
  void clearObject() => $_clearField(1);
  @$pb.TagNumber(1)
  DbObject ensureObject() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<Column> get columns => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<Index> get indexes => $_getList(2);

  @$pb.TagNumber(4)
  $pb.PbList<Constraint> get constraints => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get ddl => $_getSZ(4);
  @$pb.TagNumber(5)
  set ddl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDdl() => $_has(4);
  @$pb.TagNumber(5)
  void clearDdl() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get primaryKey => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get owner => $_getSZ(6);
  @$pb.TagNumber(7)
  set owner($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOwner() => $_has(6);
  @$pb.TagNumber(7)
  void clearOwner() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get sizeBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSizeBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearSizeBytes() => $_clearField(8);
}

class ResultColumn extends $pb.GeneratedMessage {
  factory ResultColumn({
    $core.String? name,
    $core.int? typeOid,
    $core.String? type,
    $core.String? tableColumn,
  }) {
    final result = ResultColumn._();
    if (name != null) result.name = name;
    if (typeOid != null) result.typeOid = typeOid;
    if (type != null) result.type = type;
    if (tableColumn != null) result.tableColumn = tableColumn;
    return result;
  }

  ResultColumn._();

  factory ResultColumn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResultColumn()..mergeFromBuffer(data, registry);
  factory ResultColumn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResultColumn()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResultColumn',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ResultColumn.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'typeOid', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'type')
    ..aOS(4, _omitFieldNames ? '' : 'tableColumn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultColumn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultColumn copyWith(void Function(ResultColumn) updates) =>
      super.copyWith((message) => updates(message as ResultColumn))
          as ResultColumn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResultColumn() / ResultColumn.new instead')
  static ResultColumn create() => ResultColumn._();
  static $pb.GeneratedMessage $_createMessage() => ResultColumn._();
  @$core.override
  ResultColumn createEmptyInstance() => ResultColumn._();
  @$core.pragma('dart2js:noInline')
  static ResultColumn getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResultColumn>(
          ResultColumn.$_createMessage);
  static ResultColumn? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get typeOid => $_getIZ(1);
  @$pb.TagNumber(2)
  set typeOid($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTypeOid() => $_has(1);
  @$pb.TagNumber(2)
  void clearTypeOid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get type => $_getSZ(2);
  @$pb.TagNumber(3)
  set type($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  /// ReadTable: the column of the table (editable), else "".
  @$pb.TagNumber(4)
  $core.String get tableColumn => $_getSZ(3);
  @$pb.TagNumber(4)
  set tableColumn($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTableColumn() => $_has(3);
  @$pb.TagNumber(4)
  void clearTableColumn() => $_clearField(4);
}

class Cell extends $pb.GeneratedMessage {
  factory Cell({
    $core.String? text,
    $core.bool? null_2,
  }) {
    final result = Cell._();
    if (text != null) result.text = text;
    if (null_2 != null) result.null_2 = null_2;
    return result;
  }

  Cell._();

  factory Cell.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Cell()..mergeFromBuffer(data, registry);
  factory Cell.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Cell()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Cell',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Cell.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..aOB(2, _omitFieldNames ? '' : 'null')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cell clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Cell copyWith(void Function(Cell) updates) =>
      super.copyWith((message) => updates(message as Cell)) as Cell;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Cell() / Cell.new instead')
  static Cell create() => Cell._();
  static $pb.GeneratedMessage $_createMessage() => Cell._();
  @$core.override
  Cell createEmptyInstance() => Cell._();
  @$core.pragma('dart2js:noInline')
  static Cell getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Cell>(Cell.$_createMessage);
  static Cell? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get null_2 => $_getBF(1);
  @$pb.TagNumber(2)
  set null_2($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNull_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearNull_2() => $_clearField(2);
}

class Row extends $pb.GeneratedMessage {
  factory Row({
    $core.Iterable<Cell>? cells,
  }) {
    final result = Row._();
    if (cells != null) result.cells.addAll(cells);
    return result;
  }

  Row._();

  factory Row.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Row()..mergeFromBuffer(data, registry);
  factory Row.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Row()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Row',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Row.$_createMessage)
    ..pPM<Cell>(1, _omitFieldNames ? '' : 'cells',
        subBuilder: Cell.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Row clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Row copyWith(void Function(Row) updates) =>
      super.copyWith((message) => updates(message as Row)) as Row;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Row() / Row.new instead')
  static Row create() => Row._();
  static $pb.GeneratedMessage $_createMessage() => Row._();
  @$core.override
  Row createEmptyInstance() => Row._();
  @$core.pragma('dart2js:noInline')
  static Row getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Row>(Row.$_createMessage);
  static Row? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Cell> get cells => $_getList(0);
}

class ResultSet extends $pb.GeneratedMessage {
  factory ResultSet({
    $core.Iterable<ResultColumn>? columns,
    $core.Iterable<Row>? rows,
    $core.bool? truncated,
    $core.String? commandTag,
    $fixnum.Int64? rowsAffected,
    $core.String? error,
    $core.String? errorDetail,
    $fixnum.Int64? durationMs,
    $core.String? statement,
    $core.Iterable<$core.String>? keyColumns,
    $core.bool? hasCtid,
    $fixnum.Int64? totalEstimate,
    $core.Iterable<$core.String>? notices,
    $core.int? statementStart,
    $core.int? statementEnd,
    $core.int? errorOffset,
  }) {
    final result = ResultSet._();
    if (columns != null) result.columns.addAll(columns);
    if (rows != null) result.rows.addAll(rows);
    if (truncated != null) result.truncated = truncated;
    if (commandTag != null) result.commandTag = commandTag;
    if (rowsAffected != null) result.rowsAffected = rowsAffected;
    if (error != null) result.error = error;
    if (errorDetail != null) result.errorDetail = errorDetail;
    if (durationMs != null) result.durationMs = durationMs;
    if (statement != null) result.statement = statement;
    if (keyColumns != null) result.keyColumns.addAll(keyColumns);
    if (hasCtid != null) result.hasCtid = hasCtid;
    if (totalEstimate != null) result.totalEstimate = totalEstimate;
    if (notices != null) result.notices.addAll(notices);
    if (statementStart != null) result.statementStart = statementStart;
    if (statementEnd != null) result.statementEnd = statementEnd;
    if (errorOffset != null) result.errorOffset = errorOffset;
    return result;
  }

  ResultSet._();

  factory ResultSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResultSet()..mergeFromBuffer(data, registry);
  factory ResultSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResultSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResultSet',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ResultSet.$_createMessage)
    ..pPM<ResultColumn>(1, _omitFieldNames ? '' : 'columns',
        subBuilder: ResultColumn.$_createMessage)
    ..pPM<Row>(2, _omitFieldNames ? '' : 'rows',
        subBuilder: Row.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'truncated')
    ..aOS(4, _omitFieldNames ? '' : 'commandTag')
    ..aInt64(5, _omitFieldNames ? '' : 'rowsAffected')
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..aOS(7, _omitFieldNames ? '' : 'errorDetail')
    ..aInt64(8, _omitFieldNames ? '' : 'durationMs')
    ..aOS(9, _omitFieldNames ? '' : 'statement')
    ..pPS(10, _omitFieldNames ? '' : 'keyColumns')
    ..aOB(11, _omitFieldNames ? '' : 'hasCtid')
    ..aInt64(12, _omitFieldNames ? '' : 'totalEstimate')
    ..pPS(13, _omitFieldNames ? '' : 'notices')
    ..aI(14, _omitFieldNames ? '' : 'statementStart')
    ..aI(15, _omitFieldNames ? '' : 'statementEnd')
    ..aI(16, _omitFieldNames ? '' : 'errorOffset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResultSet copyWith(void Function(ResultSet) updates) =>
      super.copyWith((message) => updates(message as ResultSet)) as ResultSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResultSet() / ResultSet.new instead')
  static ResultSet create() => ResultSet._();
  static $pb.GeneratedMessage $_createMessage() => ResultSet._();
  @$core.override
  ResultSet createEmptyInstance() => ResultSet._();
  @$core.pragma('dart2js:noInline')
  static ResultSet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResultSet>(ResultSet.$_createMessage);
  static ResultSet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ResultColumn> get columns => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<Row> get rows => $_getList(1);

  /// There are more rows than returned (max_rows / page size).
  @$pb.TagNumber(3)
  $core.bool get truncated => $_getBF(2);
  @$pb.TagNumber(3)
  set truncated($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTruncated() => $_has(2);
  @$pb.TagNumber(3)
  void clearTruncated() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get commandTag => $_getSZ(3);
  @$pb.TagNumber(4)
  set commandTag($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCommandTag() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommandTag() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get rowsAffected => $_getI64(4);
  @$pb.TagNumber(5)
  set rowsAffected($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRowsAffected() => $_has(4);
  @$pb.TagNumber(5)
  void clearRowsAffected() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get errorDetail => $_getSZ(6);
  @$pb.TagNumber(7)
  set errorDetail($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasErrorDetail() => $_has(6);
  @$pb.TagNumber(7)
  void clearErrorDetail() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get durationMs => $_getI64(7);
  @$pb.TagNumber(8)
  set durationMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDurationMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearDurationMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get statement => $_getSZ(8);
  @$pb.TagNumber(9)
  set statement($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStatement() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatement() => $_clearField(9);

  /// ReadTable: how rows are identified for edits: the primary key columns
  /// (by name), or "ctid" (a hidden first column) when there is none.
  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get keyColumns => $_getList(9);

  @$pb.TagNumber(11)
  $core.bool get hasCtid => $_getBF(10);
  @$pb.TagNumber(11)
  set hasCtid($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasHasCtid() => $_has(10);
  @$pb.TagNumber(11)
  void clearHasCtid() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get totalEstimate => $_getI64(11);
  @$pb.TagNumber(12)
  set totalEstimate($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTotalEstimate() => $_has(11);
  @$pb.TagNumber(12)
  void clearTotalEstimate() => $_clearField(12);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get notices => $_getList(12);

  /// Where the statement is in ExecuteRequest.sql (UTF-16 offsets).
  @$pb.TagNumber(14)
  $core.int get statementStart => $_getIZ(13);
  @$pb.TagNumber(14)
  set statementStart($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasStatementStart() => $_has(13);
  @$pb.TagNumber(14)
  void clearStatementStart() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get statementEnd => $_getIZ(14);
  @$pb.TagNumber(15)
  set statementEnd($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasStatementEnd() => $_has(14);
  @$pb.TagNumber(15)
  void clearStatementEnd() => $_clearField(15);

  /// The error's position in ExecuteRequest.sql (UTF-16), -1 = none.
  @$pb.TagNumber(16)
  $core.int get errorOffset => $_getIZ(15);
  @$pb.TagNumber(16)
  set errorOffset($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasErrorOffset() => $_has(15);
  @$pb.TagNumber(16)
  void clearErrorOffset() => $_clearField(16);
}

class Sort extends $pb.GeneratedMessage {
  factory Sort({
    $core.String? column,
    $core.bool? desc,
  }) {
    final result = Sort._();
    if (column != null) result.column = column;
    if (desc != null) result.desc = desc;
    return result;
  }

  Sort._();

  factory Sort.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Sort()..mergeFromBuffer(data, registry);
  factory Sort.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Sort()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Sort',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Sort.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'column')
    ..aOB(2, _omitFieldNames ? '' : 'desc')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Sort clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Sort copyWith(void Function(Sort) updates) =>
      super.copyWith((message) => updates(message as Sort)) as Sort;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Sort() / Sort.new instead')
  static Sort create() => Sort._();
  static $pb.GeneratedMessage $_createMessage() => Sort._();
  @$core.override
  Sort createEmptyInstance() => Sort._();
  @$core.pragma('dart2js:noInline')
  static Sort getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Sort>(Sort.$_createMessage);
  static Sort? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get column => $_getSZ(0);
  @$pb.TagNumber(1)
  set column($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get desc => $_getBF(1);
  @$pb.TagNumber(2)
  set desc($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDesc() => $_has(1);
  @$pb.TagNumber(2)
  void clearDesc() => $_clearField(2);
}

class ReadTableRequest extends $pb.GeneratedMessage {
  factory ReadTableRequest({
    $core.String? connectionId,
    $core.String? database,
    $core.String? schema,
    $core.String? table,
    $fixnum.Int64? offset,
    $core.int? limit,
    $core.Iterable<Sort>? sort,
    $core.String? filter,
  }) {
    final result = ReadTableRequest._();
    if (connectionId != null) result.connectionId = connectionId;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (table != null) result.table = table;
    if (offset != null) result.offset = offset;
    if (limit != null) result.limit = limit;
    if (sort != null) result.sort.addAll(sort);
    if (filter != null) result.filter = filter;
    return result;
  }

  ReadTableRequest._();

  factory ReadTableRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadTableRequest()..mergeFromBuffer(data, registry);
  factory ReadTableRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadTableRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadTableRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ReadTableRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'schema')
    ..aOS(4, _omitFieldNames ? '' : 'table')
    ..aInt64(5, _omitFieldNames ? '' : 'offset')
    ..aI(6, _omitFieldNames ? '' : 'limit')
    ..pPM<Sort>(7, _omitFieldNames ? '' : 'sort',
        subBuilder: Sort.$_createMessage)
    ..aOS(8, _omitFieldNames ? '' : 'filter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadTableRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadTableRequest copyWith(void Function(ReadTableRequest) updates) =>
      super.copyWith((message) => updates(message as ReadTableRequest))
          as ReadTableRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReadTableRequest() / ReadTableRequest.new instead')
  static ReadTableRequest create() => ReadTableRequest._();
  static $pb.GeneratedMessage $_createMessage() => ReadTableRequest._();
  @$core.override
  ReadTableRequest createEmptyInstance() => ReadTableRequest._();
  @$core.pragma('dart2js:noInline')
  static ReadTableRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReadTableRequest>(
          ReadTableRequest.$_createMessage);
  static ReadTableRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get schema => $_getSZ(2);
  @$pb.TagNumber(3)
  set schema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get table => $_getSZ(3);
  @$pb.TagNumber(4)
  set table($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTable() => $_has(3);
  @$pb.TagNumber(4)
  void clearTable() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get offset => $_getI64(4);
  @$pb.TagNumber(5)
  set offset($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get limit => $_getIZ(5);
  @$pb.TagNumber(6)
  set limit($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLimit() => $_has(5);
  @$pb.TagNumber(6)
  void clearLimit() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<Sort> get sort => $_getList(6);

  /// A WHERE condition as typed by the user (without "WHERE").
  @$pb.TagNumber(8)
  $core.String get filter => $_getSZ(7);
  @$pb.TagNumber(8)
  set filter($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFilter() => $_has(7);
  @$pb.TagNumber(8)
  void clearFilter() => $_clearField(8);
}

class EditValue extends $pb.GeneratedMessage {
  factory EditValue({
    $core.String? column,
    Cell? value,
    $core.bool? useDefault,
  }) {
    final result = EditValue._();
    if (column != null) result.column = column;
    if (value != null) result.value = value;
    if (useDefault != null) result.useDefault = useDefault;
    return result;
  }

  EditValue._();

  factory EditValue.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditValue()..mergeFromBuffer(data, registry);
  factory EditValue.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditValue()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditValue',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: EditValue.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'column')
    ..aOM<Cell>(2, _omitFieldNames ? '' : 'value',
        subBuilder: Cell.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'useDefault')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditValue clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditValue copyWith(void Function(EditValue) updates) =>
      super.copyWith((message) => updates(message as EditValue)) as EditValue;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EditValue() / EditValue.new instead')
  static EditValue create() => EditValue._();
  static $pb.GeneratedMessage $_createMessage() => EditValue._();
  @$core.override
  EditValue createEmptyInstance() => EditValue._();
  @$core.pragma('dart2js:noInline')
  static EditValue getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditValue>(EditValue.$_createMessage);
  static EditValue? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get column => $_getSZ(0);
  @$pb.TagNumber(1)
  set column($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasColumn() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumn() => $_clearField(1);

  @$pb.TagNumber(2)
  Cell get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(Cell value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
  @$pb.TagNumber(2)
  Cell ensureValue() => $_ensure(1);

  /// Set to DEFAULT (inserts) instead of the value.
  @$pb.TagNumber(3)
  $core.bool get useDefault => $_getBF(2);
  @$pb.TagNumber(3)
  set useDefault($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUseDefault() => $_has(2);
  @$pb.TagNumber(3)
  void clearUseDefault() => $_clearField(3);
}

class RowEdit extends $pb.GeneratedMessage {
  factory RowEdit({
    RowEdit_Op? op,
    $core.Iterable<EditValue>? key,
    $core.Iterable<EditValue>? values,
  }) {
    final result = RowEdit._();
    if (op != null) result.op = op;
    if (key != null) result.key.addAll(key);
    if (values != null) result.values.addAll(values);
    return result;
  }

  RowEdit._();

  factory RowEdit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RowEdit()..mergeFromBuffer(data, registry);
  factory RowEdit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RowEdit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RowEdit',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: RowEdit.$_createMessage)
    ..aE<RowEdit_Op>(1, _omitFieldNames ? '' : 'op',
        enumValues: RowEdit_Op.values)
    ..pPM<EditValue>(2, _omitFieldNames ? '' : 'key',
        subBuilder: EditValue.$_createMessage)
    ..pPM<EditValue>(3, _omitFieldNames ? '' : 'values',
        subBuilder: EditValue.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowEdit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RowEdit copyWith(void Function(RowEdit) updates) =>
      super.copyWith((message) => updates(message as RowEdit)) as RowEdit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RowEdit() / RowEdit.new instead')
  static RowEdit create() => RowEdit._();
  static $pb.GeneratedMessage $_createMessage() => RowEdit._();
  @$core.override
  RowEdit createEmptyInstance() => RowEdit._();
  @$core.pragma('dart2js:noInline')
  static RowEdit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RowEdit>(RowEdit.$_createMessage);
  static RowEdit? _defaultInstance;

  @$pb.TagNumber(1)
  RowEdit_Op get op => $_getN(0);
  @$pb.TagNumber(1)
  set op(RowEdit_Op value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOp() => $_has(0);
  @$pb.TagNumber(1)
  void clearOp() => $_clearField(1);

  /// UPDATE / DELETE: the row's key (ResultSet.key_columns, or "ctid").
  @$pb.TagNumber(2)
  $pb.PbList<EditValue> get key => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<EditValue> get values => $_getList(2);
}

class EditRequest extends $pb.GeneratedMessage {
  factory EditRequest({
    $core.String? connectionId,
    $core.String? database,
    $core.String? schema,
    $core.String? table,
    $core.Iterable<RowEdit>? edits,
  }) {
    final result = EditRequest._();
    if (connectionId != null) result.connectionId = connectionId;
    if (database != null) result.database = database;
    if (schema != null) result.schema = schema;
    if (table != null) result.table = table;
    if (edits != null) result.edits.addAll(edits);
    return result;
  }

  EditRequest._();

  factory EditRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditRequest()..mergeFromBuffer(data, registry);
  factory EditRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: EditRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'connectionId')
    ..aOS(2, _omitFieldNames ? '' : 'database')
    ..aOS(3, _omitFieldNames ? '' : 'schema')
    ..aOS(4, _omitFieldNames ? '' : 'table')
    ..pPM<RowEdit>(5, _omitFieldNames ? '' : 'edits',
        subBuilder: RowEdit.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditRequest copyWith(void Function(EditRequest) updates) =>
      super.copyWith((message) => updates(message as EditRequest))
          as EditRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EditRequest() / EditRequest.new instead')
  static EditRequest create() => EditRequest._();
  static $pb.GeneratedMessage $_createMessage() => EditRequest._();
  @$core.override
  EditRequest createEmptyInstance() => EditRequest._();
  @$core.pragma('dart2js:noInline')
  static EditRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EditRequest>(
          EditRequest.$_createMessage);
  static EditRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get connectionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set connectionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConnectionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnectionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get database => $_getSZ(1);
  @$pb.TagNumber(2)
  set database($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDatabase() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get schema => $_getSZ(2);
  @$pb.TagNumber(3)
  set schema($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get table => $_getSZ(3);
  @$pb.TagNumber(4)
  set table($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTable() => $_has(3);
  @$pb.TagNumber(4)
  void clearTable() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<RowEdit> get edits => $_getList(4);
}

class EditReply extends $pb.GeneratedMessage {
  factory EditReply({
    $fixnum.Int64? rowsAffected,
    $core.Iterable<$core.String>? statements,
  }) {
    final result = EditReply._();
    if (rowsAffected != null) result.rowsAffected = rowsAffected;
    if (statements != null) result.statements.addAll(statements);
    return result;
  }

  EditReply._();

  factory EditReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditReply()..mergeFromBuffer(data, registry);
  factory EditReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: EditReply.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'rowsAffected')
    ..pPS(2, _omitFieldNames ? '' : 'statements')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditReply copyWith(void Function(EditReply) updates) =>
      super.copyWith((message) => updates(message as EditReply)) as EditReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EditReply() / EditReply.new instead')
  static EditReply create() => EditReply._();
  static $pb.GeneratedMessage $_createMessage() => EditReply._();
  @$core.override
  EditReply createEmptyInstance() => EditReply._();
  @$core.pragma('dart2js:noInline')
  static EditReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditReply>(EditReply.$_createMessage);
  static EditReply? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get rowsAffected => $_getI64(0);
  @$pb.TagNumber(1)
  set rowsAffected($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRowsAffected() => $_has(0);
  @$pb.TagNumber(1)
  void clearRowsAffected() => $_clearField(1);

  /// The statements run, for the log ("UPDATE ... WHERE ...").
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get statements => $_getList(1);
}

class Console extends $pb.GeneratedMessage {
  factory Console({
    $core.String? id,
    $core.String? connectionId,
    $core.String? database,
    $core.String? serverVersion,
    $core.int? backendPid,
  }) {
    final result = Console._();
    if (id != null) result.id = id;
    if (connectionId != null) result.connectionId = connectionId;
    if (database != null) result.database = database;
    if (serverVersion != null) result.serverVersion = serverVersion;
    if (backendPid != null) result.backendPid = backendPid;
    return result;
  }

  Console._();

  factory Console.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Console()..mergeFromBuffer(data, registry);
  factory Console.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Console()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Console',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: Console.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'connectionId')
    ..aOS(3, _omitFieldNames ? '' : 'database')
    ..aOS(4, _omitFieldNames ? '' : 'serverVersion')
    ..aI(5, _omitFieldNames ? '' : 'backendPid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Console clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Console copyWith(void Function(Console) updates) =>
      super.copyWith((message) => updates(message as Console)) as Console;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Console() / Console.new instead')
  static Console create() => Console._();
  static $pb.GeneratedMessage $_createMessage() => Console._();
  @$core.override
  Console createEmptyInstance() => Console._();
  @$core.pragma('dart2js:noInline')
  static Console getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Console>(Console.$_createMessage);
  static Console? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get connectionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set connectionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasConnectionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearConnectionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get database => $_getSZ(2);
  @$pb.TagNumber(3)
  set database($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDatabase() => $_has(2);
  @$pb.TagNumber(3)
  void clearDatabase() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get serverVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set serverVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasServerVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearServerVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get backendPid => $_getIZ(4);
  @$pb.TagNumber(5)
  set backendPid($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBackendPid() => $_has(4);
  @$pb.TagNumber(5)
  void clearBackendPid() => $_clearField(5);
}

class ConsoleRef extends $pb.GeneratedMessage {
  factory ConsoleRef({
    $core.String? id,
  }) {
    final result = ConsoleRef._();
    if (id != null) result.id = id;
    return result;
  }

  ConsoleRef._();

  factory ConsoleRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsoleRef()..mergeFromBuffer(data, registry);
  factory ConsoleRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConsoleRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConsoleRef',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ConsoleRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsoleRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConsoleRef copyWith(void Function(ConsoleRef) updates) =>
      super.copyWith((message) => updates(message as ConsoleRef)) as ConsoleRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConsoleRef() / ConsoleRef.new instead')
  static ConsoleRef create() => ConsoleRef._();
  static $pb.GeneratedMessage $_createMessage() => ConsoleRef._();
  @$core.override
  ConsoleRef createEmptyInstance() => ConsoleRef._();
  @$core.pragma('dart2js:noInline')
  static ConsoleRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ConsoleRef>(ConsoleRef.$_createMessage);
  static ConsoleRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ExecuteRequest extends $pb.GeneratedMessage {
  factory ExecuteRequest({
    $core.String? consoleId,
    $core.String? sql,
    $core.int? maxRows,
    $core.bool? all,
    $core.int? cursor,
  }) {
    final result = ExecuteRequest._();
    if (consoleId != null) result.consoleId = consoleId;
    if (sql != null) result.sql = sql;
    if (maxRows != null) result.maxRows = maxRows;
    if (all != null) result.all = all;
    if (cursor != null) result.cursor = cursor;
    return result;
  }

  ExecuteRequest._();

  factory ExecuteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteRequest()..mergeFromBuffer(data, registry);
  factory ExecuteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ExecuteRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'consoleId')
    ..aOS(2, _omitFieldNames ? '' : 'sql')
    ..aI(3, _omitFieldNames ? '' : 'maxRows')
    ..aOB(4, _omitFieldNames ? '' : 'all')
    ..aI(5, _omitFieldNames ? '' : 'cursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteRequest copyWith(void Function(ExecuteRequest) updates) =>
      super.copyWith((message) => updates(message as ExecuteRequest))
          as ExecuteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExecuteRequest() / ExecuteRequest.new instead')
  static ExecuteRequest create() => ExecuteRequest._();
  static $pb.GeneratedMessage $_createMessage() => ExecuteRequest._();
  @$core.override
  ExecuteRequest createEmptyInstance() => ExecuteRequest._();
  @$core.pragma('dart2js:noInline')
  static ExecuteRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExecuteRequest>(
          ExecuteRequest.$_createMessage);
  static ExecuteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get consoleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set consoleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConsoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearConsoleId() => $_clearField(1);

  /// The console's text (or the selection: then run all of it).
  @$pb.TagNumber(2)
  $core.String get sql => $_getSZ(1);
  @$pb.TagNumber(2)
  set sql($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSql() => $_has(1);
  @$pb.TagNumber(2)
  void clearSql() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get maxRows => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxRows($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxRows() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxRows() => $_clearField(3);

  /// false: run only the statement at `cursor` (UTF-16 offset into sql),
  /// like Ctrl+Enter in DataGrip; true: every statement, stopping at the
  /// first error.
  @$pb.TagNumber(4)
  $core.bool get all => $_getBF(3);
  @$pb.TagNumber(4)
  set all($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAll() => $_has(3);
  @$pb.TagNumber(4)
  void clearAll() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get cursor => $_getIZ(4);
  @$pb.TagNumber(5)
  set cursor($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCursor() => $_has(4);
  @$pb.TagNumber(5)
  void clearCursor() => $_clearField(5);
}

class StatementsRequest extends $pb.GeneratedMessage {
  factory StatementsRequest({
    $core.String? sql,
  }) {
    final result = StatementsRequest._();
    if (sql != null) result.sql = sql;
    return result;
  }

  StatementsRequest._();

  factory StatementsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementsRequest()..mergeFromBuffer(data, registry);
  factory StatementsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: StatementsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sql')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementsRequest copyWith(void Function(StatementsRequest) updates) =>
      super.copyWith((message) => updates(message as StatementsRequest))
          as StatementsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatementsRequest() / StatementsRequest.new instead')
  static StatementsRequest create() => StatementsRequest._();
  static $pb.GeneratedMessage $_createMessage() => StatementsRequest._();
  @$core.override
  StatementsRequest createEmptyInstance() => StatementsRequest._();
  @$core.pragma('dart2js:noInline')
  static StatementsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatementsRequest>(
          StatementsRequest.$_createMessage);
  static StatementsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sql => $_getSZ(0);
  @$pb.TagNumber(1)
  set sql($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSql() => $_has(0);
  @$pb.TagNumber(1)
  void clearSql() => $_clearField(1);
}

class StatementRange extends $pb.GeneratedMessage {
  factory StatementRange({
    $core.int? start,
    $core.int? end,
  }) {
    final result = StatementRange._();
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    return result;
  }

  StatementRange._();

  factory StatementRange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementRange()..mergeFromBuffer(data, registry);
  factory StatementRange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementRange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementRange',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: StatementRange.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'start')
    ..aI(2, _omitFieldNames ? '' : 'end')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementRange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementRange copyWith(void Function(StatementRange) updates) =>
      super.copyWith((message) => updates(message as StatementRange))
          as StatementRange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatementRange() / StatementRange.new instead')
  static StatementRange create() => StatementRange._();
  static $pb.GeneratedMessage $_createMessage() => StatementRange._();
  @$core.override
  StatementRange createEmptyInstance() => StatementRange._();
  @$core.pragma('dart2js:noInline')
  static StatementRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatementRange>(
          StatementRange.$_createMessage);
  static StatementRange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get end => $_getIZ(1);
  @$pb.TagNumber(2)
  set end($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => $_clearField(2);
}

class StatementsReply extends $pb.GeneratedMessage {
  factory StatementsReply({
    $core.Iterable<StatementRange>? statements,
  }) {
    final result = StatementsReply._();
    if (statements != null) result.statements.addAll(statements);
    return result;
  }

  StatementsReply._();

  factory StatementsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementsReply()..mergeFromBuffer(data, registry);
  factory StatementsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatementsReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatementsReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: StatementsReply.$_createMessage)
    ..pPM<StatementRange>(1, _omitFieldNames ? '' : 'statements',
        subBuilder: StatementRange.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatementsReply copyWith(void Function(StatementsReply) updates) =>
      super.copyWith((message) => updates(message as StatementsReply))
          as StatementsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatementsReply() / StatementsReply.new instead')
  static StatementsReply create() => StatementsReply._();
  static $pb.GeneratedMessage $_createMessage() => StatementsReply._();
  @$core.override
  StatementsReply createEmptyInstance() => StatementsReply._();
  @$core.pragma('dart2js:noInline')
  static StatementsReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatementsReply>(
          StatementsReply.$_createMessage);
  static StatementsReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<StatementRange> get statements => $_getList(0);
}

class ExecuteReply extends $pb.GeneratedMessage {
  factory ExecuteReply({
    $core.Iterable<ResultSet>? results,
    $core.String? txStatus,
    $fixnum.Int64? durationMs,
  }) {
    final result = ExecuteReply._();
    if (results != null) result.results.addAll(results);
    if (txStatus != null) result.txStatus = txStatus;
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  ExecuteReply._();

  factory ExecuteReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteReply()..mergeFromBuffer(data, registry);
  factory ExecuteReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExecuteReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExecuteReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'selfhold.cellar.v1'),
      createEmptyInstance: ExecuteReply.$_createMessage)
    ..pPM<ResultSet>(1, _omitFieldNames ? '' : 'results',
        subBuilder: ResultSet.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'txStatus')
    ..aInt64(3, _omitFieldNames ? '' : 'durationMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExecuteReply copyWith(void Function(ExecuteReply) updates) =>
      super.copyWith((message) => updates(message as ExecuteReply))
          as ExecuteReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExecuteReply() / ExecuteReply.new instead')
  static ExecuteReply create() => ExecuteReply._();
  static $pb.GeneratedMessage $_createMessage() => ExecuteReply._();
  @$core.override
  ExecuteReply createEmptyInstance() => ExecuteReply._();
  @$core.pragma('dart2js:noInline')
  static ExecuteReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExecuteReply>(
          ExecuteReply.$_createMessage);
  static ExecuteReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ResultSet> get results => $_getList(0);

  /// The session's transaction state after the run: "idle", "transaction",
  /// "failed" (an error inside a transaction block).
  @$pb.TagNumber(2)
  $core.String get txStatus => $_getSZ(1);
  @$pb.TagNumber(2)
  set txStatus($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTxStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearTxStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get durationMs => $_getI64(2);
  @$pb.TagNumber(3)
  set durationMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDurationMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearDurationMs() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

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

import 'package:protobuf/protobuf.dart' as $pb;

class ToolPlace extends $pb.ProtobufEnum {
  static const ToolPlace TOOL_PLACE_UNSPECIFIED =
      ToolPlace._(0, _omitEnumNames ? '' : 'TOOL_PLACE_UNSPECIFIED');
  static const ToolPlace LOCAL = ToolPlace._(1, _omitEnumNames ? '' : 'LOCAL');
  static const ToolPlace REMOTE =
      ToolPlace._(2, _omitEnumNames ? '' : 'REMOTE');

  static const $core.List<ToolPlace> values = <ToolPlace>[
    TOOL_PLACE_UNSPECIFIED,
    LOCAL,
    REMOTE,
  ];

  static final $core.List<ToolPlace?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ToolPlace? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ToolPlace._(super.value, super.name);
}

class SyncState_Phase extends $pb.ProtobufEnum {
  static const SyncState_Phase PHASE_UNSPECIFIED =
      SyncState_Phase._(0, _omitEnumNames ? '' : 'PHASE_UNSPECIFIED');
  static const SyncState_Phase OFF =
      SyncState_Phase._(1, _omitEnumNames ? '' : 'OFF');
  static const SyncState_Phase NOT_RUNNING =
      SyncState_Phase._(2, _omitEnumNames ? '' : 'NOT_RUNNING');
  static const SyncState_Phase NO_VAULT =
      SyncState_Phase._(3, _omitEnumNames ? '' : 'NO_VAULT');
  static const SyncState_Phase LOCKED =
      SyncState_Phase._(4, _omitEnumNames ? '' : 'LOCKED');
  static const SyncState_Phase PAIRING =
      SyncState_Phase._(5, _omitEnumNames ? '' : 'PAIRING');
  static const SyncState_Phase OFFLINE =
      SyncState_Phase._(6, _omitEnumNames ? '' : 'OFFLINE');
  static const SyncState_Phase SYNCED =
      SyncState_Phase._(7, _omitEnumNames ? '' : 'SYNCED');
  static const SyncState_Phase ERROR =
      SyncState_Phase._(8, _omitEnumNames ? '' : 'ERROR');

  static const $core.List<SyncState_Phase> values = <SyncState_Phase>[
    PHASE_UNSPECIFIED,
    OFF,
    NOT_RUNNING,
    NO_VAULT,
    LOCKED,
    PAIRING,
    OFFLINE,
    SYNCED,
    ERROR,
  ];

  static final $core.List<SyncState_Phase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static SyncState_Phase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SyncState_Phase._(super.value, super.name);
}

class Event_Kind extends $pb.ProtobufEnum {
  static const Event_Kind KIND_UNSPECIFIED =
      Event_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const Event_Kind SERVERS =
      Event_Kind._(1, _omitEnumNames ? '' : 'SERVERS');
  static const Event_Kind CONNECTIONS =
      Event_Kind._(2, _omitEnumNames ? '' : 'CONNECTIONS');
  static const Event_Kind KEYS = Event_Kind._(3, _omitEnumNames ? '' : 'KEYS');
  static const Event_Kind SYNC = Event_Kind._(4, _omitEnumNames ? '' : 'SYNC');
  static const Event_Kind SSH = Event_Kind._(5, _omitEnumNames ? '' : 'SSH');

  static const $core.List<Event_Kind> values = <Event_Kind>[
    KIND_UNSPECIFIED,
    SERVERS,
    CONNECTIONS,
    KEYS,
    SYNC,
    SSH,
  ];

  static final $core.List<Event_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static Event_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Event_Kind._(super.value, super.name);
}

class Server_Auth extends $pb.ProtobufEnum {
  static const Server_Auth AUTH_UNSPECIFIED =
      Server_Auth._(0, _omitEnumNames ? '' : 'AUTH_UNSPECIFIED');
  static const Server_Auth PASSWORD =
      Server_Auth._(1, _omitEnumNames ? '' : 'PASSWORD');
  static const Server_Auth KEY = Server_Auth._(2, _omitEnumNames ? '' : 'KEY');
  static const Server_Auth AGENT =
      Server_Auth._(3, _omitEnumNames ? '' : 'AGENT');

  static const $core.List<Server_Auth> values = <Server_Auth>[
    AUTH_UNSPECIFIED,
    PASSWORD,
    KEY,
    AGENT,
  ];

  static final $core.List<Server_Auth?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Server_Auth? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Server_Auth._(super.value, super.name);
}

class HostKey_Status extends $pb.ProtobufEnum {
  static const HostKey_Status STATUS_UNSPECIFIED =
      HostKey_Status._(0, _omitEnumNames ? '' : 'STATUS_UNSPECIFIED');
  static const HostKey_Status KNOWN =
      HostKey_Status._(1, _omitEnumNames ? '' : 'KNOWN');
  static const HostKey_Status UNKNOWN =
      HostKey_Status._(2, _omitEnumNames ? '' : 'UNKNOWN');
  static const HostKey_Status CHANGED =
      HostKey_Status._(3, _omitEnumNames ? '' : 'CHANGED');

  static const $core.List<HostKey_Status> values = <HostKey_Status>[
    STATUS_UNSPECIFIED,
    KNOWN,
    UNKNOWN,
    CHANGED,
  ];

  static final $core.List<HostKey_Status?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static HostKey_Status? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HostKey_Status._(super.value, super.name);
}

class DiscoveredService_Kind extends $pb.ProtobufEnum {
  static const DiscoveredService_Kind KIND_UNSPECIFIED =
      DiscoveredService_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const DiscoveredService_Kind POSTGRES =
      DiscoveredService_Kind._(1, _omitEnumNames ? '' : 'POSTGRES');

  static const $core.List<DiscoveredService_Kind> values =
      <DiscoveredService_Kind>[
    KIND_UNSPECIFIED,
    POSTGRES,
  ];

  static final $core.List<DiscoveredService_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static DiscoveredService_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DiscoveredService_Kind._(super.value, super.name);
}

class Connection_Kind extends $pb.ProtobufEnum {
  static const Connection_Kind KIND_UNSPECIFIED =
      Connection_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const Connection_Kind POSTGRES =
      Connection_Kind._(1, _omitEnumNames ? '' : 'POSTGRES');

  static const $core.List<Connection_Kind> values = <Connection_Kind>[
    KIND_UNSPECIFIED,
    POSTGRES,
  ];

  static final $core.List<Connection_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Connection_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Connection_Kind._(super.value, super.name);
}

class Connection_SslMode extends $pb.ProtobufEnum {
  static const Connection_SslMode SSL_MODE_UNSPECIFIED =
      Connection_SslMode._(0, _omitEnumNames ? '' : 'SSL_MODE_UNSPECIFIED');
  static const Connection_SslMode DISABLE =
      Connection_SslMode._(1, _omitEnumNames ? '' : 'DISABLE');
  static const Connection_SslMode PREFER =
      Connection_SslMode._(2, _omitEnumNames ? '' : 'PREFER');
  static const Connection_SslMode REQUIRE =
      Connection_SslMode._(3, _omitEnumNames ? '' : 'REQUIRE');

  static const $core.List<Connection_SslMode> values = <Connection_SslMode>[
    SSL_MODE_UNSPECIFIED,
    DISABLE,
    PREFER,
    REQUIRE,
  ];

  static final $core.List<Connection_SslMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Connection_SslMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Connection_SslMode._(super.value, super.name);
}

class DbObject_Kind extends $pb.ProtobufEnum {
  static const DbObject_Kind KIND_UNSPECIFIED =
      DbObject_Kind._(0, _omitEnumNames ? '' : 'KIND_UNSPECIFIED');
  static const DbObject_Kind TABLE =
      DbObject_Kind._(1, _omitEnumNames ? '' : 'TABLE');
  static const DbObject_Kind VIEW =
      DbObject_Kind._(2, _omitEnumNames ? '' : 'VIEW');
  static const DbObject_Kind MATERIALIZED_VIEW =
      DbObject_Kind._(3, _omitEnumNames ? '' : 'MATERIALIZED_VIEW');
  static const DbObject_Kind SEQUENCE =
      DbObject_Kind._(4, _omitEnumNames ? '' : 'SEQUENCE');
  static const DbObject_Kind FUNCTION =
      DbObject_Kind._(5, _omitEnumNames ? '' : 'FUNCTION');
  static const DbObject_Kind FOREIGN_TABLE =
      DbObject_Kind._(6, _omitEnumNames ? '' : 'FOREIGN_TABLE');
  static const DbObject_Kind PARTITIONED_TABLE =
      DbObject_Kind._(7, _omitEnumNames ? '' : 'PARTITIONED_TABLE');
  static const DbObject_Kind PROCEDURE =
      DbObject_Kind._(8, _omitEnumNames ? '' : 'PROCEDURE');
  static const DbObject_Kind ENUM =
      DbObject_Kind._(9, _omitEnumNames ? '' : 'ENUM');
  static const DbObject_Kind DOMAIN =
      DbObject_Kind._(10, _omitEnumNames ? '' : 'DOMAIN');
  static const DbObject_Kind COMPOSITE_TYPE =
      DbObject_Kind._(11, _omitEnumNames ? '' : 'COMPOSITE_TYPE');
  static const DbObject_Kind RANGE_TYPE =
      DbObject_Kind._(12, _omitEnumNames ? '' : 'RANGE_TYPE');

  static const $core.List<DbObject_Kind> values = <DbObject_Kind>[
    KIND_UNSPECIFIED,
    TABLE,
    VIEW,
    MATERIALIZED_VIEW,
    SEQUENCE,
    FUNCTION,
    FOREIGN_TABLE,
    PARTITIONED_TABLE,
    PROCEDURE,
    ENUM,
    DOMAIN,
    COMPOSITE_TYPE,
    RANGE_TYPE,
  ];

  static final $core.List<DbObject_Kind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 12);
  static DbObject_Kind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DbObject_Kind._(super.value, super.name);
}

class Change_Op extends $pb.ProtobufEnum {
  static const Change_Op OP_UNSPECIFIED =
      Change_Op._(0, _omitEnumNames ? '' : 'OP_UNSPECIFIED');
  static const Change_Op CREATE =
      Change_Op._(1, _omitEnumNames ? '' : 'CREATE');
  static const Change_Op ALTER = Change_Op._(2, _omitEnumNames ? '' : 'ALTER');
  static const Change_Op DROP = Change_Op._(3, _omitEnumNames ? '' : 'DROP');

  static const $core.List<Change_Op> values = <Change_Op>[
    OP_UNSPECIFIED,
    CREATE,
    ALTER,
    DROP,
  ];

  static final $core.List<Change_Op?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static Change_Op? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Change_Op._(super.value, super.name);
}

class DumpRequest_Format extends $pb.ProtobufEnum {
  static const DumpRequest_Format FORMAT_UNSPECIFIED =
      DumpRequest_Format._(0, _omitEnumNames ? '' : 'FORMAT_UNSPECIFIED');
  static const DumpRequest_Format PLAIN =
      DumpRequest_Format._(1, _omitEnumNames ? '' : 'PLAIN');
  static const DumpRequest_Format CUSTOM =
      DumpRequest_Format._(2, _omitEnumNames ? '' : 'CUSTOM');
  static const DumpRequest_Format TAR =
      DumpRequest_Format._(3, _omitEnumNames ? '' : 'TAR');

  static const $core.List<DumpRequest_Format> values = <DumpRequest_Format>[
    FORMAT_UNSPECIFIED,
    PLAIN,
    CUSTOM,
    TAR,
  ];

  static final $core.List<DumpRequest_Format?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static DumpRequest_Format? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DumpRequest_Format._(super.value, super.name);
}

class RowEdit_Op extends $pb.ProtobufEnum {
  static const RowEdit_Op OP_UNSPECIFIED =
      RowEdit_Op._(0, _omitEnumNames ? '' : 'OP_UNSPECIFIED');
  static const RowEdit_Op INSERT =
      RowEdit_Op._(1, _omitEnumNames ? '' : 'INSERT');
  static const RowEdit_Op UPDATE =
      RowEdit_Op._(2, _omitEnumNames ? '' : 'UPDATE');
  static const RowEdit_Op DELETE =
      RowEdit_Op._(3, _omitEnumNames ? '' : 'DELETE');

  static const $core.List<RowEdit_Op> values = <RowEdit_Op>[
    OP_UNSPECIFIED,
    INSERT,
    UPDATE,
    DELETE,
  ];

  static final $core.List<RowEdit_Op?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static RowEdit_Op? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RowEdit_Op._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');

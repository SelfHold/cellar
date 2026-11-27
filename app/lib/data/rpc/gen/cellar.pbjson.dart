// This is a generated file - do not edit.
//
// Generated from cellar.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use toolPlaceDescriptor instead')
const ToolPlace$json = {
  '1': 'ToolPlace',
  '2': [
    {'1': 'TOOL_PLACE_UNSPECIFIED', '2': 0},
    {'1': 'LOCAL', '2': 1},
    {'1': 'REMOTE', '2': 2},
  ],
};

/// Descriptor for `ToolPlace`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List toolPlaceDescriptor = $convert.base64Decode(
    'CglUb29sUGxhY2USGgoWVE9PTF9QTEFDRV9VTlNQRUNJRklFRBAAEgkKBUxPQ0FMEAESCgoGUk'
    'VNT1RFEAI=');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use refDescriptor instead')
const Ref$json = {
  '1': 'Ref',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `Ref`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refDescriptor =
    $convert.base64Decode('CgNSZWYSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use stateDescriptor instead')
const State$json = {
  '1': 'State',
  '2': [
    {'1': 'core_version', '3': 1, '4': 1, '5': 9, '10': 'coreVersion'},
    {'1': 'core_build', '3': 2, '4': 1, '5': 9, '10': 'coreBuild'},
    {'1': 'platform', '3': 3, '4': 1, '5': 9, '10': 'platform'},
    {
      '1': 'sync',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.SyncState',
      '10': 'sync'
    },
    {'1': 'keychain', '3': 5, '4': 1, '5': 8, '10': 'keychain'},
  ],
};

/// Descriptor for `State`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stateDescriptor = $convert.base64Decode(
    'CgVTdGF0ZRIhCgxjb3JlX3ZlcnNpb24YASABKAlSC2NvcmVWZXJzaW9uEh0KCmNvcmVfYnVpbG'
    'QYAiABKAlSCWNvcmVCdWlsZBIaCghwbGF0Zm9ybRgDIAEoCVIIcGxhdGZvcm0SMQoEc3luYxgE'
    'IAEoCzIdLnNlbGZob2xkLmNlbGxhci52MS5TeW5jU3RhdGVSBHN5bmMSGgoIa2V5Y2hhaW4YBS'
    'ABKAhSCGtleWNoYWlu');

@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState$json = {
  '1': 'SyncState',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.SyncState.Phase',
      '10': 'phase'
    },
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'available', '3': 3, '4': 1, '5': 8, '10': 'available'},
    {'1': 'pairing_code', '3': 4, '4': 1, '5': 9, '10': 'pairingCode'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
    {'1': 'pending', '3': 6, '4': 1, '5': 8, '10': 'pending'},
    {'1': 'last_sync_ms', '3': 7, '4': 1, '5': 3, '10': 'lastSyncMs'},
    {'1': 'device_name', '3': 8, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'shared_servers', '3': 9, '4': 1, '5': 8, '10': 'sharedServers'},
    {'1': 'safe_keys', '3': 10, '4': 1, '5': 8, '10': 'safeKeys'},
    {'1': 'own_servers', '3': 11, '4': 1, '5': 5, '10': 'ownServers'},
  ],
  '4': [SyncState_Phase$json],
};

@$core.Deprecated('Use syncStateDescriptor instead')
const SyncState_Phase$json = {
  '1': 'Phase',
  '2': [
    {'1': 'PHASE_UNSPECIFIED', '2': 0},
    {'1': 'OFF', '2': 1},
    {'1': 'NOT_RUNNING', '2': 2},
    {'1': 'NO_VAULT', '2': 3},
    {'1': 'LOCKED', '2': 4},
    {'1': 'PAIRING', '2': 5},
    {'1': 'OFFLINE', '2': 6},
    {'1': 'SYNCED', '2': 7},
    {'1': 'ERROR', '2': 8},
  ],
};

/// Descriptor for `SyncState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncStateDescriptor = $convert.base64Decode(
    'CglTeW5jU3RhdGUSOQoFcGhhc2UYASABKA4yIy5zZWxmaG9sZC5jZWxsYXIudjEuU3luY1N0YX'
    'RlLlBoYXNlUgVwaGFzZRIYCgdlbmFibGVkGAIgASgIUgdlbmFibGVkEhwKCWF2YWlsYWJsZRgD'
    'IAEoCFIJYXZhaWxhYmxlEiEKDHBhaXJpbmdfY29kZRgEIAEoCVILcGFpcmluZ0NvZGUSFAoFZX'
    'Jyb3IYBSABKAlSBWVycm9yEhgKB3BlbmRpbmcYBiABKAhSB3BlbmRpbmcSIAoMbGFzdF9zeW5j'
    'X21zGAcgASgDUgpsYXN0U3luY01zEh8KC2RldmljZV9uYW1lGAggASgJUgpkZXZpY2VOYW1lEi'
    'UKDnNoYXJlZF9zZXJ2ZXJzGAkgASgIUg1zaGFyZWRTZXJ2ZXJzEhsKCXNhZmVfa2V5cxgKIAEo'
    'CFIIc2FmZUtleXMSHwoLb3duX3NlcnZlcnMYCyABKAVSCm93blNlcnZlcnMigwEKBVBoYXNlEh'
    'UKEVBIQVNFX1VOU1BFQ0lGSUVEEAASBwoDT0ZGEAESDwoLTk9UX1JVTk5JTkcQAhIMCghOT19W'
    'QVVMVBADEgoKBkxPQ0tFRBAEEgsKB1BBSVJJTkcQBRILCgdPRkZMSU5FEAYSCgoGU1lOQ0VEEA'
    'cSCQoFRVJST1IQCA==');

@$core.Deprecated('Use eventDescriptor instead')
const Event$json = {
  '1': 'Event',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.Event.Kind',
      '10': 'kind'
    },
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
  '4': [Event_Kind$json],
};

@$core.Deprecated('Use eventDescriptor instead')
const Event_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_UNSPECIFIED', '2': 0},
    {'1': 'SERVERS', '2': 1},
    {'1': 'CONNECTIONS', '2': 2},
    {'1': 'KEYS', '2': 3},
    {'1': 'SYNC', '2': 4},
    {'1': 'SSH', '2': 5},
  ],
};

/// Descriptor for `Event`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventDescriptor = $convert.base64Decode(
    'CgVFdmVudBIyCgRraW5kGAEgASgOMh4uc2VsZmhvbGQuY2VsbGFyLnYxLkV2ZW50LktpbmRSBG'
    'tpbmQSDgoCaWQYAiABKAlSAmlkEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2UiVwoES2luZBIU'
    'ChBLSU5EX1VOU1BFQ0lGSUVEEAASCwoHU0VSVkVSUxABEg8KC0NPTk5FQ1RJT05TEAISCAoES0'
    'VZUxADEggKBFNZTkMQBBIHCgNTU0gQBQ==');

@$core.Deprecated('Use serverDescriptor instead')
const Server$json = {
  '1': 'Server',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'group', '3': 3, '4': 1, '5': 9, '10': 'group'},
    {'1': 'host', '3': 4, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 5, '4': 1, '5': 13, '10': 'port'},
    {'1': 'user', '3': 6, '4': 1, '5': 9, '10': 'user'},
    {
      '1': 'auth',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.Server.Auth',
      '10': 'auth'
    },
    {'1': 'password', '3': 8, '4': 1, '5': 9, '10': 'password'},
    {'1': 'key_id', '3': 9, '4': 1, '5': 9, '10': 'keyId'},
    {'1': 'host_keys', '3': 10, '4': 3, '5': 9, '10': 'hostKeys'},
    {'1': 'jump_server_id', '3': 11, '4': 1, '5': 9, '10': 'jumpServerId'},
    {'1': 'notes', '3': 12, '4': 1, '5': 9, '10': 'notes'},
    {'1': 'updated_ms', '3': 13, '4': 1, '5': 3, '10': 'updatedMs'},
    {'1': 'shared', '3': 14, '4': 1, '5': 8, '10': 'shared'},
    {'1': 'connected', '3': 15, '4': 1, '5': 8, '10': 'connected'},
  ],
  '4': [Server_Auth$json],
};

@$core.Deprecated('Use serverDescriptor instead')
const Server_Auth$json = {
  '1': 'Auth',
  '2': [
    {'1': 'AUTH_UNSPECIFIED', '2': 0},
    {'1': 'PASSWORD', '2': 1},
    {'1': 'KEY', '2': 2},
    {'1': 'AGENT', '2': 3},
  ],
};

/// Descriptor for `Server`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverDescriptor = $convert.base64Decode(
    'CgZTZXJ2ZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSFAoFZ3JvdXAYAy'
    'ABKAlSBWdyb3VwEhIKBGhvc3QYBCABKAlSBGhvc3QSEgoEcG9ydBgFIAEoDVIEcG9ydBISCgR1'
    'c2VyGAYgASgJUgR1c2VyEjMKBGF1dGgYByABKA4yHy5zZWxmaG9sZC5jZWxsYXIudjEuU2Vydm'
    'VyLkF1dGhSBGF1dGgSGgoIcGFzc3dvcmQYCCABKAlSCHBhc3N3b3JkEhUKBmtleV9pZBgJIAEo'
    'CVIFa2V5SWQSGwoJaG9zdF9rZXlzGAogAygJUghob3N0S2V5cxIkCg5qdW1wX3NlcnZlcl9pZB'
    'gLIAEoCVIManVtcFNlcnZlcklkEhQKBW5vdGVzGAwgASgJUgVub3RlcxIdCgp1cGRhdGVkX21z'
    'GA0gASgDUgl1cGRhdGVkTXMSFgoGc2hhcmVkGA4gASgIUgZzaGFyZWQSHAoJY29ubmVjdGVkGA'
    '8gASgIUgljb25uZWN0ZWQiPgoEQXV0aBIUChBBVVRIX1VOU1BFQ0lGSUVEEAASDAoIUEFTU1dP'
    'UkQQARIHCgNLRVkQAhIJCgVBR0VOVBAD');

@$core.Deprecated('Use serverListDescriptor instead')
const ServerList$json = {
  '1': 'ServerList',
  '2': [
    {
      '1': 'servers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Server',
      '10': 'servers'
    },
  ],
};

/// Descriptor for `ServerList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverListDescriptor = $convert.base64Decode(
    'CgpTZXJ2ZXJMaXN0EjQKB3NlcnZlcnMYASADKAsyGi5zZWxmaG9sZC5jZWxsYXIudjEuU2Vydm'
    'VyUgdzZXJ2ZXJz');

@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = {
  '1': 'ConnectRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'passphrase', '3': 2, '4': 1, '5': 9, '10': 'passphrase'},
  ],
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor = $convert.base64Decode(
    'Cg5Db25uZWN0UmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSHgoKcGFzc3BocmFzZRgCIAEoCVIKcG'
    'Fzc3BocmFzZQ==');

@$core.Deprecated('Use hostKeyDescriptor instead')
const HostKey$json = {
  '1': 'HostKey',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.HostKey.Status',
      '10': 'status'
    },
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'fingerprint', '3': 3, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'type', '3': 4, '4': 1, '5': 9, '10': 'type'},
    {'1': 'server_id', '3': 5, '4': 1, '5': 9, '10': 'serverId'},
  ],
  '4': [HostKey_Status$json],
};

@$core.Deprecated('Use hostKeyDescriptor instead')
const HostKey_Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'STATUS_UNSPECIFIED', '2': 0},
    {'1': 'KNOWN', '2': 1},
    {'1': 'UNKNOWN', '2': 2},
    {'1': 'CHANGED', '2': 3},
  ],
};

/// Descriptor for `HostKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostKeyDescriptor = $convert.base64Decode(
    'CgdIb3N0S2V5EjoKBnN0YXR1cxgBIAEoDjIiLnNlbGZob2xkLmNlbGxhci52MS5Ib3N0S2V5Ll'
    'N0YXR1c1IGc3RhdHVzEhAKA2tleRgCIAEoCVIDa2V5EiAKC2ZpbmdlcnByaW50GAMgASgJUgtm'
    'aW5nZXJwcmludBISCgR0eXBlGAQgASgJUgR0eXBlEhsKCXNlcnZlcl9pZBgFIAEoCVIIc2Vydm'
    'VySWQiRQoGU3RhdHVzEhYKElNUQVRVU19VTlNQRUNJRklFRBAAEgkKBUtOT1dOEAESCwoHVU5L'
    'Tk9XThACEgsKB0NIQU5HRUQQAw==');

@$core.Deprecated('Use connectReplyDescriptor instead')
const ConnectReply$json = {
  '1': 'ConnectReply',
  '2': [
    {'1': 'connected', '3': 1, '4': 1, '5': 8, '10': 'connected'},
    {
      '1': 'host_key',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.HostKey',
      '10': 'hostKey'
    },
    {'1': 'need_passphrase', '3': 3, '4': 1, '5': 8, '10': 'needPassphrase'},
    {'1': 'server_banner', '3': 4, '4': 1, '5': 9, '10': 'serverBanner'},
  ],
};

/// Descriptor for `ConnectReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectReplyDescriptor = $convert.base64Decode(
    'CgxDb25uZWN0UmVwbHkSHAoJY29ubmVjdGVkGAEgASgIUgljb25uZWN0ZWQSNgoIaG9zdF9rZX'
    'kYAiABKAsyGy5zZWxmaG9sZC5jZWxsYXIudjEuSG9zdEtleVIHaG9zdEtleRInCg9uZWVkX3Bh'
    'c3NwaHJhc2UYAyABKAhSDm5lZWRQYXNzcGhyYXNlEiMKDXNlcnZlcl9iYW5uZXIYBCABKAlSDH'
    'NlcnZlckJhbm5lcg==');

@$core.Deprecated('Use trustRequestDescriptor instead')
const TrustRequest$json = {
  '1': 'TrustRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'replace', '3': 3, '4': 1, '5': 8, '10': 'replace'},
  ],
};

/// Descriptor for `TrustRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustRequestDescriptor = $convert.base64Decode(
    'CgxUcnVzdFJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhAKA2tleRgCIAEoCVIDa2V5EhgKB3JlcG'
    'xhY2UYAyABKAhSB3JlcGxhY2U=');

@$core.Deprecated('Use discoveredServiceDescriptor instead')
const DiscoveredService$json = {
  '1': 'DiscoveredService',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.DiscoveredService.Kind',
      '10': 'kind'
    },
    {'1': 'host', '3': 2, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 3, '4': 1, '5': 13, '10': 'port'},
    {'1': 'source', '3': 4, '4': 1, '5': 9, '10': 'source'},
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
    {'1': 'detail', '3': 6, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'confirmed', '3': 7, '4': 1, '5': 8, '10': 'confirmed'},
    {'1': 'connection_id', '3': 8, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'user_hint', '3': 9, '4': 1, '5': 9, '10': 'userHint'},
    {'1': 'database_hint', '3': 10, '4': 1, '5': 9, '10': 'databaseHint'},
  ],
  '4': [DiscoveredService_Kind$json],
};

@$core.Deprecated('Use discoveredServiceDescriptor instead')
const DiscoveredService_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_UNSPECIFIED', '2': 0},
    {'1': 'POSTGRES', '2': 1},
  ],
};

/// Descriptor for `DiscoveredService`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoveredServiceDescriptor = $convert.base64Decode(
    'ChFEaXNjb3ZlcmVkU2VydmljZRI+CgRraW5kGAEgASgOMiouc2VsZmhvbGQuY2VsbGFyLnYxLk'
    'Rpc2NvdmVyZWRTZXJ2aWNlLktpbmRSBGtpbmQSEgoEaG9zdBgCIAEoCVIEaG9zdBISCgRwb3J0'
    'GAMgASgNUgRwb3J0EhYKBnNvdXJjZRgEIAEoCVIGc291cmNlEhQKBXRpdGxlGAUgASgJUgV0aX'
    'RsZRIWCgZkZXRhaWwYBiABKAlSBmRldGFpbBIcCgljb25maXJtZWQYByABKAhSCWNvbmZpcm1l'
    'ZBIjCg1jb25uZWN0aW9uX2lkGAggASgJUgxjb25uZWN0aW9uSWQSGwoJdXNlcl9oaW50GAkgAS'
    'gJUgh1c2VySGludBIjCg1kYXRhYmFzZV9oaW50GAogASgJUgxkYXRhYmFzZUhpbnQiKgoES2lu'
    'ZBIUChBLSU5EX1VOU1BFQ0lGSUVEEAASDAoIUE9TVEdSRVMQAQ==');

@$core.Deprecated('Use discoverReplyDescriptor instead')
const DiscoverReply$json = {
  '1': 'DiscoverReply',
  '2': [
    {
      '1': 'services',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.DiscoveredService',
      '10': 'services'
    },
    {'1': 'warnings', '3': 2, '4': 3, '5': 9, '10': 'warnings'},
  ],
};

/// Descriptor for `DiscoverReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoverReplyDescriptor = $convert.base64Decode(
    'Cg1EaXNjb3ZlclJlcGx5EkEKCHNlcnZpY2VzGAEgAygLMiUuc2VsZmhvbGQuY2VsbGFyLnYxLk'
    'Rpc2NvdmVyZWRTZXJ2aWNlUghzZXJ2aWNlcxIaCgh3YXJuaW5ncxgCIAMoCVIId2FybmluZ3M=');

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'key_type', '3': 3, '4': 1, '5': 9, '10': 'keyType'},
    {'1': 'fingerprint', '3': 4, '4': 1, '5': 9, '10': 'fingerprint'},
    {'1': 'public_key', '3': 5, '4': 1, '5': 9, '10': 'publicKey'},
    {'1': 'comment', '3': 6, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'encrypted', '3': 7, '4': 1, '5': 8, '10': 'encrypted'},
    {'1': 'has_passphrase', '3': 8, '4': 1, '5': 8, '10': 'hasPassphrase'},
    {'1': 'local', '3': 9, '4': 1, '5': 8, '10': 'local'},
    {'1': 'group', '3': 10, '4': 1, '5': 9, '10': 'group'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSDgoCaWQYASABKAlSAmlkEhQKBXRpdGxlGAIgASgJUgV0aXRsZRIZCghrZXlfdHlwZR'
    'gDIAEoCVIHa2V5VHlwZRIgCgtmaW5nZXJwcmludBgEIAEoCVILZmluZ2VycHJpbnQSHQoKcHVi'
    'bGljX2tleRgFIAEoCVIJcHVibGljS2V5EhgKB2NvbW1lbnQYBiABKAlSB2NvbW1lbnQSHAoJZW'
    '5jcnlwdGVkGAcgASgIUgllbmNyeXB0ZWQSJQoOaGFzX3Bhc3NwaHJhc2UYCCABKAhSDWhhc1Bh'
    'c3NwaHJhc2USFAoFbG9jYWwYCSABKAhSBWxvY2FsEhQKBWdyb3VwGAogASgJUgVncm91cA==');

@$core.Deprecated('Use keyListDescriptor instead')
const KeyList$json = {
  '1': 'KeyList',
  '2': [
    {
      '1': 'keys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Key',
      '10': 'keys'
    },
    {'1': 'safe_note', '3': 2, '4': 1, '5': 9, '10': 'safeNote'},
  ],
};

/// Descriptor for `KeyList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyListDescriptor = $convert.base64Decode(
    'CgdLZXlMaXN0EisKBGtleXMYASADKAsyFy5zZWxmaG9sZC5jZWxsYXIudjEuS2V5UgRrZXlzEh'
    'sKCXNhZmVfbm90ZRgCIAEoCVIIc2FmZU5vdGU=');

@$core.Deprecated('Use localKeyDescriptor instead')
const LocalKey$json = {
  '1': 'LocalKey',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'private_key', '3': 2, '4': 1, '5': 9, '10': 'privateKey'},
    {'1': 'passphrase', '3': 3, '4': 1, '5': 9, '10': 'passphrase'},
  ],
};

/// Descriptor for `LocalKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localKeyDescriptor = $convert.base64Decode(
    'CghMb2NhbEtleRIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSHwoLcHJpdmF0ZV9rZXkYAiABKAlSCn'
    'ByaXZhdGVLZXkSHgoKcGFzc3BocmFzZRgDIAEoCVIKcGFzc3BocmFzZQ==');

@$core.Deprecated('Use connectionDescriptor instead')
const Connection$json = {
  '1': 'Connection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'server_id', '3': 3, '4': 1, '5': 9, '10': 'serverId'},
    {
      '1': 'kind',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.Connection.Kind',
      '10': 'kind'
    },
    {'1': 'host', '3': 5, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 6, '4': 1, '5': 13, '10': 'port'},
    {'1': 'user', '3': 7, '4': 1, '5': 9, '10': 'user'},
    {'1': 'password', '3': 8, '4': 1, '5': 9, '10': 'password'},
    {'1': 'database', '3': 9, '4': 1, '5': 9, '10': 'database'},
    {
      '1': 'ssl_mode',
      '3': 10,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.Connection.SslMode',
      '10': 'sslMode'
    },
    {'1': 'source', '3': 11, '4': 1, '5': 9, '10': 'source'},
    {'1': 'color', '3': 12, '4': 1, '5': 9, '10': 'color'},
    {'1': 'updated_ms', '3': 13, '4': 1, '5': 3, '10': 'updatedMs'},
    {'1': 'databases', '3': 14, '4': 3, '5': 9, '10': 'databases'},
    {'1': 'read_only', '3': 15, '4': 1, '5': 8, '10': 'readOnly'},
  ],
  '4': [Connection_Kind$json, Connection_SslMode$json],
};

@$core.Deprecated('Use connectionDescriptor instead')
const Connection_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_UNSPECIFIED', '2': 0},
    {'1': 'POSTGRES', '2': 1},
  ],
};

@$core.Deprecated('Use connectionDescriptor instead')
const Connection_SslMode$json = {
  '1': 'SslMode',
  '2': [
    {'1': 'SSL_MODE_UNSPECIFIED', '2': 0},
    {'1': 'DISABLE', '2': 1},
    {'1': 'PREFER', '2': 2},
    {'1': 'REQUIRE', '2': 3},
  ],
};

/// Descriptor for `Connection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionDescriptor = $convert.base64Decode(
    'CgpDb25uZWN0aW9uEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhsKCXNlcn'
    'Zlcl9pZBgDIAEoCVIIc2VydmVySWQSNwoEa2luZBgEIAEoDjIjLnNlbGZob2xkLmNlbGxhci52'
    'MS5Db25uZWN0aW9uLktpbmRSBGtpbmQSEgoEaG9zdBgFIAEoCVIEaG9zdBISCgRwb3J0GAYgAS'
    'gNUgRwb3J0EhIKBHVzZXIYByABKAlSBHVzZXISGgoIcGFzc3dvcmQYCCABKAlSCHBhc3N3b3Jk'
    'EhoKCGRhdGFiYXNlGAkgASgJUghkYXRhYmFzZRJBCghzc2xfbW9kZRgKIAEoDjImLnNlbGZob2'
    'xkLmNlbGxhci52MS5Db25uZWN0aW9uLlNzbE1vZGVSB3NzbE1vZGUSFgoGc291cmNlGAsgASgJ'
    'UgZzb3VyY2USFAoFY29sb3IYDCABKAlSBWNvbG9yEh0KCnVwZGF0ZWRfbXMYDSABKANSCXVwZG'
    'F0ZWRNcxIcCglkYXRhYmFzZXMYDiADKAlSCWRhdGFiYXNlcxIbCglyZWFkX29ubHkYDyABKAhS'
    'CHJlYWRPbmx5IioKBEtpbmQSFAoQS0lORF9VTlNQRUNJRklFRBAAEgwKCFBPU1RHUkVTEAEiSQ'
    'oHU3NsTW9kZRIYChRTU0xfTU9ERV9VTlNQRUNJRklFRBAAEgsKB0RJU0FCTEUQARIKCgZQUkVG'
    'RVIQAhILCgdSRVFVSVJFEAM=');

@$core.Deprecated('Use connectionListDescriptor instead')
const ConnectionList$json = {
  '1': 'ConnectionList',
  '2': [
    {
      '1': 'connections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Connection',
      '10': 'connections'
    },
  ],
};

/// Descriptor for `ConnectionList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionListDescriptor = $convert.base64Decode(
    'Cg5Db25uZWN0aW9uTGlzdBJACgtjb25uZWN0aW9ucxgBIAMoCzIeLnNlbGZob2xkLmNlbGxhci'
    '52MS5Db25uZWN0aW9uUgtjb25uZWN0aW9ucw==');

@$core.Deprecated('Use testReplyDescriptor instead')
const TestReply$json = {
  '1': 'TestReply',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'server_version', '3': 2, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
    {'1': 'latency_ms', '3': 4, '4': 1, '5': 3, '10': 'latencyMs'},
  ],
};

/// Descriptor for `TestReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testReplyDescriptor = $convert.base64Decode(
    'CglUZXN0UmVwbHkSDgoCb2sYASABKAhSAm9rEiUKDnNlcnZlcl92ZXJzaW9uGAIgASgJUg1zZX'
    'J2ZXJWZXJzaW9uEhQKBWVycm9yGAMgASgJUgVlcnJvchIdCgpsYXRlbmN5X21zGAQgASgDUgls'
    'YXRlbmN5TXM=');

@$core.Deprecated('Use databaseDescriptor instead')
const Database$json = {
  '1': 'Database',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'owner', '3': 2, '4': 1, '5': 9, '10': 'owner'},
    {'1': 'size_bytes', '3': 3, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'is_template', '3': 4, '4': 1, '5': 8, '10': 'isTemplate'},
    {'1': 'can_connect', '3': 5, '4': 1, '5': 8, '10': 'canConnect'},
    {'1': 'encoding', '3': 6, '4': 1, '5': 9, '10': 'encoding'},
    {'1': 'collate', '3': 7, '4': 1, '5': 9, '10': 'collate'},
    {'1': 'ctype', '3': 8, '4': 1, '5': 9, '10': 'ctype'},
    {'1': 'connection_limit', '3': 9, '4': 1, '5': 5, '10': 'connectionLimit'},
    {'1': 'comment', '3': 10, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'template', '3': 11, '4': 1, '5': 9, '10': 'template'},
  ],
};

/// Descriptor for `Database`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List databaseDescriptor = $convert.base64Decode(
    'CghEYXRhYmFzZRISCgRuYW1lGAEgASgJUgRuYW1lEhQKBW93bmVyGAIgASgJUgVvd25lchIdCg'
    'pzaXplX2J5dGVzGAMgASgDUglzaXplQnl0ZXMSHwoLaXNfdGVtcGxhdGUYBCABKAhSCmlzVGVt'
    'cGxhdGUSHwoLY2FuX2Nvbm5lY3QYBSABKAhSCmNhbkNvbm5lY3QSGgoIZW5jb2RpbmcYBiABKA'
    'lSCGVuY29kaW5nEhgKB2NvbGxhdGUYByABKAlSB2NvbGxhdGUSFAoFY3R5cGUYCCABKAlSBWN0'
    'eXBlEikKEGNvbm5lY3Rpb25fbGltaXQYCSABKAVSD2Nvbm5lY3Rpb25MaW1pdBIYCgdjb21tZW'
    '50GAogASgJUgdjb21tZW50EhoKCHRlbXBsYXRlGAsgASgJUgh0ZW1wbGF0ZQ==');

@$core.Deprecated('Use databaseListDescriptor instead')
const DatabaseList$json = {
  '1': 'DatabaseList',
  '2': [
    {
      '1': 'databases',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Database',
      '10': 'databases'
    },
    {'1': 'server_version', '3': 2, '4': 1, '5': 9, '10': 'serverVersion'},
  ],
};

/// Descriptor for `DatabaseList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List databaseListDescriptor = $convert.base64Decode(
    'CgxEYXRhYmFzZUxpc3QSOgoJZGF0YWJhc2VzGAEgAygLMhwuc2VsZmhvbGQuY2VsbGFyLnYxLk'
    'RhdGFiYXNlUglkYXRhYmFzZXMSJQoOc2VydmVyX3ZlcnNpb24YAiABKAlSDXNlcnZlclZlcnNp'
    'b24=');

@$core.Deprecated('Use dbRefDescriptor instead')
const DbRef$json = {
  '1': 'DbRef',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
  ],
};

/// Descriptor for `DbRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dbRefDescriptor = $convert.base64Decode(
    'CgVEYlJlZhIjCg1jb25uZWN0aW9uX2lkGAEgASgJUgxjb25uZWN0aW9uSWQSGgoIZGF0YWJhc2'
    'UYAiABKAlSCGRhdGFiYXNl');

@$core.Deprecated('Use schemaDescriptor instead')
const Schema$json = {
  '1': 'Schema',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'owner', '3': 2, '4': 1, '5': 9, '10': 'owner'},
    {'1': 'system', '3': 3, '4': 1, '5': 8, '10': 'system'},
    {'1': 'comment', '3': 4, '4': 1, '5': 9, '10': 'comment'},
  ],
};

/// Descriptor for `Schema`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schemaDescriptor = $convert.base64Decode(
    'CgZTY2hlbWESEgoEbmFtZRgBIAEoCVIEbmFtZRIUCgVvd25lchgCIAEoCVIFb3duZXISFgoGc3'
    'lzdGVtGAMgASgIUgZzeXN0ZW0SGAoHY29tbWVudBgEIAEoCVIHY29tbWVudA==');

@$core.Deprecated('Use schemaListDescriptor instead')
const SchemaList$json = {
  '1': 'SchemaList',
  '2': [
    {
      '1': 'schemas',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Schema',
      '10': 'schemas'
    },
  ],
};

/// Descriptor for `SchemaList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schemaListDescriptor = $convert.base64Decode(
    'CgpTY2hlbWFMaXN0EjQKB3NjaGVtYXMYASADKAsyGi5zZWxmaG9sZC5jZWxsYXIudjEuU2NoZW'
    '1hUgdzY2hlbWFz');

@$core.Deprecated('Use schemaRefDescriptor instead')
const SchemaRef$json = {
  '1': 'SchemaRef',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 3, '4': 1, '5': 9, '10': 'schema'},
  ],
};

/// Descriptor for `SchemaRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schemaRefDescriptor = $convert.base64Decode(
    'CglTY2hlbWFSZWYSIwoNY29ubmVjdGlvbl9pZBgBIAEoCVIMY29ubmVjdGlvbklkEhoKCGRhdG'
    'FiYXNlGAIgASgJUghkYXRhYmFzZRIWCgZzY2hlbWEYAyABKAlSBnNjaGVtYQ==');

@$core.Deprecated('Use dbObjectDescriptor instead')
const DbObject$json = {
  '1': 'DbObject',
  '2': [
    {
      '1': 'kind',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.DbObject.Kind',
      '10': 'kind'
    },
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'comment', '3': 3, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'rows_estimate', '3': 4, '4': 1, '5': 3, '10': 'rowsEstimate'},
    {'1': 'signature', '3': 5, '4': 1, '5': 9, '10': 'signature'},
    {'1': 'labels', '3': 6, '4': 3, '5': 9, '10': 'labels'},
    {'1': 'base_type', '3': 7, '4': 1, '5': 9, '10': 'baseType'},
  ],
  '4': [DbObject_Kind$json],
};

@$core.Deprecated('Use dbObjectDescriptor instead')
const DbObject_Kind$json = {
  '1': 'Kind',
  '2': [
    {'1': 'KIND_UNSPECIFIED', '2': 0},
    {'1': 'TABLE', '2': 1},
    {'1': 'VIEW', '2': 2},
    {'1': 'MATERIALIZED_VIEW', '2': 3},
    {'1': 'SEQUENCE', '2': 4},
    {'1': 'FUNCTION', '2': 5},
    {'1': 'FOREIGN_TABLE', '2': 6},
    {'1': 'PARTITIONED_TABLE', '2': 7},
    {'1': 'PROCEDURE', '2': 8},
    {'1': 'ENUM', '2': 9},
    {'1': 'DOMAIN', '2': 10},
    {'1': 'COMPOSITE_TYPE', '2': 11},
    {'1': 'RANGE_TYPE', '2': 12},
  ],
};

/// Descriptor for `DbObject`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dbObjectDescriptor = $convert.base64Decode(
    'CghEYk9iamVjdBI1CgRraW5kGAEgASgOMiEuc2VsZmhvbGQuY2VsbGFyLnYxLkRiT2JqZWN0Lk'
    'tpbmRSBGtpbmQSEgoEbmFtZRgCIAEoCVIEbmFtZRIYCgdjb21tZW50GAMgASgJUgdjb21tZW50'
    'EiMKDXJvd3NfZXN0aW1hdGUYBCABKANSDHJvd3NFc3RpbWF0ZRIcCglzaWduYXR1cmUYBSABKA'
    'lSCXNpZ25hdHVyZRIWCgZsYWJlbHMYBiADKAlSBmxhYmVscxIbCgliYXNlX3R5cGUYByABKAlS'
    'CGJhc2VUeXBlItcBCgRLaW5kEhQKEEtJTkRfVU5TUEVDSUZJRUQQABIJCgVUQUJMRRABEggKBF'
    'ZJRVcQAhIVChFNQVRFUklBTElaRURfVklFVxADEgwKCFNFUVVFTkNFEAQSDAoIRlVOQ1RJT04Q'
    'BRIRCg1GT1JFSUdOX1RBQkxFEAYSFQoRUEFSVElUSU9ORURfVEFCTEUQBxINCglQUk9DRURVUk'
    'UQCBIICgRFTlVNEAkSCgoGRE9NQUlOEAoSEgoOQ09NUE9TSVRFX1RZUEUQCxIOCgpSQU5HRV9U'
    'WVBFEAw=');

@$core.Deprecated('Use objectListDescriptor instead')
const ObjectList$json = {
  '1': 'ObjectList',
  '2': [
    {
      '1': 'objects',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.DbObject',
      '10': 'objects'
    },
  ],
};

/// Descriptor for `ObjectList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List objectListDescriptor = $convert.base64Decode(
    'CgpPYmplY3RMaXN0EjYKB29iamVjdHMYASADKAsyHC5zZWxmaG9sZC5jZWxsYXIudjEuRGJPYm'
    'plY3RSB29iamVjdHM=');

@$core.Deprecated('Use objectRefDescriptor instead')
const ObjectRef$json = {
  '1': 'ObjectRef',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 3, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.DbObject.Kind',
      '10': 'kind'
    },
    {'1': 'signature', '3': 6, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `ObjectRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List objectRefDescriptor = $convert.base64Decode(
    'CglPYmplY3RSZWYSIwoNY29ubmVjdGlvbl9pZBgBIAEoCVIMY29ubmVjdGlvbklkEhoKCGRhdG'
    'FiYXNlGAIgASgJUghkYXRhYmFzZRIWCgZzY2hlbWEYAyABKAlSBnNjaGVtYRISCgRuYW1lGAQg'
    'ASgJUgRuYW1lEjUKBGtpbmQYBSABKA4yIS5zZWxmaG9sZC5jZWxsYXIudjEuRGJPYmplY3QuS2'
    'luZFIEa2luZBIcCglzaWduYXR1cmUYBiABKAlSCXNpZ25hdHVyZQ==');

@$core.Deprecated('Use columnDescriptor instead')
const Column$json = {
  '1': 'Column',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'nullable', '3': 3, '4': 1, '5': 8, '10': 'nullable'},
    {'1': 'default', '3': 4, '4': 1, '5': 9, '10': 'default'},
    {'1': 'comment', '3': 5, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'primary_key', '3': 6, '4': 1, '5': 8, '10': 'primaryKey'},
    {'1': 'type_oid', '3': 7, '4': 1, '5': 13, '10': 'typeOid'},
    {'1': 'position', '3': 8, '4': 1, '5': 5, '10': 'position'},
    {'1': 'identity', '3': 9, '4': 1, '5': 8, '10': 'identity'},
    {'1': 'generated', '3': 10, '4': 1, '5': 8, '10': 'generated'},
  ],
};

/// Descriptor for `Column`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnDescriptor = $convert.base64Decode(
    'CgZDb2x1bW4SEgoEbmFtZRgBIAEoCVIEbmFtZRISCgR0eXBlGAIgASgJUgR0eXBlEhoKCG51bG'
    'xhYmxlGAMgASgIUghudWxsYWJsZRIYCgdkZWZhdWx0GAQgASgJUgdkZWZhdWx0EhgKB2NvbW1l'
    'bnQYBSABKAlSB2NvbW1lbnQSHwoLcHJpbWFyeV9rZXkYBiABKAhSCnByaW1hcnlLZXkSGQoIdH'
    'lwZV9vaWQYByABKA1SB3R5cGVPaWQSGgoIcG9zaXRpb24YCCABKAVSCHBvc2l0aW9uEhoKCGlk'
    'ZW50aXR5GAkgASgIUghpZGVudGl0eRIcCglnZW5lcmF0ZWQYCiABKAhSCWdlbmVyYXRlZA==');

@$core.Deprecated('Use indexDescriptor instead')
const Index$json = {
  '1': 'Index',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'definition', '3': 2, '4': 1, '5': 9, '10': 'definition'},
    {'1': 'unique', '3': 3, '4': 1, '5': 8, '10': 'unique'},
    {'1': 'primary', '3': 4, '4': 1, '5': 8, '10': 'primary'},
  ],
};

/// Descriptor for `Index`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List indexDescriptor = $convert.base64Decode(
    'CgVJbmRleBISCgRuYW1lGAEgASgJUgRuYW1lEh4KCmRlZmluaXRpb24YAiABKAlSCmRlZmluaX'
    'Rpb24SFgoGdW5pcXVlGAMgASgIUgZ1bmlxdWUSGAoHcHJpbWFyeRgEIAEoCFIHcHJpbWFyeQ==');

@$core.Deprecated('Use constraintDescriptor instead')
const Constraint$json = {
  '1': 'Constraint',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 2, '4': 1, '5': 9, '10': 'type'},
    {'1': 'definition', '3': 3, '4': 1, '5': 9, '10': 'definition'},
  ],
};

/// Descriptor for `Constraint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List constraintDescriptor = $convert.base64Decode(
    'CgpDb25zdHJhaW50EhIKBG5hbWUYASABKAlSBG5hbWUSEgoEdHlwZRgCIAEoCVIEdHlwZRIeCg'
    'pkZWZpbml0aW9uGAMgASgJUgpkZWZpbml0aW9u');

@$core.Deprecated('Use triggerDescriptor instead')
const Trigger$json = {
  '1': 'Trigger',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'definition', '3': 2, '4': 1, '5': 9, '10': 'definition'},
    {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `Trigger`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List triggerDescriptor = $convert.base64Decode(
    'CgdUcmlnZ2VyEhIKBG5hbWUYASABKAlSBG5hbWUSHgoKZGVmaW5pdGlvbhgCIAEoCVIKZGVmaW'
    '5pdGlvbhIYCgdlbmFibGVkGAMgASgIUgdlbmFibGVk');

@$core.Deprecated('Use objectInfoDescriptor instead')
const ObjectInfo$json = {
  '1': 'ObjectInfo',
  '2': [
    {
      '1': 'object',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.DbObject',
      '10': 'object'
    },
    {
      '1': 'columns',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Column',
      '10': 'columns'
    },
    {
      '1': 'indexes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Index',
      '10': 'indexes'
    },
    {
      '1': 'constraints',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Constraint',
      '10': 'constraints'
    },
    {'1': 'ddl', '3': 5, '4': 1, '5': 9, '10': 'ddl'},
    {'1': 'primary_key', '3': 6, '4': 3, '5': 9, '10': 'primaryKey'},
    {'1': 'owner', '3': 7, '4': 1, '5': 9, '10': 'owner'},
    {'1': 'size_bytes', '3': 8, '4': 1, '5': 3, '10': 'sizeBytes'},
    {
      '1': 'triggers',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Trigger',
      '10': 'triggers'
    },
  ],
};

/// Descriptor for `ObjectInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List objectInfoDescriptor = $convert.base64Decode(
    'CgpPYmplY3RJbmZvEjQKBm9iamVjdBgBIAEoCzIcLnNlbGZob2xkLmNlbGxhci52MS5EYk9iam'
    'VjdFIGb2JqZWN0EjQKB2NvbHVtbnMYAiADKAsyGi5zZWxmaG9sZC5jZWxsYXIudjEuQ29sdW1u'
    'Ugdjb2x1bW5zEjMKB2luZGV4ZXMYAyADKAsyGS5zZWxmaG9sZC5jZWxsYXIudjEuSW5kZXhSB2'
    'luZGV4ZXMSQAoLY29uc3RyYWludHMYBCADKAsyHi5zZWxmaG9sZC5jZWxsYXIudjEuQ29uc3Ry'
    'YWludFILY29uc3RyYWludHMSEAoDZGRsGAUgASgJUgNkZGwSHwoLcHJpbWFyeV9rZXkYBiADKA'
    'lSCnByaW1hcnlLZXkSFAoFb3duZXIYByABKAlSBW93bmVyEh0KCnNpemVfYnl0ZXMYCCABKANS'
    'CXNpemVCeXRlcxI3Cgh0cmlnZ2VycxgJIAMoCzIbLnNlbGZob2xkLmNlbGxhci52MS5UcmlnZ2'
    'VyUgh0cmlnZ2Vycw==');

@$core.Deprecated('Use roleDescriptor instead')
const Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'login', '3': 2, '4': 1, '5': 8, '10': 'login'},
    {'1': 'superuser', '3': 3, '4': 1, '5': 8, '10': 'superuser'},
    {'1': 'create_db', '3': 4, '4': 1, '5': 8, '10': 'createDb'},
    {'1': 'create_role', '3': 5, '4': 1, '5': 8, '10': 'createRole'},
    {'1': 'inherit', '3': 6, '4': 1, '5': 8, '10': 'inherit'},
    {'1': 'replication', '3': 7, '4': 1, '5': 8, '10': 'replication'},
    {'1': 'bypass_rls', '3': 8, '4': 1, '5': 8, '10': 'bypassRls'},
    {'1': 'connection_limit', '3': 9, '4': 1, '5': 5, '10': 'connectionLimit'},
    {'1': 'valid_until', '3': 10, '4': 1, '5': 9, '10': 'validUntil'},
    {'1': 'member_of', '3': 11, '4': 3, '5': 9, '10': 'memberOf'},
    {'1': 'comment', '3': 12, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'system', '3': 13, '4': 1, '5': 8, '10': 'system'},
    {'1': 'password', '3': 14, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `Role`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleDescriptor = $convert.base64Decode(
    'CgRSb2xlEhIKBG5hbWUYASABKAlSBG5hbWUSFAoFbG9naW4YAiABKAhSBWxvZ2luEhwKCXN1cG'
    'VydXNlchgDIAEoCFIJc3VwZXJ1c2VyEhsKCWNyZWF0ZV9kYhgEIAEoCFIIY3JlYXRlRGISHwoL'
    'Y3JlYXRlX3JvbGUYBSABKAhSCmNyZWF0ZVJvbGUSGAoHaW5oZXJpdBgGIAEoCFIHaW5oZXJpdB'
    'IgCgtyZXBsaWNhdGlvbhgHIAEoCFILcmVwbGljYXRpb24SHQoKYnlwYXNzX3JscxgIIAEoCFIJ'
    'YnlwYXNzUmxzEikKEGNvbm5lY3Rpb25fbGltaXQYCSABKAVSD2Nvbm5lY3Rpb25MaW1pdBIfCg'
    't2YWxpZF91bnRpbBgKIAEoCVIKdmFsaWRVbnRpbBIbCgltZW1iZXJfb2YYCyADKAlSCG1lbWJl'
    'ck9mEhgKB2NvbW1lbnQYDCABKAlSB2NvbW1lbnQSFgoGc3lzdGVtGA0gASgIUgZzeXN0ZW0SGg'
    'oIcGFzc3dvcmQYDiABKAlSCHBhc3N3b3Jk');

@$core.Deprecated('Use roleListDescriptor instead')
const RoleList$json = {
  '1': 'RoleList',
  '2': [
    {
      '1': 'roles',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Role',
      '10': 'roles'
    },
  ],
};

/// Descriptor for `RoleList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roleListDescriptor = $convert.base64Decode(
    'CghSb2xlTGlzdBIuCgVyb2xlcxgBIAMoCzIYLnNlbGZob2xkLmNlbGxhci52MS5Sb2xlUgVyb2'
    'xlcw==');

@$core.Deprecated('Use columnSpecDescriptor instead')
const ColumnSpec$json = {
  '1': 'ColumnSpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'original', '3': 2, '4': 1, '5': 9, '10': 'original'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'nullable', '3': 4, '4': 1, '5': 8, '10': 'nullable'},
    {'1': 'default', '3': 5, '4': 1, '5': 9, '10': 'default'},
    {'1': 'comment', '3': 6, '4': 1, '5': 9, '10': 'comment'},
  ],
};

/// Descriptor for `ColumnSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List columnSpecDescriptor = $convert.base64Decode(
    'CgpDb2x1bW5TcGVjEhIKBG5hbWUYASABKAlSBG5hbWUSGgoIb3JpZ2luYWwYAiABKAlSCG9yaW'
    'dpbmFsEhIKBHR5cGUYAyABKAlSBHR5cGUSGgoIbnVsbGFibGUYBCABKAhSCG51bGxhYmxlEhgK'
    'B2RlZmF1bHQYBSABKAlSB2RlZmF1bHQSGAoHY29tbWVudBgGIAEoCVIHY29tbWVudA==');

@$core.Deprecated('Use tableSpecDescriptor instead')
const TableSpec$json = {
  '1': 'TableSpec',
  '2': [
    {'1': 'schema', '3': 1, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'comment', '3': 3, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'owner', '3': 4, '4': 1, '5': 9, '10': 'owner'},
    {
      '1': 'columns',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.ColumnSpec',
      '10': 'columns'
    },
    {'1': 'primary_key', '3': 6, '4': 3, '5': 9, '10': 'primaryKey'},
    {
      '1': 'constraints',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Constraint',
      '10': 'constraints'
    },
    {
      '1': 'indexes',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Index',
      '10': 'indexes'
    },
  ],
};

/// Descriptor for `TableSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableSpecDescriptor = $convert.base64Decode(
    'CglUYWJsZVNwZWMSFgoGc2NoZW1hGAEgASgJUgZzY2hlbWESEgoEbmFtZRgCIAEoCVIEbmFtZR'
    'IYCgdjb21tZW50GAMgASgJUgdjb21tZW50EhQKBW93bmVyGAQgASgJUgVvd25lchI4Cgdjb2x1'
    'bW5zGAUgAygLMh4uc2VsZmhvbGQuY2VsbGFyLnYxLkNvbHVtblNwZWNSB2NvbHVtbnMSHwoLcH'
    'JpbWFyeV9rZXkYBiADKAlSCnByaW1hcnlLZXkSQAoLY29uc3RyYWludHMYByADKAsyHi5zZWxm'
    'aG9sZC5jZWxsYXIudjEuQ29uc3RyYWludFILY29uc3RyYWludHMSMwoHaW5kZXhlcxgIIAMoCz'
    'IZLnNlbGZob2xkLmNlbGxhci52MS5JbmRleFIHaW5kZXhlcw==');

@$core.Deprecated('Use changeDescriptor instead')
const Change$json = {
  '1': 'Change',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {
      '1': 'op',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.Change.Op',
      '10': 'op'
    },
    {'1': 'original', '3': 4, '4': 1, '5': 9, '10': 'original'},
    {'1': 'cascade', '3': 5, '4': 1, '5': 8, '10': 'cascade'},
    {
      '1': 'role',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.Role',
      '9': 0,
      '10': 'role'
    },
    {
      '1': 'db',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.Database',
      '9': 0,
      '10': 'db'
    },
    {
      '1': 'schema',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.Schema',
      '9': 0,
      '10': 'schema'
    },
    {
      '1': 'table',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.TableSpec',
      '9': 0,
      '10': 'table'
    },
    {
      '1': 'target',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.ObjectRef',
      '9': 0,
      '10': 'target'
    },
  ],
  '4': [Change_Op$json],
  '8': [
    {'1': 'object'},
  ],
};

@$core.Deprecated('Use changeDescriptor instead')
const Change_Op$json = {
  '1': 'Op',
  '2': [
    {'1': 'OP_UNSPECIFIED', '2': 0},
    {'1': 'CREATE', '2': 1},
    {'1': 'ALTER', '2': 2},
    {'1': 'DROP', '2': 3},
  ],
};

/// Descriptor for `Change`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeDescriptor = $convert.base64Decode(
    'CgZDaGFuZ2USIwoNY29ubmVjdGlvbl9pZBgBIAEoCVIMY29ubmVjdGlvbklkEhoKCGRhdGFiYX'
    'NlGAIgASgJUghkYXRhYmFzZRItCgJvcBgDIAEoDjIdLnNlbGZob2xkLmNlbGxhci52MS5DaGFu'
    'Z2UuT3BSAm9wEhoKCG9yaWdpbmFsGAQgASgJUghvcmlnaW5hbBIYCgdjYXNjYWRlGAUgASgIUg'
    'djYXNjYWRlEi4KBHJvbGUYBiABKAsyGC5zZWxmaG9sZC5jZWxsYXIudjEuUm9sZUgAUgRyb2xl'
    'Ei4KAmRiGAcgASgLMhwuc2VsZmhvbGQuY2VsbGFyLnYxLkRhdGFiYXNlSABSAmRiEjQKBnNjaG'
    'VtYRgIIAEoCzIaLnNlbGZob2xkLmNlbGxhci52MS5TY2hlbWFIAFIGc2NoZW1hEjUKBXRhYmxl'
    'GAkgASgLMh0uc2VsZmhvbGQuY2VsbGFyLnYxLlRhYmxlU3BlY0gAUgV0YWJsZRI3CgZ0YXJnZX'
    'QYCiABKAsyHS5zZWxmaG9sZC5jZWxsYXIudjEuT2JqZWN0UmVmSABSBnRhcmdldCI5CgJPcBIS'
    'Cg5PUF9VTlNQRUNJRklFRBAAEgoKBkNSRUFURRABEgkKBUFMVEVSEAISCAoERFJPUBADQggKBm'
    '9iamVjdA==');

@$core.Deprecated('Use changePlanDescriptor instead')
const ChangePlan$json = {
  '1': 'ChangePlan',
  '2': [
    {'1': 'statements', '3': 1, '4': 3, '5': 9, '10': 'statements'},
    {'1': 'warnings', '3': 2, '4': 3, '5': 9, '10': 'warnings'},
    {'1': 'transactional', '3': 3, '4': 1, '5': 8, '10': 'transactional'},
  ],
};

/// Descriptor for `ChangePlan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePlanDescriptor = $convert.base64Decode(
    'CgpDaGFuZ2VQbGFuEh4KCnN0YXRlbWVudHMYASADKAlSCnN0YXRlbWVudHMSGgoId2FybmluZ3'
    'MYAiADKAlSCHdhcm5pbmdzEiQKDXRyYW5zYWN0aW9uYWwYAyABKAhSDXRyYW5zYWN0aW9uYWw=');

@$core.Deprecated('Use changeReplyDescriptor instead')
const ChangeReply$json = {
  '1': 'ChangeReply',
  '2': [
    {'1': 'statements', '3': 1, '4': 3, '5': 9, '10': 'statements'},
  ],
};

/// Descriptor for `ChangeReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changeReplyDescriptor = $convert.base64Decode(
    'CgtDaGFuZ2VSZXBseRIeCgpzdGF0ZW1lbnRzGAEgAygJUgpzdGF0ZW1lbnRz');

@$core.Deprecated('Use dumpToolDescriptor instead')
const DumpTool$json = {
  '1': 'DumpTool',
  '2': [
    {
      '1': 'place',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.ToolPlace',
      '10': 'place'
    },
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    {'1': 'major', '3': 4, '4': 1, '5': 5, '10': 'major'},
    {'1': 'fits', '3': 5, '4': 1, '5': 8, '10': 'fits'},
  ],
};

/// Descriptor for `DumpTool`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dumpToolDescriptor = $convert.base64Decode(
    'CghEdW1wVG9vbBIzCgVwbGFjZRgBIAEoDjIdLnNlbGZob2xkLmNlbGxhci52MS5Ub29sUGxhY2'
    'VSBXBsYWNlEhIKBHBhdGgYAiABKAlSBHBhdGgSGAoHdmVyc2lvbhgDIAEoCVIHdmVyc2lvbhIU'
    'CgVtYWpvchgEIAEoBVIFbWFqb3ISEgoEZml0cxgFIAEoCFIEZml0cw==');

@$core.Deprecated('Use dumpToolsReplyDescriptor instead')
const DumpToolsReply$json = {
  '1': 'DumpToolsReply',
  '2': [
    {
      '1': 'tools',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.DumpTool',
      '10': 'tools'
    },
    {'1': 'server_version', '3': 2, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'note', '3': 3, '4': 1, '5': 9, '10': 'note'},
  ],
};

/// Descriptor for `DumpToolsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dumpToolsReplyDescriptor = $convert.base64Decode(
    'Cg5EdW1wVG9vbHNSZXBseRIyCgV0b29scxgBIAMoCzIcLnNlbGZob2xkLmNlbGxhci52MS5EdW'
    '1wVG9vbFIFdG9vbHMSJQoOc2VydmVyX3ZlcnNpb24YAiABKAlSDXNlcnZlclZlcnNpb24SEgoE'
    'bm90ZRgDIAEoCVIEbm90ZQ==');

@$core.Deprecated('Use dumpRequestDescriptor instead')
const DumpRequest$json = {
  '1': 'DumpRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'format',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.DumpRequest.Format',
      '10': 'format'
    },
    {'1': 'schemas', '3': 5, '4': 3, '5': 9, '10': 'schemas'},
    {
      '1': 'tables',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.ObjectRef',
      '10': 'tables'
    },
    {'1': 'schema_only', '3': 7, '4': 1, '5': 8, '10': 'schemaOnly'},
    {'1': 'data_only', '3': 8, '4': 1, '5': 8, '10': 'dataOnly'},
    {'1': 'no_owner', '3': 9, '4': 1, '5': 8, '10': 'noOwner'},
    {'1': 'no_privileges', '3': 10, '4': 1, '5': 8, '10': 'noPrivileges'},
    {'1': 'clean', '3': 11, '4': 1, '5': 8, '10': 'clean'},
    {'1': 'create_database', '3': 12, '4': 1, '5': 8, '10': 'createDatabase'},
    {'1': 'inserts', '3': 13, '4': 1, '5': 8, '10': 'inserts'},
    {
      '1': 'place',
      '3': 14,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.ToolPlace',
      '10': 'place'
    },
  ],
  '4': [DumpRequest_Format$json],
};

@$core.Deprecated('Use dumpRequestDescriptor instead')
const DumpRequest_Format$json = {
  '1': 'Format',
  '2': [
    {'1': 'FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'PLAIN', '2': 1},
    {'1': 'CUSTOM', '2': 2},
    {'1': 'TAR', '2': 3},
  ],
};

/// Descriptor for `DumpRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dumpRequestDescriptor = $convert.base64Decode(
    'CgtEdW1wUmVxdWVzdBIjCg1jb25uZWN0aW9uX2lkGAEgASgJUgxjb25uZWN0aW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKAlSCGRhdGFiYXNlEhIKBHBhdGgYAyABKAlSBHBhdGgSPgoGZm9ybWF0GAQg'
    'ASgOMiYuc2VsZmhvbGQuY2VsbGFyLnYxLkR1bXBSZXF1ZXN0LkZvcm1hdFIGZm9ybWF0EhgKB3'
    'NjaGVtYXMYBSADKAlSB3NjaGVtYXMSNQoGdGFibGVzGAYgAygLMh0uc2VsZmhvbGQuY2VsbGFy'
    'LnYxLk9iamVjdFJlZlIGdGFibGVzEh8KC3NjaGVtYV9vbmx5GAcgASgIUgpzY2hlbWFPbmx5Eh'
    'sKCWRhdGFfb25seRgIIAEoCFIIZGF0YU9ubHkSGQoIbm9fb3duZXIYCSABKAhSB25vT3duZXIS'
    'IwoNbm9fcHJpdmlsZWdlcxgKIAEoCFIMbm9Qcml2aWxlZ2VzEhQKBWNsZWFuGAsgASgIUgVjbG'
    'VhbhInCg9jcmVhdGVfZGF0YWJhc2UYDCABKAhSDmNyZWF0ZURhdGFiYXNlEhgKB2luc2VydHMY'
    'DSABKAhSB2luc2VydHMSMwoFcGxhY2UYDiABKA4yHS5zZWxmaG9sZC5jZWxsYXIudjEuVG9vbF'
    'BsYWNlUgVwbGFjZSJACgZGb3JtYXQSFgoSRk9STUFUX1VOU1BFQ0lGSUVEEAASCQoFUExBSU4Q'
    'ARIKCgZDVVNUT00QAhIHCgNUQVIQAw==');

@$core.Deprecated('Use restoreRequestDescriptor instead')
const RestoreRequest$json = {
  '1': 'RestoreRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {'1': 'clean', '3': 4, '4': 1, '5': 8, '10': 'clean'},
    {'1': 'no_owner', '3': 5, '4': 1, '5': 8, '10': 'noOwner'},
    {'1': 'no_privileges', '3': 6, '4': 1, '5': 8, '10': 'noPrivileges'},
    {
      '1': 'single_transaction',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'singleTransaction'
    },
    {'1': 'schema_only', '3': 8, '4': 1, '5': 8, '10': 'schemaOnly'},
    {'1': 'data_only', '3': 9, '4': 1, '5': 8, '10': 'dataOnly'},
    {'1': 'create_database', '3': 10, '4': 1, '5': 8, '10': 'createDatabase'},
    {'1': 'exit_on_error', '3': 11, '4': 1, '5': 8, '10': 'exitOnError'},
    {
      '1': 'place',
      '3': 12,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.ToolPlace',
      '10': 'place'
    },
  ],
};

/// Descriptor for `RestoreRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List restoreRequestDescriptor = $convert.base64Decode(
    'Cg5SZXN0b3JlUmVxdWVzdBIjCg1jb25uZWN0aW9uX2lkGAEgASgJUgxjb25uZWN0aW9uSWQSGg'
    'oIZGF0YWJhc2UYAiABKAlSCGRhdGFiYXNlEhIKBHBhdGgYAyABKAlSBHBhdGgSFAoFY2xlYW4Y'
    'BCABKAhSBWNsZWFuEhkKCG5vX293bmVyGAUgASgIUgdub093bmVyEiMKDW5vX3ByaXZpbGVnZX'
    'MYBiABKAhSDG5vUHJpdmlsZWdlcxItChJzaW5nbGVfdHJhbnNhY3Rpb24YByABKAhSEXNpbmds'
    'ZVRyYW5zYWN0aW9uEh8KC3NjaGVtYV9vbmx5GAggASgIUgpzY2hlbWFPbmx5EhsKCWRhdGFfb2'
    '5seRgJIAEoCFIIZGF0YU9ubHkSJwoPY3JlYXRlX2RhdGFiYXNlGAogASgIUg5jcmVhdGVEYXRh'
    'YmFzZRIiCg1leGl0X29uX2Vycm9yGAsgASgIUgtleGl0T25FcnJvchIzCgVwbGFjZRgMIAEoDj'
    'IdLnNlbGZob2xkLmNlbGxhci52MS5Ub29sUGxhY2VSBXBsYWNl');

@$core.Deprecated('Use dumpProgressDescriptor instead')
const DumpProgress$json = {
  '1': 'DumpProgress',
  '2': [
    {'1': 'bytes', '3': 1, '4': 1, '5': 3, '10': 'bytes'},
    {'1': 'total', '3': 2, '4': 1, '5': 3, '10': 'total'},
    {'1': 'log', '3': 3, '4': 3, '5': 9, '10': 'log'},
    {'1': 'done', '3': 4, '4': 1, '5': 8, '10': 'done'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
    {'1': 'tool', '3': 6, '4': 1, '5': 9, '10': 'tool'},
    {'1': 'format', '3': 7, '4': 1, '5': 9, '10': 'format'},
  ],
};

/// Descriptor for `DumpProgress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dumpProgressDescriptor = $convert.base64Decode(
    'CgxEdW1wUHJvZ3Jlc3MSFAoFYnl0ZXMYASABKANSBWJ5dGVzEhQKBXRvdGFsGAIgASgDUgV0b3'
    'RhbBIQCgNsb2cYAyADKAlSA2xvZxISCgRkb25lGAQgASgIUgRkb25lEhQKBWVycm9yGAUgASgJ'
    'UgVlcnJvchISCgR0b29sGAYgASgJUgR0b29sEhYKBmZvcm1hdBgHIAEoCVIGZm9ybWF0');

@$core.Deprecated('Use resultColumnDescriptor instead')
const ResultColumn$json = {
  '1': 'ResultColumn',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type_oid', '3': 2, '4': 1, '5': 13, '10': 'typeOid'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {'1': 'table_column', '3': 4, '4': 1, '5': 9, '10': 'tableColumn'},
  ],
};

/// Descriptor for `ResultColumn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resultColumnDescriptor = $convert.base64Decode(
    'CgxSZXN1bHRDb2x1bW4SEgoEbmFtZRgBIAEoCVIEbmFtZRIZCgh0eXBlX29pZBgCIAEoDVIHdH'
    'lwZU9pZBISCgR0eXBlGAMgASgJUgR0eXBlEiEKDHRhYmxlX2NvbHVtbhgEIAEoCVILdGFibGVD'
    'b2x1bW4=');

@$core.Deprecated('Use cellDescriptor instead')
const Cell$json = {
  '1': 'Cell',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'null', '3': 2, '4': 1, '5': 8, '10': 'null'},
  ],
};

/// Descriptor for `Cell`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cellDescriptor = $convert.base64Decode(
    'CgRDZWxsEhIKBHRleHQYASABKAlSBHRleHQSEgoEbnVsbBgCIAEoCFIEbnVsbA==');

@$core.Deprecated('Use rowDescriptor instead')
const Row$json = {
  '1': 'Row',
  '2': [
    {
      '1': 'cells',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Cell',
      '10': 'cells'
    },
  ],
};

/// Descriptor for `Row`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowDescriptor = $convert.base64Decode(
    'CgNSb3cSLgoFY2VsbHMYASADKAsyGC5zZWxmaG9sZC5jZWxsYXIudjEuQ2VsbFIFY2VsbHM=');

@$core.Deprecated('Use resultSetDescriptor instead')
const ResultSet$json = {
  '1': 'ResultSet',
  '2': [
    {
      '1': 'columns',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.ResultColumn',
      '10': 'columns'
    },
    {
      '1': 'rows',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Row',
      '10': 'rows'
    },
    {'1': 'truncated', '3': 3, '4': 1, '5': 8, '10': 'truncated'},
    {'1': 'command_tag', '3': 4, '4': 1, '5': 9, '10': 'commandTag'},
    {'1': 'rows_affected', '3': 5, '4': 1, '5': 3, '10': 'rowsAffected'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
    {'1': 'error_detail', '3': 7, '4': 1, '5': 9, '10': 'errorDetail'},
    {'1': 'duration_ms', '3': 8, '4': 1, '5': 3, '10': 'durationMs'},
    {'1': 'statement', '3': 9, '4': 1, '5': 9, '10': 'statement'},
    {'1': 'key_columns', '3': 10, '4': 3, '5': 9, '10': 'keyColumns'},
    {'1': 'has_ctid', '3': 11, '4': 1, '5': 8, '10': 'hasCtid'},
    {'1': 'total_estimate', '3': 12, '4': 1, '5': 3, '10': 'totalEstimate'},
    {'1': 'notices', '3': 13, '4': 3, '5': 9, '10': 'notices'},
    {'1': 'statement_start', '3': 14, '4': 1, '5': 5, '10': 'statementStart'},
    {'1': 'statement_end', '3': 15, '4': 1, '5': 5, '10': 'statementEnd'},
    {'1': 'error_offset', '3': 16, '4': 1, '5': 5, '10': 'errorOffset'},
  ],
};

/// Descriptor for `ResultSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resultSetDescriptor = $convert.base64Decode(
    'CglSZXN1bHRTZXQSOgoHY29sdW1ucxgBIAMoCzIgLnNlbGZob2xkLmNlbGxhci52MS5SZXN1bH'
    'RDb2x1bW5SB2NvbHVtbnMSKwoEcm93cxgCIAMoCzIXLnNlbGZob2xkLmNlbGxhci52MS5Sb3dS'
    'BHJvd3MSHAoJdHJ1bmNhdGVkGAMgASgIUgl0cnVuY2F0ZWQSHwoLY29tbWFuZF90YWcYBCABKA'
    'lSCmNvbW1hbmRUYWcSIwoNcm93c19hZmZlY3RlZBgFIAEoA1IMcm93c0FmZmVjdGVkEhQKBWVy'
    'cm9yGAYgASgJUgVlcnJvchIhCgxlcnJvcl9kZXRhaWwYByABKAlSC2Vycm9yRGV0YWlsEh8KC2'
    'R1cmF0aW9uX21zGAggASgDUgpkdXJhdGlvbk1zEhwKCXN0YXRlbWVudBgJIAEoCVIJc3RhdGVt'
    'ZW50Eh8KC2tleV9jb2x1bW5zGAogAygJUgprZXlDb2x1bW5zEhkKCGhhc19jdGlkGAsgASgIUg'
    'doYXNDdGlkEiUKDnRvdGFsX2VzdGltYXRlGAwgASgDUg10b3RhbEVzdGltYXRlEhgKB25vdGlj'
    'ZXMYDSADKAlSB25vdGljZXMSJwoPc3RhdGVtZW50X3N0YXJ0GA4gASgFUg5zdGF0ZW1lbnRTdG'
    'FydBIjCg1zdGF0ZW1lbnRfZW5kGA8gASgFUgxzdGF0ZW1lbnRFbmQSIQoMZXJyb3Jfb2Zmc2V0'
    'GBAgASgFUgtlcnJvck9mZnNldA==');

@$core.Deprecated('Use sortDescriptor instead')
const Sort$json = {
  '1': 'Sort',
  '2': [
    {'1': 'column', '3': 1, '4': 1, '5': 9, '10': 'column'},
    {'1': 'desc', '3': 2, '4': 1, '5': 8, '10': 'desc'},
  ],
};

/// Descriptor for `Sort`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sortDescriptor = $convert.base64Decode(
    'CgRTb3J0EhYKBmNvbHVtbhgBIAEoCVIGY29sdW1uEhIKBGRlc2MYAiABKAhSBGRlc2M=');

@$core.Deprecated('Use readTableRequestDescriptor instead')
const ReadTableRequest$json = {
  '1': 'ReadTableRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 3, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'table', '3': 4, '4': 1, '5': 9, '10': 'table'},
    {'1': 'offset', '3': 5, '4': 1, '5': 3, '10': 'offset'},
    {'1': 'limit', '3': 6, '4': 1, '5': 5, '10': 'limit'},
    {
      '1': 'sort',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.Sort',
      '10': 'sort'
    },
    {'1': 'filter', '3': 8, '4': 1, '5': 9, '10': 'filter'},
  ],
};

/// Descriptor for `ReadTableRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readTableRequestDescriptor = $convert.base64Decode(
    'ChBSZWFkVGFibGVSZXF1ZXN0EiMKDWNvbm5lY3Rpb25faWQYASABKAlSDGNvbm5lY3Rpb25JZB'
    'IaCghkYXRhYmFzZRgCIAEoCVIIZGF0YWJhc2USFgoGc2NoZW1hGAMgASgJUgZzY2hlbWESFAoF'
    'dGFibGUYBCABKAlSBXRhYmxlEhYKBm9mZnNldBgFIAEoA1IGb2Zmc2V0EhQKBWxpbWl0GAYgAS'
    'gFUgVsaW1pdBIsCgRzb3J0GAcgAygLMhguc2VsZmhvbGQuY2VsbGFyLnYxLlNvcnRSBHNvcnQS'
    'FgoGZmlsdGVyGAggASgJUgZmaWx0ZXI=');

@$core.Deprecated('Use editValueDescriptor instead')
const EditValue$json = {
  '1': 'EditValue',
  '2': [
    {'1': 'column', '3': 1, '4': 1, '5': 9, '10': 'column'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.selfhold.cellar.v1.Cell',
      '10': 'value'
    },
    {'1': 'use_default', '3': 3, '4': 1, '5': 8, '10': 'useDefault'},
  ],
};

/// Descriptor for `EditValue`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editValueDescriptor = $convert.base64Decode(
    'CglFZGl0VmFsdWUSFgoGY29sdW1uGAEgASgJUgZjb2x1bW4SLgoFdmFsdWUYAiABKAsyGC5zZW'
    'xmaG9sZC5jZWxsYXIudjEuQ2VsbFIFdmFsdWUSHwoLdXNlX2RlZmF1bHQYAyABKAhSCnVzZURl'
    'ZmF1bHQ=');

@$core.Deprecated('Use rowEditDescriptor instead')
const RowEdit$json = {
  '1': 'RowEdit',
  '2': [
    {
      '1': 'op',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.selfhold.cellar.v1.RowEdit.Op',
      '10': 'op'
    },
    {
      '1': 'key',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.EditValue',
      '10': 'key'
    },
    {
      '1': 'values',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.EditValue',
      '10': 'values'
    },
  ],
  '4': [RowEdit_Op$json],
};

@$core.Deprecated('Use rowEditDescriptor instead')
const RowEdit_Op$json = {
  '1': 'Op',
  '2': [
    {'1': 'OP_UNSPECIFIED', '2': 0},
    {'1': 'INSERT', '2': 1},
    {'1': 'UPDATE', '2': 2},
    {'1': 'DELETE', '2': 3},
  ],
};

/// Descriptor for `RowEdit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rowEditDescriptor = $convert.base64Decode(
    'CgdSb3dFZGl0Ei4KAm9wGAEgASgOMh4uc2VsZmhvbGQuY2VsbGFyLnYxLlJvd0VkaXQuT3BSAm'
    '9wEi8KA2tleRgCIAMoCzIdLnNlbGZob2xkLmNlbGxhci52MS5FZGl0VmFsdWVSA2tleRI1CgZ2'
    'YWx1ZXMYAyADKAsyHS5zZWxmaG9sZC5jZWxsYXIudjEuRWRpdFZhbHVlUgZ2YWx1ZXMiPAoCT3'
    'ASEgoOT1BfVU5TUEVDSUZJRUQQABIKCgZJTlNFUlQQARIKCgZVUERBVEUQAhIKCgZERUxFVEUQ'
    'Aw==');

@$core.Deprecated('Use editRequestDescriptor instead')
const EditRequest$json = {
  '1': 'EditRequest',
  '2': [
    {'1': 'connection_id', '3': 1, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 2, '4': 1, '5': 9, '10': 'database'},
    {'1': 'schema', '3': 3, '4': 1, '5': 9, '10': 'schema'},
    {'1': 'table', '3': 4, '4': 1, '5': 9, '10': 'table'},
    {
      '1': 'edits',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.RowEdit',
      '10': 'edits'
    },
  ],
};

/// Descriptor for `EditRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editRequestDescriptor = $convert.base64Decode(
    'CgtFZGl0UmVxdWVzdBIjCg1jb25uZWN0aW9uX2lkGAEgASgJUgxjb25uZWN0aW9uSWQSGgoIZG'
    'F0YWJhc2UYAiABKAlSCGRhdGFiYXNlEhYKBnNjaGVtYRgDIAEoCVIGc2NoZW1hEhQKBXRhYmxl'
    'GAQgASgJUgV0YWJsZRIxCgVlZGl0cxgFIAMoCzIbLnNlbGZob2xkLmNlbGxhci52MS5Sb3dFZG'
    'l0UgVlZGl0cw==');

@$core.Deprecated('Use editReplyDescriptor instead')
const EditReply$json = {
  '1': 'EditReply',
  '2': [
    {'1': 'rows_affected', '3': 1, '4': 1, '5': 3, '10': 'rowsAffected'},
    {'1': 'statements', '3': 2, '4': 3, '5': 9, '10': 'statements'},
  ],
};

/// Descriptor for `EditReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editReplyDescriptor = $convert.base64Decode(
    'CglFZGl0UmVwbHkSIwoNcm93c19hZmZlY3RlZBgBIAEoA1IMcm93c0FmZmVjdGVkEh4KCnN0YX'
    'RlbWVudHMYAiADKAlSCnN0YXRlbWVudHM=');

@$core.Deprecated('Use consoleDescriptor instead')
const Console$json = {
  '1': 'Console',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'connection_id', '3': 2, '4': 1, '5': 9, '10': 'connectionId'},
    {'1': 'database', '3': 3, '4': 1, '5': 9, '10': 'database'},
    {'1': 'server_version', '3': 4, '4': 1, '5': 9, '10': 'serverVersion'},
    {'1': 'backend_pid', '3': 5, '4': 1, '5': 5, '10': 'backendPid'},
  ],
};

/// Descriptor for `Console`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consoleDescriptor = $convert.base64Decode(
    'CgdDb25zb2xlEg4KAmlkGAEgASgJUgJpZBIjCg1jb25uZWN0aW9uX2lkGAIgASgJUgxjb25uZW'
    'N0aW9uSWQSGgoIZGF0YWJhc2UYAyABKAlSCGRhdGFiYXNlEiUKDnNlcnZlcl92ZXJzaW9uGAQg'
    'ASgJUg1zZXJ2ZXJWZXJzaW9uEh8KC2JhY2tlbmRfcGlkGAUgASgFUgpiYWNrZW5kUGlk');

@$core.Deprecated('Use consoleRefDescriptor instead')
const ConsoleRef$json = {
  '1': 'ConsoleRef',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `ConsoleRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consoleRefDescriptor =
    $convert.base64Decode('CgpDb25zb2xlUmVmEg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use executeRequestDescriptor instead')
const ExecuteRequest$json = {
  '1': 'ExecuteRequest',
  '2': [
    {'1': 'console_id', '3': 1, '4': 1, '5': 9, '10': 'consoleId'},
    {'1': 'sql', '3': 2, '4': 1, '5': 9, '10': 'sql'},
    {'1': 'max_rows', '3': 3, '4': 1, '5': 5, '10': 'maxRows'},
    {'1': 'all', '3': 4, '4': 1, '5': 8, '10': 'all'},
    {'1': 'cursor', '3': 5, '4': 1, '5': 5, '10': 'cursor'},
  ],
};

/// Descriptor for `ExecuteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeRequestDescriptor = $convert.base64Decode(
    'Cg5FeGVjdXRlUmVxdWVzdBIdCgpjb25zb2xlX2lkGAEgASgJUgljb25zb2xlSWQSEAoDc3FsGA'
    'IgASgJUgNzcWwSGQoIbWF4X3Jvd3MYAyABKAVSB21heFJvd3MSEAoDYWxsGAQgASgIUgNhbGwS'
    'FgoGY3Vyc29yGAUgASgFUgZjdXJzb3I=');

@$core.Deprecated('Use statementsRequestDescriptor instead')
const StatementsRequest$json = {
  '1': 'StatementsRequest',
  '2': [
    {'1': 'sql', '3': 1, '4': 1, '5': 9, '10': 'sql'},
  ],
};

/// Descriptor for `StatementsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementsRequestDescriptor = $convert
    .base64Decode('ChFTdGF0ZW1lbnRzUmVxdWVzdBIQCgNzcWwYASABKAlSA3NxbA==');

@$core.Deprecated('Use statementRangeDescriptor instead')
const StatementRange$json = {
  '1': 'StatementRange',
  '2': [
    {'1': 'start', '3': 1, '4': 1, '5': 5, '10': 'start'},
    {'1': 'end', '3': 2, '4': 1, '5': 5, '10': 'end'},
  ],
};

/// Descriptor for `StatementRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementRangeDescriptor = $convert.base64Decode(
    'Cg5TdGF0ZW1lbnRSYW5nZRIUCgVzdGFydBgBIAEoBVIFc3RhcnQSEAoDZW5kGAIgASgFUgNlbm'
    'Q=');

@$core.Deprecated('Use statementsReplyDescriptor instead')
const StatementsReply$json = {
  '1': 'StatementsReply',
  '2': [
    {
      '1': 'statements',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.StatementRange',
      '10': 'statements'
    },
  ],
};

/// Descriptor for `StatementsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statementsReplyDescriptor = $convert.base64Decode(
    'Cg9TdGF0ZW1lbnRzUmVwbHkSQgoKc3RhdGVtZW50cxgBIAMoCzIiLnNlbGZob2xkLmNlbGxhci'
    '52MS5TdGF0ZW1lbnRSYW5nZVIKc3RhdGVtZW50cw==');

@$core.Deprecated('Use executeReplyDescriptor instead')
const ExecuteReply$json = {
  '1': 'ExecuteReply',
  '2': [
    {
      '1': 'results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.selfhold.cellar.v1.ResultSet',
      '10': 'results'
    },
    {'1': 'tx_status', '3': 2, '4': 1, '5': 9, '10': 'txStatus'},
    {'1': 'duration_ms', '3': 3, '4': 1, '5': 3, '10': 'durationMs'},
  ],
};

/// Descriptor for `ExecuteReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executeReplyDescriptor = $convert.base64Decode(
    'CgxFeGVjdXRlUmVwbHkSNwoHcmVzdWx0cxgBIAMoCzIdLnNlbGZob2xkLmNlbGxhci52MS5SZX'
    'N1bHRTZXRSB3Jlc3VsdHMSGwoJdHhfc3RhdHVzGAIgASgJUgh0eFN0YXR1cxIfCgtkdXJhdGlv'
    'bl9tcxgDIAEoA1IKZHVyYXRpb25Ncw==');

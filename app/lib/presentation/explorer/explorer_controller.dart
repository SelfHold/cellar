import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../core/core_cubit.dart';

/// What a tree row is.
enum NodeKind { group, server, direct, connection, roles, role, database, schema, folder, object, part, column, key, idx, trigger, info }

/// Folders of a schema (DataGrip: tables, views, routines, sequences).
enum ObjFolder { tables, views, matviews, foreign, sequences, routines, enums, domains, types }

/// Folders of a table.
enum ObjPart { columns, keys, indexes, triggers }

String partLabel(ObjPart p) => switch (p) {
  ObjPart.columns => tr('columns', 'колонки'),
  ObjPart.keys => tr('keys and checks', 'ключи и проверки'),
  ObjPart.indexes => tr('indexes', 'индексы'),
  ObjPart.triggers => tr('triggers', 'триггеры'),
};

String folderLabel(ObjFolder f) => switch (f) {
  ObjFolder.tables => tr('tables', 'таблицы'),
  ObjFolder.views => tr('views', 'представления'),
  ObjFolder.matviews => tr('materialized views', 'материализованные'),
  ObjFolder.foreign => tr('foreign tables', 'внешние таблицы'),
  ObjFolder.sequences => tr('sequences', 'последовательности'),
  ObjFolder.routines => tr('routines', 'функции'),
  ObjFolder.enums => tr('enums', 'перечисления'),
  ObjFolder.domains => tr('domains', 'домены'),
  ObjFolder.types => tr('types', 'типы'),
};

ObjFolder folderOf(pb.DbObject_Kind k) => switch (k) {
  pb.DbObject_Kind.TABLE || pb.DbObject_Kind.PARTITIONED_TABLE => ObjFolder.tables,
  pb.DbObject_Kind.VIEW => ObjFolder.views,
  pb.DbObject_Kind.MATERIALIZED_VIEW => ObjFolder.matviews,
  pb.DbObject_Kind.FOREIGN_TABLE => ObjFolder.foreign,
  pb.DbObject_Kind.SEQUENCE => ObjFolder.sequences,
  pb.DbObject_Kind.ENUM => ObjFolder.enums,
  pb.DbObject_Kind.DOMAIN => ObjFolder.domains,
  pb.DbObject_Kind.COMPOSITE_TYPE || pb.DbObject_Kind.RANGE_TYPE => ObjFolder.types,
  _ => ObjFolder.routines,
};

/// Where an object lives.
class DbPath {
  const DbPath(this.conn, [this.db = '', this.schema = '', this.name = '', this.kind = pb.DbObject_Kind.KIND_UNSPECIFIED, this.signature = '']);

  final String conn;
  final String db;
  final String schema;
  final String name;
  final pb.DbObject_Kind kind;
  final String signature;

  bool get readable => switch (kind) {
    pb.DbObject_Kind.TABLE ||
    pb.DbObject_Kind.VIEW ||
    pb.DbObject_Kind.MATERIALIZED_VIEW ||
    pb.DbObject_Kind.FOREIGN_TABLE ||
    pb.DbObject_Kind.PARTITIONED_TABLE ||
    pb.DbObject_Kind.SEQUENCE => true,
    _ => false,
  };

  bool get editable => kind == pb.DbObject_Kind.TABLE || kind == pb.DbObject_Kind.PARTITIONED_TABLE || kind == pb.DbObject_Kind.FOREIGN_TABLE;

  /// A plain or partitioned table: its structure can be modified.
  bool get table => kind == pb.DbObject_Kind.TABLE || kind == pb.DbObject_Kind.PARTITIONED_TABLE;

  /// Only DDL to show (no columns, no data).
  bool get ddlOnly => switch (kind) {
    pb.DbObject_Kind.FUNCTION || pb.DbObject_Kind.PROCEDURE || pb.DbObject_Kind.SEQUENCE || pb.DbObject_Kind.ENUM || pb.DbObject_Kind.DOMAIN || pb.DbObject_Kind.RANGE_TYPE => true,
    _ => false,
  };

  pb.ObjectRef get ref => pb.ObjectRef(connectionId: conn, database: db, schema: schema, name: name, kind: kind, signature: signature);
}

/// One visible row of the tree.
class TreeRow {
  TreeRow({required this.key, required this.depth, required this.kind, required this.label, this.detail = '', this.expandable = false, this.server, this.connection, this.path, this.folder, this.object, this.column, this.color, this.role, this.part, this.item});

  final String key;
  final int depth;
  final NodeKind kind;
  final String label;
  final String detail;
  final bool expandable;
  final pb.Server? server;
  final pb.Connection? connection;
  final DbPath? path;
  final ObjFolder? folder;
  final pb.DbObject? object;
  final pb.Column? column;
  final Color? color;
  final pb.Role? role;
  final ObjPart? part;

  /// A key, index or trigger row: its pb.Constraint / pb.Index / pb.Trigger.
  final Object? item;
}

const _sep = '\u0000';

/// The tree's data: servers and connections from the core, databases and
/// schema objects loaded as nodes open; [rows] is what is visible.
class ExplorerController extends ChangeNotifier {
  ExplorerController(this.core) {
    _events = core.events.listen(_onEvent);
    _session = core.stream.listen((s) {
      if (s.session != _seenSession && s.conn == Conn.ready) {
        _seenSession = s.session;
        _cache.clear();
        reload();
      }
    });
    if (core.state.conn == Conn.ready) {
      _seenSession = core.state.session;
      reload();
    }
  }

  final CoreCubit core;
  late final StreamSubscription<pb.Event> _events;
  late final StreamSubscription<CoreState> _session;
  int _seenSession = -1;

  List<pb.Server> servers = [];
  List<pb.Connection> connections = [];
  bool loaded = false;
  String? error;

  final expanded = <String>{'d:'};
  final _cache = <String, Object>{}; // node key -> loaded children data
  final loading = <String>{};
  final errors = <String, String>{};
  String? selected;

  pb.CellarClient get api => core.api;

  void _onEvent(pb.Event ev) {
    switch (ev.kind) {
      case pb.Event_Kind.SERVERS:
      case pb.Event_Kind.SSH:
        _loadServers();
      case pb.Event_Kind.CONNECTIONS:
        _loadConnections();
      default:
    }
  }

  Future<void> reload() async {
    await Future.wait([_loadServers(), _loadConnections()]);
    loaded = true;
    notifyListeners();
  }

  Future<void> _loadServers() async {
    try {
      servers = (await api.listServers(pb.Empty())).servers;
      for (final s in servers) {
        if (s.group.isNotEmpty) {
          // New groups start open.
          final parts = s.group.split('/');
          for (var i = 1; i <= parts.length; i++) {
            final k = 'g:${parts.take(i).join('/')}';
            if (!_seenGroups.contains(k)) {
              _seenGroups.add(k);
              expanded.add(k);
            }
          }
        }
      }
      error = null;
    } catch (e) {
      error = errorText(e);
    }
    notifyListeners();
  }

  final _seenGroups = <String>{};

  Future<void> _loadConnections() async {
    try {
      final old = {for (final c in connections) c.id: c};
      connections = (await api.listConnections(pb.Empty())).connections;
      // A connection whose settings changed reloads its subtree.
      for (final c in connections) {
        final o = old[c.id];
        if (o != null && o.writeToBuffer().toString() != c.writeToBuffer().toString()) _dropUnder('c:${c.id}');
      }
      error = null;
    } catch (e) {
      error = errorText(e);
    }
    notifyListeners();
  }

  pb.Server? server(String id) {
    for (final s in servers) {
      if (s.id == id) return s;
    }
    return null;
  }

  pb.Connection? connection(String id) {
    for (final c in connections) {
      if (c.id == id) return c;
    }
    return null;
  }

  void select(String key) {
    selected = key;
    notifyListeners();
  }

  void toggle(TreeRow r) {
    if (!r.expandable) return;
    if (expanded.remove(r.key)) {
      notifyListeners();
      return;
    }
    expanded.add(r.key);
    notifyListeners();
    _ensure(r);
  }

  void expand(String key) {
    expanded.add(key);
    notifyListeners();
  }

  /// Loads the node's children again.
  void refresh(TreeRow r) {
    _dropUnder(r.key);
    if (r.kind == NodeKind.server || r.kind == NodeKind.group || r.kind == NodeKind.direct) {
      reload();
      return;
    }
    if (expanded.contains(r.key)) _ensure(r);
    notifyListeners();
  }

  void _dropUnder(String key) {
    final body = key.substring(key.indexOf(':') + 1);
    _cache.removeWhere((k, _) => k == key || k.substring(k.indexOf(':') + 1).startsWith(body));
    errors.removeWhere((k, _) => k == key || k.substring(k.indexOf(':') + 1).startsWith(body));
  }

  Future<void> _ensure(TreeRow r) async {
    if (_cache.containsKey(r.key) || loading.contains(r.key)) return;
    final p = r.path;
    Future<Object> Function()? load;
    switch (r.kind) {
      case NodeKind.connection:
        load = () async => (await api.listDatabases(pb.Ref(id: r.connection!.id))).databases;
      case NodeKind.database:
        load = () async => (await api.listSchemas(pb.DbRef(connectionId: p!.conn, database: p.db))).schemas;
      case NodeKind.schema:
        load = () async => (await api.listObjects(pb.SchemaRef(connectionId: p!.conn, database: p.db, schema: p.schema))).objects;
      case NodeKind.object:
        load = () async => await api.describeObject(p!.ref);
      case NodeKind.roles:
        load = () async => (await api.listRoles(pb.Ref(id: r.connection!.id))).roles;
      default:
    }
    if (load == null) return;
    loading.add(r.key);
    errors.remove(r.key);
    notifyListeners();
    try {
      _cache[r.key] = await load();
    } catch (e) {
      errors[r.key] = errorText(e);
    }
    loading.remove(r.key);
    notifyListeners();
  }

  /// Loads a node's children again (after a change made from the tree).
  void reloadKey(String key) {
    _dropUnder(key);
    notifyListeners();
  }

  /// Keys of the tree's nodes.
  static String connectionKey(String conn) => 'c:$conn';
  static String rolesKey(String conn) => 'r:$conn';
  static String databaseKey(String conn, String db) => 'db:$conn$_sep$db';
  static String schemaKey(String conn, String db, String schema) => 'sc:$conn$_sep$db$_sep$schema';

  /// Roles of a connection, when loaded.
  List<pb.Role> rolesOf(String conn) => (_cache[rolesKey(conn)] as List<pb.Role>?) ?? const [];

  /// Databases of a connection, when loaded.
  List<pb.Database> databasesOf(String conn) => (_cache[connectionKey(conn)] as List<pb.Database>?) ?? const [];

  /// Schemas of a database, when loaded.
  List<pb.Schema> schemasOf(String conn, String db) => (_cache[databaseKey(conn, db)] as List<pb.Schema>?) ?? const [];

  /// Objects of a schema, when loaded (the console's completion uses them).
  List<pb.DbObject> objectsOf(String conn, String db, String schema) =>
      (_cache['sc:$conn$_sep$db$_sep$schema'] as List<pb.DbObject>?) ?? const [];

  // --- the visible rows ------------------------------------------------------

  List<TreeRow> get rows {
    final out = <TreeRow>[];
    // Groups as a tree of folders.
    final byGroup = <String, List<pb.Server>>{};
    for (final s in servers) {
      byGroup.putIfAbsent(s.group, () => []).add(s);
    }
    final groups = byGroup.keys.where((g) => g.isNotEmpty).toSet();
    final allFolders = <String>{};
    for (final g in groups) {
      final parts = g.split('/');
      for (var i = 1; i <= parts.length; i++) {
        allFolders.add(parts.take(i).join('/'));
      }
    }
    void addFolder(String path, int depth) {
      final key = 'g:$path';
      final name = path.split('/').last;
      final open = expanded.contains(key);
      out.add(TreeRow(key: key, depth: depth, kind: NodeKind.group, label: name, expandable: true));
      if (!open) return;
      final subs = allFolders.where((f) => f.startsWith('$path/') && !f.substring(path.length + 1).contains('/')).toList()..sort();
      for (final f in subs) {
        addFolder(f, depth + 1);
      }
      for (final s in byGroup[path] ?? const <pb.Server>[]) {
        _addServer(out, s, depth + 1);
      }
    }

    final top = allFolders.where((f) => !f.contains('/')).toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final f in top) {
      addFolder(f, 0);
    }
    for (final s in byGroup[''] ?? const <pb.Server>[]) {
      _addServer(out, s, 0);
    }
    final direct = connections.where((c) => c.serverId.isEmpty || server(c.serverId) == null).toList();
    if (direct.isNotEmpty) {
      final open = expanded.contains('d:');
      out.add(TreeRow(key: 'd:', depth: 0, kind: NodeKind.direct, label: tr('This device', 'Это устройство'), detail: tr('direct connections', 'прямые подключения'), expandable: true));
      if (open) {
        for (final c in direct) {
          _addConnection(out, c, 1);
        }
      }
    }
    return out;
  }

  void _addServer(List<TreeRow> out, pb.Server s, int depth) {
    final key = 's:${s.id}';
    final conns = connections.where((c) => c.serverId == s.id).toList();
    out.add(TreeRow(key: key, depth: depth, kind: NodeKind.server, label: s.name, detail: '${s.user}@${s.host}${s.port == 0 || s.port == 22 ? '' : ':${s.port}'}', expandable: true, server: s));
    if (!expanded.contains(key)) return;
    if (conns.isEmpty) {
      out.add(TreeRow(key: '$key/empty', depth: depth + 1, kind: NodeKind.info, label: tr('No databases yet: “Find databases” looks on the server', 'Баз пока нет: «Найти базы» поищет на сервере'), server: s));
    }
    for (final c in conns) {
      _addConnection(out, c, depth + 1);
    }
  }

  void _addConnection(List<TreeRow> out, pb.Connection c, int depth) {
    final key = 'c:${c.id}';
    out.add(TreeRow(key: key, depth: depth, kind: NodeKind.connection, label: c.name, detail: '${c.host}:${c.port == 0 ? 5432 : c.port}', expandable: true, connection: c, path: DbPath(c.id)));
    if (!expanded.contains(key)) return;
    if (!_status(out, key, depth + 1)) return;
    final dbs = (_cache[key] as List<pb.Database>?) ?? const [];
    for (final d in dbs) {
      if (d.isTemplate) continue;
      final dk = 'db:${c.id}$_sep${d.name}';
      out.add(TreeRow(key: dk, depth: depth + 1, kind: NodeKind.database, label: d.name, detail: d.sizeBytes >= 0 ? _size(d.sizeBytes.toInt()) : '', expandable: d.canConnect, connection: c, path: DbPath(c.id, d.name)));
      if (!expanded.contains(dk) || !_status(out, dk, depth + 2)) continue;
      final schemas = (_cache[dk] as List<pb.Schema>?) ?? const [];
      for (final sc in schemas) {
        if (sc.system && !AppSettings.instance.showSystemSchemas) continue;
        final sk = 'sc:${c.id}$_sep${d.name}$_sep${sc.name}';
        out.add(TreeRow(key: sk, depth: depth + 2, kind: NodeKind.schema, label: sc.name, expandable: true, connection: c, path: DbPath(c.id, d.name, sc.name)));
        if (!expanded.contains(sk) || !_status(out, sk, depth + 3)) continue;
        final objs = (_cache[sk] as List<pb.DbObject>?) ?? const [];
        final byFolder = <ObjFolder, List<pb.DbObject>>{};
        for (final o in objs) {
          byFolder.putIfAbsent(folderOf(o.kind), () => []).add(o);
        }
        if (objs.isEmpty) out.add(TreeRow(key: '$sk/empty', depth: depth + 3, kind: NodeKind.info, label: tr('empty schema', 'пустая схема')));
        for (final f in ObjFolder.values) {
          final list = byFolder[f];
          if (list == null) continue;
          final fk = 'k:${c.id}$_sep${d.name}$_sep${sc.name}$_sep${f.name}';
          out.add(TreeRow(key: fk, depth: depth + 3, kind: NodeKind.folder, label: folderLabel(f), detail: '${list.length}', expandable: true, folder: f, path: DbPath(c.id, d.name, sc.name)));
          if (!expanded.contains(fk)) continue;
          for (final o in list) {
            final ok = 'o:${c.id}$_sep${d.name}$_sep${sc.name}$_sep${o.kind.value}$_sep${o.name}$_sep${o.signature}';
            final path = DbPath(c.id, d.name, sc.name, o.name, o.kind, o.signature);
            final hasCols = f == ObjFolder.tables || f == ObjFolder.views || f == ObjFolder.matviews || f == ObjFolder.foreign || f == ObjFolder.types && o.kind == pb.DbObject_Kind.COMPOSITE_TYPE;
            out.add(TreeRow(
              key: ok,
              depth: depth + 4,
              kind: NodeKind.object,
              label: f == ObjFolder.routines ? '${o.name}(${o.signature})' : o.name,
              detail: _objectDetail(o),
              expandable: hasCols,
              object: o,
              connection: c,
              path: path,
            ));
            if (!hasCols || !expanded.contains(ok) || !_status(out, ok, depth + 5)) continue;
            final info = _cache[ok] as pb.ObjectInfo;
            if (!path.table && path.kind != pb.DbObject_Kind.FOREIGN_TABLE) {
              _addColumns(out, info.columns, ok, path, depth + 5);
              continue;
            }
            final ownIndexes = info.indexes.where((ix) => !info.constraints.any((k) => k.name == ix.name)).toList();
            for (final part in ObjPart.values) {
              final n = switch (part) {
                ObjPart.columns => info.columns.length,
                ObjPart.keys => info.constraints.length,
                ObjPart.indexes => ownIndexes.length,
                ObjPart.triggers => info.triggers.length,
              };
              if (n == 0 && part != ObjPart.columns) continue;
              final pk = '$ok${_sep}part$_sep${part.name}';
              out.add(TreeRow(key: pk, depth: depth + 5, kind: NodeKind.part, label: partLabel(part), detail: '$n', expandable: n > 0, part: part, path: path, connection: c));
              if (!expanded.contains(pk)) continue;
              switch (part) {
                case ObjPart.columns:
                  _addColumns(out, info.columns, pk, path, depth + 6);
                case ObjPart.keys:
                  for (final k in info.constraints) {
                    out.add(TreeRow(key: '$pk$_sep${k.name}', depth: depth + 6, kind: NodeKind.key, label: k.name, detail: k.definition, item: k, path: path));
                  }
                case ObjPart.indexes:
                  for (final ix in ownIndexes) {
                    out.add(TreeRow(key: '$pk$_sep${ix.name}', depth: depth + 6, kind: NodeKind.idx, label: ix.name, detail: _indexDetail(ix), item: ix, path: path));
                  }
                case ObjPart.triggers:
                  for (final tg in info.triggers) {
                    out.add(TreeRow(key: '$pk$_sep${tg.name}', depth: depth + 6, kind: NodeKind.trigger, label: tg.name, detail: tg.enabled ? '' : tr('disabled', 'выключен'), item: tg, path: path));
                  }
              }
            }
          }
        }
      }
    }
    _addRoles(out, c, depth + 1);
  }

  void _addColumns(List<TreeRow> out, List<pb.Column> cols, String parent, DbPath path, int depth) {
    for (final col in cols) {
      out.add(TreeRow(key: '$parent${_sep}col$_sep${col.name}', depth: depth, kind: NodeKind.column, label: col.name, detail: col.type + (col.nullable ? '' : ' not null'), column: col, path: path));
    }
  }

  void _addRoles(List<TreeRow> out, pb.Connection c, int depth) {
    final key = rolesKey(c.id);
    final showSystem = AppSettings.instance.showSystemSchemas;
    final loaded = _cache[key] as List<pb.Role>?;
    final shown = loaded?.where((r) => showSystem || !r.system).toList();
    out.add(TreeRow(key: key, depth: depth, kind: NodeKind.roles, label: tr('users and roles', 'пользователи и роли'), detail: shown == null ? '' : '${shown.length}', expandable: true, connection: c, path: DbPath(c.id)));
    if (!expanded.contains(key) || !_status(out, key, depth + 1)) return;
    for (final r in shown!) {
      final flags = [if (r.superuser) 'superuser', if (!r.login) tr('group', 'группа'), if (r.memberOf.isNotEmpty) '∈ ${r.memberOf.join(', ')}'];
      out.add(TreeRow(key: 'ro:${c.id}$_sep${r.name}', depth: depth + 1, kind: NodeKind.role, label: r.name, detail: flags.join('  ·  '), role: r, connection: c, path: DbPath(c.id)));
    }
  }

  String _objectDetail(pb.DbObject o) {
    if (o.comment.isNotEmpty) return o.comment;
    return switch (o.kind) {
      pb.DbObject_Kind.ENUM => o.labels.join(', '),
      pb.DbObject_Kind.DOMAIN || pb.DbObject_Kind.RANGE_TYPE => o.baseType,
      _ => '',
    };
  }

  String _indexDetail(pb.Index ix) {
    final d = ix.definition;
    final i = d.indexOf(' USING ');
    return (ix.unique ? 'unique ' : '') + (i >= 0 ? d.substring(i + 7) : d);
  }

  /// Adds a loading / error row; true when the children are there. An
  /// open node without data (refreshed, or opened before) loads now.
  bool _status(List<TreeRow> out, String key, int depth) {
    if (!_cache.containsKey(key) && !loading.contains(key) && !errors.containsKey(key)) {
      final row = out.lastWhere((r) => r.key == key);
      scheduleMicrotask(() => _ensure(row));
      out.add(TreeRow(key: '$key/loading', depth: depth, kind: NodeKind.info, label: tr('loading…', 'загрузка…')));
      return false;
    }
    if (loading.contains(key) && !_cache.containsKey(key)) {
      out.add(TreeRow(key: '$key/loading', depth: depth, kind: NodeKind.info, label: tr('loading…', 'загрузка…')));
      return false;
    }
    final e = errors[key];
    if (e != null) {
      out.add(TreeRow(key: '$key/error', depth: depth, kind: NodeKind.info, label: e, color: const Color(0xFFEF4444)));
      return false;
    }
    return _cache.containsKey(key);
  }

  @override
  void dispose() {
    _events.cancel();
    _session.cancel();
    super.dispose();
  }
}

String _size(int b) {
  if (b < 1024) return '$b B';
  if (b < 1 << 20) return '${(b / 1024).toStringAsFixed(0)} KB';
  if (b < 1 << 30) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
  return '${(b / (1 << 30)).toStringAsFixed(1)} GB';
}

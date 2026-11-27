import 'package:flutter/foundation.dart';

import '../explorer/explorer_controller.dart';

enum TabKind { table, console, object }

/// One open tab of the workspace.
class WsTab {
  WsTab({required this.id, required this.kind, required this.path, required this.title, this.initialSql = ''});

  final String id;
  final TabKind kind;
  final DbPath path;
  String title;
  final String initialSql;
}

/// The tabs (DataGrip's editor area): data viewers, consoles, object info.
class WorkspaceController extends ChangeNotifier {
  final tabs = <WsTab>[];
  String? activeId;
  int _seq = 0;
  final _consoleCount = <String, int>{};

  WsTab? get active {
    for (final t in tabs) {
      if (t.id == activeId) return t;
    }
    return null;
  }

  void activate(String id) {
    activeId = id;
    notifyListeners();
  }

  /// Opens (or shows the open) data viewer of an object.
  void openTable(DbPath p) => _openUnique(TabKind.table, p, p.name);

  void openObject(DbPath p) => _openUnique(TabKind.object, p, p.kind.name == 'FUNCTION' || p.kind.name == 'PROCEDURE' ? '${p.name}()' : p.name);

  void _openUnique(TabKind kind, DbPath p, String title) {
    for (final t in tabs) {
      if (t.kind == kind && t.path.conn == p.conn && t.path.db == p.db && t.path.schema == p.schema && t.path.name == p.name && t.path.signature == p.signature) {
        activate(t.id);
        return;
      }
    }
    final t = WsTab(id: 't${_seq++}', kind: kind, path: p, title: title);
    tabs.add(t);
    activate(t.id);
  }

  /// A new console on a database.
  void openConsole(DbPath p, {String connName = '', String sql = ''}) {
    final k = '${p.conn}/${p.db}';
    final n = (_consoleCount[k] ?? 0) + 1;
    _consoleCount[k] = n;
    final base = connName.isEmpty ? p.db : '${p.db} @ $connName';
    final t = WsTab(id: 't${_seq++}', kind: TabKind.console, path: DbPath(p.conn, p.db, p.schema), title: n == 1 ? base : '$base [$n]', initialSql: sql);
    tabs.add(t);
    activate(t.id);
  }

  void close(String id) {
    final i = tabs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tabs.removeAt(i);
    if (activeId == id) activeId = tabs.isEmpty ? null : tabs[i.clamp(0, tabs.length - 1)].id;
    notifyListeners();
  }

  /// Closes the tabs on a database (it was dropped or renamed).
  void closeDatabase(String conn, String db) {
    tabs.removeWhere((t) => t.path.conn == conn && t.path.db == db);
    if (active == null) activeId = tabs.isEmpty ? null : tabs.last.id;
    notifyListeners();
  }

  /// Closes the tabs of one object (it was dropped).
  void closeObject(DbPath p) {
    tabs.removeWhere((t) => t.kind != TabKind.console && t.path.conn == p.conn && t.path.db == p.db && t.path.schema == p.schema && t.path.name == p.name);
    if (active == null) activeId = tabs.isEmpty ? null : tabs.last.id;
    notifyListeners();
  }

  /// Closes the tabs of a connection (it was removed).
  void closeConnection(String conn) {
    tabs.removeWhere((t) => t.path.conn == conn);
    if (active == null) activeId = tabs.isEmpty ? null : tabs.last.id;
    notifyListeners();
  }
}

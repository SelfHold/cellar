import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../servers/discover_dialog.dart';
import '../servers/server_dialogs.dart';
import '../settings/settings_dialog.dart';
import '../workspace/workspace_controller.dart';
import 'explorer_controller.dart';

enum _Act { connect, disconnect, discover, newConnection, edit, delete, console, refresh, openData, structure, selectConsole, copyName, newServer }

/// The left panel (DataGrip's Database Explorer): servers in folders, the
/// databases found on them, schemas and their objects.
class ExplorerView extends StatelessWidget {
  const ExplorerView({super.key, required this.ctl, required this.ws});

  final ExplorerController ctl;
  final WorkspaceController ws;

  @override
  Widget build(BuildContext context) => Container(
    color: HmColors.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
          child: Row(children: [
            Expanded(child: Text(tr('DATABASE EXPLORER', 'БАЗЫ ДАННЫХ'), style: HmText.sectionTitle)),
            HmIconButton(icon: Icons.add, label: tr('New server', 'Новый сервер'), onPressed: () => _newServer(context, '')),
            HmIconButton(icon: Icons.cable, label: tr('New direct connection', 'Новое прямое подключение'), onPressed: () => showConnectionForm(context)),
            HmIconButton(icon: Icons.refresh, label: tr('Reload', 'Обновить'), onPressed: ctl.reload),
            HmIconButton(icon: Icons.settings_outlined, label: tr('Settings and Shard', 'Настройки и Shard'), onPressed: () => showSettings(context)),
          ]),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: ctl,
            builder: (context, _) {
              if (!ctl.loaded) return const HmLoading();
              final rows = ctl.rows;
              if (rows.isEmpty) {
                return HmEmptyState(
                  tr('Add a server: Cellar connects over SSH and finds the databases running there.', 'Добавьте сервер: Cellar подключится по SSH и найдёт запущенные на нём базы.'),
                  icon: Icons.dns_outlined,
                  action: HmButton(tr('Add server', 'Добавить сервер'), variant: HmVariant.primary, icon: Icons.add, onPressed: () => _newServer(context, '')),
                );
              }
              return Column(
                children: [
                  if (ctl.error != null) Padding(padding: const EdgeInsets.all(8), child: HmBanner(ctl.error!, tone: HmTone.error)),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemExtent: Hm.of(context).mobile ? 40 : 26,
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _RowView(row: rows[i], ctl: ctl, onTap: () => _tap(context, rows[i]), onOpen: () => _open(context, rows[i]), onMenu: (p) => _menu(context, rows[i], p)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _newServer(BuildContext context, String group) async {
    final s = await showServerForm(context, server: group.isEmpty ? null : pb.Server(group: group, auth: pb.Server_Auth.KEY), all: ctl.servers);
    if (s == null || !context.mounted) return;
    await ctl.reload();
    ctl.expand('s:${s.id}');
    if (context.mounted) await showDiscover(context, s);
  }

  Future<void> _tap(BuildContext context, TreeRow r) async {
    ctl.select(r.key);
    if (r.kind == NodeKind.connection && !ctl.expanded.contains(r.key)) {
      final sid = r.connection!.serverId;
      final srv = ctl.server(sid);
      if (srv != null && !srv.connected && !await ensureConnected(context, sid)) return;
    }
    if (r.kind == NodeKind.info && r.server != null && r.key.endsWith('/empty')) {
      if (context.mounted) await showDiscover(context, r.server!);
      return;
    }
    if (!context.mounted) return;
    if (r.kind == NodeKind.object && !r.expandable) {
      _open(context, r);
      return;
    }
    ctl.toggle(r);
  }

  void _open(BuildContext context, TreeRow r) {
    final p = r.path;
    switch (r.kind) {
      case NodeKind.object:
      case NodeKind.column:
        if (p!.readable && p.kind != pb.DbObject_Kind.SEQUENCE) {
          ws.openTable(p);
        } else {
          ws.openObject(p);
        }
      case NodeKind.database:
      case NodeKind.schema:
        ws.openConsole(p!, connName: r.connection?.name ?? '');
      default:
        _tap(context, r);
    }
  }

  Future<void> _menu(BuildContext context, TreeRow r, Offset pos) async {
    ctl.select(r.key);
    final items = <HmMenuItem<_Act>>[];
    switch (r.kind) {
      case NodeKind.group:
        items.add((value: _Act.newServer, label: tr('New server in this folder…', 'Новый сервер в этой папке…')));
      case NodeKind.server:
        final s = r.server!;
        items.addAll([
          if (!s.connected) (value: _Act.connect, label: tr('Connect', 'Подключиться')) else (value: _Act.disconnect, label: tr('Disconnect', 'Отключиться')),
          (value: _Act.discover, label: tr('Find databases…', 'Найти базы…')),
          (value: _Act.newConnection, label: tr('New connection…', 'Новое подключение…')),
          (value: _Act.edit, label: tr('Edit…', 'Изменить…')),
          (value: _Act.delete, label: tr('Delete', 'Удалить')),
        ]);
      case NodeKind.connection:
        items.addAll([
          (value: _Act.console, label: tr('New console', 'Новая консоль')),
          (value: _Act.refresh, label: tr('Refresh', 'Обновить')),
          (value: _Act.edit, label: tr('Edit…', 'Изменить…')),
          (value: _Act.delete, label: tr('Delete', 'Удалить')),
        ]);
      case NodeKind.database:
      case NodeKind.schema:
      case NodeKind.folder:
        items.addAll([
          (value: _Act.console, label: tr('New console', 'Новая консоль')),
          (value: _Act.refresh, label: tr('Refresh', 'Обновить')),
        ]);
      case NodeKind.object:
        final p = r.path!;
        items.addAll([
          if (p.readable) (value: _Act.openData, label: tr('Open data', 'Открыть данные')),
          (value: _Act.structure, label: tr('Structure and DDL', 'Структура и DDL')),
          if (p.readable) (value: _Act.selectConsole, label: tr('SELECT in a console', 'SELECT в консоли')),
          (value: _Act.copyName, label: tr('Copy the qualified name', 'Копировать полное имя')),
          (value: _Act.refresh, label: tr('Refresh', 'Обновить')),
        ]);
      default:
        return;
    }
    final a = await showContextMenu<_Act>(context, title: r.label, items: items, position: pos);
    if (a == null || !context.mounted) return;
    final api = ctl.api;
    try {
      switch (a) {
        case _Act.newServer:
          await _newServer(context, r.key.substring(2));
        case _Act.connect:
          await ensureConnected(context, r.server!.id);
        case _Act.disconnect:
          await api.disconnectServer(pb.Ref(id: r.server!.id));
        case _Act.discover:
          await showDiscover(context, r.server!);
        case _Act.newConnection:
          await showConnectionForm(context, connection: pb.Connection(serverId: r.server!.id, host: '127.0.0.1', port: 5432, user: 'postgres'));
        case _Act.edit:
          if (r.kind == NodeKind.server) {
            await showServerForm(context, server: r.server, all: ctl.servers);
          } else {
            await showConnectionForm(context, connection: r.connection);
          }
        case _Act.delete:
          final server = r.kind == NodeKind.server;
          final n = server ? ctl.connections.where((c) => c.serverId == r.server!.id).length : 0;
          final ok = await confirm(
            context,
            title: server ? tr('Delete the server?', 'Удалить сервер?') : tr('Delete the connection?', 'Удалить подключение?'),
            message: server
                ? (r.server!.shared
                      ? tr('${r.label} is removed from Shard: Postern and your other devices lose it too. Its $n connections go with it.', '${r.label} удаляется из Shard: Postern и другие устройства тоже его потеряют. Подключения ($n) удалятся вместе с ним.')
                      : tr('${r.label} and its $n connections are removed.', '${r.label} и подключения ($n) будут удалены.'))
                : tr('${r.label} is removed. The database itself is not touched.', '${r.label} будет удалено. Сама база не затрагивается.'),
            action: tr('Delete', 'Удалить'),
            destructive: true,
          );
          if (!ok) return;
          if (server) {
            for (final c in ctl.connections.where((c) => c.serverId == r.server!.id)) {
              ws.closeConnection(c.id);
            }
            await api.deleteServer(pb.Ref(id: r.server!.id));
          } else {
            ws.closeConnection(r.connection!.id);
            await api.deleteConnection(pb.Ref(id: r.connection!.id));
          }
        case _Act.console:
          final p = r.path!;
          ws.openConsole(p.db.isEmpty ? DbPath(p.conn, r.connection!.database.isEmpty ? 'postgres' : r.connection!.database) : p, connName: r.connection?.name ?? '');
        case _Act.refresh:
          ctl.refresh(r);
        case _Act.openData:
          ws.openTable(r.path!);
        case _Act.structure:
          ws.openObject(r.path!);
        case _Act.selectConsole:
          final p = r.path!;
          ws.openConsole(DbPath(p.conn, p.db, p.schema), connName: r.connection?.name ?? '', sql: 'SELECT *\nFROM ${_q(p.schema)}.${_q(p.name)}\nLIMIT 100;');
        case _Act.copyName:
          Clipboard.setData(ClipboardData(text: '${_q(r.path!.schema)}.${_q(r.path!.name)}'));
      }
    } catch (e) {
      Toasts.error(r.label, errorText(e));
    }
  }
}

String _q(String s) => RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(s) ? s : '"${s.replaceAll('"', '""')}"';

class _RowView extends StatefulWidget {
  const _RowView({required this.row, required this.ctl, required this.onTap, required this.onOpen, required this.onMenu});

  final TreeRow row;
  final ExplorerController ctl;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final void Function(Offset) onMenu;

  @override
  State<_RowView> createState() => _RowViewState();
}

class _RowViewState extends State<_RowView> {
  bool _hot = false;

  (IconData, Color) get _icon {
    final r = widget.row;
    return switch (r.kind) {
      NodeKind.group => (widget.ctl.expanded.contains(r.key) ? Icons.folder_open : Icons.folder, HmColors.warning),
      NodeKind.server => (Icons.dns, r.server!.connected ? HmColors.ok : HmColors.muted),
      NodeKind.direct => (Icons.computer, HmColors.muted),
      NodeKind.connection => (Icons.storage_rounded, const Color(0xFF336791)),
      NodeKind.database => (Icons.dataset_outlined, HmColors.accent),
      NodeKind.schema => (Icons.account_tree_outlined, HmColors.purpleLight),
      NodeKind.folder => (Icons.folder_outlined, HmColors.muted),
      NodeKind.object => switch (r.object!.kind) {
        pb.DbObject_Kind.VIEW || pb.DbObject_Kind.MATERIALIZED_VIEW => (Icons.visibility_outlined, HmColors.active),
        pb.DbObject_Kind.SEQUENCE => (Icons.format_list_numbered, HmColors.muted),
        pb.DbObject_Kind.FUNCTION || pb.DbObject_Kind.PROCEDURE => (Icons.functions, HmColors.ok),
        _ => (Icons.table_chart_outlined, HmColors.accent),
      },
      NodeKind.column => (r.column!.primaryKey ? Icons.key : Icons.view_column_outlined, r.column!.primaryKey ? HmColors.warning : HmColors.muted),
      NodeKind.info => (Icons.info_outline, r.color ?? HmColors.muted),
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final sel = widget.ctl.selected == r.key;
    final open = widget.ctl.expanded.contains(r.key);
    final (icon, color) = _icon;
    return MouseRegion(
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onOpen,
        onSecondaryTapDown: (d) => widget.onMenu(d.globalPosition),
        onLongPressStart: (d) => widget.onMenu(d.globalPosition),
        child: Container(
          color: sel ? HmColors.tint(HmColors.accent, 0.12) : (_hot ? HmColors.tint(HmColors.text, 0.04) : null),
          padding: EdgeInsets.only(left: 6.0 + r.depth * 14, right: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: r.expandable
                    ? GestureDetector(onTap: () => widget.ctl.toggle(r), child: Icon(open ? Icons.expand_more : Icons.chevron_right, size: 15, color: HmColors.muted))
                    : null,
              ),
              const SizedBox(width: 2),
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  r.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: r.kind == NodeKind.info ? HmText.jb(11, color: r.color ?? HmColors.muted).copyWith(fontStyle: FontStyle.italic) : HmText.jb(12, weight: r.kind == NodeKind.server || r.kind == NodeKind.group ? 600 : 400),
                ),
              ),
              if (r.kind == NodeKind.server && r.server!.shared) ...[const SizedBox(width: 4), const Tooltip(message: 'Shard', child: Icon(Icons.cloud_outlined, size: 12, color: HmColors.muted))],
              if (r.detail.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(child: Text(r.detail, overflow: TextOverflow.ellipsis, maxLines: 1, style: HmText.jb(11, color: HmColors.muted))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

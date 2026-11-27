import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../common/hm.dart';
import '../explorer/explorer_controller.dart';
import 'console_tab.dart';
import 'object_tab.dart';
import 'table_tab.dart';
import 'workspace_controller.dart';

/// The tab strip and the open tabs; every tab stays alive while open (a
/// console keeps its session and text).
class WorkspaceView extends StatelessWidget {
  const WorkspaceView({super.key, required this.ws, required this.explorer});

  final WorkspaceController ws;
  final ExplorerController explorer;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ws,
    builder: (context, _) {
      if (ws.tabs.isEmpty) {
        return Center(
          child: HmEmptyState(
            tr('Open a table from the tree (double click), or a console: right click on a database → New console.', 'Откройте таблицу в дереве (двойной клик) или консоль: правый клик по базе → «Новая консоль».'),
            icon: Icons.table_view_outlined,
          ),
        );
      }
      final idx = ws.tabs.indexWhere((t) => t.id == ws.activeId).clamp(0, ws.tabs.length - 1);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            decoration: const BoxDecoration(color: HmColors.surface, border: Border(bottom: BorderSide(color: HmColors.border))),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [for (final t in ws.tabs) _TabChip(tab: t, active: t.id == ws.activeId, ws: ws, explorer: explorer)],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: idx,
              children: [for (final t in ws.tabs) KeyedSubtree(key: ValueKey(t.id), child: tabBody(t, ws, explorer))],
            ),
          ),
        ],
      );
    },
  );
}

/// The content of a tab (also shown as a page on phones).
Widget tabBody(WsTab t, WorkspaceController ws, ExplorerController explorer) => switch (t.kind) {
  TabKind.table => TableTab(
    path: t.path,
    onOpenConsole: (sql) => ws.openConsole(DbPath(t.path.conn, t.path.db, t.path.schema), connName: explorer.connection(t.path.conn)?.name ?? '', sql: '$sql;'),
  ),
  TabKind.console => ConsoleTab(path: t.path, initialSql: t.initialSql),
  TabKind.object => ObjectTab(path: t.path),
};

class _TabChip extends StatefulWidget {
  const _TabChip({required this.tab, required this.active, required this.ws, required this.explorer});

  final WsTab tab;
  final bool active;
  final WorkspaceController ws;
  final ExplorerController explorer;

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tab;
    final icon = switch (t.kind) {
      TabKind.table => Icons.table_chart_outlined,
      TabKind.console => Icons.terminal,
      TabKind.object => Icons.schema_outlined,
    };
    final conn = widget.explorer.connection(t.path.conn);
    final tip = [conn?.name ?? '', t.path.db, if (t.path.schema.isNotEmpty) t.path.schema].where((s) => s.isNotEmpty).join(' / ');
    return Listener(
      // Middle click closes, like in browsers and IDEs.
      onPointerDown: (e) {
        if (e.buttons == kMiddleMouseButton) widget.ws.close(t.id);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.ws.activate(t.id),
          child: Tooltip(
            message: tip,
            child: Container(
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: widget.active ? HmColors.bg : (_hot ? HmColors.tint(HmColors.text, 0.03) : null),
                border: Border(
                  right: const BorderSide(color: HmColors.border),
                  top: BorderSide(color: widget.active ? HmColors.accent : Colors.transparent, width: 2),
                ),
              ),
              child: Row(children: [
                Icon(icon, size: 14, color: widget.active ? HmColors.accent : HmColors.muted),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(t.title, overflow: TextOverflow.ellipsis, style: HmText.jb(12, weight: widget.active ? 600 : 400, color: widget.active ? HmColors.text : HmColors.muted)),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 22,
                  child: _hot || widget.active ? HmIconButton(icon: Icons.close, dense: true, label: tr('Close', 'Закрыть'), onPressed: () => widget.ws.close(t.id)) : null,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/desktop/desktop_window.dart';

import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import '../explorer/explorer_controller.dart';
import '../explorer/explorer_view.dart';
import '../settings/settings_dialog.dart';
import '../workspace/workspace_controller.dart';
import '../workspace/workspace_view.dart';

/// Explorer on the left, tabs on the right, a status bar below (desktops);
/// on phones the explorer is the page and every tab opens as its own page.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final _explorer = ExplorerController(context.read<CoreCubit>());
  final _ws = WorkspaceController();
  late double _width = AppSettings.instance.explorerWidth;
  int _pushed = 0;

  @override
  void initState() {
    super.initState();
    _ws.addListener(_phoneTabs);
  }

  @override
  void dispose() {
    _ws.removeListener(_phoneTabs);
    _explorer.dispose();
    _ws.dispose();
    super.dispose();
  }

  /// Phones: a newly opened tab becomes a page; going back closes it.
  void _phoneTabs() {
    if (!Hm.of(context).mobile) return;
    if (_ws.tabs.length <= _pushed) {
      _pushed = _ws.tabs.length;
      return;
    }
    final t = _ws.tabs.last;
    _pushed = _ws.tabs.length;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(
              backgroundColor: HmColors.surface,
              elevation: 0,
              title: Text(t.title, style: HmText.modalTitle),
            ),
            body: tabBody(t, _ws, _explorer),
          ),
        ))
        .then((_) {
          _ws.close(t.id);
          _pushed = _ws.tabs.length;
        });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Hm.of(context).mobile;
    final explorer = ExplorerView(ctl: _explorer, ws: _ws);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (DesktopWindow.supported) _Header(mobile: mobile),
            Expanded(
              child: mobile
                  ? explorer
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: _width, child: explorer),
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (d) => setState(() => _width = (_width + d.delta.dx).clamp(200.0, 700.0)),
                            onHorizontalDragEnd: (_) => AppSettings.instance.explorerWidth = _width,
                            child: Container(width: 5, color: HmColors.bg, child: Center(child: Container(width: 1, color: HmColors.border))),
                          ),
                        ),
                        Expanded(child: WorkspaceView(ws: _ws, explorer: _explorer)),
                      ],
                    ),
            ),
            const _StatusBar(),
          ],
        ),
      ),
    );
  }
}

final _headerGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [HmColors.tint(HmColors.accent, 0.04), HmColors.tint(HmColors.accent, 0)]);

/// Desktop header, which doubles as the window title bar: drag to move,
/// double-click to maximize.
class _Header extends StatelessWidget {
  const _Header({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context) => DragToMoveArea(
    child: Container(
      height: mobile ? 56 : null,
      padding: mobile ? const EdgeInsets.only(left: 16, right: 8) : const EdgeInsets.fromLTRB(32, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: _headerGradient,
        border: const Border(bottom: BorderSide(color: HmColors.border)),
      ),
      child: Row(
        children: [
          // Takes the free space and gives way first in a narrow window.
          Expanded(
            child: Text('Cellar', style: mobile ? HmText.logo.copyWith(fontSize: 18) : HmText.logo, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const _WindowButtons(),
        ],
      ),
    ),
  );
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _WindowButton(icon: Icons.remove, tooltip: tr('Minimize', 'Свернуть'), onTap: DesktopWindow.instance.minimize),
      _WindowButton(icon: Icons.crop_square, tooltip: tr('Maximize', 'Развернуть'), onTap: DesktopWindow.instance.toggleMaximize),
      _WindowButton(icon: Icons.close, tooltip: tr('Close', 'Закрыть'), danger: true, onTap: DesktopWindow.instance.close),
    ],
  );
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({required this.icon, required this.tooltip, required this.onTap, this.danger = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.danger ? HmColors.error : HmColors.accent;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 28,
            margin: const EdgeInsets.only(left: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HmColors.tint(base, _hot ? 0.10 : 0.0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 16, color: _hot ? base : HmColors.muted),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) => BlocBuilder<CoreCubit, CoreState>(
    builder: (context, s) {
      final sync = s.sync;
      final (syncText, syncColor) = switch (sync.phase) {
        pb.SyncState_Phase.SYNCED => (tr('Shard: synced', 'Shard: синхронизировано'), HmColors.ok),
        pb.SyncState_Phase.PAIRING => (tr('Shard: confirm ${sync.pairingCode}', 'Shard: подтвердите ${sync.pairingCode}'), HmColors.warning),
        pb.SyncState_Phase.OFFLINE => (tr('Shard: offline', 'Shard: нет хранилища'), HmColors.warning),
        pb.SyncState_Phase.LOCKED => (tr('Shard: locked', 'Shard: заблокирован'), HmColors.warning),
        pb.SyncState_Phase.NOT_RUNNING => (tr('Shard: not running', 'Shard: не запущен'), HmColors.muted),
        pb.SyncState_Phase.ERROR => (tr('Shard: error', 'Shard: ошибка'), HmColors.error),
        _ => (tr('Standalone', 'Автономно'), HmColors.muted),
      };
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(color: HmColors.surface, border: Border(top: BorderSide(color: HmColors.border))),
        child: Row(children: [
          Icon(Icons.circle, size: 8, color: s.conn == Conn.ready ? HmColors.ok : (s.conn == Conn.failed ? HmColors.error : HmColors.warning)),
          const SizedBox(width: 6),
          Text(s.conn == Conn.ready ? tr('Core', 'Ядро') : (s.error ?? tr('Starting…', 'Запуск…')), style: HmText.footer),
          if (s.conn == Conn.failed) ...[const SizedBox(width: 8), HmButton(tr('Retry', 'Повторить'), small: true, variant: HmVariant.neutral, onPressed: context.read<CoreCubit>().connect)],
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => showSettings(context),
              child: Row(children: [
                Icon(Icons.cloud_outlined, size: 12, color: syncColor),
                const SizedBox(width: 6),
                Text(syncText, style: HmText.footer.copyWith(color: syncColor)),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          Text('Cellar ${s.state?.coreVersion ?? ''}', style: HmText.footer),
        ]),
      );
    },
  );
}

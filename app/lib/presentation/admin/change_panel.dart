import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import '../workspace/sql_highlight.dart';

/// Opens [sql] in a new console (the dialogs' "Open in console").
typedef OpenConsole = void Function(String sql);

/// The lower half of every create / modify / drop dialog (DataGrip's
/// "Modify" dialogs): the SQL the change will run, worked out by the core
/// as the form changes, its warnings, and the buttons. Executing pops the
/// dialog with true.
class ChangePanel extends StatefulWidget {
  const ChangePanel({super.key, required this.change, this.action, this.destructive = false, this.openConsole, this.hasSecret = false});

  /// The change as the form is now (rebuilt by the form on every edit).
  final pb.Change change;
  final String? action;
  final bool destructive;
  final OpenConsole? openConsole;

  /// The change carries a password: the preview masks it, so it cannot be
  /// opened in a console.
  final bool hasSecret;

  @override
  State<ChangePanel> createState() => _ChangePanelState();
}

class _ChangePanelState extends State<ChangePanel> {
  pb.ChangePlan? _plan;
  String? _planError;
  String? _runError;
  bool _running = false;
  bool _planning = false;
  Timer? _debounce;
  String _planned = '';

  pb.CellarClient get _api => context.read<CoreCubit>().api;

  @override
  void initState() {
    super.initState();
    _schedule(immediate: true);
  }

  @override
  void didUpdateWidget(ChangePanel old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule({bool immediate = false}) {
    final key = widget.change.writeToBuffer().toString();
    if (key == _planned) return;
    _planned = key;
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: immediate ? 0 : 350), _replan);
  }

  Future<void> _replan() async {
    final asked = _planned;
    setState(() => _planning = true);
    try {
      final p = await _api.planChange(widget.change);
      if (!mounted || asked != _planned) return;
      setState(() {
        _plan = p;
        _planError = null;
        _planning = false;
      });
    } catch (e) {
      if (!mounted || asked != _planned) return;
      setState(() {
        _plan = null;
        _planError = errorText(e);
        _planning = false;
      });
    }
  }

  String get _sql => (_plan?.statements ?? const <String>[]).join('\n');

  Future<void> _run() async {
    if (widget.destructive) HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _runError = null;
    });
    try {
      final r = await _api.applyChange(widget.change);
      Toasts.success(tr('Done', 'Готово'), r.statements.length == 1 ? r.statements.first.split('\n').first : tr('${r.statements.length} statements', 'Выражений: ${r.statements.length}'));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _runError = errorText(e));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final empty = _plan != null && _plan!.statements.isEmpty;
    final ready = _plan != null && !empty && !_planning;
    final buttons = <Widget>[
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, expand: hm.mobile, onPressed: () => Navigator.pop(context, false)),
      if (widget.openConsole != null && !widget.hasSecret && !hm.mobile)
        HmButton(tr('Open in console', 'Открыть в консоли'), variant: HmVariant.neutral, icon: Icons.terminal, onPressed: ready ? () {
          Navigator.pop(context, false);
          widget.openConsole!(_sql);
        } : null),
      HmButton(
        widget.action ?? tr('Execute', 'Выполнить'),
        variant: widget.destructive ? HmVariant.red : HmVariant.primary,
        expand: hm.mobile,
        loading: _running,
        onPressed: ready && !_running ? _run : null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: Text(tr('SQL PREVIEW', 'SQL'), style: HmText.label)),
          if (_planning) const SizedBox(width: 12, height: 12, child: HmSpinner()),
          if (ready)
            HmIconButton(
              icon: Icons.copy,
              dense: true,
              label: tr('Copy SQL', 'Копировать SQL'),
              onPressed: widget.hasSecret
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: _sql));
                      Toasts.success(tr('Copied', 'Скопировано'));
                    },
            ),
        ]),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 220),
          decoration: BoxDecoration(color: HmColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: HmColors.border)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: _planError != null
                ? Text(_planError!, style: HmText.jb(12, color: HmColors.error))
                : empty
                ? Text(tr('Nothing to change yet.', 'Пока нечего менять.'), style: HmText.jb(12, color: HmColors.muted).copyWith(fontStyle: FontStyle.italic))
                : SelectableText.rich(TextSpan(style: HmText.jb(12, height: 1.5), children: highlightSql(_sql))),
          ),
        ),
        for (final w in _plan?.warnings ?? const <String>[]) ...[const SizedBox(height: 8), HmBanner(w, tone: HmTone.warning)],
        if (_runError != null) ...[const SizedBox(height: 8), HmBanner(_runError!, tone: HmTone.error)],
        const SizedBox(height: 18),
        if (hm.mobile)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [buttons.last, const SizedBox(height: 8), buttons.first])
        else
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            for (final (i, b) in buttons.indexed) ...[if (i > 0) const SizedBox(width: 8), b],
          ]),
      ],
    );
  }
}

/// A form row: side by side on desktops, stacked on phones.
Widget formRow(BuildContext context, List<Widget> ws, {List<int>? flex}) {
  if (Hm.of(context).mobile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final w in ws) Padding(padding: const EdgeInsets.only(bottom: 12), child: w)]);
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(flex: flex?[i] ?? 1, child: ws[i])],
    ]),
  );
}

/// Owner choices: the roles of the server ("" = the default).
Map<String, String> ownerOptions(List<pb.Role> roles, String current, {String none = ''}) => {
  '': none.isEmpty ? tr('— default —', '— по умолчанию —') : none,
  for (final r in roles.where((r) => !r.system)) r.name: r.name,
  if (current.isNotEmpty) current: current,
};

/// Confirms dropping an object, with CASCADE and the SQL.
Future<bool> showDropDialog(BuildContext context, {required String title, required String message, required pb.Change Function(bool cascade) change, String cascadeLabel = ''}) async {
  var cascade = false;
  final ok = await showHmModal<bool>(
    context,
    title: title,
    size: HmModalSize.md,
    body: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: HmText.body.copyWith(height: 1.5)),
          const SizedBox(height: 14),
          HmCheckRow(label: cascadeLabel.isNotEmpty ? cascadeLabel : tr('Also drop what depends on it (CASCADE)', 'Удалить и зависящие объекты (CASCADE)'), value: cascade, onChanged: (v) => set(() => cascade = v)),
          const SizedBox(height: 14),
          ChangePanel(change: change(cascade), destructive: true, action: tr('Drop', 'Удалить')),
        ],
      ),
    ),
  );
  return ok ?? false;
}

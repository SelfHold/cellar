import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import '../explorer/explorer_controller.dart';
import '../grid/result_grid.dart';
import 'sql_highlight.dart';

/// A query console (DataGrip's console): one pinned session, Ctrl+Enter
/// runs the statement at the cursor (or the selection), Ctrl+Shift+Enter
/// runs everything; results below, one tab each, and an output log.
class ConsoleTab extends StatefulWidget {
  const ConsoleTab({super.key, required this.path, this.initialSql = ''});

  final DbPath path;
  final String initialSql;

  @override
  State<ConsoleTab> createState() => _ConsoleTabState();
}

class _LogLine {
  _LogLine(this.time, this.text, {this.error = false, this.muted = false});

  final DateTime time;
  final String text;
  final bool error;
  final bool muted;
}

class _ConsoleTabState extends State<ConsoleTab> {
  late final SqlController _sql = SqlController(text: widget.initialSql);
  final _editorFocus = FocusNode();
  final _editorScroll = ScrollController();
  final _logScroll = ScrollController();
  pb.CellarClient? _api;
  String? _consoleId;
  pb.Console? _info;
  String? _openError;
  bool _running = false;
  String _tx = 'idle';
  List<pb.ResultSet> _results = [];
  final _log = <_LogLine>[];
  int _resultTab = 0; // 0 = output, 1.. = results with rows
  double _split = 0.45;

  @override
  void initState() {
    super.initState();
    _api = context.read<CoreCubit>().api;
    _open();
    if (widget.initialSql.isNotEmpty) _sql.selection = TextSelection.collapsed(offset: widget.initialSql.length);
    // The error underline goes once the text is edited.
    var last = _sql.text;
    _sql.addListener(() {
      if (_sql.text != last) {
        last = _sql.text;
        _sql.errorAt = -1;
      }
    });
  }

  @override
  void dispose() {
    final id = _consoleId;
    if (id != null) _api?.closeConsole(pb.ConsoleRef(id: id)).ignore();
    _sql.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _openError = null);
    try {
      final c = await _api!.openConsole(pb.DbRef(connectionId: widget.path.conn, database: widget.path.db));
      if (!mounted) {
        _api!.closeConsole(pb.ConsoleRef(id: c.id)).ignore();
        return;
      }
      setState(() {
        _consoleId = c.id;
        _info = c;
      });
      _addLog(tr('Connected: PostgreSQL ${c.serverVersion}, session ${c.backendPid}', 'Подключено: PostgreSQL ${c.serverVersion}, сеанс ${c.backendPid}'), muted: true);
      if (widget.path.schema.isNotEmpty && widget.path.schema != 'public') {
        await _api!.execute(pb.ExecuteRequest(consoleId: c.id, sql: 'SET search_path TO "${widget.path.schema.replaceAll('"', '""')}", public', all: true));
      }
      _editorFocus.requestFocus();
    } catch (e) {
      if (mounted) setState(() => _openError = errorText(e));
    }
  }

  void _addLog(String text, {bool error = false, bool muted = false}) {
    setState(() => _log.add(_LogLine(DateTime.now(), text, error: error, muted: muted)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
    });
  }

  Future<void> _run({bool all = false, String? sql}) async {
    final id = _consoleId;
    if (id == null || _running) return;
    var text = sql ?? _sql.text;
    var cursor = _sql.selection.baseOffset.clamp(0, text.length);
    var offset = 0;
    final sel = _sql.selection;
    if (sql == null && sel.isValid && !sel.isCollapsed) {
      offset = sel.start;
      text = sel.textInside(_sql.text);
      all = true;
      cursor = 0;
    }
    if (text.trim().isEmpty) return;
    setState(() => _running = true);
    try {
      final r = await _api!.execute(pb.ExecuteRequest(consoleId: id, sql: text, all: all, cursor: cursor, maxRows: AppSettings.instance.maxRows));
      if (!mounted) return;
      var firstRows = -1;
      for (final rs in r.results) {
        final first = rs.statement.split('\n').first;
        final stmt = first.length > 100 ? '${first.substring(0, 100)}…' : first;
        _addLog('> $stmt', muted: true);
        for (final n in rs.notices) {
          _addLog(n, muted: true);
        }
        if (rs.error.isNotEmpty) {
          _addLog(rs.error + (rs.errorDetail.isEmpty ? '' : '\n${rs.errorDetail}'), error: true);
          if (rs.errorOffset >= 0) {
            final at = offset + rs.errorOffset;
            _sql.errorAt = at;
            _sql.selection = TextSelection.collapsed(offset: at.clamp(0, _sql.text.length));
          }
        } else if (rs.columns.isNotEmpty) {
          _addLog(tr('${rs.rows.length}${rs.truncated ? '+' : ''} rows in ${rs.durationMs} ms', 'строк: ${rs.rows.length}${rs.truncated ? '+' : ''} за ${rs.durationMs} мс') +
              (rs.truncated ? tr(' (only the first ${rs.rows.length} are kept)', ' (показаны первые ${rs.rows.length})') : ''));
        } else {
          _addLog('${rs.commandTag.isEmpty ? 'OK' : rs.commandTag} · ${rs.durationMs} ms');
        }
      }
      final withRows = r.results.where((x) => x.columns.isNotEmpty && x.error.isEmpty).toList();
      if (withRows.isNotEmpty) firstRows = 1;
      setState(() {
        _tx = r.txStatus;
        if (withRows.isNotEmpty) {
          _results = withRows;
          _resultTab = firstRows;
        } else if (r.results.any((x) => x.error.isNotEmpty)) {
          _resultTab = 0;
        }
      });
    } catch (e) {
      _addLog(errorText(e), error: true);
      setState(() => _resultTab = 0);
    } finally {
      if (mounted) setState(() => _running = false);
      _editorFocus.requestFocus();
    }
  }

  Future<void> _cancel() async {
    final id = _consoleId;
    if (id == null) return;
    try {
      await _api!.cancel(pb.ConsoleRef(id: id));
    } catch (e) {
      Toasts.error(tr('Could not cancel', 'Не удалось отменить'), errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_openError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            HmBanner(_openError!, tone: HmTone.error),
            const SizedBox(height: 16),
            HmButton(tr('Try again', 'Повторить'), onPressed: _open),
          ]),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final top = (box.maxHeight * _split).clamp(80.0, box.maxHeight - 80);
            return Column(
              children: [
                SizedBox(height: top, child: _editor()),
                MouseRegion(
                  cursor: SystemMouseCursors.resizeRow,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) => setState(() => _split = ((top + d.delta.dy) / box.maxHeight).clamp(0.1, 0.9)),
                    child: Container(height: 6, color: HmColors.surface, child: Center(child: Container(height: 1, color: HmColors.border))),
                  ),
                ),
                Expanded(child: _resultsPanel()),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _toolbar() => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
    child: Row(
      children: [
        HmIconButton(icon: Icons.play_arrow, color: HmColors.ok, label: tr('Run the statement at the cursor (Ctrl+Enter)', 'Выполнить оператор под курсором (Ctrl+Enter)'), onPressed: _consoleId == null || _running ? null : () => _run()),
        HmIconButton(icon: Icons.fast_forward, label: tr('Run everything (Ctrl+Shift+Enter)', 'Выполнить всё (Ctrl+Shift+Enter)'), onPressed: _consoleId == null || _running ? null : () => _run(all: true)),
        HmIconButton(icon: Icons.stop, color: HmColors.error, label: tr('Cancel the running statement', 'Прервать выполнение'), onPressed: _running ? _cancel : null),
        const SizedBox(width: 8),
        if (_running) const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        if (_tx != 'idle') ...[
          const SizedBox(width: 8),
          HmBadge(_tx == 'failed' ? tr('transaction failed', 'транзакция с ошибкой') : tr('in transaction', 'в транзакции'), tone: _tx == 'failed' ? HmTone.error : HmTone.warning),
          const SizedBox(width: 6),
          HmButton('Commit', small: true, variant: HmVariant.green, onPressed: _running || _tx == 'failed' ? null : () => _run(all: true, sql: 'COMMIT')),
          const SizedBox(width: 6),
          HmButton('Rollback', small: true, variant: HmVariant.red, onPressed: _running ? null : () => _run(all: true, sql: 'ROLLBACK')),
        ],
        const Spacer(),
        if (_info != null) Text('${widget.path.db} · PostgreSQL ${_info!.serverVersion} · pid ${_info!.backendPid}', style: HmText.jb(11, color: HmColors.muted)),
      ],
    ),
  );

  Widget _editor() => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _run(),
      const SingleActivator(LogicalKeyboardKey.enter, control: true, shift: true): () => _run(all: true),
      const SingleActivator(LogicalKeyboardKey.enter, meta: true): () => _run(),
      const SingleActivator(LogicalKeyboardKey.tab): _indent,
    },
    child: Container(
      color: HmColors.bg,
      child: TextField(
        controller: _sql,
        focusNode: _editorFocus,
        scrollController: _editorScroll,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        autocorrect: false,
        enableSuggestions: false,
        smartQuotesType: SmartQuotesType.disabled,
        smartDashesType: SmartDashesType.disabled,
        textAlignVertical: TextAlignVertical.top,
        style: HmText.jb(13, height: 1.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          hintText: tr('SELECT … — Ctrl+Enter runs the statement at the cursor', 'SELECT … — Ctrl+Enter выполняет оператор под курсором'),
          hintStyle: HmText.jb(13, color: HmColors.muted),
        ),
      ),
    ),
  );

  void _indent() {
    final s = _sql.selection;
    if (!s.isValid) return;
    final t = _sql.text;
    _sql.value = TextEditingValue(text: t.replaceRange(s.start, s.end, '  '), selection: TextSelection.collapsed(offset: s.start + 2));
  }

  Widget _resultsPanel() {
    final tabs = <String>[tr('Output', 'Вывод'), for (var i = 0; i < _results.length; i++) _results.length == 1 ? tr('Result', 'Результат') : '${tr('Result', 'Результат')} ${i + 1}'];
    final idx = _resultTab.clamp(0, tabs.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 32,
          decoration: const BoxDecoration(color: HmColors.surface, border: Border(bottom: BorderSide(color: HmColors.border))),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _SubTab(label: tabs[i], active: i == idx, onTap: () => setState(() => _resultTab = i), detail: i == 0 ? null : '${_results[i - 1].rows.length}${_results[i - 1].truncated ? '+' : ''}'),
            ],
          ),
        ),
        Expanded(child: idx == 0 ? _output() : _resultView(_results[idx - 1])),
      ],
    );
  }

  Widget _output() => SelectionArea(
    child: ListView.builder(
      controller: _logScroll,
      padding: const EdgeInsets.all(10),
      itemCount: _log.length,
      itemBuilder: (_, i) {
        final l = _log[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat.Hms().format(l.time), style: HmText.jb(11, color: HmColors.muted)),
              const SizedBox(width: 10),
              Expanded(child: Text(l.text, style: HmText.jb(12, color: l.error ? HmColors.error : (l.muted ? HmColors.muted : HmColors.text), height: 1.45))),
            ],
          ),
        );
      },
    ),
  );

  Widget _resultView(pb.ResultSet rs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ResultGrid(
          key: ObjectKey(rs),
          columns: [for (final c in rs.columns) GridColumn(c.name, c.type, oid: c.typeOid)],
          rowCount: rs.rows.length,
          cell: (r, c) => rs.rows[r].cells[c],
        ),
      ),
      Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: HmColors.border))),
        child: Text(
          '${rs.rows.length}${rs.truncated ? '+' : ''} ${tr('rows', 'строк')} · ${rs.durationMs} ms · ${rs.commandTag}',
          style: HmText.jb(11, color: HmColors.muted),
        ),
      ),
    ],
  );
}

class _SubTab extends StatelessWidget {
  const _SubTab({required this.label, required this.active, required this.onTap, this.detail});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? detail;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? HmColors.accent : Colors.transparent, width: 2))),
        child: Text.rich(
          TextSpan(text: label, children: [if (detail != null) TextSpan(text: '  $detail', style: HmText.jb(10, color: HmColors.muted))]),
          style: HmText.jb(12, weight: active ? 700 : 400, color: active ? HmColors.text : HmColors.muted),
        ),
      ),
    ),
  );
}

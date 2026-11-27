import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fixnum/fixnum.dart';

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

/// The data viewer / editor of a table or view (DataGrip's table editor):
/// pages, sort by header, a WHERE filter, edits kept until Submit.
class TableTab extends StatefulWidget {
  const TableTab({super.key, required this.path, this.onOpenConsole});

  final DbPath path;
  final void Function(String sql)? onOpenConsole;

  @override
  State<TableTab> createState() => _TableTabState();
}

class _TableTabState extends State<TableTab> {
  pb.ResultSet? _rs;
  String? _error;
  bool _loading = false;
  int _offset = 0;
  final _sort = <pb.Sort>[];
  final _filter = TextEditingController();
  String _appliedFilter = '';
  List<pb.Column> _cols = [];

  // Edits not submitted: row index -> column index -> value; new rows; deleted rows.
  final _edits = <int, Map<int, pb.Cell>>{};
  final _inserted = <List<pb.Cell?>>[]; // null = DEFAULT
  final _deleted = <int>{};
  bool _saving = false;

  pb.CellarClient get _api => context.read<CoreCubit>().api;
  int get _limit => AppSettings.instance.pageSize;
  int get _skip => _rs?.hasCtid == true ? 1 : 0; // hidden ctid column
  bool get _editable => widget.path.editable && (_rs?.keyColumns.isNotEmpty ?? false);
  bool get _dirty => _edits.isNotEmpty || _inserted.isNotEmpty || _deleted.isNotEmpty;
  int get _base => _rs?.rows.length ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
    _describe();
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _describe() async {
    try {
      final info = await _api.describeObject(widget.path.ref);
      if (mounted) setState(() => _cols = info.columns);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rs = await _api.readTable(pb.ReadTableRequest(
        connectionId: widget.path.conn,
        database: widget.path.db,
        schema: widget.path.schema,
        table: widget.path.name,
        offset: Int64(_offset),
        limit: _limit,
        sort: _sort,
        filter: _appliedFilter,
      ));
      if (!mounted) return;
      setState(() {
        _rs = rs;
        _edits.clear();
        _inserted.clear();
        _deleted.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return confirm(context,
        title: tr('Discard changes?', 'Отменить изменения?'),
        message: tr('The changes that were not submitted will be lost.', 'Неотправленные изменения будут потеряны.'),
        action: tr('Discard', 'Отменить'),
        destructive: true);
  }

  Future<void> _reload({int? offset}) async {
    if (!await _confirmDiscard()) return;
    if (offset != null) _offset = offset;
    await _load();
  }

  void _sortBy(int col) async {
    final name = _rs!.columns[col + _skip].name;
    final i = _sort.indexWhere((s) => s.column == name);
    final multi = HardwareKeyboard.instance.isShiftPressed;
    setState(() {
      if (i < 0) {
        if (!multi) _sort.clear();
        _sort.add(pb.Sort(column: name));
      } else if (!_sort[i].desc) {
        _sort[i] = pb.Sort(column: name, desc: true);
      } else {
        _sort.removeAt(i);
      }
    });
    await _reload(offset: 0);
  }

  // --- cells -----------------------------------------------------------------

  pb.Cell _cell(int r, int c) {
    if (r >= _base) {
      final v = _inserted[r - _base][c];
      return v ?? pb.Cell(text: 'DEFAULT', null_2: false);
    }
    return _edits[r]?[c] ?? _rs!.rows[r].cells[c + _skip];
  }

  bool _changed(int r, int c) => r < _base ? _inserted[r - _base][c] != null : _edits[r]?.containsKey(c) == true;

  RowMark _mark(int r) => r >= _base ? RowMark.inserted : (_deleted.contains(r) ? RowMark.deleted : RowMark.normal);

  void _edit(int r, int c, pb.Cell v) {
    setState(() {
      if (r >= _base) {
        _inserted[r - _base][c] = v;
        return;
      }
      final orig = _rs!.rows[r].cells[c + _skip];
      final m = _edits.putIfAbsent(r, () => {});
      if (orig.null_2 == v.null_2 && orig.text == v.text) {
        m.remove(c);
        if (m.isEmpty) _edits.remove(r);
      } else {
        m[c] = v;
      }
    });
  }

  void _action(CellAction a, int r, int c) {
    switch (a) {
      case CellAction.deleteRow:
        setState(() {
          if (r >= _base) {
            _inserted.removeAt(r - _base);
          } else {
            _deleted.add(r);
          }
        });
      case CellAction.revertRow:
        setState(() {
          _deleted.remove(r);
          _edits.remove(r);
        });
      case CellAction.filterBy:
        final col = _rs!.columns[c + _skip].name;
        final v = _cell(r, c);
        final ident = RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(col) ? col : '"${col.replaceAll('"', '""')}"';
        _filter.text = v.null_2 ? '$ident IS NULL' : "$ident = '${v.text.replaceAll("'", "''")}'";
        _applyFilter();
      default:
    }
  }

  void _addRow() {
    final n = _rs!.columns.length - _skip;
    setState(() => _inserted.add(List<pb.Cell?>.filled(n, null)));
  }

  void _applyFilter() {
    _appliedFilter = _filter.text.trim();
    _reload(offset: 0);
  }

  Future<void> _submit() async {
    final rs = _rs!;
    final edits = <pb.RowEdit>[];
    pb.EditValue keyOf(int r, String k) {
      final i = rs.columns.indexWhere((c) => c.name == k);
      return pb.EditValue(column: k, value: rs.rows[r].cells[i]);
    }

    List<pb.EditValue> keys(int r) => [for (final k in rs.keyColumns) keyOf(r, k)];
    for (final r in _deleted) {
      edits.add(pb.RowEdit(op: pb.RowEdit_Op.DELETE, key: keys(r)));
    }
    _edits.forEach((r, m) {
      if (_deleted.contains(r)) return;
      edits.add(pb.RowEdit(op: pb.RowEdit_Op.UPDATE, key: keys(r), values: [
        for (final e in m.entries) pb.EditValue(column: rs.columns[e.key + _skip].tableColumn, value: e.value),
      ]));
    });
    for (final row in _inserted) {
      edits.add(pb.RowEdit(op: pb.RowEdit_Op.INSERT, values: [
        for (var c = 0; c < row.length; c++)
          if (row[c] != null) pb.EditValue(column: rs.columns[c + _skip].tableColumn, value: row[c]),
      ]));
    }
    setState(() => _saving = true);
    try {
      final r = await _api.applyEdits(pb.EditRequest(connectionId: widget.path.conn, database: widget.path.db, schema: widget.path.schema, table: widget.path.name, edits: edits));
      Toasts.success(tr('${r.rowsAffected} rows saved', 'Сохранено строк: ${r.rowsAffected}'));
      _edits.clear();
      _inserted.clear();
      _deleted.clear();
      await _load();
    } catch (e) {
      Toasts.error(tr('Not saved', 'Не сохранено'), errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _revert() => setState(() {
    _edits.clear();
    _inserted.clear();
    _deleted.clear();
  });

  // --- view ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final rs = _rs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(),
        _filterBar(),
        if (_loading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: HmBanner(_error!, tone: HmTone.error)),
        if (rs != null && rs.keyColumns.isEmpty && widget.path.editable)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: HmBanner(tr('Read only: the table has no primary key and its rows cannot be told apart.', 'Только чтение: у таблицы нет первичного ключа, строки нельзя различить.'), tone: HmTone.warning),
          ),
        Expanded(
          child: rs == null
              ? (_loading ? const HmLoading() : const SizedBox.shrink())
              : rs.rows.isEmpty && _inserted.isEmpty
                  ? Column(children: [
                      SizedBox(height: 60, child: ResultGrid(columns: _gridCols(rs), rowCount: 0, cell: _cell)),
                      HmEmptyState(_appliedFilter.isEmpty ? tr('The table is empty', 'Таблица пуста') : tr('No rows match the filter', 'Нет строк по фильтру'), icon: Icons.table_rows_outlined),
                    ])
                  : ResultGrid(
                      columns: _gridCols(rs),
                      rowCount: rs.rows.length + _inserted.length,
                      cell: _cell,
                      rowOffset: _offset,
                      editable: _editable,
                      onEdit: _edit,
                      changed: _changed,
                      mark: _mark,
                      sort: _sort,
                      onSort: _sortBy,
                      onAction: _action,
                    ),
        ),
      ],
    );
  }

  List<GridColumn> _gridCols(pb.ResultSet rs) => [
    for (final c in rs.columns.skip(_skip)) GridColumn(c.name, _typeOf(c), oid: c.typeOid),
  ];

  String _typeOf(pb.ResultColumn c) {
    for (final col in _cols) {
      if (col.name == c.name) return col.primaryKey ? '${col.type} · PK' : col.type;
    }
    return c.type;
  }

  Widget _toolbar() {
    final rs = _rs;
    final n = rs?.rows.length ?? 0;
    final total = rs?.totalEstimate.toInt() ?? -1;
    final changes = _edits.length + _inserted.length + _deleted.length;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
      child: Row(
        children: [
          HmIconButton(icon: Icons.first_page, label: tr('First page', 'Первая страница'), onPressed: _offset > 0 ? () => _reload(offset: 0) : null),
          HmIconButton(icon: Icons.chevron_left, label: tr('Previous page', 'Предыдущая страница'), onPressed: _offset > 0 ? () => _reload(offset: (_offset - _limit).clamp(0, 1 << 62)) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              n == 0 ? '0' : '${_offset + 1}–${_offset + n}${total >= 0 ? ' ${tr('of', 'из')} ~$total' : ''}',
              style: HmText.jb(12, color: HmColors.muted),
            ),
          ),
          HmIconButton(icon: Icons.chevron_right, label: tr('Next page', 'Следующая страница'), onPressed: rs?.truncated == true ? () => _reload(offset: _offset + _limit) : null),
          const SizedBox(width: 4),
          HmIconButton(icon: Icons.refresh, label: tr('Reload', 'Обновить'), onPressed: _loading ? null : () => _reload()),
          const _Sep(),
          if (_editable) ...[
            HmIconButton(icon: Icons.add, label: tr('Add row', 'Добавить строку'), onPressed: _addRow),
            const SizedBox(width: 6),
            HmButton(
              changes == 0 ? tr('Submit', 'Применить') : '${tr('Submit', 'Применить')} ($changes)',
              small: true,
              variant: HmVariant.primary,
              icon: Icons.check,
              loading: _saving,
              onPressed: _dirty && !_saving ? _submit : null,
            ),
            const SizedBox(width: 6),
            HmButton(tr('Revert', 'Откатить'), small: true, variant: HmVariant.neutral, onPressed: _dirty ? _revert : null),
          ],
          const Spacer(),
          if (rs != null) Text('${rs.durationMs} ms', style: HmText.jb(11, color: HmColors.muted)),
          const SizedBox(width: 8),
          if (widget.onOpenConsole != null)
            HmIconButton(
              icon: Icons.terminal,
              label: tr('Open a console with this query', 'Открыть консоль с этим запросом'),
              onPressed: () => widget.onOpenConsole!(_rs?.statement ?? ''),
            ),
        ],
      ),
    );
  }

  Widget _filterBar() => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
    child: Row(
      children: [
        Text('WHERE', style: HmText.jb(11, weight: 700, color: HmColors.purpleLight)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _filter,
            style: HmText.jb(12),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: tr("e.g. price > 10 AND name ILIKE '%box%'", "например price > 10 AND name ILIKE '%box%'"),
              hintStyle: HmText.jb(12, color: HmColors.muted),
            ),
            onSubmitted: (_) => _applyFilter(),
          ),
        ),
        if (_appliedFilter.isNotEmpty)
          HmIconButton(
            icon: Icons.close,
            dense: true,
            label: tr('Clear the filter', 'Сбросить фильтр'),
            onPressed: () {
              _filter.clear();
              _applyFilter();
            },
          ),
        if (_sort.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text('ORDER BY ${_sort.map((s) => s.column + (s.desc ? ' DESC' : '')).join(', ')}', style: HmText.jb(11, color: HmColors.muted)),
          HmIconButton(
            icon: Icons.close,
            dense: true,
            label: tr('Clear the sort', 'Сбросить сортировку'),
            onPressed: () {
              _sort.clear();
              _reload(offset: 0);
            },
          ),
        ],
      ],
    ),
  );
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 8), color: HmColors.border);
}

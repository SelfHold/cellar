import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/gen/cellar.pb.dart' as pb;
import '../common/hm.dart';

/// A column of the grid.
class GridColumn {
  const GridColumn(this.name, this.type, {this.oid = 0});

  final String name;
  final String type;
  final int oid;

  /// Numbers are right-aligned.
  bool get numeric => const {20, 21, 23, 26, 700, 701, 1700, 790}.contains(oid);
}

/// How a row stands in the data editor.
enum RowMark { normal, inserted, deleted }

/// What a context-menu entry does.
enum CellAction { copy, copyRow, copyInsert, view, setNull, deleteRow, filterBy, revertRow }

/// The data grid of the data viewer and of query results (DataGrip's
/// result view): row numbers, resizable columns, sort by a header click,
/// a selected cell moved with the arrows, editing in place.
class ResultGrid extends StatefulWidget {
  const ResultGrid({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cell,
    this.rowOffset = 0,
    this.editable = false,
    this.onEdit,
    this.changed,
    this.mark,
    this.sort = const [],
    this.onSort,
    this.onAction,
  });

  final List<GridColumn> columns;
  final int rowCount;
  final pb.Cell Function(int row, int col) cell;
  final int rowOffset;
  final bool editable;

  /// A cell got a new value (editable grids).
  final void Function(int row, int col, pb.Cell value)? onEdit;

  /// The cell has an edit not submitted yet.
  final bool Function(int row, int col)? changed;
  final RowMark Function(int row)? mark;
  final List<pb.Sort> sort;
  final void Function(int col)? onSort;

  /// A context-menu action the grid does not do itself.
  final void Function(CellAction action, int row, int col)? onAction;

  @override
  State<ResultGrid> createState() => _ResultGridState();
}

const _rowH = 26.0;
const _headH = 34.0;
const _numW = 52.0;

class _ResultGridState extends State<ResultGrid> {
  final _h = ScrollController();
  final _v = ScrollController();
  final _focus = FocusNode();
  List<double> _widths = [];
  int? _row, _col;
  (int, int)? _editing;
  final _editCtl = TextEditingController();
  final _editFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _measure();
    _editFocus.addListener(() {
      if (!_editFocus.hasFocus && _editing != null) _commit();
    });
  }

  @override
  void didUpdateWidget(ResultGrid old) {
    super.didUpdateWidget(old);
    if (old.columns.length != widget.columns.length || !_sameNames(old.columns, widget.columns)) {
      _measure();
      _row = _col = null;
      _editing = null;
    }
    if (_row != null && _row! >= widget.rowCount) _row = widget.rowCount == 0 ? null : widget.rowCount - 1;
  }

  bool _sameNames(List<GridColumn> a, List<GridColumn> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name) return false;
    }
    return true;
  }

  /// Widths from the header and the first rows (about 7.3 px a character).
  void _measure() {
    final n = math.min(widget.rowCount, 200);
    _widths = [
      for (var c = 0; c < widget.columns.length; c++)
        () {
          var chars = math.max(widget.columns[c].name.length + 2, widget.columns[c].type.length);
          for (var r = 0; r < n; r++) {
            final v = widget.cell(r, c);
            chars = math.max(chars, v.null_2 ? 6 : math.min(v.text.length, 60));
          }
          return (chars * 7.3 + 22).clamp(64.0, 420.0);
        }(),
    ];
  }

  @override
  void dispose() {
    _h.dispose();
    _v.dispose();
    _focus.dispose();
    _editCtl.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  double get _total => _numW + _widths.fold(0.0, (a, b) => a + b);

  void _select(int r, int c) {
    setState(() {
      _row = r;
      _col = c;
    });
    _focus.requestFocus();
    _reveal(r, c);
  }

  void _reveal(int r, int c) {
    if (!_v.hasClients || !_h.hasClients) return;
    final top = r * _rowH;
    final vp = _v.position.viewportDimension;
    if (top < _v.offset) _v.jumpTo(top);
    if (top + _rowH > _v.offset + vp) _v.jumpTo(top + _rowH - vp);
    var left = _numW;
    for (var i = 0; i < c; i++) {
      left += _widths[i];
    }
    final hp = _h.position.viewportDimension;
    if (left < _h.offset + _numW) _h.jumpTo(math.max(0, left - _numW));
    if (left + _widths[c] > _h.offset + hp) _h.jumpTo(math.min(_h.position.maxScrollExtent, left + _widths[c] - hp));
  }

  void _startEdit(int r, int c) {
    if (!widget.editable || widget.mark?.call(r) == RowMark.deleted) return;
    final v = widget.cell(r, c);
    _editCtl.text = v.null_2 ? '' : v.text;
    _editCtl.selection = TextSelection(baseOffset: 0, extentOffset: _editCtl.text.length);
    setState(() => _editing = (r, c));
    WidgetsBinding.instance.addPostFrameCallback((_) => _editFocus.requestFocus());
  }

  void _commit() {
    final e = _editing;
    if (e == null) return;
    final old = widget.cell(e.$1, e.$2);
    final text = _editCtl.text;
    setState(() => _editing = null);
    if (old.null_2 && text.isEmpty) return; // untouched NULL stays NULL
    if (!old.null_2 && old.text == text) return;
    widget.onEdit?.call(e.$1, e.$2, pb.Cell(text: text));
    _focus.requestFocus();
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _focus.requestFocus();
  }

  String _rowTsv(int r) => [for (var c = 0; c < widget.columns.length; c++) _plain(widget.cell(r, c))].join('\t');

  String _plain(pb.Cell v) => v.null_2 ? '' : v.text;

  KeyEventResult _key(FocusNode _, KeyEvent ev) {
    if (ev is! KeyDownEvent && ev is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (_editing != null) return KeyEventResult.ignored;
    final r = _row, c = _col;
    if (r == null || c == null) return KeyEventResult.ignored;
    final ctrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final k = ev.logicalKey;
    if (k == LogicalKeyboardKey.arrowDown) {
      _select(math.min(r + 1, widget.rowCount - 1), c);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      _select(math.max(r - 1, 0), c);
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.tab) {
      _select(r, math.min(c + 1, widget.columns.length - 1));
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _select(r, math.max(c - 1, 0));
    } else if (k == LogicalKeyboardKey.pageDown) {
      _select(math.min(r + 20, widget.rowCount - 1), c);
    } else if (k == LogicalKeyboardKey.pageUp) {
      _select(math.max(r - 20, 0), c);
    } else if (k == LogicalKeyboardKey.home && ctrl) {
      _select(0, c);
    } else if (k == LogicalKeyboardKey.end && ctrl) {
      _select(widget.rowCount - 1, c);
    } else if (ctrl && k == LogicalKeyboardKey.keyC) {
      Clipboard.setData(ClipboardData(text: HardwareKeyboard.instance.isShiftPressed ? _rowTsv(r) : _plain(widget.cell(r, c))));
    } else if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.f2) {
      if (widget.editable) {
        _startEdit(r, c);
      } else {
        _view(r, c);
      }
    } else if (k == LogicalKeyboardKey.delete && widget.editable) {
      widget.onAction?.call(CellAction.deleteRow, r, c);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _menu(int r, int c, Offset pos) async {
    _select(r, c);
    final deleted = widget.mark?.call(r) == RowMark.deleted;
    final items = <HmMenuItem<CellAction>>[
      (value: CellAction.copy, label: tr('Copy value', 'Копировать значение')),
      (value: CellAction.copyRow, label: tr('Copy row (tab-separated)', 'Копировать строку (через табуляцию)')),
      (value: CellAction.view, label: tr('View value…', 'Показать значение…')),
      if (widget.onAction != null) (value: CellAction.filterBy, label: tr('Filter by this value', 'Фильтр по этому значению')),
      if (widget.editable && !deleted) (value: CellAction.setNull, label: tr('Set NULL', 'Установить NULL')),
      if (widget.editable && !deleted) (value: CellAction.deleteRow, label: tr('Delete row', 'Удалить строку')),
      if (widget.editable && (deleted || widget.changed != null)) (value: CellAction.revertRow, label: tr('Revert row', 'Отменить изменения строки')),
    ];
    final a = await showContextMenu<CellAction>(context, title: widget.columns[c].name, items: items, position: pos);
    if (a == null || !mounted) return;
    switch (a) {
      case CellAction.copy:
        Clipboard.setData(ClipboardData(text: _plain(widget.cell(r, c))));
      case CellAction.copyRow:
        Clipboard.setData(ClipboardData(text: _rowTsv(r)));
      case CellAction.view:
        _view(r, c);
      case CellAction.setNull:
        widget.onEdit?.call(r, c, pb.Cell(null_2: true));
      default:
        widget.onAction?.call(a, r, c);
    }
  }

  void _view(int r, int c) {
    final v = widget.cell(r, c);
    showHmModal<void>(
      context,
      title: '${widget.columns[c].name} · ${widget.columns[c].type}',
      size: HmModalSize.lg,
      body: (_) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: SingleChildScrollView(
          child: SelectableText(v.null_2 ? 'NULL' : v.text, style: HmText.jb(12, color: v.null_2 ? HmColors.muted : HmColors.text, height: 1.5)),
        ),
      ),
      actions: (ctx) => [
        HmButton(tr('Copy', 'Копировать'), variant: HmVariant.neutral, onPressed: () => Clipboard.setData(ClipboardData(text: _plain(v)))),
        HmButton(tr('Close', 'Закрыть'), variant: HmVariant.primary, onPressed: () => Navigator.pop(ctx)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.columns.isEmpty) return const SizedBox.shrink();
    if (_widths.length != widget.columns.length) _measure();
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: LayoutBuilder(
        builder: (context, box) => Scrollbar(
          controller: _v,
          thumbVisibility: true,
          notificationPredicate: (n) => n.depth == 1 && n.metrics.axis == Axis.vertical,
          child: Scrollbar(
            controller: _h,
            thumbVisibility: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: _h,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(_total, box.maxWidth),
                  height: box.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      Expanded(
                        child: ListView.builder(
                          controller: _v,
                          itemExtent: _rowH,
                          itemCount: widget.rowCount,
                          itemBuilder: (_, r) => _rowView(r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    height: _headH,
    decoration: const BoxDecoration(
      color: HmColors.surface,
      border: Border(bottom: BorderSide(color: HmColors.border)),
    ),
    child: Row(
      children: [
        Container(
          width: _numW,
          alignment: Alignment.center,
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: HmColors.border))),
          child: Text('#', style: HmText.th),
        ),
        for (var c = 0; c < widget.columns.length; c++) _headCell(c),
      ],
    ),
  );

  Widget _headCell(int c) {
    final col = widget.columns[c];
    final si = widget.sort.indexWhere((s) => s.column == col.name);
    final s = si < 0 ? null : widget.sort[si];
    return SizedBox(
      width: _widths[c],
      child: Stack(
        children: [
          Positioned.fill(
            child: MouseRegion(
              cursor: widget.onSort != null ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSort == null ? null : () => widget.onSort!(c),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: HmColors.border))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(col.name, style: HmText.jb(12, weight: 700), overflow: TextOverflow.ellipsis, maxLines: 1)),
                          if (s != null) ...[
                            const SizedBox(width: 4),
                            Icon(s.desc ? Icons.arrow_downward : Icons.arrow_upward, size: 12, color: HmColors.accent),
                            if (widget.sort.length > 1) Text('${si + 1}', style: HmText.jb(9, color: HmColors.accent)),
                          ],
                        ],
                      ),
                      if (col.type.isNotEmpty) Text(col.type, style: HmText.jb(10, color: HmColors.muted), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Resize handle.
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => setState(() => _widths[c] = (_widths[c] + d.delta.dx).clamp(40.0, 1600.0)),
                onDoubleTap: () => setState(_measure),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowView(int r) {
    final mark = widget.mark?.call(r) ?? RowMark.normal;
    final selRow = r == _row;
    final bg = switch (mark) {
      RowMark.inserted => HmColors.tint(HmColors.ok, 0.10),
      RowMark.deleted => HmColors.tint(HmColors.error, 0.10),
      RowMark.normal => selRow ? HmColors.tint(HmColors.accent, 0.05) : (r.isOdd ? HmColors.tint(HmColors.text, 0.015) : Colors.transparent),
    };
    return Container(
      color: bg,
      child: Row(
        children: [
          Container(
            width: _numW,
            height: _rowH,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: HmColors.border), bottom: BorderSide(color: HmColors.border, width: 0.5)),
            ),
            child: Text(
              mark == RowMark.inserted ? '+' : '${widget.rowOffset + r + 1}',
              style: HmText.jb(11, color: selRow ? HmColors.accent : HmColors.muted),
            ),
          ),
          for (var c = 0; c < widget.columns.length; c++) _cellView(r, c, mark),
        ],
      ),
    );
  }

  Widget _cellView(int r, int c, RowMark mark) {
    final w = _widths[c];
    if (_editing == (r, c)) {
      return Container(
        width: w,
        height: _rowH,
        decoration: BoxDecoration(border: Border.all(color: HmColors.accent)),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _cancelEdit,
          },
          child: TextField(
            controller: _editCtl,
            focusNode: _editFocus,
            style: HmText.jb(12),
            cursorHeight: 14,
            decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
            onSubmitted: (_) => _commit(),
          ),
        ),
      );
    }
    final v = widget.cell(r, c);
    final sel = r == _row && c == _col;
    final changed = widget.changed?.call(r, c) ?? false;
    final col = widget.columns[c];
    final text = v.null_2 ? '<null>' : v.text.replaceAll('\n', '⏎').replaceAll('\t', '  ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _select(r, c),
      onDoubleTap: () => widget.editable ? _startEdit(r, c) : _view(r, c),
      onSecondaryTapDown: (d) => _menu(r, c, d.globalPosition),
      onLongPressStart: (d) => _menu(r, c, d.globalPosition),
      child: Container(
        width: w,
        height: _rowH,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: col.numeric && !v.null_2 ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: changed ? HmColors.tint(HmColors.warning, 0.14) : null,
          border: sel
              ? Border.all(color: HmColors.accent)
              : const Border(right: BorderSide(color: HmColors.border, width: 0.5), bottom: BorderSide(color: HmColors.border, width: 0.5)),
        ),
        child: Text(
          text.length > 300 ? '${text.substring(0, 300)}…' : text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HmText.jb(
            12,
            color: v.null_2 ? HmColors.muted : (mark == RowMark.deleted ? HmColors.muted : HmColors.text),
          ).copyWith(
            fontStyle: v.null_2 ? FontStyle.italic : null,
            decoration: mark == RowMark.deleted ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

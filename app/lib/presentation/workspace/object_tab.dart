import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/dbm.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import '../explorer/explorer_controller.dart';
import '../grid/result_grid.dart';
import 'sql_highlight.dart';

/// An object's structure: columns, indexes, constraints and its DDL.
class ObjectTab extends StatefulWidget {
  const ObjectTab({super.key, required this.path});

  final DbPath path;

  @override
  State<ObjectTab> createState() => _ObjectTabState();
}

class _ObjectTabState extends State<ObjectTab> {
  pb.ObjectInfo? _info;
  String? _error;
  int _tab = 0;

  bool get _routine => widget.path.kind == pb.DbObject_Kind.FUNCTION || widget.path.kind == pb.DbObject_Kind.PROCEDURE || widget.path.kind == pb.DbObject_Kind.SEQUENCE;

  @override
  void initState() {
    super.initState();
    if (_routine) _tab = 3;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final i = await context.read<CoreCubit>().api.describeObject(widget.path.ref);
      if (mounted) setState(() => _info = i);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Padding(padding: const EdgeInsets.all(16), child: HmBanner(_error!, tone: HmTone.error, action: HmButton(tr('Retry', 'Повторить'), small: true, onPressed: _load)));
    final i = _info;
    if (i == null) return const HmLoading();
    final tabs = [
      if (!_routine) (0, '${tr('Columns', 'Колонки')} ${i.columns.length}'),
      if (!_routine) (1, '${tr('Indexes', 'Индексы')} ${i.indexes.length}'),
      if (!_routine) (2, '${tr('Constraints', 'Ограничения')} ${i.constraints.length}'),
      (3, 'DDL'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
          child: Row(
            children: [
              for (final t in tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: HmChip(label: t.$2, active: _tab == t.$1, onTap: () => setState(() => _tab = t.$1)),
                ),
              const Spacer(),
              if (i.owner.isNotEmpty) Text('${tr('owner', 'владелец')} ${i.owner}', style: HmText.jb(11, color: HmColors.muted)),
              if (i.sizeBytes > 0) Text('  ·  ${(i.sizeBytes.toInt() / 1024).toStringAsFixed(0)} KB', style: HmText.jb(11, color: HmColors.muted)),
              HmIconButton(icon: Icons.refresh, label: tr('Reload', 'Обновить'), onPressed: _load),
            ],
          ),
        ),
        if (i.object.comment.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Text(i.object.comment, style: HmText.small)),
        Expanded(child: _body(i)),
      ],
    );
  }

  Widget _body(pb.ObjectInfo i) {
    switch (_tab) {
      case 0:
        return ResultGrid(
          columns: const [GridColumn('name', ''), GridColumn('type', ''), GridColumn('nullable', ''), GridColumn('default', ''), GridColumn('key', ''), GridColumn('comment', '')],
          rowCount: i.columns.length,
          cell: (r, c) {
            final col = i.columns[r];
            final s = switch (c) {
              0 => col.name,
              1 => col.type,
              2 => col.nullable ? 'yes' : 'NOT NULL',
              3 => col.generated ? 'GENERATED ${col.default_4}' : col.default_4,
              4 => col.primaryKey ? 'PK' : '',
              _ => col.comment,
            };
            return pb.Cell(text: s);
          },
        );
      case 1:
        return ResultGrid(
          columns: const [GridColumn('name', ''), GridColumn('unique', ''), GridColumn('definition', '')],
          rowCount: i.indexes.length,
          cell: (r, c) {
            final x = i.indexes[r];
            return pb.Cell(text: switch (c) {
              0 => x.name,
              1 => x.primary ? 'primary' : (x.unique ? 'unique' : ''),
              _ => x.definition,
            });
          },
        );
      case 2:
        return ResultGrid(
          columns: const [GridColumn('name', ''), GridColumn('type', ''), GridColumn('definition', '')],
          rowCount: i.constraints.length,
          cell: (r, c) {
            final x = i.constraints[r];
            return pb.Cell(text: switch (c) {
              0 => x.name,
              1 => x.type,
              _ => x.definition,
            });
          },
        );
      default:
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: SelectableText.rich(TextSpan(style: HmText.jb(13, height: 1.5), children: highlightSql(i.ddl))),
              ),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: HmIconButton(
                icon: Icons.copy,
                label: tr('Copy DDL', 'Копировать DDL'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: i.ddl));
                  Toasts.success(tr('Copied', 'Скопировано'));
                },
              ),
            ),
          ],
        );
    }
  }
}

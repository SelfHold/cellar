import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';
import 'change_panel.dart';

/// Types offered by the type button of a column (any type can be typed).
const commonTypes = [
  'bigint', 'integer', 'smallint', 'numeric(12,2)', 'double precision', 'boolean', 'text', 'varchar(255)', 'uuid', 'date',
  'timestamptz', 'timestamp', 'interval', 'jsonb', 'json', 'bytea', 'text[]', 'inet', 'bigint GENERATED ALWAYS AS IDENTITY',
];

/// Creates (table = null) or modifies a table of a schema, DataGrip's
/// "Modify Table": columns, primary key, constraints, indexes.
Future<bool> showTableDialog(BuildContext context, {required String conn, required String db, required String schema, String? table, required List<pb.Role> roles, OpenConsole? openConsole}) async =>
    await showHmModal<bool>(
      context,
      title: table == null ? tr('New table in $schema', 'Новая таблица в $schema') : tr('Table $schema.$table', 'Таблица $schema.$table'),
      size: HmModalSize.lg,
      body: (_) => _TableForm(conn: conn, db: db, schema: schema, table: table, roles: roles, openConsole: openConsole),
    ) ??
    false;

class _Col {
  _Col({String name = '', this.original = '', String type = '', this.nullable = true, String def = '', String comment = '', this.pk = false, this.locked = false})
    : name = TextEditingController(text: name),
      type = TextEditingController(text: type),
      def = TextEditingController(text: def),
      comment = TextEditingController(text: comment);

  final TextEditingController name, type, def, comment;
  final String original;
  bool nullable;
  bool pk;

  /// Identity / generated: the default is not the user's to change here.
  final bool locked;
}

class _Item {
  _Item({String name = '', String definition = '', this.unique = false, this.original = ''})
    : name = TextEditingController(text: name),
      definition = TextEditingController(text: definition);

  final TextEditingController name, definition;
  bool unique;
  final String original;
}

class _TableForm extends StatefulWidget {
  const _TableForm({required this.conn, required this.db, required this.schema, this.table, required this.roles, this.openConsole});

  final String conn, db, schema;
  final String? table;
  final List<pb.Role> roles;
  final OpenConsole? openConsole;

  @override
  State<_TableForm> createState() => _TableFormState();
}

class _TableFormState extends State<_TableForm> {
  final _name = TextEditingController();
  final _comment = TextEditingController();
  String _owner = '';
  final _cols = <_Col>[];
  final _cons = <_Item>[];
  final _idx = <_Item>[];
  bool _loading = false;
  String? _error;

  bool get _create => widget.table == null;

  pb.CellarClient get _api => context.read<CoreCubit>().api;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _comment]) {
      c.addListener(_changed);
    }
    if (_create) {
      _addCol(_Col(name: 'id', type: 'bigint GENERATED ALWAYS AS IDENTITY', nullable: false, pk: true));
    } else {
      _load();
    }
  }

  void _changed() => setState(() {});

  void _addCol(_Col c) {
    for (final t in [c.name, c.type, c.def, c.comment]) {
      t.addListener(_changed);
    }
    setState(() => _cols.add(c));
  }

  void _addItem(List<_Item> list, _Item x) {
    for (final t in [x.name, x.definition]) {
      t.addListener(_changed);
    }
    setState(() => list.add(x));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final i = await _api.describeObject(pb.ObjectRef(connectionId: widget.conn, database: widget.db, schema: widget.schema, name: widget.table!, kind: pb.DbObject_Kind.TABLE));
      if (!mounted) return;
      _name.text = i.object.name;
      _comment.text = i.object.comment;
      _owner = i.owner;
      for (final c in i.columns) {
        _addCol(_Col(name: c.name, original: c.name, type: c.type, nullable: c.nullable, def: c.default_4, comment: c.comment, pk: i.primaryKey.contains(c.name), locked: c.generated || c.identity && c.default_4.isEmpty));
      }
      for (final k in i.constraints.where((k) => k.type != 'PRIMARY KEY' && k.type != 'TRIGGER')) {
        _addItem(_cons, _Item(name: k.name, definition: k.definition, original: k.name));
      }
      for (final ix in i.indexes.where((ix) => !i.constraints.any((k) => k.name == ix.name))) {
        _addItem(_idx, _Item(name: ix.name, definition: ix.definition, unique: ix.unique, original: ix.name));
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = errorText(e);
        });
      }
    }
  }

  pb.Change get _change {
    // Primary key columns in table order.
    final t = pb.TableSpec(schema: widget.schema, name: _name.text.trim(), comment: _comment.text, owner: _owner);
    for (final c in _cols) {
      t.columns.add(pb.ColumnSpec(name: c.name.text.trim(), original: c.original, type: c.type.text.trim(), nullable: c.nullable && !c.pk, default_5: c.def.text.trim(), comment: c.comment.text));
      if (c.pk) t.primaryKey.add(c.name.text.trim());
    }
    for (final k in _cons) {
      t.constraints.add(pb.Constraint(name: k.name.text.trim(), definition: k.definition.text.trim()));
    }
    for (final ix in _idx) {
      t.indexes.add(pb.Index(name: ix.name.text.trim(), definition: ix.definition.text.trim(), unique: ix.unique));
    }
    return pb.Change(connectionId: widget.conn, database: widget.db, op: _create ? pb.Change_Op.CREATE : pb.Change_Op.ALTER, original: widget.table ?? '', table: t);
  }

  Future<void> _pickType(_Col c) async {
    final t = await pickOption<String>(context, title: tr('Type', 'Тип'), options: {for (final t in commonTypes) t: t});
    if (t != null) c.type.text = t;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return HmBanner(_error!, tone: HmTone.error);
    if (_loading) return const SizedBox(height: 200, child: HmLoading());
    final mobile = Hm.of(context).mobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        formRow(context, [
          HmTextField(label: tr('Name', 'Имя'), controller: _name, required: true, identifier: true, autofocus: _create, placeholder: 'orders'),
          HmSelect<String>(label: tr('Owner', 'Владелец'), options: ownerOptions(widget.roles, _owner), value: _owner, onChanged: (v) => setState(() => _owner = v)),
        ]),
        HmTextField(label: tr('Comment', 'Комментарий'), controller: _comment),
        const SizedBox(height: 18),
        _header(tr('COLUMNS', 'КОЛОНКИ'), tr('Add column', 'Добавить колонку'), () => _addCol(_Col(type: 'text'))),
        if (!mobile)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(flex: 3, child: Text(tr('name', 'имя'), style: HmText.label)),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: Text(tr('type', 'тип'), style: HmText.label)),
              SizedBox(width: 44, child: Text('NN', style: HmText.label, textAlign: TextAlign.center)),
              SizedBox(width: 44, child: Text('PK', style: HmText.label, textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text(tr('default', 'по умолчанию'), style: HmText.label)),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: Text(tr('comment', 'комментарий'), style: HmText.label)),
              const SizedBox(width: 36),
            ]),
          ),
        for (final c in _cols) mobile ? _colCard(c) : _colRow(c),
        const SizedBox(height: 16),
        _header(tr('KEYS AND CHECKS', 'КЛЮЧИ И ПРОВЕРКИ'), tr('Add', 'Добавить'), () => _addItem(_cons, _Item())),
        for (final k in _cons) _itemRow(k, _cons, tr('UNIQUE (col) · CHECK (expr) · FOREIGN KEY (col) REFERENCES t (id)', 'UNIQUE (col) · CHECK (expr) · FOREIGN KEY (col) REFERENCES t (id)')),
        if (_cons.isEmpty) _none(),
        const SizedBox(height: 16),
        _header(tr('INDEXES', 'ИНДЕКСЫ'), tr('Add', 'Добавить'), () => _addItem(_idx, _Item())),
        for (final ix in _idx) _itemRow(ix, _idx, '(col) · USING gin (col)', unique: true),
        if (_idx.isEmpty) _none(),
        const SizedBox(height: 18),
        ChangePanel(change: _change, openConsole: widget.openConsole, action: _create ? tr('Create', 'Создать') : tr('Apply', 'Применить')),
      ],
    );
  }

  Widget _none() => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(tr('none', 'нет'), style: HmText.small));

  Widget _header(String title, String add, VoidCallback onAdd) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(title, style: HmText.label)),
      HmButton(add, small: true, variant: HmVariant.neutral, icon: Icons.add, onPressed: onAdd),
    ]),
  );

  Widget _check(bool v, ValueChanged<bool> on, String label) => SizedBox(
    width: 44,
    child: Center(
      child: Semantics(
        label: label,
        checked: v,
        child: GestureDetector(
          onTap: () => setState(() => on(!v)),
          child: Icon(v ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: v ? HmColors.accent : HmColors.muted),
        ),
      ),
    ),
  );

  Widget _remove(VoidCallback on) => HmIconButton(icon: Icons.close, dense: true, label: tr('Remove', 'Убрать'), color: HmColors.muted, onPressed: () => setState(on));

  Widget _typeField(_Col c, {bool showLabel = false}) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Expanded(child: HmTextField(label: tr('Type', 'Тип'), showLabel: showLabel, controller: c.type, identifier: true, placeholder: 'text')),
    HmIconButton(icon: Icons.expand_more, dense: true, label: tr('Common types', 'Частые типы'), onPressed: () => _pickType(c)),
  ]);

  Widget _colRow(_Col c) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Expanded(flex: 3, child: HmTextField(label: tr('Name', 'Имя'), showLabel: false, controller: c.name, identifier: true, placeholder: 'column')),
      const SizedBox(width: 6),
      Expanded(flex: 3, child: _typeField(c)),
      _check(!c.nullable || c.pk, (v) => c.nullable = !v, 'NOT NULL'),
      _check(c.pk, (v) => c.pk = v, 'PRIMARY KEY'),
      Expanded(flex: 3, child: c.locked ? Text(c.def.text.isEmpty ? 'identity' : c.def.text, style: HmText.small, maxLines: 1, overflow: TextOverflow.ellipsis) : HmTextField(label: tr('Default', 'По умолчанию'), showLabel: false, controller: c.def, identifier: true)),
      const SizedBox(width: 6),
      Expanded(flex: 3, child: HmTextField(label: tr('Comment', 'Комментарий'), showLabel: false, controller: c.comment)),
      _remove(() => _cols.remove(c)),
    ]),
  );

  Widget _colCard(_Col c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: HmCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: HmTextField(label: tr('Name', 'Имя'), controller: c.name, identifier: true)),
          _remove(() => _cols.remove(c)),
        ]),
        const SizedBox(height: 10),
        _typeField(c, showLabel: true),
        const SizedBox(height: 6),
        HmCheckRow(label: 'NOT NULL', value: !c.nullable || c.pk, onChanged: (v) => setState(() => c.nullable = !v)),
        HmCheckRow(label: tr('Primary key', 'Первичный ключ'), value: c.pk, onChanged: (v) => setState(() => c.pk = v)),
        if (!c.locked) ...[const SizedBox(height: 6), HmTextField(label: tr('Default', 'По умолчанию'), controller: c.def, identifier: true)],
        const SizedBox(height: 10),
        HmTextField(label: tr('Comment', 'Комментарий'), controller: c.comment),
      ]),
    ),
  );

  Widget _itemRow(_Item x, List<_Item> list, String hint, {bool unique = false}) {
    final mobile = Hm.of(context).mobile;
    final name = HmTextField(label: tr('Name', 'Имя'), showLabel: mobile, controller: x.name, identifier: true, placeholder: tr('auto', 'авто'));
    final def = HmTextField(label: tr('Definition', 'Определение'), showLabel: mobile, controller: x.definition, identifier: true, placeholder: hint);
    if (mobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: HmCard(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: name), _remove(() => list.remove(x))]),
            const SizedBox(height: 10),
            def,
            if (unique) HmCheckRow(label: 'UNIQUE', value: x.unique, onChanged: (v) => setState(() => x.unique = v)),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(flex: 2, child: name),
        const SizedBox(width: 6),
        Expanded(flex: 5, child: def),
        if (unique) _check(x.unique, (v) => x.unique = v, 'UNIQUE'),
        _remove(() => list.remove(x)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import 'change_panel.dart';

/// Creates (role = null) or modifies a user / role of a connection's
/// server. Returns whether it ran.
Future<bool> showRoleDialog(BuildContext context, {required String conn, pb.Role? role, required List<pb.Role> roles}) async =>
    await showHmModal<bool>(
      context,
      title: role == null ? tr('New user', 'Новый пользователь') : tr('User ${role.name}', 'Пользователь ${role.name}'),
      size: HmModalSize.lg,
      body: (_) => _RoleForm(conn: conn, role: role, roles: roles),
    ) ??
    false;

class _RoleForm extends StatefulWidget {
  const _RoleForm({required this.conn, this.role, required this.roles});

  final String conn;
  final pb.Role? role;
  final List<pb.Role> roles;

  @override
  State<_RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<_RoleForm> {
  late final r = widget.role?.deepCopy() ?? pb.Role(login: true, inherit: true, connectionLimit: -1);
  late final _name = TextEditingController(text: r.name);
  final _password = TextEditingController();
  late final _limit = TextEditingController(text: r.connectionLimit < 0 ? '' : '${r.connectionLimit}');
  late final _valid = TextEditingController(text: r.validUntil);
  late final _comment = TextEditingController(text: r.comment);

  bool get _create => widget.role == null;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _password, _limit, _valid, _comment]) {
      c.addListener(() => setState(() {}));
    }
  }

  pb.Change get _change {
    final x = r.deepCopy()
      ..name = _name.text.trim()
      ..password = _password.text
      ..connectionLimit = int.tryParse(_limit.text.trim()) ?? -1
      ..validUntil = _valid.text.trim()
      ..comment = _comment.text
      ..system = false;
    return pb.Change(connectionId: widget.conn, op: _create ? pb.Change_Op.CREATE : pb.Change_Op.ALTER, original: widget.role?.name ?? '', role: x);
  }

  Future<void> _addGroup() async {
    final options = {for (final g in widget.roles.where((g) => g.name != widget.role?.name && !r.memberOf.contains(g.name))) g.name: g.name};
    if (options.isEmpty) return;
    final g = await pickOption<String>(context, title: tr('Member of', 'Входит в'), options: options);
    if (g != null) setState(() => r.memberOf.add(g));
  }

  @override
  Widget build(BuildContext context) {
    final flags = <(String, String, bool, void Function(bool))>[
      (tr('Can log in', 'Может входить'), tr('A user; off: a group role', 'Пользователь; выкл. — групповая роль'), r.login, (v) => r.login = v),
      (tr('Superuser', 'Суперпользователь'), tr('Bypasses every permission check', 'Обходит все проверки прав'), r.superuser, (v) => r.superuser = v),
      (tr('Create databases', 'Создаёт базы'), '', r.createDb, (v) => r.createDb = v),
      (tr('Create roles', 'Создаёт роли'), '', r.createRole, (v) => r.createRole = v),
      (tr('Inherit privileges', 'Наследует права'), tr('of the roles it is a member of', 'ролей, в которые входит'), r.inherit, (v) => r.inherit = v),
      (tr('Replication', 'Репликация'), '', r.replication, (v) => r.replication = v),
      (tr('Bypass row security', 'Обходит RLS'), '', r.bypassRls, (v) => r.bypassRls = v),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        formRow(context, [
          HmTextField(label: tr('Name', 'Имя'), controller: _name, required: true, identifier: true, autofocus: _create, placeholder: 'app_user'),
          HmTextField(
            label: tr('Password', 'Пароль'),
            controller: _password,
            password: true,
            hint: _create ? tr('Hashed on this device before it is sent', 'Хешируется на этом устройстве до отправки') : tr('Empty: keep the current one', 'Пусто — оставить текущий'),
          ),
        ]),
        for (final f in flags) HmToggleRow(label: f.$1, hint: f.$2.isEmpty ? null : f.$2, value: f.$3, onChanged: (v) => setState(() => f.$4(v))),
        const SizedBox(height: 14),
        formRow(context, [
          HmTextField(label: tr('Connection limit', 'Лимит подключений'), controller: _limit, placeholder: tr('no limit', 'без лимита'), keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
          HmTextField(label: tr('Password valid until', 'Пароль действует до'), controller: _valid, placeholder: '2030-12-31', identifier: true, hint: tr('Empty: forever', 'Пусто — бессрочно')),
        ]),
        HmFormField(
          label: tr('Member of', 'Входит в роли'),
          child: Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final g in r.memberOf)
              HmChip(label: '$g  ✕', active: true, onTap: () => setState(() => r.memberOf.remove(g))),
            HmButton(tr('Add…', 'Добавить…'), small: true, variant: HmVariant.neutral, icon: Icons.add, onPressed: _addGroup),
          ]),
        ),
        const SizedBox(height: 14),
        HmTextField(label: tr('Comment', 'Комментарий'), controller: _comment),
        const SizedBox(height: 18),
        ChangePanel(change: _change, hasSecret: _password.text.isNotEmpty, action: _create ? tr('Create', 'Создать') : tr('Apply', 'Применить')),
      ],
    );
  }
}

/// Creates (db = null) or modifies a database.
Future<bool> showDatabaseDialog(BuildContext context, {required String conn, pb.Database? db, required List<pb.Role> roles, required List<pb.Database> all, OpenConsole? openConsole}) async =>
    await showHmModal<bool>(
      context,
      title: db == null ? tr('New database', 'Новая база данных') : tr('Database ${db.name}', 'База данных ${db.name}'),
      size: HmModalSize.lg,
      body: (_) => _DatabaseForm(conn: conn, db: db, roles: roles, all: all, openConsole: openConsole),
    ) ??
    false;

class _DatabaseForm extends StatefulWidget {
  const _DatabaseForm({required this.conn, this.db, required this.roles, required this.all, this.openConsole});

  final String conn;
  final pb.Database? db;
  final List<pb.Role> roles;
  final List<pb.Database> all;
  final OpenConsole? openConsole;

  @override
  State<_DatabaseForm> createState() => _DatabaseFormState();
}

class _DatabaseFormState extends State<_DatabaseForm> {
  late final d = widget.db?.deepCopy() ?? pb.Database(connectionLimit: -1);
  late final _name = TextEditingController(text: d.name);
  late final _encoding = TextEditingController(text: widget.db == null ? '' : d.encoding);
  late final _collate = TextEditingController(text: widget.db == null ? '' : d.collate);
  late final _ctype = TextEditingController(text: widget.db == null ? '' : d.ctype);
  late final _limit = TextEditingController(text: d.connectionLimit < 0 ? '' : '${d.connectionLimit}');
  late final _comment = TextEditingController(text: d.comment);

  bool get _create => widget.db == null;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _encoding, _collate, _ctype, _limit, _comment]) {
      c.addListener(() => setState(() {}));
    }
  }

  pb.Change get _change {
    final x = d.deepCopy()
      ..name = _name.text.trim()
      ..connectionLimit = int.tryParse(_limit.text.trim()) ?? -1
      ..comment = _comment.text;
    if (_create) {
      x
        ..encoding = _encoding.text.trim()
        ..collate = _collate.text.trim()
        ..ctype = _ctype.text.trim();
    }
    return pb.Change(connectionId: widget.conn, op: _create ? pb.Change_Op.CREATE : pb.Change_Op.ALTER, original: widget.db?.name ?? '', db: x);
  }

  @override
  Widget build(BuildContext context) {
    final templates = {'': tr('— default (template1) —', '— по умолчанию (template1) —'), for (final t in widget.all.where((t) => t.isTemplate || t.name == 'postgres')) t.name: t.name, 'template0': 'template0'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        formRow(context, [
          HmTextField(label: tr('Name', 'Имя'), controller: _name, required: true, identifier: true, autofocus: _create, placeholder: 'shop'),
          HmSelect<String>(label: tr('Owner', 'Владелец'), options: ownerOptions(widget.roles, d.owner), value: d.owner, onChanged: (v) => setState(() => d.owner = v)),
        ]),
        if (_create) ...[
          formRow(context, [
            HmSelect<String>(label: tr('Template', 'Шаблон'), options: templates, value: d.template, onChanged: (v) => setState(() => d.template = v)),
            HmTextField(label: tr('Encoding', 'Кодировка'), controller: _encoding, identifier: true, placeholder: 'UTF8'),
          ]),
          formRow(context, [
            HmTextField(label: 'LC_COLLATE', controller: _collate, identifier: true, placeholder: 'en_US.UTF-8'),
            HmTextField(label: 'LC_CTYPE', controller: _ctype, identifier: true, placeholder: 'en_US.UTF-8'),
          ]),
        ] else
          Padding(padding: const EdgeInsets.only(bottom: 14), child: Text('${d.encoding}  ·  ${d.collate}  ·  ${d.ctype}', style: HmText.small)),
        formRow(context, [
          HmTextField(label: tr('Connection limit', 'Лимит подключений'), controller: _limit, placeholder: tr('no limit', 'без лимита'), keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
          HmTextField(label: tr('Comment', 'Комментарий'), controller: _comment),
        ]),
        const SizedBox(height: 4),
        ChangePanel(change: _change, openConsole: widget.openConsole, action: _create ? tr('Create', 'Создать') : tr('Apply', 'Применить')),
      ],
    );
  }
}

/// Creates (schema = null) or modifies a schema of a database.
Future<bool> showSchemaDialog(BuildContext context, {required String conn, required String db, pb.Schema? schema, required List<pb.Role> roles, OpenConsole? openConsole}) async =>
    await showHmModal<bool>(
      context,
      title: schema == null ? tr('New schema in $db', 'Новая схема в $db') : tr('Schema ${schema.name}', 'Схема ${schema.name}'),
      body: (_) => _SchemaForm(conn: conn, db: db, schema: schema, roles: roles, openConsole: openConsole),
    ) ??
    false;

class _SchemaForm extends StatefulWidget {
  const _SchemaForm({required this.conn, required this.db, this.schema, required this.roles, this.openConsole});

  final String conn;
  final String db;
  final pb.Schema? schema;
  final List<pb.Role> roles;
  final OpenConsole? openConsole;

  @override
  State<_SchemaForm> createState() => _SchemaFormState();
}

class _SchemaFormState extends State<_SchemaForm> {
  late final s = widget.schema?.deepCopy() ?? pb.Schema();
  late final _name = TextEditingController(text: s.name);
  late final _comment = TextEditingController(text: s.comment);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _comment.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final create = widget.schema == null;
    final x = s.deepCopy()
      ..name = _name.text.trim()
      ..comment = _comment.text
      ..system = false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HmTextField(label: tr('Name', 'Имя'), controller: _name, required: true, identifier: true, autofocus: create, placeholder: 'sales'),
        const SizedBox(height: 14),
        HmSelect<String>(label: tr('Owner', 'Владелец'), options: ownerOptions(widget.roles, s.owner), value: s.owner, onChanged: (v) => setState(() => s.owner = v)),
        const SizedBox(height: 14),
        HmTextField(label: tr('Comment', 'Комментарий'), controller: _comment),
        const SizedBox(height: 18),
        ChangePanel(
          change: pb.Change(connectionId: widget.conn, database: widget.db, op: create ? pb.Change_Op.CREATE : pb.Change_Op.ALTER, original: widget.schema?.name ?? '', schema: x),
          openConsole: widget.openConsole,
          action: create ? tr('Create', 'Создать') : tr('Apply', 'Применить'),
        ),
      ],
    );
  }
}

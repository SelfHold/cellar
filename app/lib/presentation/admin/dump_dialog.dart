import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grpc/grpc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/cellar.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

/// Dumps a database, or some schemas / tables of it, to a file on this
/// device with pg_dump.
Future<void> showDumpDialog(BuildContext context, {required String conn, required String db, List<String> schemas = const [], List<pb.ObjectRef> tables = const []}) =>
    showHmModal<void>(
      context,
      title: tr('Dump $db', 'Дамп $db'),
      size: HmModalSize.lg,
      dismissible: false,
      body: (_) => _JobForm(conn: conn, db: db, schemas: schemas, tables: tables, restore: false),
    );

/// Restores a dump file into a database (psql for SQL files, pg_restore
/// for custom and tar archives).
Future<bool> showRestoreDialog(BuildContext context, {required String conn, required String db}) async =>
    await showHmModal<bool>(
      context,
      title: tr('Restore into $db', 'Восстановить в $db'),
      size: HmModalSize.lg,
      dismissible: false,
      body: (_) => _JobForm(conn: conn, db: db, restore: true),
    ) ??
    false;

class _JobForm extends StatefulWidget {
  const _JobForm({required this.conn, required this.db, this.schemas = const [], this.tables = const [], required this.restore});

  final String conn, db;
  final List<String> schemas;
  final List<pb.ObjectRef> tables;
  final bool restore;

  @override
  State<_JobForm> createState() => _JobFormState();
}

enum _Phase { form, running, done }

class _JobFormState extends State<_JobForm> {
  pb.DumpToolsReply? _tools;
  String? _toolsError;
  var _place = pb.ToolPlace.TOOL_PLACE_UNSPECIFIED;
  var _format = pb.DumpRequest_Format.PLAIN;
  final _path = TextEditingController();

  // dump
  bool _schemaOnly = false, _dataOnly = false, _noOwner = false, _noPrivileges = false, _clean = false, _create = false, _inserts = false;
  // restore
  bool _single = false, _exitOnError = true;

  _Phase _phase = _Phase.form;
  ResponseStream<pb.DumpProgress>? _stream;
  StreamSubscription<pb.DumpProgress>? _sub;
  String _tool = '';
  int _bytes = 0, _total = 0;
  final _log = <String>[];
  final _logScroll = ScrollController();
  String? _error;
  bool _cancelled = false;

  pb.CellarClient get _api => context.read<CoreCubit>().api;

  @override
  void initState() {
    super.initState();
    _path.addListener(() => setState(() {}));
    _loadTools();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _stream?.cancel();
    super.dispose();
  }

  Future<void> _loadTools() async {
    try {
      final t = await _api.dumpTools(pb.Ref(id: widget.conn));
      if (mounted) setState(() => _tools = t);
    } catch (e) {
      if (mounted) setState(() => _toolsError = errorText(e));
    }
  }

  String get _ext => switch (_format) {
    pb.DumpRequest_Format.CUSTOM => 'dump',
    pb.DumpRequest_Format.TAR => 'tar',
    _ => 'sql',
  };

  String get _suggested {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final what = widget.tables.length == 1 ? '${widget.db}_${widget.tables.first.name}' : (widget.schemas.length == 1 ? '${widget.db}_${widget.schemas.first}' : widget.db);
    return '${what}_${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}.$_ext';
  }

  Future<void> _choose() async {
    if (widget.restore) {
      final f = await openFile(acceptedTypeGroups: const [
        XTypeGroup(label: 'dumps', extensions: ['sql', 'dump', 'backup', 'tar', 'gz', 'pgdump']),
        XTypeGroup(label: 'all'),
      ]);
      if (f != null) _path.text = f.path;
      return;
    }
    final loc = await getSaveLocation(suggestedName: _suggested);
    if (loc != null) _path.text = loc.path;
  }

  void _start() {
    setState(() {
      _phase = _Phase.running;
      _error = null;
      _log.clear();
      _bytes = _total = 0;
      _cancelled = false;
    });
    final path = _path.text.trim();
    if (widget.restore) {
      _stream = _api.restore(pb.RestoreRequest(
        connectionId: widget.conn,
        database: widget.db,
        path: path,
        clean: _clean,
        noOwner: _noOwner,
        noPrivileges: _noPrivileges,
        singleTransaction: _single,
        schemaOnly: _schemaOnly,
        dataOnly: _dataOnly,
        createDatabase: _create,
        exitOnError: _exitOnError,
        place: _place,
      ));
    } else {
      _stream = _api.dump(pb.DumpRequest(
        connectionId: widget.conn,
        database: widget.db,
        path: path,
        format: _format,
        schemas: widget.schemas,
        tables: widget.tables,
        schemaOnly: _schemaOnly,
        dataOnly: _dataOnly,
        noOwner: _noOwner,
        noPrivileges: _noPrivileges,
        clean: _clean,
        createDatabase: _create,
        inserts: _inserts,
        place: _place,
      ));
    }
    _sub = _stream!.listen(
      (p) {
        if (!mounted) return;
        setState(() {
          if (p.tool.isNotEmpty) _tool = p.tool;
          _bytes = p.bytes.toInt();
          if (p.total > 0) _total = p.total.toInt();
          _log.addAll(p.log);
          if (_log.length > 2000) _log.removeRange(0, _log.length - 2000);
          if (p.done) {
            _phase = _Phase.done;
            if (p.error.isNotEmpty) _error = p.error;
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScroll.hasClients) _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _phase = _Phase.done;
          _error = _cancelled ? tr('Cancelled', 'Отменено') : errorText(e);
        });
      },
      onDone: () {
        if (mounted && _phase == _Phase.running) setState(() => _phase = _Phase.done);
      },
    );
  }

  void _cancel() {
    _cancelled = true;
    _stream?.cancel();
  }

  @override
  Widget build(BuildContext context) => switch (_phase) {
    _Phase.form => _form(context),
    _ => _progress(context),
  };

  Widget _form(BuildContext context) {
    final mobile = Hm.of(context).mobile;
    final t = _tools;
    final scope = [
      if (widget.schemas.isNotEmpty) tr('schemas: ${widget.schemas.join(', ')}', 'схемы: ${widget.schemas.join(', ')}'),
      if (widget.tables.isNotEmpty) tr('tables: ${widget.tables.map((x) => '${x.schema}.${x.name}').join(', ')}', 'таблицы: ${widget.tables.map((x) => '${x.schema}.${x.name}').join(', ')}'),
    ];
    final remote = t?.tools.any((x) => x.place == pb.ToolPlace.REMOTE) ?? false;
    final local = t?.tools.any((x) => x.place == pb.ToolPlace.LOCAL) ?? false;
    final opts = <(String, bool, void Function(bool))>[
      ...[
        (tr('Structure only', 'Только структура'), _schemaOnly, (v) => _schemaOnly = v),
        (tr('Data only', 'Только данные'), _dataOnly, (v) => _dataOnly = v),
        (tr('No owners (--no-owner)', 'Без владельцев (--no-owner)'), _noOwner, (v) => _noOwner = v),
        (tr('No privileges (--no-privileges)', 'Без прав (--no-privileges)'), _noPrivileges, (v) => _noPrivileges = v),
        (widget.restore ? tr('Drop objects before creating them', 'Удалять объекты перед созданием') : tr('DROP … IF EXISTS before each CREATE', 'DROP … IF EXISTS перед каждым CREATE'), _clean, (v) => _clean = v),
        (widget.restore ? tr("Create the dump's database", 'Создать базу из дампа') : tr('Include CREATE DATABASE', 'Включить CREATE DATABASE'), _create, (v) => _create = v),
      ],
      if (!widget.restore) (tr('INSERT statements instead of COPY', 'INSERT вместо COPY'), _inserts, (v) => _inserts = v),
      if (widget.restore) ...[
        (tr('One transaction (all or nothing)', 'Одна транзакция (всё или ничего)'), _single, (v) => _single = v),
        (tr('Stop at the first error', 'Остановиться на первой ошибке'), _exitOnError, (v) => _exitOnError = v),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (scope.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 14), child: HmBanner(scope.join('  ·  '), tone: HmTone.info)),
        if (widget.restore) HmBanner(tr('The dump runs against ${widget.db} as it is: what it creates or drops changes this database.', 'Дамп выполняется в ${widget.db} как есть: всё, что он создаёт или удаляет, изменит эту базу.'), tone: HmTone.warning),
        if (widget.restore) const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: HmTextField(label: widget.restore ? tr('Dump file', 'Файл дампа') : tr('Save to', 'Сохранить в'), controller: _path, identifier: true, placeholder: widget.restore ? '/path/to/shop.dump' : '/path/to/$_suggested')),
          const SizedBox(width: 8),
          HmButton(tr('Choose…', 'Выбрать…'), variant: HmVariant.neutral, icon: Icons.folder_open, onPressed: _choose),
        ]),
        const SizedBox(height: 14),
        if (!widget.restore) ...[
          HmFormField(
            label: tr('Format', 'Формат'),
            hint: switch (_format) {
              pb.DumpRequest_Format.CUSTOM => tr('Compressed archive for pg_restore: restore parts of it, in any order', 'Сжатый архив для pg_restore: можно восстановить часть, в любом порядке'),
              pb.DumpRequest_Format.TAR => tr('Tar archive for pg_restore', 'Tar-архив для pg_restore'),
              _ => tr('SQL script: readable, runs in psql or a console', 'SQL-скрипт: читается глазами, выполняется в psql или консоли'),
            },
            child: HmSegmented<pb.DumpRequest_Format>(
              options: {pb.DumpRequest_Format.PLAIN: 'SQL', pb.DumpRequest_Format.CUSTOM: 'custom', pb.DumpRequest_Format.TAR: 'tar'},
              value: _format,
              onChanged: (v) => setState(() {
                _format = v;
                final p = _path.text;
                final dot = p.lastIndexOf('.');
                if (p.isNotEmpty && dot > p.lastIndexOf('/')) _path.text = '${p.substring(0, dot)}.$_ext';
              }),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (widget.restore) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(tr('Structure, data, owners and dropping apply to custom and tar archives; an SQL file runs as it is.', 'Структура, данные, владельцы и удаление — для архивов custom и tar; SQL-файл выполняется как есть.'), style: HmText.small)),
        for (final o in opts) HmCheckRow(label: o.$1, value: o.$2, onChanged: (v) => setState(() => o.$3(v))),
        const SizedBox(height: 14),
        HmFormField(
          label: tr('Run the tools', 'Где запускать'),
          hint: _toolsError ?? (t == null ? tr('Looking for pg_dump…', 'Ищем pg_dump…') : _toolsHint(t)),
          child: HmSegmented<pb.ToolPlace>(
            options: {
              pb.ToolPlace.TOOL_PLACE_UNSPECIFIED: tr('Auto', 'Авто'),
              if (local || t == null) pb.ToolPlace.LOCAL: tr('This device', 'Это устройство'),
              if (remote) pb.ToolPlace.REMOTE: tr('The server', 'Сервер'),
            },
            value: _place,
            onChanged: (v) => setState(() => _place = v),
          ),
        ),
        const SizedBox(height: 18),
        if (mobile)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            HmButton(widget.restore ? tr('Restore', 'Восстановить') : tr('Dump', 'Создать дамп'), variant: widget.restore ? HmVariant.red : HmVariant.primary, expand: true, onPressed: _path.text.trim().isEmpty ? null : _start),
            const SizedBox(height: 8),
            HmButton(tr('Close', 'Закрыть'), variant: HmVariant.neutral, expand: true, onPressed: () => Navigator.pop(context, false)),
          ])
        else
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            HmButton(tr('Close', 'Закрыть'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(context, false)),
            const SizedBox(width: 8),
            HmButton(widget.restore ? tr('Restore', 'Восстановить') : tr('Dump', 'Создать дамп'), variant: widget.restore ? HmVariant.red : HmVariant.primary, icon: widget.restore ? Icons.upload_outlined : Icons.download_outlined, onPressed: _path.text.trim().isEmpty ? null : _start),
          ]),
      ],
    );
  }

  String _toolsHint(pb.DumpToolsReply t) {
    final found = t.tools.map((x) => '${x.place == pb.ToolPlace.REMOTE ? tr('server', 'сервер') : tr('here', 'здесь')} ${x.version}${x.fits || widget.restore ? '' : ' ✕'}').join(', ');
    final head = tr('PostgreSQL ${t.serverVersion.split(' ').first}; pg_dump: ${found.isEmpty ? tr('none', 'нет') : found}', 'PostgreSQL ${t.serverVersion.split(' ').first}; pg_dump: ${found.isEmpty ? tr('none', 'нет') : found}');
    return t.note.isEmpty || widget.restore && t.tools.isNotEmpty ? head : '$head. ${t.note}';
  }

  Widget _progress(BuildContext context) {
    final running = _phase == _Phase.running;
    final ok = !running && _error == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(child: Text(_tool.isEmpty ? tr('Starting…', 'Запуск…') : _tool, style: HmText.bodyStrong)),
          Text(_total > 0 ? '${_size(_bytes)} / ${_size(_total)}' : _size(_bytes), style: HmText.jb(12, color: HmColors.muted)),
        ]),
        const SizedBox(height: 8),
        HmProgress(value: _total > 0 ? _bytes / _total : (running ? 0 : 1), color: _error != null ? HmColors.error : (ok ? HmColors.ok : HmColors.accent)),
        const SizedBox(height: 12),
        Container(
          height: 220,
          decoration: BoxDecoration(color: HmColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: HmColors.border)),
          child: ListView.builder(
            controller: _logScroll,
            padding: const EdgeInsets.all(8),
            itemCount: _log.length,
            itemBuilder: (_, i) {
              final l = _log[i];
              final bad = l.contains('ERROR') || l.contains('error:') || l.contains('FATAL');
              return Text(l, style: HmText.jb(11, color: bad ? HmColors.error : HmColors.muted), maxLines: 3, overflow: TextOverflow.ellipsis);
            },
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 12), HmBanner(_error!, tone: HmTone.error)],
        if (ok) ...[
          const SizedBox(height: 12),
          HmBanner(widget.restore ? tr('Restored into ${widget.db}.', 'Восстановлено в ${widget.db}.') : tr('Saved to ${_path.text.trim()}', 'Сохранено в ${_path.text.trim()}'), tone: HmTone.ok),
        ],
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (running)
            HmButton(tr('Cancel', 'Отменить'), variant: HmVariant.red, onPressed: _cancel)
          else ...[
            if (_error != null) ...[HmButton(tr('Back', 'Назад'), variant: HmVariant.neutral, onPressed: () => setState(() => _phase = _Phase.form)), const SizedBox(width: 8)],
            HmButton(tr('Close', 'Закрыть'), variant: HmVariant.primary, onPressed: () => Navigator.pop(context, ok && widget.restore)),
          ],
        ]),
      ],
    );
  }
}

String _size(int b) {
  if (b < 1024) return '$b B';
  if (b < 1 << 20) return '${(b / 1024).toStringAsFixed(0)} KB';
  if (b < 1 << 30) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
  return '${(b / (1 << 30)).toStringAsFixed(2)} GB';
}

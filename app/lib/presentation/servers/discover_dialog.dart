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
import 'server_dialogs.dart';

/// Looks for database services on a server and offers to connect.
Future<void> showDiscover(BuildContext context, pb.Server server) async {
  if (!await ensureConnected(context, server.id) || !context.mounted) return;
  await showHmModal<void>(context, title: '${tr('Databases on', 'Базы на')} ${server.name}', size: HmModalSize.lg, body: (_) => _Discover(server: server));
}

class _Discover extends StatefulWidget {
  const _Discover({required this.server});

  final pb.Server server;

  @override
  State<_Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<_Discover> {
  pb.DiscoverReply? _r;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _r = null;
      _error = null;
    });
    try {
      final r = await context.read<CoreCubit>().api.discover(pb.Ref(id: widget.server.id));
      if (mounted) setState(() => _r = r);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  Future<void> _add(pb.DiscoveredService s) async {
    final c = await showConnectionForm(context,
        connection: pb.Connection(
          serverId: widget.server.id,
          name: s.title.startsWith('docker: ') ? s.title.substring(8).split(' (').first : '${widget.server.name} :${s.port}',
          host: s.host,
          port: s.port,
          user: s.userHint.isEmpty ? 'postgres' : s.userHint,
          database: s.databaseHint,
          source: s.title,
          sslMode: pb.Connection_SslMode.PREFER,
        ));
    if (c != null) _run();
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) HmBanner(_error!, tone: HmTone.error),
        if (r == null && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(children: [
              const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(height: 12),
              Text(tr('Looking at processes, ports and containers…', 'Смотрю процессы, порты и контейнеры…'), style: HmText.small),
            ]),
          ),
        if (r != null) ...[
          for (final w in r.warnings) Padding(padding: const EdgeInsets.only(bottom: 8), child: HmBanner(w, tone: HmTone.warning)),
          if (r.services.isEmpty)
            HmEmptyState(tr('No PostgreSQL found on this server. You can still add a connection by hand.', 'PostgreSQL на сервере не найден. Подключение можно добавить вручную.'), icon: Icons.search_off),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final s in r.services)
                  HmListItem(
                    leading: Icon(Icons.storage_rounded, color: s.confirmed ? HmColors.accent : HmColors.muted, size: 22),
                    title: Text(s.title, style: HmText.bodyStrong),
                    subtitle: Text('${s.host}:${s.port}  ·  ${s.source}${s.detail.isEmpty ? '' : '  ·  ${s.detail}'}', style: HmText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
                    meta: s.confirmed ? HmBadge(tr('answers', 'отвечает'), tone: HmTone.ok) : HmBadge(tr('not checked', 'не проверен'), tone: HmTone.warning),
                    trailing: s.connectionId.isNotEmpty
                        ? HmBadge(tr('added', 'добавлен'), tone: HmTone.info)
                        : HmButton(tr('Connect…', 'Подключить…'), small: true, variant: HmVariant.primary, onPressed: () => _add(s)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          HmButton(tr('Add by hand…', 'Добавить вручную…'), variant: HmVariant.neutral, onPressed: () => showConnectionForm(context, connection: pb.Connection(serverId: widget.server.id, host: '127.0.0.1', port: 5432, user: 'postgres'))),
          const Spacer(),
          HmButton(tr('Search again', 'Искать снова'), variant: HmVariant.neutral, icon: Icons.refresh, onPressed: _r == null && _error == null ? null : _run),
          const SizedBox(width: 8),
          HmButton(tr('Close', 'Закрыть'), variant: HmVariant.primary, onPressed: () => Navigator.pop(context)),
        ]),
      ],
    );
  }
}

/// Adds or edits a database connection.
Future<pb.Connection?> showConnectionForm(BuildContext context, {pb.Connection? connection}) => showHmModal<pb.Connection>(
  context,
  title: connection == null || connection.id.isEmpty ? tr('New connection', 'Новое подключение') : tr('Connection', 'Подключение'),
  size: HmModalSize.lg,
  body: (_) => _ConnectionForm(c: connection ?? pb.Connection(port: 5432, user: 'postgres')),
);

class _ConnectionForm extends StatefulWidget {
  const _ConnectionForm({required this.c});

  final pb.Connection c;

  @override
  State<_ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<_ConnectionForm> {
  late final c = widget.c.deepCopy();
  late final _name = TextEditingController(text: c.name);
  late final _host = TextEditingController(text: c.host);
  late final _port = TextEditingController(text: c.port == 0 ? '' : '${c.port}');
  late final _user = TextEditingController(text: c.user);
  late final _password = TextEditingController(text: c.password);
  late final _db = TextEditingController(text: c.database);
  List<pb.Server> _servers = [];
  bool _testing = false, _saving = false;
  pb.TestReply? _test;
  String? _error;

  pb.CellarClient get _api => context.read<CoreCubit>().api;

  @override
  void initState() {
    super.initState();
    _api.listServers(pb.Empty()).then((l) {
      if (mounted) setState(() => _servers = l.servers);
    }).ignore();
  }

  pb.Connection _value() => c.deepCopy()
    ..name = _name.text.trim()
    ..host = _host.text.trim()
    ..port = int.tryParse(_port.text.trim()) ?? 0
    ..user = _user.text.trim()
    ..password = _password.text
    ..database = _db.text.trim();

  Future<void> _runTest() async {
    final v = _value();
    if (v.serverId.isNotEmpty && !await ensureConnected(context, v.serverId)) return;
    setState(() {
      _testing = true;
      _test = null;
    });
    try {
      final r = await _api.testConnection(v);
      if (mounted) setState(() => _test = r);
    } catch (e) {
      if (mounted) setState(() => _test = pb.TestReply(error: errorText(e)));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final out = await _api.saveConnection(_value());
      if (mounted) Navigator.pop(context, out);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    final servers = {'': tr('— this device (direct) —', '— это устройство (напрямую) —'), for (final s in _servers) s.id: '${s.name}  (${s.user}@${s.host})'};
    Widget pair(Widget a, Widget b) => hm.mobile
        ? Column(children: [a, const SizedBox(height: 12), b])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: a), const SizedBox(width: 12), Expanded(flex: 2, child: b)]);
    final t = _test;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HmTextField(label: tr('Name', 'Название'), controller: _name, placeholder: tr('e.g. shop (prod)', 'например shop (prod)')),
        const SizedBox(height: 14),
        HmSelect<String>(
          label: tr('Through the server', 'Через сервер'),
          options: servers,
          value: servers.containsKey(c.serverId) ? c.serverId : '',
          onChanged: (v) => setState(() => c.serverId = v),
          hint: c.serverId.isEmpty ? null : tr('The address is as seen from the server: 127.0.0.1 is the server itself.', 'Адрес — как его видит сервер: 127.0.0.1 — сам сервер.'),
        ),
        const SizedBox(height: 14),
        pair(
          HmTextField(label: tr('Host', 'Хост'), controller: _host, required: true, identifier: true),
          HmTextField(label: tr('Port', 'Порт'), controller: _port, placeholder: '5432', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
        ),
        const SizedBox(height: 14),
        pair(
          HmTextField(label: tr('User', 'Пользователь'), controller: _user, required: true, identifier: true),
          HmTextField(label: tr('Password', 'Пароль'), controller: _password, password: true),
        ),
        const SizedBox(height: 14),
        pair(
          HmTextField(label: tr('Database', 'База'), controller: _db, identifier: true, placeholder: 'postgres'),
          HmSelect<pb.Connection_SslMode>(
            label: 'SSL',
            options: {
              pb.Connection_SslMode.SSL_MODE_UNSPECIFIED: 'prefer',
              pb.Connection_SslMode.DISABLE: 'disable',
              pb.Connection_SslMode.REQUIRE: 'require',
            },
            value: c.sslMode == pb.Connection_SslMode.PREFER ? pb.Connection_SslMode.SSL_MODE_UNSPECIFIED : c.sslMode,
            onChanged: (v) => setState(() => c.sslMode = v),
          ),
        ),
        const SizedBox(height: 8),
        HmToggleRow(label: tr('Read only', 'Только чтение'), hint: tr('Sessions start with default_transaction_read_only', 'Сеансы начинаются с default_transaction_read_only'), value: c.readOnly, onChanged: (v) => setState(() => c.readOnly = v)),
        if (t != null) ...[
          const SizedBox(height: 10),
          HmBanner(t.ok ? tr('Connected: PostgreSQL ${t.serverVersion}, ${t.latencyMs} ms', 'Подключено: PostgreSQL ${t.serverVersion}, ${t.latencyMs} мс') : t.error, tone: t.ok ? HmTone.ok : HmTone.error),
        ],
        if (_error != null) ...[const SizedBox(height: 10), HmBanner(_error!, tone: HmTone.error)],
        const SizedBox(height: 18),
        Row(children: [
          HmButton(tr('Test', 'Проверить'), variant: HmVariant.neutral, icon: Icons.bolt, loading: _testing, onPressed: _testing ? null : _runTest),
          const Spacer(),
          HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          HmButton(tr('Save', 'Сохранить'), variant: HmVariant.primary, loading: _saving, onPressed: _saving ? null : _save),
        ]),
      ],
    );
  }
}

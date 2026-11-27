import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/dbm.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

/// Connects to a server, asking the user what the connection needs: to
/// trust its host key, an SSH key's passphrase. Returns whether it is
/// connected.
Future<bool> ensureConnected(BuildContext context, String serverId) async {
  final api = context.read<CoreCubit>().api;
  var passphrase = '';
  for (var attempt = 0; attempt < 6; attempt++) {
    pb.ConnectReply r;
    try {
      r = await api.connectServer(pb.ConnectRequest(id: serverId, passphrase: passphrase));
    } catch (e) {
      Toasts.error(tr('Cannot connect', 'Не удалось подключиться'), errorText(e));
      return false;
    }
    if (r.connected) return true;
    if (!context.mounted) return false;
    if (r.hasHostKey()) {
      final ok = await _trustDialog(context, r.hostKey);
      if (ok != true || !context.mounted) return false;
      try {
        await api.trustHostKey(pb.TrustRequest(id: r.hostKey.serverId, key: r.hostKey.key, replace: r.hostKey.status == pb.HostKey_Status.CHANGED));
      } catch (e) {
        Toasts.error(tr('Cannot save the host key', 'Не удалось сохранить ключ хоста'), errorText(e));
        return false;
      }
      continue;
    }
    if (r.needPassphrase) {
      final p = await _askPassphrase(context, retry: passphrase.isNotEmpty);
      if (p == null || !context.mounted) return false;
      passphrase = p;
      continue;
    }
    return false;
  }
  return false;
}

Future<bool?> _trustDialog(BuildContext context, pb.HostKey k) {
  final changed = k.status == pb.HostKey_Status.CHANGED;
  return showHmModal<bool>(
    context,
    title: changed ? tr('The host key has CHANGED', 'Ключ хоста ИЗМЕНИЛСЯ') : tr('New server', 'Новый сервер'),
    body: (_) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (changed)
          HmBanner(
            tr('The server answers with another key than the one on record. This happens after a reinstall — or when someone is in the middle. Trust it only if you know why it changed.',
                'Сервер отвечает другим ключом, чем сохранённый. Так бывает после переустановки — или при атаке «человек посередине». Доверяйте, только если знаете, почему он изменился.'),
            tone: HmTone.error,
          )
        else
          Text(tr('This is the first connection to this server. Check its fingerprint (ssh-keygen -lf /etc/ssh/ssh_host_*_key.pub on the server):', 'Это первое подключение к серверу. Сверьте отпечаток (ssh-keygen -lf /etc/ssh/ssh_host_*_key.pub на сервере):'), style: HmText.body.copyWith(height: 1.5)),
        const SizedBox(height: 14),
        HmField(tr('Type', 'Тип'), Text(k.type)),
        const SizedBox(height: 8),
        SelectableText(k.fingerprint, style: HmText.jb(13, weight: 600, color: changed ? HmColors.error : HmColors.accent)),
        const SizedBox(height: 8),
        Text(tr('The key is saved with the server and shared with your other apps and devices through CloudSync.', 'Ключ сохранится вместе с сервером и через CloudSync станет известен другим приложениям и устройствам.'), style: HmText.small),
      ],
    ),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(ctx, false)),
      HmButton(changed ? tr('Replace the key', 'Заменить ключ') : tr('Trust and connect', 'Доверять и подключиться'), variant: changed ? HmVariant.red : HmVariant.primary, onPressed: () => Navigator.pop(ctx, true)),
    ],
  );
}

Future<String?> _askPassphrase(BuildContext context, {bool retry = false}) {
  final ctl = TextEditingController();
  return showHmModal<String>(
    context,
    title: tr('Key passphrase', 'Пароль ключа'),
    size: HmModalSize.sm,
    body: (ctx) => HmTextField(
      label: tr('Passphrase', 'Пароль'),
      controller: ctl,
      password: true,
      autofocus: true,
      error: retry ? tr('Wrong passphrase', 'Неверный пароль') : null,
      hint: tr('Kept in memory until the app quits.', 'Хранится в памяти до выхода из приложения.'),
      onSubmitted: (v) => Navigator.pop(ctx, v),
    ),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(ctx)),
      HmButton(tr('Unlock', 'Открыть'), variant: HmVariant.primary, onPressed: () => Navigator.pop(ctx, ctl.text)),
    ],
  );
}

/// Adds or edits a server. Returns the saved server.
Future<pb.Server?> showServerForm(BuildContext context, {pb.Server? server, required List<pb.Server> all}) =>
    showHmModal<pb.Server>(context, title: server == null ? tr('New server', 'Новый сервер') : tr('Server', 'Сервер'), size: HmModalSize.lg, body: (_) => _ServerForm(server: server, all: all));

class _ServerForm extends StatefulWidget {
  const _ServerForm({this.server, required this.all});

  final pb.Server? server;
  final List<pb.Server> all;

  @override
  State<_ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<_ServerForm> {
  late final s = widget.server?.deepCopy() ?? pb.Server(auth: pb.Server_Auth.KEY);
  late final _name = TextEditingController(text: s.name);
  late final _group = TextEditingController(text: s.group);
  late final _host = TextEditingController(text: s.host);
  late final _port = TextEditingController(text: s.port == 0 ? '' : '${s.port}');
  late final _user = TextEditingController(text: s.user);
  late final _password = TextEditingController(text: s.password);
  late final _notes = TextEditingController(text: s.notes);
  List<pb.Key> _keys = [];
  String _safeNote = '';
  bool _saving = false;
  String? _error;

  pb.DBManagerClient get _api => context.read<CoreCubit>().api;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      final k = await _api.listKeys(pb.Empty());
      if (mounted) {
        setState(() {
          _keys = k.keys;
          _safeNote = k.safeNote;
          if (s.keyId.isEmpty && s.auth == pb.Server_Auth.KEY && _keys.isNotEmpty) s.keyId = _keys.first.id;
        });
      }
    } catch (_) {}
  }

  Future<void> _addKey() async {
    final k = await showLocalKeyForm(context);
    if (k == null || !mounted) return;
    await _loadKeys();
    setState(() => s.keyId = k.id);
  }

  Future<void> _save() async {
    final x = s.deepCopy()
      ..name = _name.text.trim()
      ..group = _group.text.trim()
      ..host = _host.text.trim()
      ..port = int.tryParse(_port.text.trim()) ?? 0
      ..user = _user.text.trim()
      ..password = _password.text
      ..notes = _notes.text;
    if (x.name.isEmpty) x.name = x.host;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final out = await _api.saveServer(x);
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
    final sync = context.read<CoreCubit>().state.sync;
    final jumps = {'': tr('— none —', '— нет —'), for (final o in widget.all.where((o) => o.id != s.id)) o.id: o.name};
    final keyOptions = {
      for (final k in _keys) k.id: '${k.local ? '🖴 ' : '☁ '}${k.title}${k.keyType.isEmpty ? '' : '  ·  ${k.keyType.replaceFirst('ssh-', '')}'}',
    };
    Widget row(List<Widget> ws) => hm.mobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final w in ws) Padding(padding: const EdgeInsets.only(bottom: 12), child: w)])
        : Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < ws.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(flex: i == 0 && ws.length > 1 ? 3 : 2, child: ws[i])],
            ]),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.shared || (s.id.isEmpty && sync.sharedServers))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: HmBanner(tr('Kept in CloudSync: the same server list is in SSH Manager and on your other devices.', 'Хранится в CloudSync: тот же список серверов есть в SSH Manager и на других устройствах.'), tone: HmTone.info),
          ),
        row([
          HmTextField(label: tr('Name', 'Название'), controller: _name, autofocus: s.id.isEmpty, placeholder: 'prod-db-1'),
          HmTextField(label: tr('Folder', 'Папка'), controller: _group, placeholder: 'prod/eu', identifier: true),
        ]),
        row([
          HmTextField(label: tr('Address', 'Адрес'), controller: _host, required: true, identifier: true, placeholder: 'db.example.com'),
          HmTextField(label: tr('SSH port', 'SSH-порт'), controller: _port, placeholder: '22', keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
        ]),
        row([HmTextField(label: tr('User', 'Пользователь'), controller: _user, required: true, identifier: true, placeholder: 'deploy')]),
        HmFormField(
          label: tr('Log in with', 'Вход'),
          child: HmSegmented<pb.Server_Auth>(
            options: {pb.Server_Auth.KEY: tr('SSH key', 'SSH-ключ'), pb.Server_Auth.PASSWORD: tr('Password', 'Пароль'), pb.Server_Auth.AGENT: 'ssh-agent'},
            value: s.auth == pb.Server_Auth.AUTH_UNSPECIFIED ? pb.Server_Auth.PASSWORD : s.auth,
            onChanged: (v) => setState(() => s.auth = v),
          ),
        ),
        const SizedBox(height: 14),
        if (s.auth == pb.Server_Auth.KEY) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: HmSelect<String>(
                label: tr('Key', 'Ключ'),
                options: keyOptions,
                value: keyOptions.containsKey(s.keyId) ? s.keyId : null,
                placeholder: _keys.isEmpty ? tr('No keys yet', 'Ключей пока нет') : tr('Choose a key', 'Выберите ключ'),
                onChanged: (v) => setState(() => s.keyId = v),
                hint: _safeNote.isNotEmpty ? _safeNote : tr('☁ — from the CloudSync safe, 🖴 — on this device only', '☁ — из сейфа CloudSync, 🖴 — только на этом устройстве'),
              ),
            ),
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(bottom: 22), child: HmButton(tr('Add key…', 'Добавить ключ…'), variant: HmVariant.neutral, icon: Icons.vpn_key_outlined, onPressed: _addKey)),
          ]),
          const SizedBox(height: 14),
        ],
        if (s.auth == pb.Server_Auth.PASSWORD) ...[
          HmTextField(label: tr('Password', 'Пароль'), controller: _password, password: true),
          const SizedBox(height: 14),
        ],
        if (s.auth == pb.Server_Auth.AGENT) ...[
          Text(tr('Keys of the ssh-agent of this computer (\$SSH_AUTH_SOCK).', 'Ключи ssh-agent этого компьютера (\$SSH_AUTH_SOCK).'), style: HmText.small),
          const SizedBox(height: 14),
        ],
        HmSelect<String>(label: tr('Jump server', 'Через сервер (jump)'), options: jumps, value: s.jumpServerId, onChanged: (v) => setState(() => s.jumpServerId = v)),
        const SizedBox(height: 14),
        HmTextField(label: tr('Notes', 'Заметки'), controller: _notes, lines: 2),
        if (s.hostKeys.isNotEmpty) ...[
          const SizedBox(height: 14),
          HmField(tr('Trusted host keys', 'Доверенные ключи хоста'), Text(s.hostKeys.map((k) => k.split(' ').first).join(', '))),
        ],
        if (_error != null) ...[const SizedBox(height: 14), HmBanner(_error!, tone: HmTone.error)],
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 8),
          HmButton(tr('Save', 'Сохранить'), variant: HmVariant.primary, loading: _saving, onPressed: _saving ? null : _save),
        ]),
      ],
    );
  }
}

/// Adds a private key kept on this device only.
Future<pb.Key?> showLocalKeyForm(BuildContext context) {
  final title = TextEditingController();
  final key = TextEditingController();
  final pass = TextEditingController();
  String? error;
  return showHmModal<pb.Key>(
    context,
    title: tr('Add an SSH key', 'Добавить SSH-ключ'),
    size: HmModalSize.lg,
    body: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          HmBanner(tr('The key stays on this device. To use it on your other devices too, put it into the CloudSync safe instead.', 'Ключ останется только на этом устройстве. Чтобы он был и на других устройствах, положите его в сейф CloudSync.'), tone: HmTone.info),
          const SizedBox(height: 14),
          HmTextField(label: tr('Title', 'Название'), controller: title, placeholder: 'laptop ed25519'),
          const SizedBox(height: 14),
          HmTextField(label: tr('Private key', 'Приватный ключ'), controller: key, lines: 6, identifier: true, placeholder: '-----BEGIN OPENSSH PRIVATE KEY-----'),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: HmButton(tr('Load from a file…', 'Загрузить из файла…'), small: true, variant: HmVariant.neutral, icon: Icons.folder_open, onPressed: () async {
                final f = await openFile();
                if (f == null) return;
                key.text = await f.readAsString();
                if (title.text.isEmpty) title.text = f.name;
                set(() {});
              }),
            ),
          ),
          const SizedBox(height: 14),
          HmTextField(label: tr('Passphrase', 'Пароль ключа'), controller: pass, password: true, hint: tr('Empty: asked at every connection.', 'Пусто — будет спрашиваться при подключении.')),
          if (error != null) ...[const SizedBox(height: 12), HmBanner(error!, tone: HmTone.error)],
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            HmButton(tr('Add', 'Добавить'), variant: HmVariant.primary, onPressed: () async {
              try {
                final k = await ctx.read<CoreCubit>().api.saveLocalKey(pb.LocalKey(title: title.text, privateKey: key.text, passphrase: pass.text));
                if (ctx.mounted) Navigator.pop(ctx, k);
              } catch (e) {
                set(() => error = errorText(e));
              }
            }),
          ]),
        ],
      ),
    ),
  );
}

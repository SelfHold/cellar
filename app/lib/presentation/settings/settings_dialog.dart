import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/rpc/core_client.dart';
import '../../data/rpc/gen/dbm.pbgrpc.dart' as pb;
import '../common/hm.dart';
import '../core/core_cubit.dart';

Future<void> showSettings(BuildContext context) => showHmModal<void>(
  context,
  title: tr('Settings', 'Настройки'),
  size: HmModalSize.lg,
  body: (_) => const _Settings(),
  actions: (ctx) => [HmButton(tr('Close', 'Закрыть'), variant: HmVariant.primary, onPressed: () => Navigator.pop(ctx))],
);

class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _busy = false;

  Future<void> _call(Future<pb.SyncState> Function(pb.DBManagerClient api) f, {String? done}) async {
    final core = context.read<CoreCubit>();
    setState(() => _busy = true);
    try {
      core.adoptSync(await f(core.api));
      if (done != null) Toasts.success(done);
    } catch (e) {
      Toasts.error(tr('CloudSync', 'CloudSync'), errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _phase(pb.SyncState s) => switch (s.phase) {
    pb.SyncState_Phase.OFF => tr('Off: this device keeps its own list', 'Выключена: список хранится только на этом устройстве'),
    pb.SyncState_Phase.NOT_RUNNING => tr('CloudSync is not running on this device', 'CloudSync не запущен на этом устройстве'),
    pb.SyncState_Phase.NO_VAULT => tr('CloudSync is not set up yet', 'CloudSync ещё не настроен'),
    pb.SyncState_Phase.LOCKED => tr('CloudSync is locked: unlock it', 'CloudSync заблокирован: разблокируйте его'),
    pb.SyncState_Phase.PAIRING => tr('Waiting for your answer in CloudSync', 'Ждём подтверждения в CloudSync'),
    pb.SyncState_Phase.OFFLINE => tr('Offline: changes wait for a storage', 'Нет связи с хранилищем: изменения ждут'),
    pb.SyncState_Phase.SYNCED => tr('Synced', 'Синхронизировано'),
    pb.SyncState_Phase.ERROR => tr('Error', 'Ошибка'),
    _ => '—',
  };

  @override
  Widget build(BuildContext context) => BlocBuilder<CoreCubit, CoreState>(
    builder: (context, cs) {
      final s = cs.sync;
      final st = cs.state;
      final ok = s.phase == pb.SyncState_Phase.SYNCED;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const HmSectionTitle('CLOUDSYNC'),
          const SizedBox(height: 10),
          Row(children: [
            HmDot(ok: ok),
            const SizedBox(width: 8),
            Expanded(child: Text(_phase(s), style: HmText.bodyStrong)),
            if (s.lastSyncMs > 0) Text(DateFormat.yMd().add_Hm().format(DateTime.fromMillisecondsSinceEpoch(s.lastSyncMs.toInt())), style: HmText.small),
          ]),
          const SizedBox(height: 8),
          Text(
            tr('With sync on, servers and connections are the same on all your devices; servers and SSH keys come from CloudSync itself and are shared with SSH Manager.',
                'С синхронизацией серверы и подключения одинаковы на всех ваших устройствах; серверы и SSH-ключи берутся из самого CloudSync и общие с SSH Manager.'),
            style: HmText.small.copyWith(height: 1.5),
          ),
          if (s.pairingCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            HmCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text(s.pairingCode, style: HmText.syne(26, weight: 800, color: HmColors.accent, spacing: 2)),
                const SizedBox(width: 16),
                Expanded(child: Text(tr('Confirm this code in CloudSync to let DB Manager in.', 'Подтвердите этот код в CloudSync, чтобы пустить DB Manager.'), style: HmText.body)),
              ]),
            ),
          ],
          if (s.error.isNotEmpty) ...[const SizedBox(height: 12), HmBanner(s.error, tone: s.phase == pb.SyncState_Phase.ERROR ? HmTone.error : HmTone.warning)],
          if (s.enabled) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 6, children: [
              HmBadge(s.sharedServers ? tr('shared servers: on', 'общие серверы: да') : tr('shared servers: not granted', 'общие серверы: нет доступа'), tone: s.sharedServers ? HmTone.ok : HmTone.warning),
              HmBadge(s.safeKeys ? tr('safe SSH keys: on', 'ключи из сейфа: да') : tr('safe SSH keys: not granted', 'ключи из сейфа: нет доступа'), tone: s.safeKeys ? HmTone.ok : HmTone.warning),
              if (s.pending) HmBadge(tr('changes waiting', 'есть неотправленные изменения'), tone: HmTone.warning),
              if (s.deviceName.isNotEmpty) HmBadge(s.deviceName),
            ]),
          ],
          if (s.ownServers > 0) ...[
            const SizedBox(height: 12),
            HmBanner(
              tr('${s.ownServers} servers are still kept by DB Manager alone. Move them into CloudSync so SSH Manager and your other devices see them.',
                  'Серверов только в DB Manager: ${s.ownServers}. Перенесите их в CloudSync, чтобы их видели SSH Manager и другие устройства.'),
              action: HmButton(tr('Move', 'Перенести'), small: true, variant: HmVariant.primary, onPressed: _busy ? null : () => _call((a) => a.moveServersToCloudSync(pb.Empty()), done: tr('Servers moved', 'Серверы перенесены'))),
            ),
          ],
          const SizedBox(height: 14),
          Row(children: [
            if (!s.enabled && s.phase != pb.SyncState_Phase.PAIRING)
              HmButton(tr('Sync via CloudSync', 'Синхронизировать через CloudSync'), variant: HmVariant.primary, icon: Icons.cloud_sync_outlined, loading: _busy, onPressed: _busy || st == null ? null : () => _call((a) => a.enableSync(pb.Empty())))
            else ...[
              HmButton(tr('Sync now', 'Синхронизировать'), variant: HmVariant.cyan, icon: Icons.sync, onPressed: _busy ? null : () => _call((a) => a.syncNow(pb.Empty()))),
              const SizedBox(width: 8),
              if (s.enabled && (!s.sharedServers || !s.safeKeys))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: HmButton(tr('Ask for access again', 'Запросить доступ снова'), variant: HmVariant.neutral, onPressed: _busy ? null : () => _call((a) => a.enableSync(pb.Empty()))),
                ),
              HmButton(tr('Turn off', 'Выключить'), variant: HmVariant.red, onPressed: _busy
                  ? null
                  : () async {
                      if (await confirm(context,
                          title: tr('Turn sync off?', 'Выключить синхронизацию?'),
                          message: tr('This device keeps its connections. The shared servers stay in CloudSync, but DB Manager stops seeing them here.', 'Подключения на этом устройстве останутся. Общие серверы останутся в CloudSync, но DB Manager перестанет их здесь видеть.'),
                          action: tr('Turn off', 'Выключить'),
                          destructive: true)) {
                        _call((a) => a.disableSync(pb.Empty()));
                      }
                    }),
            ],
          ]),
          const SizedBox(height: 24),
          const HmSectionTitle('APP'),
          const SizedBox(height: 10),
          HmFormField(
            label: tr('Language', 'Язык'),
            child: HmSegmented<Lang>(options: const {Lang.en: 'English', Lang.ru: 'Русский'}, value: lang.value, onChanged: (l) => setState(() => AppSettings.instance.language = l)),
          ),
          const SizedBox(height: 12),
          HmFormField(
            label: tr('Rows per page in the data viewer', 'Строк на странице таблицы'),
            child: HmSegmented<int>(options: const {100: '100', 500: '500', 1000: '1000', 5000: '5000'}, value: AppSettings.instance.pageSize, onChanged: (v) => setState(() => AppSettings.instance.pageSize = v)),
          ),
          const SizedBox(height: 12),
          HmToggleRow(
            label: tr('Show system schemas', 'Показывать системные схемы'),
            hint: 'pg_catalog, information_schema, pg_toast',
            value: AppSettings.instance.showSystemSchemas,
            onChanged: (v) => setState(() => AppSettings.instance.showSystemSchemas = v),
          ),
          const SizedBox(height: 16),
          Text(
            'DB Manager ${st?.coreVersion ?? ''} (${st?.coreBuild ?? ''}) · ${st?.platform ?? ''}'
            '${st != null && !st.keychain ? ' · ${tr('no keychain: the local key is a file', 'нет keychain: локальный ключ хранится файлом')}' : ''}',
            style: HmText.footer,
          ),
        ],
      );
    },
  );
}

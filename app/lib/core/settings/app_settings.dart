import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../i18n.dart';

/// Preferences of this device (not synced): `<config dir>/dbmanager/app.json`
/// on desktops, app support on Android. Holds the UI language (`lang`).
class AppSettings extends ChangeNotifier {
  AppSettings._(this._file);

  final File? _file;
  int _pageSize = 500;
  int _maxRows = 1000;
  bool _showSystemSchemas = false;
  double _explorerWidth = 320;

  static AppSettings? _instance;
  static AppSettings get instance => _instance ??= AppSettings._(null);

  /// Rows per page in the data viewer.
  int get pageSize => _pageSize;

  /// Rows kept per result in a console.
  int get maxRows => _maxRows;

  /// pg_catalog, information_schema in the tree.
  bool get showSystemSchemas => _showSystemSchemas;

  double get explorerWidth => _explorerWidth;

  static Future<void> load() async {
    File file;
    if (Platform.isAndroid) {
      file = File(p.join((await getApplicationSupportDirectory()).path, 'app.json'));
    } else {
      final xdg = Platform.environment['XDG_CONFIG_HOME'];
      final home = Platform.environment['HOME'] ?? '.';
      final base = Platform.isWindows ? (Platform.environment['APPDATA'] ?? '.') : (xdg != null && xdg.isNotEmpty ? xdg : p.join(home, '.config'));
      file = File(p.join(base, 'dbmanager', 'app.json'));
    }
    final s = AppSettings._(file);
    // English on every start unless the user picked Russian in settings:
    // the system locale is never consulted.
    lang.value = Lang.en;
    try {
      final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (m['lang'] == 'ru') lang.value = Lang.ru;
      if (m['lang'] == 'en') lang.value = Lang.en;
      s._pageSize = (m['page_size'] as int?) ?? 500;
      s._maxRows = (m['max_rows'] as int?) ?? 1000;
      s._showSystemSchemas = (m['system_schemas'] as bool?) ?? false;
      s._explorerWidth = ((m['explorer_width'] as num?) ?? 320).toDouble();
    } catch (_) {}
    _instance = s;
  }

  Future<void> _save() async {
    notifyListeners();
    final f = _file;
    if (f == null) return;
    try {
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode({
        'lang': lang.value.name,
        'page_size': _pageSize,
        'max_rows': _maxRows,
        'system_schemas': _showSystemSchemas,
        'explorer_width': _explorerWidth,
      }));
    } catch (e) {
      debugPrint('settings: $e');
    }
  }

  set language(Lang l) {
    lang.value = l;
    _save();
  }

  set pageSize(int v) {
    _pageSize = v;
    _save();
  }

  set maxRows(int v) {
    _maxRows = v;
    _save();
  }

  set showSystemSchemas(bool v) {
    _showSystemSchemas = v;
    _save();
  }

  set explorerWidth(double v) {
    _explorerWidth = v;
    _save();
  }
}

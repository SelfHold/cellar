import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/settings/app_settings.dart';
import 'data/rpc/endpoint.dart';
import 'data/rpc/native_core.dart';
import 'presentation/core/core_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(420, 560));
    windowManager.addListener(_Quit());
    await windowManager.setPreventClose(true);
  }
  final core = CoreCubit(CoreLauncher.forPlatform())..connect();
  runApp(DbManagerApp(core: core));
}

/// Closing the window stops the core (sessions, SSH connections) first.
class _Quit with WindowListener {
  @override
  Future<void> onWindowClose() async {
    await windowManager.hide();
    NativeCore.stop();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}

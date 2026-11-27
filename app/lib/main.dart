import 'package:flutter/material.dart';

import 'app.dart';
import 'core/desktop/desktop_window.dart';
import 'core/settings/app_settings.dart';
import 'data/rpc/endpoint.dart';
import 'presentation/core/core_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  await DesktopWindow.instance.init();
  final core = CoreCubit(CoreLauncher.forPlatform())..connect();
  runApp(CellarApp(core: core));
}

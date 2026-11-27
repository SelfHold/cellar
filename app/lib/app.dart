import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/i18n.dart';
import 'core/theme/app_theme.dart';
import 'presentation/common/overlays.dart';
import 'presentation/core/core_cubit.dart';
import 'presentation/shell/app_shell.dart';

class CellarApp extends StatefulWidget {
  const CellarApp({super.key, required this.core});

  final CoreCubit core;

  @override
  State<CellarApp> createState() => _CellarAppState();
}

class _CellarAppState extends State<CellarApp> {
  @override
  void initState() {
    super.initState();
    lang.addListener(_relabel);
  }

  @override
  void dispose() {
    lang.removeListener(_relabel);
    super.dispose();
  }

  /// Strings come from tr() in build methods: a language switch rebuilds
  /// every element, state is kept.
  void _relabel() {
    setState(() {});
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.core,
    child: MaterialApp(
      title: 'Cellar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: currentLocale,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AppShell(),
      builder: (context, child) => Stack(children: [?child, const ToastHost(bottomOffset: 24)]),
    ),
  );
}

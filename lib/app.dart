import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'features/auth/providers.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => buildRouter(
    auth: ref.watch(authRepoProvider),
    demo: Env.isDemo,
    refresh: ref.watch(authListenableProvider),
  ),
);

class PendiApp extends ConsumerWidget {
  const PendiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Pendi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

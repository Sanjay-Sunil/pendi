import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';
import 'theme/theme_toggle.dart';

class PendiApp extends ConsumerWidget {
  const PendiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Pendi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('pendi'),
              FilledButton(onPressed: () {}, child: const Text('Demo button')),
              const ThemeToggle(),
            ],
          ),
        ),
      ),
    );
  }
}

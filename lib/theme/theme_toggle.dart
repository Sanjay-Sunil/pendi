import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme_mode_provider.dart';
import 'tokens.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final next = brightness == Brightness.dark ? 'light' : 'dark';
    return IconButton(
      tooltip: 'Switch to $next theme',
      color: context.colors.muted,
      icon: Icon(
        brightness == Brightness.dark ? LucideIcons.sun : LucideIcons.moon,
        size: 18,
      ),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(brightness),
    );
  }
}

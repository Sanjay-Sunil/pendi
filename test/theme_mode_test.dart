import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/theme/theme_mode_provider.dart';

import 'helpers/pump.dart';

void main() {
  test('persists the chosen theme mode', () async {
    final prefs = await testPrefs();
    final c = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.dark);
    await c.read(themeModeProvider.notifier).toggle(Brightness.dark);
    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/app.dart';
import 'package:pendi/core/env.dart';
import 'package:pendi/theme/theme_mode_provider.dart';
import 'package:pendi/theme/tokens.dart';

import 'helpers/pump.dart';

void main() {
  test('runs in demo mode without env', () {
    expect(Env.isDemo, isTrue);
    expect(Env.appTimezone, 'Asia/Kolkata');
  });

  testWidgets('defaults to dark and toggles to light, persisting the choice', (
    tester,
  ) async {
    final prefs = await testPrefs();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const PendiApp(),
      ),
    );
    BuildContext ctx() => tester.element(find.text('pendi'));
    expect(ctx().colors.bg, PendiColors.dark.bg);
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(ctx().colors.bg, PendiColors.light.bg);
    expect(prefs.getString('theme_mode'), 'light');
  });

  testWidgets('restores the saved theme', (tester) async {
    final prefs = await testPrefs({'theme_mode': 'light'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const PendiApp(),
      ),
    );
    expect(
      tester.element(find.text('pendi')).colors.accent,
      PendiColors.light.accent,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/core/env.dart';
import 'package:pendi/theme/tokens.dart';

import 'helpers/pump_app.dart';

void main() {
  test('runs in demo mode without env', () {
    expect(Env.isDemo, isTrue);
    expect(Env.appTimezone, 'Asia/Kolkata');
  });

  BuildContext ctx(WidgetTester t) => t.element(find.byType(NavigationRail));

  testWidgets('dark theme toggles to light', (tester) async {
    await pumpApp(tester, width: 1280);
    expect(ctx(tester).colors.bg, PendiColors.dark.bg);
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(ctx(tester).colors.bg, PendiColors.light.bg);
  });

  testWidgets('restores the saved theme', (tester) async {
    await pumpApp(tester, width: 1280, theme: 'light');
    expect(ctx(tester).colors.accent, PendiColors.light.accent);
  });
}

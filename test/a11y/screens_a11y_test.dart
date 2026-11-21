import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/a11y.dart';
import '../helpers/pump_app.dart';

/// Flutter's accessibility guidelines (48px tap targets, labelled targets, AA
/// text contrast) on every main screen, in both themes, at phone width.
void main() {
  const routes = [
    '/today',
    '/reading',
    '/cp',
    '/work',
    '/college',
    '/inbox',
    '/settings',
  ];
  for (final theme in ['dark', 'light']) {
    for (final route in routes) {
      testWidgets('$route meets guidelines ($theme)', (tester) async {
        await pumpApp(tester, location: route, theme: theme, height: 1600);
        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
      });
    }
    testWidgets('research tab meets guidelines ($theme)', (tester) async {
      await pumpApp(tester, location: '/work', theme: theme, height: 2400);
      await tester.tap(find.text('Research'));
      await tester.pumpAndSettle();
      await expectAccessible(tester);
    });
  }

  testWidgets('wide layout renders every tab without overflow', (tester) async {
    for (final route in routes) {
      await pumpApp(tester, location: route, width: 1280, height: 1000);
      expect(tester.takeException(), isNull, reason: route);
    }
    await pumpApp(tester, width: 1280, height: 1000);
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}

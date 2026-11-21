import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('bottom bar on phones switches between all five tabs', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final tab in ['Reading', 'CP', 'Work', 'College', 'Today']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('rail on wide screens', (tester) async {
    await pumpApp(tester, width: 1280, theme: 'light');
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('CP'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Practice'.toUpperCase()), findsOneWidget);
  });

  testWidgets('root redirects to today', (tester) async {
    await pumpApp(tester, location: '/');
    expect(find.text('DAILY'), findsOneWidget);
  });
}

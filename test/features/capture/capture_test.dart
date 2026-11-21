import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<void> captureText(WidgetTester tester, String text) async {
  await tester.tap(find.byTooltip('Quick capture'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('capture-field')), text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
}

void main() {
  for (final tab in ['/today', '/reading', '/cp', '/work', '/college']) {
    testWidgets('capture button is on $tab', (tester) async {
      await pumpApp(tester, location: tab);
      expect(find.byTooltip('Quick capture'), findsOneWidget);
    });
  }

  testWidgets('r: creates a research task that shows on Today', (tester) async {
    await pumpApp(tester, location: '/cp', height: 2400);
    await captureText(tester, 'r: Email sir the ablation table');
    expect(find.text('Research task added'), findsOneWidget);
    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Research'));
    await tester.pumpAndSettle();
    expect(find.text('Email sir the ablation table'), findsOneWidget);
  });

  testWidgets('plain text goes to the inbox and can be triaged', (
    tester,
  ) async {
    await pumpApp(tester, height: 2400);
    await captureText(tester, 'Buy lab record');
    expect(find.text('INBOX · 1'), findsOneWidget);
    await tester.tap(find.text('INBOX · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Buy lab record'), findsOneWidget);
    await tester.tap(find.byTooltip('Triage Buy lab record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark done'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox zero.'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pendi/app.dart';
import 'package:pendi/domain/dates.dart';
import 'package:pendi/features/reading/widgets/source_card.dart';
import 'package:pendi/theme/theme_mode_provider.dart';
import 'package:pendi/ui/app_checkbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three smoke flows from plan.md, run against the real app in demo mode.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launch(WidgetTester tester) async {
    initTimezones();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const PendiApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  /// Pumps real frames until [finder] matches (network calls take real time).
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int seconds = 15,
  }) async {
    for (var i = 0; i < seconds * 10; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> tab(WidgetTester tester, String name) async {
    final inBar = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(name),
    );
    final inRail = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.text(name),
    );
    await tester.tap(inBar.evaluate().isNotEmpty ? inBar : inRail);
    await tester.pumpAndSettle();
  }

  testWidgets('1. add a reading source and complete a page', (tester) async {
    await launch(tester);
    await tab(tester, 'Reading');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'https://example.com/');
    await tester.enterText(fields.at(1), 'Example post');
    await tester.enterText(fields.at(2), '1');
    await tester.tap(find.text('Find pages'));
    final add = find.textContaining(RegExp(r'^Add \d+ pages$'));
    await pumpUntil(tester, add);
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
    final box = find.descendant(
      of: find
          .ancestor(
            of: find.text('Example post'),
            matching: find.byType(SourceCard),
          )
          .first,
      matching: find.byType(AppCheckbox),
    );
    await tester.ensureVisible(find.text('Example post'));
    await tester.pumpAndSettle();
    await tester.tap(box.first);
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^1/\d+ read')), findsWidgets);
  });

  testWidgets('2. mark a CP problem solved', (tester) async {
    await launch(tester);
    await tab(tester, 'CP');
    await tester.tap(find.text('Solved').first);
    await tester.pumpAndSettle();
    expect(find.text('solved'), findsOneWidget);
  });

  testWidgets('3. quick-capture a research task and see it on Today', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byTooltip('Quick capture'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('capture-field')),
      'r: Mail sir the plots',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Mail sir the plots · Research'), findsOneWidget);
  });
}

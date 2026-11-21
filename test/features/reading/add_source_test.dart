import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/integrations/sitemap.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('seeds both default sources with today quotas', (tester) async {
    await pumpApp(tester, location: '/reading', overrides: testOverrides());
    expect(find.text('Designed to Scale'), findsOneWidget);
    expect(find.text('Saadho'), findsOneWidget);
    expect(find.text('2 pages today'), findsOneWidget); // 40 over 30 days
    expect(find.text('5 pages today'), findsOneWidget); // 141 over 30 days
  });

  testWidgets('adds a link with only the picked pages', (tester) async {
    final extractor = FakeExtractor([
      for (var i = 0; i < 5; i++) (title: 'Page $i', url: 'https://b.dev/$i'),
    ]);
    await pumpApp(
      tester,
      location: '/reading',
      height: 1400,
      overrides: testOverrides(extractor: extractor),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'https://b.dev/');
    await tester.enterText(find.byType(TextField).at(1), 'My blog');
    await tester.enterText(find.byType(TextField).at(2), '4');
    await tester.tap(find.text('Find pages'));
    await tester.pumpAndSettle();
    for (final p in ['Page 3', 'Page 4']) {
      await tester.ensureVisible(find.text(p));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p));
      await tester.pump();
    }
    expect(find.text('Add 3 pages'), findsOneWidget);
    await tester.ensureVisible(find.text('Add 3 pages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 3 pages'));
    await tester.pumpAndSettle();
    expect(find.text('My blog'), findsOneWidget);
    expect(find.text('1 page today'), findsOneWidget); // 3 over 4 days
    expect(find.text('Added 3 pages'), findsOneWidget);
  });

  testWidgets('falls back to a single page when extraction finds nothing', (
    tester,
  ) async {
    final extractor = FakeExtractor(
      const [],
      error: const ExtractError(
        'No pages found on that link',
        ExtractErrorCode.empty,
      ),
    );
    await pumpApp(
      tester,
      location: '/reading',
      overrides: testOverrides(extractor: extractor),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'https://spa.dev/');
    await tester.tap(find.text('Find pages'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Added the link as a single page'),
      findsOneWidget,
    );
    expect(find.text('Add 1 pages'), findsOneWidget);
  });
}

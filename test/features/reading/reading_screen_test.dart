import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/features/reading/providers.dart';
import 'package:pendi/ui/app_checkbox.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('progress and tomorrow quota follow completions across days', () async {
    var now = DateTime.utc(2026, 3, 1, 4); // 1 Mar, 09:30 IST
    final db = DemoDb();
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        dbProvider.overrideWith((ref) async => db),
      ],
    );
    addTearDown(c.dispose);
    final repo = await c.read(readingRepoProvider.future);
    await repo.createSource(
      title: 'R',
      url: 'https://r.dev/',
      kind: 'course',
      startDate: '2026-03-01',
      targetDays: 5,
      pages: [
        for (var i = 0; i < 10; i++) (title: 'P$i', url: 'https://r.dev/$i'),
      ],
    );

    var [o] = await c.read(readingOverviewProvider.future);
    expect(o.plan.quota, 2);
    for (final p in o.plan.items) {
      await repo.setDone(p.item.id, true);
    }
    await repo.setDone((await repo.items())[2].id, true); // one extra
    c.invalidate(readingOverviewProvider);
    [o] = await c.read(readingOverviewProvider.future);
    expect(o.done, 3);
    expect(o.plan.items.map((p) => p.item.title), ['P0', 'P1']);

    now = DateTime.utc(2026, 3, 2, 4);
    c.invalidate(readingOverviewProvider);
    [o] = await c.read(readingOverviewProvider.future);
    expect(o.plan.quota, 2); // 7 left over 4 days
    expect(o.plan.items.map((p) => p.item.title), ['P3', 'P4']);

    now = DateTime.utc(2026, 3, 4, 4); // skipped two days
    c.invalidate(readingOverviewProvider);
    [o] = await c.read(readingOverviewProvider.future);
    expect(o.plan.quota, 4);
    expect(o.plan.items.where((p) => p.carriedOver), hasLength(3));
  });

  testWidgets('ticking a page updates progress and offers a note', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/reading',
      height: 1600,
      overrides: testOverrides(),
    );
    expect(find.text('0/40 read · 30 days left'), findsOneWidget);
    await tester.tap(find.byType(AppCheckbox).first);
    await tester.pumpAndSettle();
    expect(find.text('1/40 read · 30 days left'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'DNS → LB → app');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.text('DNS → LB → app'), findsOneWidget);
  });

  for (final theme in ['dark', 'light']) {
    testWidgets('reading screen is accessible ($theme)', (tester) async {
      await pumpApp(
        tester,
        location: '/reading',
        theme: theme,
        overrides: testOverrides(),
      );
      await expectAccessible(tester);
    });
  }
}

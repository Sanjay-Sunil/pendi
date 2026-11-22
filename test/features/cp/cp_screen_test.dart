import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/cp_repo.dart';
import 'package:pendi/domain/cp.dart';
import 'package:pendi/domain/cp_import.dart';
import 'package:pendi/ui/streak_flame.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('daily picks persist; review comes first the next day; streak counts solves', () async {
    var now = DateTime.utc(2026, 3, 1, 4);
    final repo = CpRepo(DemoDb(), now: () => now);
    await repo.createList(
      'L',
      parseProblemList('4A\n71A\n231A\n158A').problems,
    );
    final d1 = await repo.daily('2026-03-01');
    expect(d1.map((p) => p.key), ['4A', '71A']);
    await repo.setStatus(d1[0].id, CpStatus.solved);
    await repo.setStatus(d1[1].id, CpStatus.review);
    expect((await repo.daily('2026-03-01')).map((p) => p.key), [
      '4A',
      '71A',
    ]); // stable
    expect(await repo.streakAsOf('2026-03-01'), 1);

    now = DateTime.utc(2026, 3, 2, 4);
    expect((await repo.daily('2026-03-02')).map((p) => p.key), ['71A', '231A']);
    expect(await repo.streakAsOf('2026-03-02'), 1); // yesterday still counts
    expect(await repo.streakAsOf('2026-03-03'), 0);
  });

  testWidgets('marking solved updates the streak and keeps the same two', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/cp',
      height: 1600,
      overrides: testOverrides(),
    );
    expect(find.text('4A · Watermelon'), findsOneWidget);
    expect(find.text('71A · Way Too Long Words'), findsOneWidget);
    expect(tester.widget<StreakFlame>(find.byType(StreakFlame)).days, 0);
    await tester.tap(find.text('Solved').first);
    await tester.pumpAndSettle();
    expect(tester.widget<StreakFlame>(find.byType(StreakFlame)).days, 1);
    expect(find.text('4A · Watermelon'), findsOneWidget);
    expect(find.text('solved'), findsOneWidget);
  });

  testWidgets('sync without a handle asks for one', (tester) async {
    await pumpApp(
      tester,
      location: '/cp',
      height: 1600,
      overrides: testOverrides(),
    );
    expect(find.text('Codeforces handle'), findsOneWidget);
  });

  testWidgets('cp screen is accessible', (tester) async {
    await pumpApp(tester, location: '/cp', overrides: testOverrides());
    await expectAccessible(tester);
  });

  test('saved daily picks come back in list order', () async {
    final db = DemoDb();
    final repo = CpRepo(db);
    await repo.createList('L', parseProblemList('4A\n71A\n231A').problems);
    final picks = await repo.daily('2026-03-01');
    // Simulate Postgres returning rows reversed.
    final rows = await db.list('cp_daily');
    for (final r in rows) {
      await db.remove('cp_daily', r['id']! as String);
    }
    for (final r in rows.reversed) {
      await db.insert('cp_daily', [
        {'day': r['day'], 'problem_id': r['problem_id']},
      ]);
    }
    expect(
      (await repo.daily('2026-03-01')).map((p) => p.key),
      picks.map((p) => p.key),
    );
  });
}

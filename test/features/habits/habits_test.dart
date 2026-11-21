import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/habit_repo.dart';
import 'package:pendi/features/habits/habits_section.dart';
import 'package:pendi/ui/app_checkbox.dart';
import 'package:pendi/ui/streak_flame.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('logging is idempotent; streak and week dots follow logs', () async {
    final repo = HabitRepo(DemoDb());
    final h = (await repo.add('Workout')).valueOrNull!;
    for (final d in ['2026-11-19', '2026-11-20', '2026-11-21', '2026-11-21']) {
      await repo.setDone(h.id, d, true);
    }
    var w = (await repo.all()).single;
    expect(w.days, hasLength(3));
    expect(w.streakAsOf('2026-11-21'), 3);
    expect(w.week('2026-11-21'), [
      false,
      false,
      false,
      true,
      true,
      true,
      false,
    ]);
    await repo.setDone(h.id, '2026-11-20', false);
    w = (await repo.all()).single;
    expect(w.streakAsOf('2026-11-21'), 1);
    expect((await repo.add('x', targetPerWeek: 9)).isOk, isFalse);
  });

  testWidgets('one tap on Today logs a habit optimistically', (tester) async {
    await pumpApp(tester, height: 2600);
    final row = find.widgetWithText(AppCheckbox, 'Workout');
    expect(row, findsOneWidget);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pump();
    expect(tester.widget<AppCheckbox>(row).value, isTrue);
    await tester.pumpAndSettle();
    final flame = find.descendant(
      of: find.widgetWithText(HabitRow, 'Workout'),
      matching: find.byType(StreakFlame),
    );
    expect(tester.widget<StreakFlame>(flame).days, 1);
  });
}

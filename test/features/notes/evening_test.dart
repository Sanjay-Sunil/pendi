import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/models/college.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/repos/college_repo.dart';
import 'package:pendi/data/repos/cp_repo.dart';
import 'package:pendi/data/repos/notes_repo.dart';
import 'package:pendi/data/repos/reading_repo.dart';
import 'package:pendi/domain/cp.dart';
import 'package:pendi/domain/day_summary.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('summarizeDay counts only completions on that IST day', () {
    final s = summarizeDay(
      day: '2026-11-21',
      readingDone: [
        DateTime.utc(2026, 11, 20, 18, 31),
        DateTime.utc(2026, 11, 20, 12),
        null,
      ],
      cpSolved: [DateTime.utc(2026, 11, 21, 10)],
      researchDone: const [],
      collegeDone: [DateTime.utc(2026, 11, 21, 18, 29)],
      habitsDone: 2,
    );
    expect([s.reading, s.cp, s.research, s.college, s.habits], [1, 1, 0, 1, 2]);
    expect(
      s.text,
      '1 page read · 1 problem solved · 0 research tasks · 1 college task · 2 habits',
    );
  });

  test('notes upsert and drop empty picks', () async {
    final repo = NotesRepo(DemoDb());
    await repo.save('2026-11-21', reflection: 'ok', top3: ['a', '', 'b']);
    final n = (await repo.save(
      '2026-11-21',
      reflection: 'better',
      top3: ['x'],
    )).valueOrNull!;
    expect(
      [n.reflection, n.top3],
      [
        'better',
        ['x'],
      ],
    );
  });

  testWidgets('summary counts match actual completions; top 3 shows tomorrow', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 11, 21, 14); // 19:30 IST
    final db = await seededDb(now: now);
    final reading = ReadingRepo(db, now: () => now);
    final items = await reading.items();
    for (final i in items.take(3)) {
      await reading.setDone(i.id, true);
    }
    final cp = CpRepo(db, now: () => now);
    await cp.setStatus((await cp.problems()).first.id, CpStatus.solved);
    final college = CollegeRepo(db, now: () => now);
    final t = (await college.addTask(
      title: 'Lab record',
      kind: CollegeKind.other,
    )).valueOrNull!;
    await college.setDone(t.id, true);

    await pumpApp(
      tester,
      height: 2600,
      overrides: [
        ...testOverrides(now: now),
        dbProvider.overrideWith((ref) async => db),
      ],
    );
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('day-summary'))).data,
      '3 pages read · 1 problem solved · 0 research tasks · 1 college task · 0 habits',
    );
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Solid day.');
    await tester.enterText(fields.at(1), 'Finish OS assignment');
    await tester.ensureVisible(find.text('Save review'));
    await tester.tap(find.text('Save review'));
    await tester.pumpAndSettle();
    expect((await NotesRepo(db).get('2026-11-21'))!.top3, [
      'Finish OS assignment',
    ]);
  });

  testWidgets("yesterday's picks show as today's top 3", (tester) async {
    final db = await seededDb();
    await NotesRepo(db)
        .save('2026-11-20', reflection: '', top3: ['Ship F28', 'Call home']);
    await pumpApp(
      tester,
      overrides: [
        ...testOverrides(),
        dbProvider.overrideWith((ref) async => db),
      ],
    );
    expect(find.text('TOP 3'), findsOneWidget);
    expect(find.text('1. Ship F28'), findsOneWidget);
  });
}

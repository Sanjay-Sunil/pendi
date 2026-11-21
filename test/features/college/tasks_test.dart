import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/models/college.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/repos/college_repo.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test(
    'due-soon ordering: open by due date, undated after, done last',
    () async {
      final repo = CollegeRepo(DemoDb());
      await repo.addTask(title: 'undated', kind: CollegeKind.club);
      await repo.addTask(
        title: 'later',
        kind: CollegeKind.assignment,
        dueAt: DateTime.utc(2026, 12, 5),
      );
      final done = (await repo.addTask(
        title: 'done',
        kind: CollegeKind.assignment,
        dueAt: DateTime.utc(2026, 11, 22),
      )).valueOrNull!;
      await repo.addTask(
        title: 'soon',
        kind: CollegeKind.exam,
        dueAt: DateTime.utc(2026, 11, 25),
      );
      await repo.setDone(done.id, true);
      expect((await repo.tasks()).map((t) => t.title), [
        'soon',
        'later',
        'undated',
        'done',
      ]);
      expect((await repo.tasks(kind: CollegeKind.exam)).map((t) => t.title), [
        'soon',
      ]);
    },
  );

  testWidgets('filters by kind and shows an exam countdown card', (
    tester,
  ) async {
    final db = DemoDb();
    final repo = CollegeRepo(db);
    await repo.addTask(
      title: 'DBMS midsem',
      kind: CollegeKind.exam,
      dueAt: DateTime.utc(2026, 11, 24, 4),
    );
    await repo.addTask(title: 'OS assignment', kind: CollegeKind.assignment);
    await repo.addTask(title: 'Coding club meet', kind: CollegeKind.club);
    await pumpApp(
      tester,
      location: '/college',
      height: 1400,
      overrides: [
        ...testOverrides(),
        dbProvider.overrideWith((ref) async => db),
      ],
    );
    expect(find.text('3d 0h'), findsOneWidget); // countdown from 21 Nov 04:00Z
    expect(find.text('OS assignment'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Clubs'));
    await tester.pumpAndSettle();
    expect(find.text('OS assignment'), findsNothing);
    expect(find.text('Coding club meet'), findsOneWidget);
  });
}

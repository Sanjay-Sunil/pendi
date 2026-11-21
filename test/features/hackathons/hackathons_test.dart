import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/hackathon_repo.dart';
import 'package:pendi/ui/countdown.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('multiple hackathons sort by nearest open deadline', () async {
    final repo = HackathonRepo(DemoDb());
    final far = (await repo.create(name: 'Far')).valueOrNull!;
    final near = (await repo.create(name: 'Near')).valueOrNull!;
    await repo.create(name: 'Undated');
    await repo.addMilestone(
      far.id,
      title: 'Submit',
      dueAt: DateTime.utc(2026, 12, 20),
    );
    final done = (await repo.addMilestone(
      near.id,
      title: 'Reg',
      dueAt: DateTime.utc(2026, 11, 1),
    )).valueOrNull!;
    await repo.addTask(
      near.id,
      title: 'Deck',
      dueAt: DateTime.utc(2026, 12, 1),
    );
    await repo.setMilestoneDone(done.id, true);
    expect((await repo.all()).map((d) => d.hackathon.name), [
      'Near',
      'Far',
      'Undated',
    ]);
    expect((await repo.all()).first.nextDeadline, DateTime.utc(2026, 12, 1));
    expect((await repo.create(name: ' ')).errorOrNull, 'Name is required');
  });

  test('countdown', () {
    final now = DateTime.utc(2026, 11, 21, 10);
    expect(countdown(DateTime.utc(2026, 11, 24, 14), now), '3d 4h');
    expect(countdown(DateTime.utc(2026, 11, 21, 15, 20), now), '5h 20m');
    expect(countdown(DateTime.utc(2026, 11, 21, 9), now), 'overdue');
  });

  testWidgets('adds a hackathon from the Work tab', (tester) async {
    await pumpApp(tester, location: '/work');
    expect(find.text('No hackathons yet.'), findsOneWidget);
    await tester.tap(find.text('New hackathon'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          )
          .first,
      'HackNITC',
    );
    await tester.tap(find.text('Add hackathon'));
    await tester.pumpAndSettle();
    expect(find.text('HackNITC'), findsOneWidget);
    expect(find.text('No deadlines yet'), findsOneWidget);
  });
}

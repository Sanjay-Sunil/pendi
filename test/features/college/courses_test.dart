import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/college_repo.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('counters update and validate', () async {
    final repo = CollegeRepo(DemoDb());
    final c = (await repo.addCourse(name: 'OS', code: 'CS301')).valueOrNull!;
    await repo.mark(c.id, attended: true);
    final after = (await repo.mark(c.id, attended: false)).valueOrNull!;
    expect([after.attended, after.total], [1, 2]);
    expect((await repo.setCounts(c.id, attended: 3, total: 2)).isOk, isFalse);
    expect(
      (await repo.addCourse(name: 'X', minPct: 120)).errorOrNull,
      contains('Minimum %'),
    );
  });

  testWidgets('adding a course and marking classes updates the advice', (
    tester,
  ) async {
    await pumpApp(tester, location: '/college', height: 1400);
    await tester.tap(find.text('Add a course'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          )
          .first,
      'Operating Systems',
    );
    await tester.tap(find.text('Add course'));
    await tester.pumpAndSettle();
    expect(find.text('No classes yet.'), findsOneWidget);
    await tester.tap(find.text('Missed'));
    await tester.pumpAndSettle();
    expect(find.text('Attend the next 3 classes to recover.'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Attended'));
      await tester.pumpAndSettle();
    }
    expect(find.text('3/4 · 75%'), findsOneWidget);
    expect(find.text('At the limit. Attend the next class.'), findsOneWidget);
  });
}

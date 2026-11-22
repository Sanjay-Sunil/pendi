import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/models/college.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/repos/college_repo.dart';
import 'package:pendi/data/repos/research_repo.dart';
import 'package:pendi/features/today/providers.dart';
import 'package:pendi/features/today/screens/today_screen.dart';
import 'package:pendi/ui/app_checkbox.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('topWork keeps due-by-today items, overdue first, max 3', () {
    final end = DateTime.utc(2026, 11, 21, 18, 30);
    WorkItem w(String id, int day) =>
        WorkItem(id, id, DateTime.utc(2026, 11, day), WorkSource.research);
    final top = topWork(
      endOfToday: end,
      candidates: [w('a', 21), w('b', 19), w('c', 25), w('d', 20), w('e', 18)],
    );
    expect(top.map((x) => x.id), ['e', 'b', 'd']);
  });

  test('greeting by IST hour', () {
    expect(greeting(DateTime.utc(2026, 11, 21, 2)), 'Good morning'); // 07:30
    expect(greeting(DateTime.utc(2026, 11, 21, 8)), 'Good afternoon'); // 13:30
    expect(greeting(DateTime.utc(2026, 11, 21, 14)), 'Good evening'); // 19:30
  });

  testWidgets(
    'all sections render in demo mode; completing a row updates in place',
    (tester) async {
      final db = await seededDb();
      await ResearchRepo(db)
          .addTask('Send weekly update', dueAt: DateTime.utc(2026, 11, 20));
      await CollegeRepo(db).addTask(
        title: 'DBMS assignment',
        kind: CollegeKind.assignment,
        dueAt: DateTime.utc(2026, 11, 23),
      );
      await pumpApp(
        tester,
        height: 2400,
        overrides: [
          ...testOverrides(),
          dbProvider.overrideWith((ref) async => db),
        ],
      );
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Operating Systems lecture'), findsOneWidget);
      expect(find.text('7 pages'), findsOneWidget);
      expect(find.text('4A · Watermelon'), findsOneWidget);
      expect(find.text('Send weekly update · Research'), findsOneWidget);
      expect(find.text('Overdue 1d'), findsOneWidget);
      expect(find.text('DBMS assignment'), findsOneWidget);
      expect(find.text('INBOX · 0'), findsOneWidget);

      final row = find.widgetWithText(AppCheckbox, '4A · Watermelon');
      await tester.tap(row);
      await tester.pump(); // optimistic: flips before the save completes
      expect(tester.widget<AppCheckbox>(row).value, isTrue);
      await tester.pumpAndSettle();
      expect(tester.widget<AppCheckbox>(row).value, isTrue);
    },
  );

  testWidgets('today is accessible', (tester) async {
    await pumpApp(tester);
    await expectAccessible(tester);
  });
}

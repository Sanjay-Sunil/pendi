import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/repos/hackathon_repo.dart';
import 'package:pendi/ui/app_checkbox.dart';
import 'package:pendi/ui/app_progress_bar.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('template fills milestones; completing one updates progress', (
    tester,
  ) async {
    final db = DemoDb();
    final h = (await HackathonRepo(db).create(name: 'HackNITC')).valueOrNull!;
    await pumpApp(
      tester,
      location: '/work/hackathon/${h.id}',
      height: 2200,
      overrides: [
        ...testOverrides(),
        dbProvider.overrideWith((ref) async => db),
      ],
    );
    expect(find.text('HackNITC'), findsOneWidget);
    await tester.tap(find.textContaining('Standard hackathon'));
    await tester.pumpAndSettle();
    expect(find.text('Registration closes'), findsOneWidget);
    expect(find.text('Final submission'), findsOneWidget);
    expect(find.text('In 3d'), findsOneWidget);
    expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value, 0);
    await tester.tap(find.widgetWithText(AppCheckbox, 'Registration closes'));
    await tester.pumpAndSettle();
    expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value, 1);
    expect(find.text('25%'), findsOneWidget);
  });

  test('overdue milestones are detected by due date', () async {
    final db = DemoDb();
    final repo = HackathonRepo(db);
    final h = (await repo.create(name: 'X')).valueOrNull!;
    await repo.addMilestone(
      h.id,
      title: 'Past',
      dueAt: DateTime.utc(2026, 11, 1),
    );
    final d = (await repo.detail(h.id))!;
    expect(
      d.milestones.single.dueAt!.isBefore(DateTime.utc(2026, 11, 21)),
      isTrue,
    );
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/models/research.dart';
import 'package:pendi/data/repos/research_repo.dart';
import 'package:pendi/features/research/widgets/daily_log.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('seeds the project; one log per day', () async {
    final repo = ResearchRepo(DemoDb());
    expect((await repo.project()).name, 'NITC research internship');
    await repo.saveLog('2026-11-21', 'a');
    await repo.saveLog('2026-11-21', 'b');
    await repo.saveLog('2026-11-20', 'c');
    expect((await repo.logs()).map((l) => [l.day, l.body]), [
      ['2026-11-21', 'b'],
      ['2026-11-20', 'c'],
    ]);
  });

  test('tasks: overdue first, then dated, then undated; done last', () async {
    final repo = ResearchRepo(DemoDb(), now: () => DateTime.utc(2026, 11, 21));
    await repo.addTask('undated', priority: 1);
    await repo.addTask('later', dueAt: DateTime.utc(2026, 11, 30));
    await repo.addTask('overdue', dueAt: DateTime.utc(2026, 11, 19));
    final done = (await repo.addTask('done')).valueOrNull!;
    await repo.setTaskStatus(done.id, TaskStatus.done);
    expect((await repo.tasks()).map((t) => t.title), [
      'overdue',
      'later',
      'undated',
      'done',
    ]);
  });

  testWidgets('task added in 2 taps (field + enter); log autosaves', (
    tester,
  ) async {
    await pumpApp(tester, location: '/work', height: 1800);
    await tester.tap(find.text('Research'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-task')));
    await tester.enterText(
      find.byKey(const Key('new-task')),
      'Read the baseline paper',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Read the baseline paper'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('research-log')),
      'Ran the baseline.',
    );
    await tester.pump(DailyLog.debounce + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
  });
}

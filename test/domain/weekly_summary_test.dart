import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/weekly_summary.dart';

void main() {
  test('compiles the week into markdown, excluding other weeks', () {
    final md = weeklySummary(
      project: 'NITC research internship',
      weekOf: '2026-11-19',
      logs: [
        (day: '2026-11-16', body: 'Set up the repo.'),
        (day: '2026-11-18', body: 'Ran baseline.\nLoss plateaus.'),
        (day: '2026-11-23', body: 'Next week'),
      ],
      tasks: [
        (title: 'Reproduce table 2', doneAt: DateTime.utc(2026, 11, 17, 8)),
        (title: 'Old task', doneAt: DateTime.utc(2026, 11, 10, 8)),
      ],
      papers: [
        (
          title: 'GAT',
          summary: 'Attention over neighbours',
          doneAt: DateTime.utc(2026, 11, 20, 8),
        ),
      ],
      experiments: [
        (
          title: 'LR sweep',
          day: '2026-11-19',
          hypothesis: '3e-4 is best',
          result: null,
        ),
      ],
    );
    expect(md, '''
# NITC research internship — week of Mon, 16 Nov

1 tasks done · 1 papers read · 1 experiments · 2 log entries

## Completed tasks
- Reproduce table 2

## Papers read
- GAT: Attention over neighbours

## Experiments
- **LR sweep** (Thu, 19 Nov)
  - Hypothesis: 3e-4 is best
  - Result: pending

## Daily log
- **Mon, 16 Nov**: Set up the repo.
- **Wed, 18 Nov**: Ran baseline. Loss plateaus.''');
  });

  test('empty week says so', () {
    final md = weeklySummary(
      project: 'P',
      weekOf: '2026-11-19',
      logs: const [],
      tasks: const [],
      papers: const [],
      experiments: const [],
    );
    expect(md, contains('## Completed tasks\n- None this week'));
  });
}

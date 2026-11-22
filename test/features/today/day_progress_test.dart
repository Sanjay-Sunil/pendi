import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/features/today/widgets/day_progress.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('sums only areas with work today', (tester) async {
    await pumpThemed(
      tester,
      const DayProgress(
        parts: [
          (label: 'Reading', done: 1, total: 3),
          (label: 'CP', done: 2, total: 2),
          (label: 'Habits', done: 0, total: 0),
        ],
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text(' / 5'), findsOneWidget);
    expect(find.text('Reading 1/3  ·  CP 2/2'), findsOneWidget);
  });

  testWidgets('celebrates a finished day and handles an empty one', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const DayProgress(parts: [(label: 'CP', done: 2, total: 2)]),
    );
    expect(find.text('All done today. Nice.'), findsOneWidget);
    await pumpThemed(tester, const DayProgress(parts: []));
    expect(find.text('A clear day.'), findsOneWidget);
  });
}

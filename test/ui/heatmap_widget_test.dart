import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/ui/streak_heatmap.dart';

import '../helpers/pump.dart';

void main() {
  for (final b in Brightness.values) {
    testWidgets('heatmap fits a phone width and shows stats ($b)', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const Padding(
          padding: EdgeInsets.all(20),
          child: StreakHeatmap(
            counts: {'2026-11-19': 1, '2026-11-20': 3, '2026-11-21': 2},
            today: '2026-11-21',
            unit: 'solved',
          ),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('6 solved · 3d streak · best 3d'), findsOneWidget);
      expect(find.text('Nov'), findsOneWidget);
    });
  }

  testWidgets('tapping a square shows that day', (tester) async {
    await pumpThemed(
      tester,
      const StreakHeatmap(
        counts: {'2026-11-20': 3},
        today: '2026-11-21',
        unit: 'solved',
      ),
    );
    await tester.tap(find.byTooltip('3 solved on Fri, 20 Nov'));
    await tester.pumpAndSettle();
    expect(find.text('3 solved on Fri, 20 Nov'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/heatmap.dart';

void main() {
  test(
    'grid ends with the current week, Monday first, future days flagged',
    () {
      final weeks = heatmapWeeks({'2026-11-20': 2}, '2026-11-21', weeks: 3);
      expect(weeks, hasLength(3));
      expect(weeks.first.first.day, '2026-11-02'); // Monday, 3 weeks back
      expect(weeks.last.map((c) => c.day).first, '2026-11-16');
      final fri = weeks.last[4];
      expect([fri.day, fri.count, fri.future], ['2026-11-20', 2, false]);
      expect(
        weeks.last[6].future,
        isTrue,
      ); // Sunday 22nd is after Saturday 21st
    },
  );

  test('levels scale to the busiest day', () {
    expect(heatLevel(0, 5), 0);
    expect(heatLevel(1, 5), 1);
    expect(heatLevel(5, 5), 4);
    expect(heatLevel(3, 5), 2);
    expect(heatLevel(1, 1), 1);
  });

  test('longest and current streaks', () {
    final counts = {
      '2026-11-01': 1, '2026-11-02': 1, '2026-11-03': 1, // 3-day run
      '2026-11-20': 1, '2026-11-21': 2,
    };
    final s = streakStats(counts, '2026-11-21');
    expect([s.current, s.longest, s.total, s.activeDays], [2, 3, 6, 5]);
    expect(longestStreak(counts, threshold: 2), 1);
  });
}

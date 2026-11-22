import 'dart:math';

import 'dates.dart';
import 'streak.dart';

/// One square in a contribution grid.
class HeatCell {
  const HeatCell(this.day, this.count, {required this.future});
  final LocalDay day;
  final int count;

  /// Days after today in the current week are drawn empty.
  final bool future;
}

/// GitHub-style grid: [weeks] columns (oldest first), each Monday..Sunday,
/// ending with the week that contains [today].
List<List<HeatCell>> heatmapWeeks(
  Map<LocalDay, int> counts,
  LocalDay today, {
  int weeks = 20,
}) {
  final firstMonday = addDays(weekStart(today), -7 * (weeks - 1));
  return [
    for (var w = 0; w < weeks; w++)
      [
        for (var d = 0; d < 7; d++)
          () {
            final day = addDays(firstMonday, w * 7 + d);
            return HeatCell(
              day,
              counts[day] ?? 0,
              future: day.compareTo(today) > 0,
            );
          }(),
      ],
  ];
}

/// 0 (none) to 4 (busiest) intensity, relative to [max] like GitHub's quartiles.
int heatLevel(int count, int max) {
  if (count <= 0 || max <= 0) return 0;
  return (1 + (count - 1) * 4 ~/ max).clamp(1, 4);
}

/// Longest run of consecutive days with at least [threshold] completions.
int longestStreak(Map<LocalDay, int> counts, {int threshold = 1}) {
  final days =
      counts.entries
          .where((e) => e.value >= threshold)
          .map((e) => e.key)
          .toList()
        ..sort();
  var best = 0, run = 0;
  LocalDay? prev;
  for (final d in days) {
    run = prev != null && daysBetween(prev, d) == 1 ? run + 1 : 1;
    best = max(best, run);
    prev = d;
  }
  return best;
}

class StreakStats {
  const StreakStats({
    required this.current,
    required this.longest,
    required this.total,
    required this.activeDays,
  });
  final int current;
  final int longest;
  final int total;
  final int activeDays;
}

StreakStats streakStats(
  Map<LocalDay, int> counts,
  LocalDay today, {
  int threshold = 1,
}) => StreakStats(
  current: streak(counts, today, threshold: threshold),
  longest: longestStreak(counts, threshold: threshold),
  total: counts.values.fold(0, (a, b) => a + b),
  activeDays: counts.values.where((v) => v >= threshold).length,
);

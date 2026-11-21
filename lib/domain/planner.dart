import 'dart:math';

import 'dates.dart';

enum ItemStatus { todo, done, skipped }

/// What the planner needs to know about a page.
abstract interface class PlannerItem {
  int get position;
  ItemStatus get status;
  DateTime? get doneAt;
}

/// Pages to read today: remaining spread evenly over the days left.
/// Day 1 is [startDate]; on or after the last day, everything remaining is due.
int todayQuota(
  int remaining,
  LocalDay startDate,
  int targetDays,
  LocalDay today,
) {
  if (remaining <= 0) return 0;
  final elapsed = max(0, daysBetween(startDate, today));
  final daysLeft = targetDays - elapsed;
  return (remaining / max(1, daysLeft)).ceil();
}

class PlannedItem<T extends PlannerItem> {
  const PlannedItem(this.item, {required this.carriedOver});
  final T item;
  final bool carriedOver;
}

class TodayPlan<T extends PlannerItem> {
  const TodayPlan({
    required this.quota,
    required this.items,
    required this.doneToday,
    required this.remaining,
    required this.daysLeft,
  });

  final int quota;

  /// Today's slice in reading order; includes items already ticked today.
  final List<PlannedItem<T>> items;
  final int doneToday;
  final int remaining;
  final int daysLeft;
}

/// Today's reading slice. The quota is fixed at the start of the day (items finished
/// today still count toward it) so ticking pages off never shrinks or grows the list.
/// Items an even pace would have finished before today are flagged as carried over.
TodayPlan<T> todaysItems<T extends PlannerItem>(
  List<T> all, {
  required LocalDay startDate,
  required int targetDays,
  required LocalDay today,
  String zone = defaultTimezone,
}) {
  final live = all.where((i) => i.status != ItemStatus.skipped).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  bool doneBefore(T i) =>
      i.status == ItemStatus.done &&
      i.doneAt != null &&
      toLocalDay(i.doneAt!, zone: zone).compareTo(today) < 0;
  final doneBeforeCount = live.where(doneBefore).length;
  final open = live.where((i) => !doneBefore(i)).toList();
  final quota = todayQuota(open.length, startDate, targetDays, today);

  final elapsed = max(0, daysBetween(startDate, today));
  final expectedBefore = min(
    live.length,
    (live.length * elapsed / targetDays).ceil(),
  );
  final behind = max(0, expectedBefore - doneBeforeCount);

  final slice = [
    for (var i = 0; i < min(quota, open.length); i++)
      PlannedItem(open[i], carriedOver: i < behind),
  ];
  return TodayPlan(
    quota: quota,
    items: slice,
    doneToday: slice.where((p) => p.item.status == ItemStatus.done).length,
    remaining: open.where((i) => i.status != ItemStatus.done).length,
    daysLeft: max(0, targetDays - elapsed),
  );
}

const _minutesPerPart = 20;
const _wordsPerMinute = 230;

int estimateMinutes(int wordCount) =>
    max(1, (wordCount / _wordsPerMinute).ceil());

/// Splits a long single page into ~20-minute parts with distinct URLs.
List<({String title, String url})> splitByReadingTime(
  String title,
  String url,
  int minutes,
) {
  final parts = max(1, (minutes / _minutesPerPart).ceil());
  if (parts == 1) return [(title: title, url: url)];
  final base = url.split('#').first;
  return [
    for (var i = 1; i <= parts; i++)
      (title: '$title · Part $i', url: '$base#part-$i'),
  ];
}

import 'dates.dart';

/// Consecutive days with at least [threshold] completions, ending today or
/// yesterday (so the streak survives until the end of today).
int streak(
  Map<LocalDay, int> completionsPerDay,
  LocalDay today, {
  int threshold = 1,
}) {
  bool hit(LocalDay d) => (completionsPerDay[d] ?? 0) >= threshold;
  var day = hit(today) ? today : addDays(today, -1);
  var n = 0;
  while (hit(day)) {
    n++;
    day = addDays(day, -1);
  }
  return n;
}

/// Counts completions per local day from completion instants.
Map<LocalDay, int> countByDay(
  Iterable<DateTime> instants, {
  String zone = defaultTimezone,
}) {
  final out = <LocalDay, int>{};
  for (final t in instants) {
    final d = toLocalDay(t, zone: zone);
    out[d] = (out[d] ?? 0) + 1;
  }
  return out;
}

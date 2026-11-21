import 'dates.dart';

class DaySummary {
  const DaySummary({
    required this.reading,
    required this.cp,
    required this.research,
    required this.college,
    required this.habits,
  });
  final int reading;
  final int cp;
  final int research;
  final int college;
  final int habits;

  int get total => reading + cp + research + college + habits;

  String get text {
    String n(int v, String one, String many) => '$v ${v == 1 ? one : many}';
    return [
      n(reading, 'page read', 'pages read'),
      n(cp, 'problem solved', 'problems solved'),
      n(research, 'research task', 'research tasks'),
      n(college, 'college task', 'college tasks'),
      n(habits, 'habit', 'habits'),
    ].join(' · ');
  }
}

/// Counts completions whose timestamp falls on [day] in [zone].
DaySummary summarizeDay({
  required LocalDay day,
  required Iterable<DateTime?> readingDone,
  required Iterable<DateTime?> cpSolved,
  required Iterable<DateTime?> researchDone,
  required Iterable<DateTime?> collegeDone,
  required int habitsDone,
  String zone = defaultTimezone,
}) {
  int on(Iterable<DateTime?> ts) => ts
      .whereType<DateTime>()
      .where((t) => toLocalDay(t, zone: zone) == day)
      .length;
  return DaySummary(
    reading: on(readingDone),
    cp: on(cpSolved),
    research: on(researchDone),
    college: on(collegeDone),
    habits: habitsDone,
  );
}

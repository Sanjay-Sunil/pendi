import 'dates.dart';

class ClassSlot {
  const ClassSlot({
    required this.weekday,
    required this.start,
    required this.end,
    required this.courseCode,
    this.courseName,
  });

  /// 1 = Monday … 7 = Sunday.
  final int weekday;

  /// `HH:mm` local.
  final String start;
  final String end;
  final String courseCode;
  final String? courseName;

  bool get isLab => _minutes(end) - _minutes(start) >= 110;

  Map<String, Object?> toJson() => {
    'weekday': weekday,
    'start': start,
    'end': end,
    'courseCode': courseCode,
    'courseName': courseName,
  };

  static ClassSlot fromJson(Map<String, Object?> j) => ClassSlot(
    weekday: j['weekday']! as int,
    start: j['start']! as String,
    end: j['end']! as String,
    courseCode: j['courseCode']! as String,
    courseName: j['courseName'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is ClassSlot &&
      other.weekday == weekday &&
      other.start == start &&
      other.end == end &&
      other.courseCode == courseCode;

  @override
  int get hashCode => Object.hash(weekday, start, end, courseCode);
}

typedef SessionRecord = ({
  LocalDay date,
  String start,
  String end,
  String courseCode,
  String? courseName,
});

int _minutes(String hhmm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm.trim());
  return m == null ? -1 : int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

String _norm(String hhmm) {
  final m = _minutes(hhmm);
  return m < 0
      ? ''
      : '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

int weekdayOf(LocalDay day) {
  final [y, m, d] = day.split('-').map(int.parse).toList();
  return DateTime.utc(y, m, d).weekday;
}

/// Infers the weekly timetable from attendance sessions: a (weekday, time,
/// course) slot counts when it happened at least [minRepeats] times within the
/// last [weeks] weeks, so one-off extra classes don't become permanent.
List<ClassSlot> inferTimetable(
  List<SessionRecord> sessions,
  LocalDay today, {
  int weeks = 5,
  int minRepeats = 2,
}) {
  final since = addDays(today, -7 * weeks);
  final counts = <ClassSlot, int>{};
  for (final s in sessions) {
    if (s.date.compareTo(since) < 0 || s.date.compareTo(today) > 0) continue;
    final start = _norm(s.start), end = _norm(s.end);
    if (start.isEmpty || end.isEmpty || _minutes(end) <= _minutes(start)) {
      continue;
    }
    final slot = ClassSlot(
      weekday: weekdayOf(s.date),
      start: start,
      end: end,
      courseCode: s.courseCode,
      courseName: s.courseName,
    );
    counts[slot] = (counts[slot] ?? 0) + 1;
  }
  final slots =
      [
        for (final e in counts.entries)
          if (e.value >= minRepeats) e.key,
      ]..sort(
        (a, b) => a.weekday != b.weekday
            ? a.weekday - b.weekday
            : a.start.compareTo(b.start),
      );
  return slots;
}

/// The class happening at [time] on [weekday], and the next one today.
({ClassSlot? now, ClassSlot? next}) nowAndNext(
  List<ClassSlot> slots,
  int weekday,
  String time,
) {
  final t = _minutes(time);
  final today = slots.where((s) => s.weekday == weekday).toList();
  ClassSlot? now, next;
  for (final s in today) {
    if (_minutes(s.start) <= t && t < _minutes(s.end)) now = s;
    if (_minutes(s.start) > t && next == null) next = s;
  }
  return (now: now, next: next);
}

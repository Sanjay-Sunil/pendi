import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/timetable.dart';

SessionRecord s(String date, String start, String end, String code) =>
    (date: date, start: start, end: end, courseCode: code, courseName: null);

void main() {
  // Mondays: 16, 9, 2 Nov. Wednesday 18 Nov. Today Sat 21 Nov.
  final sessions = [
    s('2026-11-16', '09:00', '10:00', 'CS311'),
    s('2026-11-09', '9:00', '10:00', 'CS311'),
    s('2026-11-02', '09:00:00', '10:00:00', 'CS311'),
    s('2026-11-18', '14:00', '16:00', 'CS312'),
    s('2026-11-11', '14:00', '16:00', 'CS312'),
    s('2026-11-17', '11:00', '12:00', 'MA301'), // only once: an extra class
    s('2026-09-01', '08:00', '09:00', 'OLD'), // too old
    s('2026-11-20', '10:00', '09:00', 'BAD'), // end before start
  ];

  test(
    'keeps repeating slots, drops one-offs and bad rows, sorts by day and time',
    () {
      final t = inferTimetable(sessions, '2026-11-21');
      expect(t.map((c) => [c.weekday, c.start, c.end, c.courseCode]), [
        [1, '09:00', '10:00', 'CS311'],
        [3, '14:00', '16:00', 'CS312'],
      ]);
      expect(t[1].isLab, isTrue);
      expect(t[0].isLab, isFalse);
    },
  );

  test('now and next', () {
    final t = inferTimetable(sessions, '2026-11-21');
    expect(nowAndNext(t, 1, '09:30').now?.courseCode, 'CS311');
    expect(nowAndNext(t, 3, '09:30').next?.courseCode, 'CS312');
    expect(nowAndNext(t, 3, '17:00'), (now: null, next: null));
  });

  test('json round trip', () {
    final slot = inferTimetable(sessions, '2026-11-21').first;
    expect(ClassSlot.fromJson(slot.toJson()), slot);
  });
}

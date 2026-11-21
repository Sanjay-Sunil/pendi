import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/dates.dart';

void main() {
  const ist = 'Asia/Kolkata';
  DateTime u(String s) => DateTime.parse(s);

  group('todayLocal', () {
    test('rolls over at IST midnight, not UTC midnight', () {
      expect(todayLocal(u('2026-03-09T18:29:59Z'), zone: ist), '2026-03-09');
      expect(todayLocal(u('2026-03-09T18:30:00Z'), zone: ist), '2026-03-10');
    });

    test('differs from the UTC date in the early IST morning', () {
      final now = u('2026-03-09T20:00:00Z');
      expect(todayLocal(now, zone: 'UTC'), '2026-03-09');
      expect(todayLocal(now, zone: ist), '2026-03-10');
    });

    test('defaults to IST', () {
      expect(todayLocal(u('2026-03-09T18:30:00Z')), '2026-03-10');
    });
  });

  group('startOfDay', () {
    test('returns the UTC instant of local midnight', () {
      expect(startOfDay('2026-03-10', zone: ist), u('2026-03-09T18:30:00Z'));
      expect(startOfDay('2026-03-10', zone: 'UTC'), u('2026-03-10T00:00:00Z'));
    });

    test('is stable across the year in DST-free zones', () {
      for (final day in ['2026-01-15', '2026-07-15', '2026-11-01']) {
        final s = startOfDay(day, zone: ist);
        expect([s.hour, s.minute], [18, 30]);
        expect(startOfDay(day, zone: 'Asia/Tokyo').hour, 15);
      }
    });

    test('rejects malformed days', () {
      expect(() => startOfDay('2026-3-1'), throwsRangeError);
    });
  });

  test('toLocalDay buckets instants by local day', () {
    expect(toLocalDay(u('2026-03-09T18:30:00Z'), zone: ist), '2026-03-10');
    expect(toLocalDay(u('2026-03-09T18:29:00Z'), zone: ist), '2026-03-09');
  });

  group('daysBetween / addDays / weekStart', () {
    test('counts calendar days', () {
      expect(daysBetween('2026-03-01', '2026-03-31'), 30);
      expect(daysBetween('2026-03-10', '2026-03-08'), -2);
      expect(daysBetween('2026-02-28', '2026-03-01'), 1);
      expect(daysBetween('2024-02-28', '2024-03-01'), 2);
    });

    test('adds days across month and year ends', () {
      expect(addDays('2026-12-31', 1), '2027-01-01');
      expect(addDays('2026-03-01', -1), '2026-02-28');
    });

    test('finds Monday', () {
      expect(weekStart('2026-11-21'), '2026-11-16'); // Saturday → Monday
      expect(weekStart('2026-11-16'), '2026-11-16');
    });
  });

  test('formatDue labels by local calendar day', () {
    final now = u('2026-03-09T20:00:00Z'); // 10 Mar 01:30 IST
    expect(formatDue(u('2026-03-10T17:00:00Z'), now, zone: ist), 'Today');
    expect(formatDue(u('2026-03-10T19:00:00Z'), now, zone: ist), 'Tomorrow');
    expect(formatDue(u('2026-03-09T12:00:00Z'), now, zone: ist), 'Overdue 1d');
    expect(formatDue(u('2026-03-15T06:00:00Z'), now, zone: ist), 'In 5d');
    expect(formatDue(u('2026-04-14T06:00:00Z'), now, zone: ist), 'Apr 14');
  });

  test('labels', () {
    expect(formatDayLabel('2026-11-21'), 'Sat, 21 Nov');
    expect(formatTime(u('2026-11-21T04:00:00Z')), '09:30');
  });
}

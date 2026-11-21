import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/planner.dart';

class Item implements PlannerItem {
  Item(this.id, this.position, {this.status = ItemStatus.todo, this.doneAt});
  final String id;
  @override
  final int position;
  @override
  ItemStatus status;
  @override
  DateTime? doneAt;
}

List<Item> items(int n) => [for (var i = 0; i < n; i++) Item('i$i', i)];

/// Marks the first [n] open items done at noon IST on [day].
List<Item> complete(List<Item> list, int n, String day) {
  var left = n;
  for (final i in list) {
    if (left > 0 && i.status == ItemStatus.todo) {
      left--;
      i
        ..status = ItemStatus.done
        ..doneAt = DateTime.parse('${day}T06:30:00Z');
    }
  }
  return list;
}

List<String> ids(TodayPlan<Item> p) => p.items.map((e) => e.item.id).toList();

void main() {
  group('todayQuota', () {
    test('splits evenly across the target days', () {
      expect(todayQuota(30, '2026-03-01', 30, '2026-03-01'), 1);
      expect(todayQuota(120, '2026-03-01', 30, '2026-03-01'), 4);
      expect(todayQuota(31, '2026-03-01', 30, '2026-03-01'), 2);
    });
    test('redistributes missed days over the days left', () {
      expect(todayQuota(30, '2026-03-01', 30, '2026-03-11'), 2);
    });
    test(
      'puts everything remaining on the last day and after the deadline',
      () {
        expect(todayQuota(7, '2026-03-01', 30, '2026-03-30'), 7);
        expect(todayQuota(7, '2026-03-01', 30, '2026-04-15'), 7);
      },
    );
    test('returns 0 for a completed source', () {
      expect(todayQuota(0, '2026-03-01', 30, '2026-03-05'), 0);
    });
    test('treats a future start as day one', () {
      expect(todayQuota(10, '2026-03-05', 5, '2026-03-01'), 2);
    });
  });

  group('todaysItems', () {
    TodayPlan<Item> plan(List<Item> l, String today, {int days = 10}) =>
        todaysItems(l, startDate: '2026-03-01', targetDays: days, today: today);

    test('returns the first quota items in order', () {
      final p = plan(items(20), '2026-03-01');
      expect(p.quota, 2);
      expect(ids(p), ['i0', 'i1']);
      expect(p.items.every((e) => !e.carriedOver), isTrue);
    });

    test('keeps today stable as pages are ticked off', () {
      final p = plan(complete(items(20), 1, '2026-03-01'), '2026-03-01');
      expect(p.quota, 2);
      expect(ids(p), ['i0', 'i1']);
      expect(p.doneToday, 1);
    });

    test(
      'advances tomorrow and flags carried-over pages after a missed day',
      () {
        final day1 = complete(items(20), 2, '2026-03-01');
        expect(ids(plan(day1, '2026-03-02')), ['i2', 'i3']);
        final p = plan(day1, '2026-03-03');
        expect(p.quota, 3);
        expect(p.items.map((e) => [e.item.id, e.carriedOver]), [
          ['i2', true],
          ['i3', true],
          ['i4', false],
        ]);
      },
    );

    test('ignores skipped items', () {
      final l = items(4)..first.status = ItemStatus.skipped;
      final p = plan(l, '2026-03-01', days: 3);
      expect(ids(p), ['i1']);
      expect(p.remaining, 3);
    });

    test('returns nothing for a finished source', () {
      final p = plan(complete(items(3), 3, '2026-03-01'), '2026-03-02');
      expect(p.quota, 0);
      expect(p.items, isEmpty);
    });
  });

  group('reading-time splitting', () {
    test('splits into 20-minute parts with unique urls', () {
      final parts = splitByReadingTime(
        'Long post',
        'https://b.dev/post#intro',
        45,
      );
      expect(parts, hasLength(3));
      expect(parts[2], (
        title: 'Long post · Part 3',
        url: 'https://b.dev/post#part-3',
      ));
    });
    test('keeps short pages whole', () {
      expect(splitByReadingTime('Short', 'https://b.dev/s', 12), [
        (title: 'Short', url: 'https://b.dev/s'),
      ]);
    });
    test('estimates minutes from word count', () {
      expect(estimateMinutes(2300), 10);
      expect(estimateMinutes(0), 1);
    });
  });
}

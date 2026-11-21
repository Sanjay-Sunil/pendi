import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/cp.dart';
import 'package:pendi/domain/streak.dart';

class P implements PickableProblem {
  P(this.id, this.position, [this.status = CpStatus.todo]);
  @override
  final String id;
  @override
  final int position;
  @override
  final CpStatus status;
}

void main() {
  group('pickDaily', () {
    final list = [P('a', 0), P('b', 1, CpStatus.solved), P('c', 2), P('d', 3)];

    test('takes the first two open problems in list order', () {
      expect(pickDaily(list, const []), ['a', 'c']);
    });

    test('is idempotent once a day has picks', () {
      expect(pickDaily(list, const ['d', 'c']), ['d', 'c']);
    });

    test('puts the review queue first', () {
      final withReview = [...list, P('r', 9, CpStatus.review)];
      expect(pickDaily(withReview, const []), ['r', 'a']);
    });

    test('returns fewer when the list runs out', () {
      expect(pickDaily([P('x', 0, CpStatus.skipped), P('y', 1)], const []), [
        'y',
      ]);
    });
  });

  test('canonicalKey', () {
    expect(canonicalKey(1950, ' b '), '1950B');
  });

  group('streak', () {
    test('counts consecutive days ending today', () {
      expect(
        streak({
          '2026-03-10': 1,
          '2026-03-09': 2,
          '2026-03-08': 1,
        }, '2026-03-10'),
        3,
      );
    });

    test('survives until end of today if yesterday was hit', () {
      expect(streak({'2026-03-09': 1, '2026-03-08': 1}, '2026-03-10'), 2);
    });

    test('breaks across a gap', () {
      expect(streak({'2026-03-10': 1, '2026-03-08': 1}, '2026-03-10'), 1);
      expect(streak({'2026-03-08': 1}, '2026-03-10'), 0);
    });

    test('respects the threshold', () {
      final days = {'2026-03-10': 2, '2026-03-09': 1};
      expect(streak(days, '2026-03-10', threshold: 2), 1);
    });

    test('countByDay buckets by IST day', () {
      expect(
        countByDay([
          DateTime.utc(2026, 3, 9, 18, 31),
          DateTime.utc(2026, 3, 9, 10),
        ]),
        {'2026-03-10': 1, '2026-03-09': 1},
      );
    });
  });
}

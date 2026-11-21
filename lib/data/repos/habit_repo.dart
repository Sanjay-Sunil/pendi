import '../../core/result.dart';
import '../../domain/dates.dart';
import '../../domain/streak.dart';
import '../db.dart';
import '../models/json.dart';

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.targetPerWeek,
  });

  factory Habit.fromJson(Row r) => Habit(
    id: r.str('id'),
    name: r.str('name'),
    targetPerWeek: r.integer('target_per_week'),
  );

  final String id;
  final String name;
  final int targetPerWeek;
}

/// A habit with the days it was done (local days).
class HabitWithLogs {
  const HabitWithLogs(this.habit, this.days);
  final Habit habit;
  final Set<LocalDay> days;

  bool doneOn(LocalDay d) => days.contains(d);
  int streakAsOf(LocalDay today) => streak({for (final d in days) d: 1}, today);

  /// Done-flags for Monday..Sunday of the week containing [today].
  List<bool> week(LocalDay today) {
    final start = weekStart(today);
    return [for (var i = 0; i < 7; i++) doneOn(addDays(start, i))];
  }
}

class HabitRepo {
  HabitRepo(this._db);

  final Db _db;

  Future<List<HabitWithLogs>> all() async {
    final (hs, logs) = await (
      _db.list('habits', orderBy: 'created_at'),
      _db.list('habit_logs'),
    ).wait;
    return [
      for (final h in hs.map(Habit.fromJson))
        HabitWithLogs(h, {
          for (final l in logs)
            if (l['habit_id'] == h.id) l.str('day'),
        }),
    ];
  }

  Future<Result<Habit>> add(String name, {Object targetPerWeek = 7}) =>
      Result.guard(
        () async => Habit.fromJson(
          (await _db.insert('habits', [
            {
              'name': requireText(name, 'Habit', max: 80),
              'target_per_week': requireInt(
                targetPerWeek,
                'Days per week',
                min: 1,
                max: 7,
              ),
            },
          ])).single,
        ),
      );

  Future<Result<void>> delete(String id) =>
      Result.guard(() => _db.remove('habits', id));

  /// Marks [habitId] done or not done on [day]. Idempotent.
  Future<Result<void>> setDone(String habitId, LocalDay day, bool done) =>
      Result.guard(() async {
        final existing = (await _db.list(
          'habit_logs',
          where: {'habit_id': habitId, 'day': day},
        ));
        if (done && existing.isEmpty) {
          await _db.insert('habit_logs', [
            {'habit_id': habitId, 'day': day},
          ]);
        } else if (!done) {
          for (final r in existing) {
            await _db.remove('habit_logs', r.str('id'));
          }
        }
      });
}

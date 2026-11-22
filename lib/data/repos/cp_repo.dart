import '../../core/result.dart';
import '../../domain/cp.dart';
import '../../domain/cp_import.dart';
import '../../domain/dates.dart';
import '../../domain/streak.dart';
import '../db.dart';
import '../models/cp.dart';
import '../models/json.dart';

class CpRepo {
  CpRepo(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Db _db;
  final DateTime Function() _now;

  Future<List<CpList>> lists() async => (await _db.list(
    'cp_lists',
    orderBy: 'created_at',
  )).map(CpList.fromJson).toList();

  Future<CpList?> activeList() async {
    final all = await lists();
    return all.where((l) => l.active).firstOrNull;
  }

  Future<List<CpProblem>> problems({String? listId}) async => (await _db.list(
    'cp_problems',
    where: listId == null ? const {} : {'list_id': listId},
    orderBy: 'position',
  )).map(CpProblem.fromJson).toList();

  /// Creates a list from parsed problems. The first list becomes active.
  Future<Result<CpList>> createList(
    String name,
    List<ParsedProblem> parsed, {
    String? source,
  }) => Result.guard(() async {
    final title = requireText(name, 'Name', max: 120);
    if (parsed.isEmpty) {
      throw const ValidationError('No valid problems to import');
    }
    final first = (await lists()).isEmpty;
    final list = CpList.fromJson(
      (await _db.insert('cp_lists', [
        {'name': title, 'source': source, 'active': first},
      ])).single,
    );
    await _db.insert('cp_problems', [
      for (var i = 0; i < parsed.length; i++)
        {
          'list_id': list.id,
          'contest_id': parsed[i].contestId,
          'idx': parsed[i].index,
          'name': parsed[i].name,
          'rating': parsed[i].rating,
          'position': i,
        },
    ]);
    return list;
  });

  Future<Result<void>> rename(String id, String name) => Result.guard(
    () => _db.update('cp_lists', id, {
      'name': requireText(name, 'Name', max: 120),
    }),
  );

  /// Makes [id] the only active list.
  Future<Result<void>> activate(String id) => Result.guard(() async {
    for (final l in await lists()) {
      if (l.active != (l.id == id)) {
        await _db.update('cp_lists', l.id, {'active': l.id == id});
      }
    }
  });

  Future<Result<CpProblem>> setStatus(String id, CpStatus status) =>
      Result.guard(
        () async => CpProblem.fromJson(
          await _db.update('cp_problems', id, {
            'status': status.name,
            'solved_at': status == CpStatus.solved ? isoOrNull(_now()) : null,
          }),
        ),
      );

  Future<Result<CpProblem>> setNote(String id, String note) => Result.guard(
    () async => CpProblem.fromJson(
      await _db.update('cp_problems', id, {
        'note': note.trim().isEmpty ? null : note.trim(),
      }),
    ),
  );

  /// Marks problems whose key is in [solvedKeys] as solved. Returns how many changed.
  Future<Result<int>> markSolved(Set<String> solvedKeys) =>
      Result.guard(() async {
        var n = 0;
        for (final p in await problems()) {
          if (p.status != CpStatus.solved && solvedKeys.contains(p.key)) {
            await setStatus(p.id, CpStatus.solved);
            n++;
          }
        }
        return n;
      });

  /// Today's problems from the active list; picked once per day and persisted.
  Future<List<CpProblem>> daily(LocalDay day, {int count = 2}) async {
    final list = await activeList();
    if (list == null) return [];
    final all = await problems(listId: list.id);
    final position = {for (final p in all) p.id: p.position};
    // Rows come back in no fixed order from Postgres; keep list order stable.
    final existing =
        (await _db.list('cp_daily', where: {'day': day}))
            .map((r) => r.str('problem_id'))
            .where(position.containsKey)
            .toList()
          ..sort((a, b) => position[a]!.compareTo(position[b]!));
    final ids = pickDaily(all, existing, count: count);
    if (existing.isEmpty && ids.isNotEmpty) {
      await _db.insert('cp_daily', [
        for (final id in ids) {'day': day, 'problem_id': id},
      ]);
    }
    return [for (final id in ids) all.firstWhere((p) => p.id == id)];
  }

  /// Days in a row with at least [threshold] solves, ending today or yesterday.
  Future<int> streakAsOf(LocalDay today, {int threshold = 1}) async {
    final solved = (await problems())
        .map((p) => p.solvedAt)
        .whereType<DateTime>();
    return streak(countByDay(solved), today, threshold: threshold);
  }

  Future<List<CpProblem>> reviewQueue() async =>
      (await problems()).where((p) => p.status == CpStatus.review).toList();
}

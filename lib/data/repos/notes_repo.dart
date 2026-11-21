import '../../core/result.dart';
import '../../domain/dates.dart';
import '../db.dart';
import '../models/json.dart';

class DailyNote {
  const DailyNote({
    required this.id,
    required this.day,
    required this.reflection,
    required this.top3,
  });

  factory DailyNote.fromJson(Row r) => DailyNote(
    id: r.str('id'),
    day: r.str('day'),
    reflection: r.str('reflection'),
    top3: r.strings('top3'),
  );

  final String id;
  final LocalDay day;
  final String reflection;

  /// Picks for the day after [day].
  final List<String> top3;
}

class NotesRepo {
  NotesRepo(this._db);

  final Db _db;

  Future<DailyNote?> get(LocalDay day) async {
    final rows = await _db.list('daily_notes', where: {'day': day});
    return rows.isEmpty ? null : DailyNote.fromJson(rows.first);
  }

  /// Upserts [day]'s note. Empty top-3 entries are dropped.
  Future<Result<DailyNote>> save(
    LocalDay day, {
    required String reflection,
    required List<String> top3,
  }) => Result.guard(() async {
    if (reflection.length > 280) {
      throw const ValidationError('Reflection is one line (max 280)');
    }
    final picks = top3
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();
    final row = {'day': day, 'reflection': reflection.trim(), 'top3': picks};
    final existing = await get(day);
    return DailyNote.fromJson(
      existing == null
          ? (await _db.insert('daily_notes', [row])).single
          : await _db.update('daily_notes', existing.id, row),
    );
  });
}

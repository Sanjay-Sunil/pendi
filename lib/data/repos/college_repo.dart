import '../../core/result.dart';
import '../db.dart';
import '../models/college.dart';
import '../models/json.dart';

/// Called after a dated college task is written, so Calendar sync can mirror it.
typedef OnTaskDated = Future<void> Function(CollegeTask task);

class CollegeRepo {
  CollegeRepo(this._db, {DateTime Function()? now, this.onTaskDated})
    : _now = now ?? DateTime.now;

  final Db _db;
  final DateTime Function() _now;
  OnTaskDated? onTaskDated;

  Future<List<Course>> courses() async => (await _db.list(
    'courses',
    orderBy: 'created_at',
  )).map(Course.fromJson).toList();

  Future<Result<Course>> addCourse({
    required String name,
    String? code,
    Object minPct = 75,
  }) => Result.guard(
    () async => Course.fromJson(
      (await _db.insert('courses', [
        {
          'name': requireText(name, 'Course', max: 120),
          'code': (code ?? '').trim().isEmpty ? null : code!.trim(),
          'min_pct': requireInt(minPct, 'Minimum %', min: 0, max: 100),
        },
      ])).single,
    ),
  );

  /// Records one class: attended or missed.
  Future<Result<Course>> mark(String courseId, {required bool attended}) =>
      Result.guard(() async {
        final c = Course.fromJson((await _db.get('courses', courseId))!);
        return Course.fromJson(
          await _db.update('courses', courseId, {
            'attendance_total': c.total + 1,
            'attendance_attended': c.attended + (attended ? 1 : 0),
          }),
        );
      });

  /// Undo / correct counts directly.
  Future<Result<Course>> setCounts(
    String courseId, {
    required int attended,
    required int total,
  }) => Result.guard(() async {
    if (attended < 0 || total < 0 || attended > total) {
      throw const ValidationError('Attended must be between 0 and total');
    }
    return Course.fromJson(
      await _db.update('courses', courseId, {
        'attendance_attended': attended,
        'attendance_total': total,
      }),
    );
  });

  Future<Result<void>> deleteCourse(String id) =>
      Result.guard(() => _db.remove('courses', id));

  // Tasks ------------------------------------------------------------------

  /// Open tasks soonest-first (undated last), then done ones.
  Future<List<CollegeTask>> tasks({CollegeKind? kind}) async {
    final all = (await _db.list(
      'college_tasks',
      where: kind == null ? const {} : {'kind': kind.name},
    )).map(CollegeTask.fromJson).toList();
    all.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (a.dueAt == null || b.dueAt == null) {
        return a.dueAt == null ? (b.dueAt == null ? 0 : 1) : -1;
      }
      return a.dueAt!.compareTo(b.dueAt!);
    });
    return all;
  }

  Future<Result<CollegeTask>> addTask({
    required String title,
    required CollegeKind kind,
    DateTime? dueAt,
    String? courseId,
  }) => Result.guard(() async {
    final t = CollegeTask.fromJson(
      (await _db.insert('college_tasks', [
        {
          'title': requireText(title, 'Title', max: 200),
          'kind': kind.name,
          'due_at': isoOrNull(dueAt),
          'course_id': courseId,
        },
      ])).single,
    );
    if (t.dueAt != null) await onTaskDated?.call(t);
    return t;
  });

  Future<Result<CollegeTask>> setDone(String id, bool done) => Result.guard(
    () async => CollegeTask.fromJson(
      await _db.update('college_tasks', id, {
        'done': done,
        'done_at': done ? isoOrNull(_now()) : null,
      }),
    ),
  );

  Future<Result<void>> setEvent(String id, String eventId) => Result.guard(
    () => _db.update('college_tasks', id, {'gcal_event_id': eventId}),
  );
}

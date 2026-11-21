import '../../core/result.dart';
import '../../domain/dates.dart';
import '../db.dart';
import '../models/json.dart';
import '../models/research.dart';

class ResearchRepo {
  ResearchRepo(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Db _db;
  final DateTime Function() _now;

  static const defaultProject = 'NITC research internship';

  /// The active project, created on first use.
  Future<ResearchProject> project() async {
    final rows = await _db.list(
      'research_projects',
      where: {'active': true},
      orderBy: 'created_at',
    );
    if (rows.isNotEmpty) return ResearchProject.fromJson(rows.first);
    return ResearchProject.fromJson(
      (await _db.insert('research_projects', [
        {'name': defaultProject, 'org': 'NIT Calicut'},
      ])).single,
    );
  }

  // Daily log -------------------------------------------------------------

  Future<List<ResearchLog>> logs() async {
    final p = await project();
    return (await _db.list(
      'research_logs',
      where: {'project_id': p.id},
      orderBy: 'day',
      ascending: false,
    )).map(ResearchLog.fromJson).toList();
  }

  Future<ResearchLog?> logFor(LocalDay day) async =>
      (await logs()).where((l) => l.day == day).firstOrNull;

  /// One entry per day: creates or replaces that day's body.
  Future<Result<ResearchLog>> saveLog(LocalDay day, String body) =>
      Result.guard(() async {
        final existing = await logFor(day);
        if (existing != null) {
          return ResearchLog.fromJson(
            await _db.update('research_logs', existing.id, {'body': body}),
          );
        }
        final p = await project();
        return ResearchLog.fromJson(
          (await _db.insert('research_logs', [
            {'project_id': p.id, 'day': day, 'body': body},
          ])).single,
        );
      });

  // Tasks -------------------------------------------------------------------

  /// Open tasks with overdue first, then by due date, then priority; done last.
  Future<List<ResearchTask>> tasks() async {
    final p = await project();
    final now = _now();
    final all = (await _db.list(
      'research_tasks',
      where: {'project_id': p.id},
    )).map(ResearchTask.fromJson).toList();
    int rank(ResearchTask t) {
      if (t.isDone) return 3;
      if (t.dueAt != null && t.dueAt!.isBefore(now)) return 0;
      return t.dueAt != null ? 1 : 2;
    }

    all.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      if (a.dueAt != null && b.dueAt != null) {
        final d = a.dueAt!.compareTo(b.dueAt!);
        if (d != 0) return d;
      }
      return a.priority.compareTo(b.priority);
    });
    return all;
  }

  Future<Result<ResearchTask>> addTask(
    String title, {
    DateTime? dueAt,
    int priority = 2,
    String? assignedBy = 'Sir',
  }) => Result.guard(() async {
    final p = await project();
    return ResearchTask.fromJson(
      (await _db.insert('research_tasks', [
        {
          'project_id': p.id,
          'title': requireText(title, 'Task', max: 300),
          'due_at': isoOrNull(dueAt),
          'priority': requireInt(priority, 'Priority', min: 1, max: 3),
          'assigned_by': assignedBy,
        },
      ])).single,
    );
  });

  Future<Result<ResearchTask>> setTaskStatus(String id, TaskStatus status) =>
      Result.guard(
        () async => ResearchTask.fromJson(
          await _db.update('research_tasks', id, {
            'status': status.name,
            'done_at': status == TaskStatus.done ? isoOrNull(_now()) : null,
          }),
        ),
      );
}

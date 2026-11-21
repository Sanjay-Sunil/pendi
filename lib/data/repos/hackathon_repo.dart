import '../../core/result.dart';
import '../db.dart';
import '../models/hackathon.dart';
import '../models/json.dart';

/// Called after a dated milestone is written, so Calendar sync can mirror it.
typedef OnDated = Future<void> Function(Milestone milestone);

class HackathonRepo {
  HackathonRepo(this._db, {this.onMilestoneDated});

  final Db _db;
  OnDated? onMilestoneDated;

  Future<List<HackathonDetail>> all({bool includeClosed = false}) async {
    final (hs, ms, ts) = await (
      _db.list('hackathons', orderBy: 'created_at'),
      _db.list('hackathon_milestones', orderBy: 'due_at'),
      _db.list('hackathon_tasks', orderBy: 'due_at'),
    ).wait;
    final milestones = ms.map(Milestone.fromJson).toList();
    final tasks = ts.map(HackTask.fromJson).toList();
    final out = [
      for (final h in hs.map(Hackathon.fromJson))
        if (includeClosed || h.status == 'active' || h.status == 'submitted')
          HackathonDetail(
            h,
            milestones.where((m) => m.hackathonId == h.id).toList(),
            tasks.where((t) => t.hackathonId == h.id).toList(),
          ),
    ];
    // Nearest deadline first; undated last.
    out.sort((a, b) {
      final x = a.nextDeadline, y = b.nextDeadline;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    return out;
  }

  Future<HackathonDetail?> detail(String id) async =>
      (await all(includeClosed: true))
          .where((d) => d.hackathon.id == id)
          .firstOrNull;

  Future<Result<Hackathon>> create({
    required String name,
    String? url,
    String? theme,
  }) => Result.guard(() async {
    final row = {
      'name': requireText(name, 'Name', max: 120),
      'url': (url ?? '').trim().isEmpty ? null : requireUrl(url, 'Link'),
      'theme': (theme ?? '').trim().isEmpty ? null : theme!.trim(),
    };
    return Hackathon.fromJson((await _db.insert('hackathons', [row])).single);
  });

  Future<Result<Hackathon>> update(String id, Row patch) => Result.guard(
    () async => Hackathon.fromJson(await _db.update('hackathons', id, patch)),
  );

  Future<Result<void>> delete(String id) =>
      Result.guard(() => _db.remove('hackathons', id));

  Future<Result<Milestone>> addMilestone(
    String hackathonId, {
    required String title,
    DateTime? dueAt,
    String? kind,
  }) => Result.guard(() async {
    final m = Milestone.fromJson(
      (await _db.insert('hackathon_milestones', [
        {
          'hackathon_id': hackathonId,
          'title': requireText(title, 'Title', max: 200),
          'due_at': isoOrNull(dueAt),
          'kind': kind,
        },
      ])).single,
    );
    if (m.dueAt != null) await onMilestoneDated?.call(m);
    return m;
  });

  Future<Result<Milestone>> setMilestoneDone(String id, bool done) =>
      Result.guard(
        () async => Milestone.fromJson(
          await _db.update('hackathon_milestones', id, {'done': done}),
        ),
      );

  Future<Result<void>> setMilestoneEvent(String id, String eventId) =>
      Result.guard(
        () =>
            _db.update('hackathon_milestones', id, {'gcal_event_id': eventId}),
      );

  Future<Result<HackTask>> addTask(
    String hackathonId, {
    required String title,
    DateTime? dueAt,
  }) => Result.guard(
    () async => HackTask.fromJson(
      (await _db.insert('hackathon_tasks', [
        {
          'hackathon_id': hackathonId,
          'title': requireText(title, 'Title', max: 200),
          'due_at': isoOrNull(dueAt),
        },
      ])).single,
    ),
  );

  Future<Result<HackTask>> setTaskDone(String id, bool done) => Result.guard(
    () async => HackTask.fromJson(
      await _db.update('hackathon_tasks', id, {'done': done}),
    ),
  );
}

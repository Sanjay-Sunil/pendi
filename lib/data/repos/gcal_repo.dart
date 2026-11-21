import '../../core/result.dart';
import '../../integrations/gcal.dart';
import '../db.dart';
import '../models/college.dart';
import '../models/hackathon.dart';
import '../models/json.dart';

class CachedEvent {
  const CachedEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.endsAt,
    this.allDay = false,
  });

  factory CachedEvent.fromJson(Row r) => CachedEvent(
    id: r.str('gcal_event_id'),
    title: r.str('title'),
    startsAt: r.time('starts_at')!,
    endsAt: r.time('ends_at'),
    allDay: r.boolean('all_day'),
  );

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
}

/// Mirrors Google Calendar into `gcal_events_cache` and writes dated tasks back.
class GcalRepo {
  GcalRepo(this._db, this._client);

  final Db _db;
  final CalendarClient _client;

  /// Pulls events in [from, to) into the cache. Idempotent: upserts by event id.
  Future<Result<int>> sync(DateTime from, DateTime to) =>
      Result.guard(() async {
        final events = await _client.listEvents(from, to);
        final cached = {
          for (final r in await _db.list('gcal_events_cache'))
            r.str('gcal_event_id'): r.str('id'),
        };
        for (final e in events) {
          final row = {
            'gcal_event_id': e.id,
            'title': e.title,
            'starts_at': isoOrNull(e.start),
            'ends_at': isoOrNull(e.end),
            'all_day': e.allDay,
          };
          final existing = cached[e.id];
          if (existing == null) {
            await _db.insert('gcal_events_cache', [row]);
          } else {
            await _db.update('gcal_events_cache', existing, row);
          }
        }
        return events.length;
      });

  Future<List<CachedEvent>> eventsBetween(DateTime from, DateTime to) async {
    final all = (await _db.list('gcal_events_cache', orderBy: 'starts_at'))
        .map(CachedEvent.fromJson)
        .where((e) => !e.startsAt.isBefore(from) && e.startsAt.isBefore(to));
    return all.toList();
  }

  /// Creates or updates the Calendar event for a dated college task.
  Future<Result<String>> mirrorCollegeTask(CollegeTask t) =>
      Result.guard(() async {
        if (t.dueAt == null) throw StateError('Task has no due date');
        final id = await _client.upsertEvent(
          eventId: t.gcalEventId,
          title: t.title,
          start: t.dueAt!.subtract(const Duration(minutes: 30)),
          end: t.dueAt,
        );
        if (id != t.gcalEventId) {
          await _db.update('college_tasks', t.id, {'gcal_event_id': id});
        }
        return id;
      });

  /// Creates or updates the Calendar event for a dated hackathon milestone.
  Future<Result<String>> mirrorMilestone(Milestone m) => Result.guard(() async {
    if (m.dueAt == null) throw StateError('Milestone has no due date');
    final id = await _client.upsertEvent(
      eventId: m.gcalEventId,
      title: m.title,
      start: m.dueAt!.subtract(const Duration(minutes: 30)),
      end: m.dueAt,
    );
    if (id != m.gcalEventId) {
      await _db.update('hackathon_milestones', m.id, {'gcal_event_id': id});
    }
    return id;
  });
}

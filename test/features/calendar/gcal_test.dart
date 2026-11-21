import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/models/college.dart';
import 'package:pendi/data/repos/college_repo.dart';
import 'package:pendi/data/repos/gcal_repo.dart';
import 'package:pendi/data/repos/hackathon_repo.dart';
import 'package:pendi/integrations/gcal.dart';

void main() {
  final day = DateTime.utc(2026, 11, 20, 18, 30); // 21 Nov 00:00 IST

  test(
    'sync is idempotent: no duplicate cache rows, edits update in place',
    () async {
      final db = DemoDb();
      final client = FakeCalendarClient.sample(day);
      final repo = GcalRepo(db, client);
      await repo.sync(day, day.add(const Duration(days: 1)));
      await repo.sync(day, day.add(const Duration(days: 1)));
      expect(await db.list('gcal_events_cache'), hasLength(3));
      client.events[0] = CalEvent(
        id: 'demo-1',
        title: 'OS (moved)',
        start: day.add(const Duration(hours: 11)),
      );
      await repo.sync(day, day.add(const Duration(days: 1)));
      final events = await repo.eventsBetween(
        day,
        day.add(const Duration(days: 1)),
      );
      expect(events, hasLength(3));
      expect(events.map((e) => e.title), contains('OS (moved)'));
    },
  );

  test('dated college tasks create one event, then update it', () async {
    final db = DemoDb();
    final client = FakeCalendarClient();
    final gcal = GcalRepo(db, client);
    final college = CollegeRepo(
      db,
      onTaskDated: (t) async => gcal.mirrorCollegeTask(t),
    );
    final t = (await college.addTask(
      title: 'DBMS assignment',
      kind: CollegeKind.assignment,
      dueAt: DateTime.utc(2026, 11, 25, 12),
    )).valueOrNull!;
    final saved = (await college.tasks()).single;
    expect(saved.gcalEventId, 'fake-1');
    await gcal.mirrorCollegeTask(saved);
    expect([client.creates, client.updates], [1, 1]);
    expect(client.events, hasLength(1));
    expect(t.title, 'DBMS assignment');
    await college.addTask(title: 'Undated', kind: CollegeKind.other);
    expect(client.creates, 1);
  });

  test('dated milestones are mirrored and remember their event id', () async {
    final db = DemoDb();
    final client = FakeCalendarClient();
    final gcal = GcalRepo(db, client);
    final hack = HackathonRepo(
      db,
      onMilestoneDated: (m) async => gcal.mirrorMilestone(m),
    );
    final h = (await hack.create(name: 'HackNITC')).valueOrNull!;
    await hack.addMilestone(
      h.id,
      title: 'Submit',
      dueAt: DateTime.utc(2026, 12, 1),
    );
    final m = (await hack.detail(h.id))!.milestones.single;
    expect(m.gcalEventId, 'fake-1');
    await gcal.mirrorMilestone(m);
    expect(client.events, hasLength(1));
  });

  test('calendar failures surface as errors, not crashes', () async {
    final repo = GcalRepo(DemoDb(), _Broken());
    final res = await repo.sync(day, day.add(const Duration(days: 1)));
    expect(res.errorOrNull, contains('offline'));
  });
}

class _Broken implements CalendarClient {
  @override
  Future<List<CalEvent>> listEvents(DateTime from, DateTime to) =>
      Future.error(const CalendarError('offline'));
  @override
  Future<String> upsertEvent({
    String? eventId,
    required String title,
    required DateTime start,
    DateTime? end,
  }) => Future.error(const CalendarError('offline'));
}

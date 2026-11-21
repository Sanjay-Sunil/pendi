import '../db.dart';
import 'json.dart';

class Hackathon {
  const Hackathon({
    required this.id,
    required this.name,
    required this.status,
    this.url,
    this.theme,
    this.team,
    this.notes,
  });

  factory Hackathon.fromJson(Row r) => Hackathon(
    id: r.str('id'),
    name: r.str('name'),
    status: r.str('status'),
    url: r.strOrNull('url'),
    theme: r.strOrNull('theme'),
    team: r.strOrNull('team'),
    notes: r.strOrNull('notes'),
  );

  final String id;
  final String name;
  final String status;
  final String? url;
  final String? theme;
  final String? team;
  final String? notes;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.hackathonId,
    required this.title,
    required this.done,
    this.dueAt,
    this.kind,
    this.gcalEventId,
  });

  factory Milestone.fromJson(Row r) => Milestone(
    id: r.str('id'),
    hackathonId: r.str('hackathon_id'),
    title: r.str('title'),
    done: r.boolean('done'),
    dueAt: r.time('due_at'),
    kind: r.strOrNull('kind'),
    gcalEventId: r.strOrNull('gcal_event_id'),
  );

  final String id;
  final String hackathonId;
  final String title;
  final bool done;
  final DateTime? dueAt;
  final String? kind;
  final String? gcalEventId;
}

class HackTask {
  const HackTask({
    required this.id,
    required this.hackathonId,
    required this.title,
    required this.done,
    this.dueAt,
  });

  factory HackTask.fromJson(Row r) => HackTask(
    id: r.str('id'),
    hackathonId: r.str('hackathon_id'),
    title: r.str('title'),
    done: r.boolean('done'),
    dueAt: r.time('due_at'),
  );

  final String id;
  final String hackathonId;
  final String title;
  final bool done;
  final DateTime? dueAt;
}

class HackathonDetail {
  const HackathonDetail(this.hackathon, this.milestones, this.tasks);
  final Hackathon hackathon;
  final List<Milestone> milestones;
  final List<HackTask> tasks;

  /// The earliest open milestone or task deadline.
  DateTime? get nextDeadline {
    final due = [
      ...milestones.where((m) => !m.done).map((m) => m.dueAt),
      ...tasks.where((t) => !t.done).map((t) => t.dueAt),
    ].whereType<DateTime>().toList()..sort();
    return due.firstOrNull;
  }

  double get progress => milestones.isEmpty
      ? 0
      : milestones.where((m) => m.done).length / milestones.length;
}

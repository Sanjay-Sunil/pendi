import '../db.dart';
import 'json.dart';

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.attended,
    required this.total,
    required this.minPct,
    this.code,
  });

  factory Course.fromJson(Row r) => Course(
    id: r.str('id'),
    name: r.str('name'),
    code: r.strOrNull('code'),
    attended: r.integer('attendance_attended'),
    total: r.integer('attendance_total'),
    minPct: r.integer('min_pct'),
  );

  final String id;
  final String name;
  final String? code;
  final int attended;
  final int total;
  final int minPct;
}

enum CollegeKind { assignment, exam, club, other }

class CollegeTask {
  const CollegeTask({
    required this.id,
    required this.title,
    required this.kind,
    required this.done,
    this.courseId,
    this.dueAt,
    this.doneAt,
    this.gcalEventId,
  });

  factory CollegeTask.fromJson(Row r) => CollegeTask(
    id: r.str('id'),
    title: r.str('title'),
    kind: CollegeKind.values.byName(r.str('kind')),
    done: r.boolean('done'),
    courseId: r.strOrNull('course_id'),
    dueAt: r.time('due_at'),
    doneAt: r.time('done_at'),
    gcalEventId: r.strOrNull('gcal_event_id'),
  );

  final String id;
  final String title;
  final CollegeKind kind;
  final bool done;
  final String? courseId;
  final DateTime? dueAt;
  final DateTime? doneAt;
  final String? gcalEventId;
}

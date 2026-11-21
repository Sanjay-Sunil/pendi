import '../db.dart';
import 'json.dart';

class ResearchProject {
  const ResearchProject({
    required this.id,
    required this.name,
    this.org,
    this.mentor,
  });

  factory ResearchProject.fromJson(Row r) => ResearchProject(
    id: r.str('id'),
    name: r.str('name'),
    org: r.strOrNull('org'),
    mentor: r.strOrNull('mentor'),
  );

  final String id;
  final String name;
  final String? org;
  final String? mentor;
}

class ResearchLog {
  const ResearchLog({required this.id, required this.day, required this.body});

  factory ResearchLog.fromJson(Row r) =>
      ResearchLog(id: r.str('id'), day: r.str('day'), body: r.str('body'));

  final String id;
  final String day;
  final String body;
}

enum TaskStatus { todo, doing, done }

class ResearchTask {
  const ResearchTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.assignedBy,
    this.dueAt,
    this.doneAt,
  });

  factory ResearchTask.fromJson(Row r) => ResearchTask(
    id: r.str('id'),
    title: r.str('title'),
    status: TaskStatus.values.byName(r.str('status')),
    priority: r.integer('priority'),
    assignedBy: r.strOrNull('assigned_by'),
    dueAt: r.time('due_at'),
    doneAt: r.time('done_at'),
  );

  final String id;
  final String title;
  final TaskStatus status;
  final int priority;
  final String? assignedBy;
  final DateTime? dueAt;
  final DateTime? doneAt;

  bool get isDone => status == TaskStatus.done;
}

enum PaperStatus {
  toRead('to_read', 'To read'),
  reading('reading', 'Reading'),
  done('done', 'Done');

  const PaperStatus(this.db, this.label);
  final String db;
  final String label;

  static PaperStatus fromDb(String v) => values.firstWhere((s) => s.db == v);
}

class ResearchPaper {
  const ResearchPaper({
    required this.id,
    required this.title,
    required this.status,
    this.url,
    this.summary,
    this.doneAt,
  });

  factory ResearchPaper.fromJson(Row r) => ResearchPaper(
    id: r.str('id'),
    title: r.str('title'),
    status: PaperStatus.fromDb(r.str('status')),
    url: r.strOrNull('url'),
    summary: r.strOrNull('summary'),
    doneAt: r.time('done_at'),
  );

  final String id;
  final String title;
  final PaperStatus status;
  final String? url;
  final String? summary;
  final DateTime? doneAt;
}

class ResearchIdea {
  const ResearchIdea({
    required this.id,
    required this.body,
    required this.status,
  });

  factory ResearchIdea.fromJson(Row r) => ResearchIdea(
    id: r.str('id'),
    body: r.str('body'),
    status: r.str('status'),
  );

  final String id;
  final String body;
  final String status;
}

class ResearchExperiment {
  const ResearchExperiment({
    required this.id,
    required this.title,
    required this.day,
    this.hypothesis,
    this.result,
  });

  factory ResearchExperiment.fromJson(Row r) => ResearchExperiment(
    id: r.str('id'),
    title: r.str('title'),
    day: r.str('day'),
    hypothesis: r.strOrNull('hypothesis'),
    result: r.strOrNull('result'),
  );

  final String id;
  final String title;
  final String day;
  final String? hypothesis;
  final String? result;
}

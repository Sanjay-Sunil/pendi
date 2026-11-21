import 'dates.dart';

typedef SummaryLog = ({LocalDay day, String body});
typedef SummaryTask = ({String title, DateTime doneAt});
typedef SummaryPaper = ({String title, String? summary, DateTime doneAt});
typedef SummaryExperiment = ({
  String title,
  LocalDay day,
  String? hypothesis,
  String? result,
});

/// Markdown digest of one week (Monday [weekOf]..Sunday) of research work.
String weeklySummary({
  required String project,
  required LocalDay weekOf,
  required List<SummaryLog> logs,
  required List<SummaryTask> tasks,
  required List<SummaryPaper> papers,
  required List<SummaryExperiment> experiments,
  String zone = defaultTimezone,
}) {
  final start = weekStart(weekOf);
  final end = addDays(start, 6);
  bool inWeek(LocalDay d) => d.compareTo(start) >= 0 && d.compareTo(end) <= 0;

  final weekLogs =
      logs.where((l) => inWeek(l.day) && l.body.trim().isNotEmpty).toList()
        ..sort((a, b) => a.day.compareTo(b.day));
  final weekTasks =
      tasks.where((t) => inWeek(toLocalDay(t.doneAt, zone: zone))).toList()
        ..sort((a, b) => a.doneAt.compareTo(b.doneAt));
  final weekPapers =
      papers.where((p) => inWeek(toLocalDay(p.doneAt, zone: zone))).toList()
        ..sort((a, b) => a.doneAt.compareTo(b.doneAt));
  final weekExps = experiments.where((e) => inWeek(e.day)).toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  final b = StringBuffer()
    ..writeln('# $project — week of ${formatDayLabel(start)}')
    ..writeln()
    ..writeln(
      '${weekTasks.length} tasks done · ${weekPapers.length} papers read · '
      '${weekExps.length} experiments · ${weekLogs.length} log entries',
    );

  void section(String title, Iterable<String> lines) {
    b
      ..writeln()
      ..writeln('## $title');
    final list = lines.toList();
    if (list.isEmpty) {
      b.writeln('- None this week');
    } else {
      list.forEach(b.writeln);
    }
  }

  section('Completed tasks', weekTasks.map((t) => '- ${t.title}'));
  section(
    'Papers read',
    weekPapers.map(
      (p) => p.summary == null ? '- ${p.title}' : '- ${p.title}: ${p.summary}',
    ),
  );
  section('Experiments', [
    for (final e in weekExps)
      [
        '- **${e.title}** (${formatDayLabel(e.day)})',
        if (e.hypothesis != null) '  - Hypothesis: ${e.hypothesis}',
        '  - Result: ${e.result ?? 'pending'}',
      ].join('\n'),
  ]);
  section('Daily log', [
    for (final l in weekLogs)
      '- **${formatDayLabel(l.day)}**: ${l.body.trim().replaceAll('\n', ' ')}',
  ]);
  return b.toString().trimRight();
}

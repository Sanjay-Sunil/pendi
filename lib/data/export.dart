import 'dart:convert';

import 'db.dart';
import 'models/college.dart';
import 'models/cp.dart';
import 'models/hackathon.dart';
import 'models/json.dart';
import 'models/profile.dart';
import 'models/reading.dart';
import 'models/research.dart';
import 'repos/gcal_repo.dart';
import 'repos/habit_repo.dart';
import 'repos/inbox_repo.dart';
import 'repos/notes_repo.dart';
import 'schema.dart';

/// Per-table validators: each row must parse into its model.
final Map<String, void Function(Row)> rowValidators = {
  'profiles': Profile.fromJson,
  'reading_sources': ReadingSource.fromJson,
  'reading_items': ReadingItem.fromJson,
  'cp_lists': CpList.fromJson,
  'cp_problems': CpProblem.fromJson,
  'cp_daily': (r) => (r.str('day'), r.str('problem_id')),
  'hackathons': Hackathon.fromJson,
  'hackathon_milestones': Milestone.fromJson,
  'hackathon_tasks': HackTask.fromJson,
  'research_projects': ResearchProject.fromJson,
  'research_logs': ResearchLog.fromJson,
  'research_tasks': ResearchTask.fromJson,
  'research_papers': ResearchPaper.fromJson,
  'research_ideas': ResearchIdea.fromJson,
  'research_experiments': ResearchExperiment.fromJson,
  'courses': Course.fromJson,
  'college_tasks': CollegeTask.fromJson,
  'gcal_events_cache': CachedEvent.fromJson,
  'inbox': InboxItem.fromJson,
  'habits': Habit.fromJson,
  'habit_logs': (r) => (r.str('day'), r.str('habit_id')),
  'daily_notes': DailyNote.fromJson,
};

/// All user data as pretty JSON: `{app, exportedAt, tables: {name: rows}}`.
Future<String> exportAll(Db db, DateTime now) async {
  final tablesOut = <String, Object?>{};
  for (final t in tables) {
    tablesOut[t] = await db.list(t, orderBy: 'created_at');
  }
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'pendi',
    'version': 1,
    'exportedAt': now.toUtc().toIso8601String(),
    'tables': tablesOut,
  });
}

/// Parses an export and validates every row; returns row counts per table.
Map<String, int> validateExport(String json) {
  final root = jsonDecode(json) as Map<String, Object?>;
  if (root['app'] != 'pendi') throw const FormatException('Not a Pendi export');
  final t = root['tables']! as Map<String, Object?>;
  return {
    for (final name in tables)
      name: () {
        final rows = (t[name] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>();
        rows.forEach(rowValidators[name]!);
        return rows.length;
      }(),
  };
}

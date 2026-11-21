import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/college.dart';
import '../../data/models/research.dart';
import '../../data/providers.dart';
import '../../data/repos/gcal_repo.dart';
import '../../domain/dates.dart';
import '../calendar/providers.dart';
import '../college/providers.dart';
import '../cp/providers.dart';
import '../habits/providers.dart';
import '../hackathons/providers.dart';
import '../reading/providers.dart';
import '../research/providers.dart';

enum WorkSource { hackathonTask, milestone, research }

/// A due or overdue item from the work hub, flattened for Today.
class WorkItem {
  const WorkItem(this.id, this.title, this.dueAt, this.source, {this.context});
  final String id;
  final String title;
  final DateTime dueAt;
  final WorkSource source;
  final String? context;
}

class TodayData {
  const TodayData({
    required this.day,
    required this.events,
    required this.reading,
    required this.cp,
    required this.work,
    required this.college,
    required this.inboxCount,
  });
  final LocalDay day;
  final List<CachedEvent> events;
  final List<SourceOverview> reading;
  final CpToday cp;
  final List<WorkItem> work;
  final List<CollegeTask> college;
  final int inboxCount;
}

/// Top [limit] open work items due by end of today (overdue first).
List<WorkItem> topWork({
  required List<WorkItem> candidates,
  required DateTime endOfToday,
  int limit = 3,
}) {
  final due = candidates.where((w) => w.dueAt.isBefore(endOfToday)).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  return due.take(limit).toList();
}

/// Everything Today shows, fetched in parallel in one go (no waterfall).
final todayProvider = FutureProvider<TodayData>((ref) async {
  final now = ref.watch(clockProvider)();
  final day = todayLocal(now);
  final endOfToday = startOfDay(addDays(day, 1));

  final (events, reading, cp, hacks, research, college, inbox) = await (
    ref
        .watch(todayEventsProvider.future)
        .then<List<CachedEvent>>(
          (e) => e,
          onError: (Object _) => const <CachedEvent>[],
        ),
    ref.watch(readingOverviewProvider.future),
    ref.watch(cpTodayProvider.future),
    ref.watch(hackathonsProvider.future),
    ref.watch(researchTasksProvider.future),
    ref.watch(collegeTasksProvider.future),
    ref.watch(inboxProvider.future),
  ).wait;

  final work = topWork(
    endOfToday: endOfToday,
    candidates: [
      for (final h in hacks) ...[
        for (final m in h.milestones)
          if (!m.done && m.dueAt != null)
            WorkItem(
              m.id,
              m.title,
              m.dueAt!,
              WorkSource.milestone,
              context: h.hackathon.name,
            ),
        for (final t in h.tasks)
          if (!t.done && t.dueAt != null)
            WorkItem(
              t.id,
              t.title,
              t.dueAt!,
              WorkSource.hackathonTask,
              context: h.hackathon.name,
            ),
      ],
      for (final t in research)
        if (t.status != TaskStatus.done && t.dueAt != null)
          WorkItem(
            t.id,
            t.title,
            t.dueAt!,
            WorkSource.research,
            context: 'Research',
          ),
    ],
  );

  final soon = startOfDay(addDays(day, 8));
  return TodayData(
    day: day,
    events: events,
    reading: reading,
    cp: cp,
    work: work,
    college: college
        .where((t) => !t.done && t.dueAt != null && t.dueAt!.isBefore(soon))
        .take(5)
        .toList(),
    inboxCount: inbox.length,
  );
});

void invalidateToday(WidgetRef ref) {
  ref
    ..invalidate(readingOverviewProvider)
    ..invalidate(cpTodayProvider)
    ..invalidate(hackathonsProvider)
    ..invalidate(researchTasksProvider)
    ..invalidate(collegeTasksProvider)
    ..invalidate(inboxProvider)
    ..invalidate(habitsProvider)
    ..invalidate(todayProvider);
}

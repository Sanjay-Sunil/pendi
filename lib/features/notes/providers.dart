import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/research.dart';
import '../../data/providers.dart';
import '../../data/repos/notes_repo.dart';
import '../../domain/dates.dart';
import '../../domain/day_summary.dart';
import '../college/providers.dart';
import '../cp/providers.dart';
import '../habits/providers.dart';
import '../reading/providers.dart';
import '../research/providers.dart';

final notesRepoProvider = FutureProvider<NotesRepo>(
  (ref) async => NotesRepo(await ref.watch(dbProvider.future)),
);

/// What got done today, counted from the actual completion timestamps.
final daySummaryProvider = FutureProvider.autoDispose<DaySummary>((ref) async {
  final day = todayLocal(ref.watch(clockProvider)());
  final (reading, cp, research, college, habits) = await (
    ref.watch(readingRepoProvider.future).then((r) => r.items()),
    ref.watch(cpRepoProvider.future).then((r) => r.problems()),
    ref.watch(researchRepoProvider.future).then((r) => r.tasks()),
    ref.watch(collegeRepoProvider.future).then((r) => r.tasks()),
    ref.watch(habitsProvider.future),
  ).wait;
  return summarizeDay(
    day: day,
    readingDone: reading.where((i) => i.isDone).map((i) => i.doneAt),
    cpSolved: cp.map((p) => p.solvedAt),
    researchDone: research
        .where((t) => t.status == TaskStatus.done)
        .map((t) => t.doneAt),
    collegeDone: college.where((t) => t.done).map((t) => t.doneAt),
    habitsDone: habits.where((h) => h.doneOn(day)).length,
  );
});

/// Yesterday's note holds today's top 3.
final todayTop3Provider = FutureProvider<List<String>>((ref) async {
  final day = todayLocal(ref.watch(clockProvider)());
  final note = await (await ref.watch(notesRepoProvider.future))
      .get(addDays(day, -1));
  return note?.top3 ?? const [];
});

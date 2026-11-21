import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/reading.dart';
import '../../data/providers.dart';
import '../../data/repos/reading_repo.dart';
import '../../domain/dates.dart';
import '../../domain/planner.dart';
import '../../integrations/sitemap.dart';

final readingRepoProvider = FutureProvider<ReadingRepo>(
  (ref) async => ReadingRepo(
    await ref.watch(dbProvider.future),
    now: ref.watch(clockProvider),
  ),
);

final pageExtractorProvider = Provider<PageExtractor>((ref) => PageExtractor());

class SourceOverview {
  const SourceOverview({
    required this.source,
    required this.plan,
    required this.total,
    required this.done,
  });
  final ReadingSource source;
  final TodayPlan<ReadingItem> plan;
  final int total;
  final int done;
}

/// Active sources with today's plan. Recomputed on read, so missed days redistribute.
final readingOverviewProvider = FutureProvider<List<SourceOverview>>((
  ref,
) async {
  final repo = await ref.watch(readingRepoProvider.future);
  final today = todayLocal(ref.watch(clockProvider)());
  final (sources, items) = await (repo.sources(), repo.items()).wait;
  return [
    for (final s in sources)
      () {
        final mine = items
            .where((i) => i.sourceId == s.id && i.status != ItemStatus.skipped)
            .toList();
        return SourceOverview(
          source: s,
          plan: todaysItems(
            mine,
            startDate: s.startDate,
            targetDays: s.targetDays,
            today: today,
          ),
          total: mine.length,
          done: mine.where((i) => i.isDone).length,
        );
      }(),
  ];
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cp.dart';
import '../../data/providers.dart';
import '../../data/repos/cp_repo.dart';
import '../../data/repos/profile_repo.dart';
import '../../domain/dates.dart';
import '../../integrations/codeforces.dart';

final cpRepoProvider = FutureProvider<CpRepo>(
  (ref) async =>
      CpRepo(await ref.watch(dbProvider.future), now: ref.watch(clockProvider)),
);

class CpListSummary {
  const CpListSummary(this.list, this.total, this.solved);
  final CpList list;
  final int total;
  final int solved;
}

final cpListsProvider = FutureProvider<List<CpListSummary>>((ref) async {
  final repo = await ref.watch(cpRepoProvider.future);
  final (lists, problems) = await (repo.lists(), repo.problems()).wait;
  return [
    for (final l in lists)
      CpListSummary(
        l,
        problems.where((p) => p.listId == l.id).length,
        problems.where((p) => p.listId == l.id && p.solvedAt != null).length,
      ),
  ];
});

final codeforcesProvider = Provider<CodeforcesClient>(
  (ref) => CodeforcesClient(now: ref.watch(clockProvider)),
);

final profileRepoProvider = FutureProvider<ProfileRepo>(
  (ref) async => ProfileRepo(await ref.watch(dbProvider.future)),
);

/// Pulls accepted submissions and marks matching problems solved.
/// State is true while a sync runs. [sync] returns a snackbar message; never throws.
class CpSync extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String> sync() async {
    state = true;
    try {
      final profile = await (await ref.read(profileRepoProvider.future)).get();
      final handle = profile.cfHandle;
      if (handle == null) return 'Add your Codeforces handle first';
      final keys = await ref.read(codeforcesProvider).solvedKeys(handle);
      final res = await (await ref.read(cpRepoProvider.future))
          .markSolved(keys);
      if (!res.isOk) return res.errorOrNull!;
      return res.valueOrNull == 0
          ? 'Up to date'
          : 'Marked ${res.valueOrNull} solved';
    } on CfError catch (e) {
      return e.message;
    } finally {
      ref.invalidate(cpListsProvider);
      ref.invalidate(cpTodayProvider);
      state = false;
    }
  }
}

final cpSyncProvider = NotifierProvider<CpSync, bool>(CpSync.new);

class CpToday {
  const CpToday({
    required this.problems,
    required this.streak,
    required this.review,
    required this.handle,
    required this.hasList,
    this.solvesByDay = const {},
  });
  final List<CpProblem> problems;
  final int streak;
  final List<CpProblem> review;
  final String? handle;
  final bool hasList;
  final Map<String, int> solvesByDay;
}

final cpTodayProvider = FutureProvider<CpToday>((ref) async {
  final repo = await ref.watch(cpRepoProvider.future);
  final today = todayLocal(ref.watch(clockProvider)());
  final profile = await (await ref.watch(profileRepoProvider.future)).get();
  final (daily, streak, review, active, solves) = await (
    repo.daily(today),
    repo.streakAsOf(today),
    repo.reviewQueue(),
    repo.activeList(),
    repo.solvesByDay(),
  ).wait;
  return CpToday(
    problems: daily,
    streak: streak,
    review: review,
    handle: profile.cfHandle,
    hasList: active != null,
    solvesByDay: solves,
  );
});

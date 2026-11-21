import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cp.dart';
import '../../data/providers.dart';
import '../../data/repos/cp_repo.dart';

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

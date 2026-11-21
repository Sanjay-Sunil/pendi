import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/research.dart';
import '../../data/providers.dart';
import '../../data/repos/research_repo.dart';

final researchRepoProvider = FutureProvider<ResearchRepo>(
  (ref) async => ResearchRepo(
    await ref.watch(dbProvider.future),
    now: ref.watch(clockProvider),
  ),
);

final researchLogsProvider = FutureProvider<List<ResearchLog>>(
  (ref) async => (await ref.watch(researchRepoProvider.future)).logs(),
);

final researchTasksProvider = FutureProvider<List<ResearchTask>>(
  (ref) async => (await ref.watch(researchRepoProvider.future)).tasks(),
);

class ResearchLibrary {
  const ResearchLibrary(this.papers, this.ideas, this.experiments);
  final List<ResearchPaper> papers;
  final List<ResearchIdea> ideas;
  final List<ResearchExperiment> experiments;
}

final researchLibraryProvider = FutureProvider<ResearchLibrary>((ref) async {
  final repo = await ref.watch(researchRepoProvider.future);
  final (p, i, e) = await (
    repo.papers(),
    repo.ideas(),
    repo.experiments(),
  ).wait;
  return ResearchLibrary(p, i, e);
});

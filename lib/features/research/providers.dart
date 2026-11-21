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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gcal_providers.dart';
import '../../data/models/college.dart';
import '../../data/providers.dart';
import '../../data/repos/college_repo.dart';

final collegeRepoProvider = FutureProvider<CollegeRepo>((ref) async {
  final gcal = await ref.watch(gcalRepoProvider.future);
  return CollegeRepo(
    await ref.watch(dbProvider.future),
    now: ref.watch(clockProvider),
    // Best effort: a Calendar failure never blocks saving the task.
    onTaskDated: (t) async => gcal.mirrorCollegeTask(t),
  );
});

final coursesProvider = FutureProvider<List<Course>>(
  (ref) async => (await ref.watch(collegeRepoProvider.future)).courses(),
);

final collegeTasksProvider = FutureProvider<List<CollegeTask>>(
  (ref) async => (await ref.watch(collegeRepoProvider.future)).tasks(),
);

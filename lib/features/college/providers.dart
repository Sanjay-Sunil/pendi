import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/college.dart';
import '../../data/providers.dart';
import '../../data/repos/college_repo.dart';

final collegeRepoProvider = FutureProvider<CollegeRepo>(
  (ref) async => CollegeRepo(
    await ref.watch(dbProvider.future),
    now: ref.watch(clockProvider),
  ),
);

final coursesProvider = FutureProvider<List<Course>>(
  (ref) async => (await ref.watch(collegeRepoProvider.future)).courses(),
);

final collegeTasksProvider = FutureProvider<List<CollegeTask>>(
  (ref) async => (await ref.watch(collegeRepoProvider.future)).tasks(),
);

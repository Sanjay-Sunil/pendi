import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/repos/habit_repo.dart';

final habitRepoProvider = FutureProvider<HabitRepo>(
  (ref) async => HabitRepo(await ref.watch(dbProvider.future)),
);

final habitsProvider = FutureProvider<List<HabitWithLogs>>(
  (ref) async => (await ref.watch(habitRepoProvider.future)).all(),
);

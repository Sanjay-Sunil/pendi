import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/hackathon.dart';
import '../../data/providers.dart';
import '../../data/repos/hackathon_repo.dart';

final hackathonRepoProvider = FutureProvider<HackathonRepo>(
  (ref) async => HackathonRepo(await ref.watch(dbProvider.future)),
);

final hackathonsProvider = FutureProvider<List<HackathonDetail>>(
  (ref) async => (await ref.watch(hackathonRepoProvider.future)).all(),
);

final hackathonDetailProvider = FutureProvider.family<HackathonDetail?, String>(
  (ref, id) async => (await ref.watch(hackathonRepoProvider.future)).detail(id),
);

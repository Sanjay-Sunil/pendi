import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gcal_providers.dart';
import '../../data/models/hackathon.dart';
import '../../data/providers.dart';
import '../../data/repos/hackathon_repo.dart';

final hackathonRepoProvider = FutureProvider<HackathonRepo>((ref) async {
  final gcal = await ref.watch(gcalRepoProvider.future);
  return HackathonRepo(
    await ref.watch(dbProvider.future),
    onMilestoneDated: (m) async => gcal.mirrorMilestone(m),
  );
});

final hackathonsProvider = FutureProvider<List<HackathonDetail>>(
  (ref) async => (await ref.watch(hackathonRepoProvider.future)).all(),
);

final hackathonDetailProvider = FutureProvider.family<HackathonDetail?, String>(
  (ref, id) async => (await ref.watch(hackathonRepoProvider.future)).detail(id),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gcal_providers.dart';
import '../../data/providers.dart';
import '../../data/repos/gcal_repo.dart';
import '../../domain/dates.dart';

/// Today's events: syncs the next 7 days, then reads today from the cache.
/// A failed sync still shows whatever is cached.
final todayEventsProvider = FutureProvider<List<CachedEvent>>((ref) async {
  final repo = await ref.watch(gcalRepoProvider.future);
  final start = startOfDay(todayLocal(ref.watch(clockProvider)()));
  await repo.sync(start, start.add(const Duration(days: 7)));
  return repo.eventsBetween(start, start.add(const Duration(days: 1)));
});

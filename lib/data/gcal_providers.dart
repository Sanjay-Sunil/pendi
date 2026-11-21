import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';
import '../domain/dates.dart';
import '../integrations/gcal.dart';
import 'providers.dart';
import 'repos/gcal_repo.dart';

/// Shared by every feature that writes dated items, so it lives in `lib/data`.
final calendarClientProvider = Provider<CalendarClient>((ref) {
  if (!Env.isDemo) return GoogleCalendarClient();
  return FakeCalendarClient.sample(
    startOfDay(todayLocal(ref.read(clockProvider)())),
  );
});

final gcalRepoProvider = FutureProvider<GcalRepo>(
  (ref) async => GcalRepo(
    await ref.watch(dbProvider.future),
    ref.watch(calendarClientProvider),
  ),
);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gcal_providers.dart';
import '../../data/providers.dart';
import '../../data/repos/gcal_repo.dart';
import '../../domain/dates.dart';

class CalendarDay {
  const CalendarDay(this.events, this.error);
  final List<CachedEvent> events;

  /// Why the last sync failed, or null. Cached events are still returned.
  final String? error;
}

DateTime? _lastSync;
String? _lastError;

/// Today's events from the cache, immediately. A Google sync runs in the
/// background (at most every 5 minutes, or on pull-to-refresh via [force])
/// and reloads this provider when it finishes.
final todayEventsProvider = FutureProvider<CalendarDay>((ref) async {
  final repo = await ref.watch(gcalRepoProvider.future);
  final now = ref.watch(clockProvider)();
  final start = startOfDay(todayLocal(now));
  final due =
      _lastSync == null ||
      now.difference(_lastSync!) > const Duration(minutes: 5);
  if (due) {
    _lastSync = now;
    unawaited(
      repo.sync(start, start.add(const Duration(days: 7))).then((res) {
        _lastError = res.errorOrNull;
        if (!res.isOk) debugPrint('Calendar sync failed: ${res.errorOrNull}');
        ref.invalidateSelf();
      }),
    );
  }
  return CalendarDay(
    await repo.eventsBetween(start, start.add(const Duration(days: 1))),
    _lastError,
  );
});

/// Makes the next read of [todayEventsProvider] sync with Google again.
void forceCalendarSync() => _lastSync = null;

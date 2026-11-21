import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/cp.dart';
import '../../theme/theme_mode_provider.dart';
import 'providers.dart';

/// A plain-text copy of the last Today that loaded, for opening offline.
class TodaySnapshot {
  const TodaySnapshot(this.savedAt, this.sections);

  factory TodaySnapshot.fromData(TodayData d, DateTime now) =>
      TodaySnapshot(now, [
        ('Calendar', [for (final e in d.events) e.title]),
        (
          'Reading',
          [
            for (final o in d.reading)
              for (final p in o.plan.items)
                '${p.item.isDone ? '✓ ' : ''}${p.item.title}',
          ],
        ),
        (
          'CP',
          [
            for (final p in d.cp.problems)
              '${p.status == CpStatus.solved ? '✓ ' : ''}${p.label}',
          ],
        ),
        ('Work', [for (final w in d.work) w.title]),
        ('College', [for (final t in d.college) t.title]),
      ]);

  static TodaySnapshot? decode(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return TodaySnapshot(DateTime.parse(j['savedAt']! as String), [
        for (final s
            in (j['sections']! as List<Object?>).cast<Map<String, Object?>>())
          (
            s['label']! as String,
            (s['lines']! as List<Object?>).cast<String>(),
          ),
      ]);
    } on Object {
      return null; // corrupt cache is ignored, never fatal
    }
  }

  final DateTime savedAt;
  final List<(String, List<String>)> sections;

  String encode() => jsonEncode({
    'savedAt': savedAt.toUtc().toIso8601String(),
    'sections': [
      for (final (label, lines) in sections) {'label': label, 'lines': lines},
    ],
  });
}

class TodayCache {
  TodayCache(this._prefs);
  static const key = 'today_snapshot';
  final SharedPreferences _prefs;

  Future<void> save(TodaySnapshot s) => _prefs.setString(key, s.encode());
  TodaySnapshot? load() => TodaySnapshot.decode(_prefs.getString(key));
}

final todayCacheProvider = Provider<TodayCache>(
  (ref) => TodayCache(ref.watch(sharedPrefsProvider)),
);

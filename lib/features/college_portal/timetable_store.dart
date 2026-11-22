import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/timetable.dart';
import '../../theme/theme_mode_provider.dart';

/// The inferred timetable, cached on the device (rebuilt on every sync).
class TimetableStore {
  TimetableStore(this._prefs);
  final SharedPreferences _prefs;
  static const key = 'timetable_slots';

  List<ClassSlot> load() {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return const [];
      return [
        for (final j
            in (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>())
          ClassSlot.fromJson(j),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<ClassSlot> slots) =>
      _prefs.setString(key, jsonEncode([for (final s in slots) s.toJson()]));
}

final timetableStoreProvider = Provider<TimetableStore>(
  (ref) => TimetableStore(ref.watch(sharedPrefsProvider)),
);

/// Re-read after each sync via `ref.invalidate(timetableProvider)`.
final timetableProvider = Provider<List<ClassSlot>>(
  (ref) => ref.watch(timetableStoreProvider).load(),
);

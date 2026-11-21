import '../../core/result.dart';
import '../db.dart';
import '../models/profile.dart';

class ProfileRepo {
  ProfileRepo(this._db);

  final Db _db;

  /// The user's profile, created on first access.
  Future<Profile> get() async {
    final rows = await _db.list('profiles');
    if (rows.isNotEmpty) return Profile.fromJson(rows.first);
    return Profile.fromJson((await _db.insert('profiles', [{}])).single);
  }

  Future<Result<Profile>> update({String? timezone, String? cfHandle}) =>
      Result.guard(() async {
        final p = await get();
        final patch = <String, Object?>{
          if (timezone != null)
            'timezone': requireText(timezone, 'Timezone', max: 64),
          if (cfHandle != null)
            'cf_handle': cfHandle.trim().isEmpty ? null : cfHandle.trim(),
        };
        return Profile.fromJson(await _db.update('profiles', p.id, patch));
      });
}

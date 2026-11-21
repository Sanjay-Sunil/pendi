import 'db.dart';

/// Loads bundled JSON assets; overridable in tests.
typedef AssetLoader = Future<String> Function(String path);

/// Demo-mode seed. Each feature appends its seed step here as it lands.
Future<void> seedDemo(
  Db db, {
  required DateTime now,
  required AssetLoader loadAsset,
}) async {
  await db.insert('profiles', [
    {'timezone': 'Asia/Kolkata'},
  ]);
}

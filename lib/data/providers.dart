import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import 'db.dart';
import 'demo_db.dart';
import 'seed.dart';
import 'supabase_db.dart';

/// Current time; overridden in tests for deterministic dates.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final assetLoaderProvider = Provider<AssetLoader>(
  (ref) => rootBundle.loadString,
);

/// Ready-to-use database: seeded demo store, or Supabase when configured.
final dbProvider = FutureProvider<Db>((ref) async {
  if (Env.isDemo) {
    final db = DemoDb(now: ref.read(clockProvider));
    await seedDemo(
      db,
      now: ref.read(clockProvider)(),
      loadAsset: ref.read(assetLoaderProvider),
    );
    return db;
  }
  return SupabaseDb(Supabase.instance.client);
});

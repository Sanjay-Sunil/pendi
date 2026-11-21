import 'dart:io';

import 'package:flutter_riverpod/misc.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/seed.dart';
import 'package:pendi/features/reading/providers.dart';
import 'package:pendi/integrations/sitemap.dart';

/// Reads seed assets straight from disk in tests.
/// Synchronous read: real async IO never completes inside widget tests.
Future<String> diskAssets(String path) =>
    Future.value(File(path).readAsStringSync());

class FakeExtractor implements PageExtractor {
  FakeExtractor(this.pages, {this.error});
  final List<ExtractedPage> pages;
  final ExtractError? error;
  @override
  Future<List<ExtractedPage>> extract(String rawUrl) async {
    if (error != null) throw error!;
    return pages;
  }
}

/// Standard overrides: fixed clock (21 Nov 2026, 09:30 IST), disk assets, fake extractor.
List<Override> testOverrides({DateTime? now, PageExtractor? extractor}) => [
  clockProvider.overrideWithValue(() => now ?? DateTime.utc(2026, 11, 21, 4)),
  assetLoaderProvider.overrideWithValue(diskAssets),
  pageExtractorProvider.overrideWithValue(extractor ?? FakeExtractor(const [])),
];

/// A demo database seeded exactly like the app's demo mode.
Future<DemoDb> seededDb({DateTime? now}) async {
  final t = now ?? DateTime.utc(2026, 11, 21, 4);
  final db = DemoDb(now: () => t);
  await seedDemo(db, now: t, loadAsset: diskAssets);
  return db;
}

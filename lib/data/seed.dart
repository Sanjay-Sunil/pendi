import 'dart:convert';

import '../domain/cp_import.dart';
import '../domain/dates.dart';
import 'db.dart';
import 'models/reading.dart';
import 'repos/cp_repo.dart';
import 'repos/reading_repo.dart';
import 'repos/research_repo.dart';

/// Loads bundled JSON assets; overridable in tests.
typedef AssetLoader = Future<String> Function(String path);

Future<List<NewPage>> _pages(AssetLoader load, String file) async {
  final raw = jsonDecode(await load('assets/seed/$file')) as List<Object?>;
  return [
    for (final p in raw.cast<Map<String, Object?>>())
      (title: p['title']! as String, url: p['url']! as String),
  ];
}

/// Demo-mode seed. Each feature appends its seed step here as it lands.
Future<void> seedDemo(
  Db db, {
  required DateTime now,
  required AssetLoader loadAsset,
}) async {
  final today = todayLocal(now);
  await db.insert('profiles', [
    {'timezone': defaultTimezone},
  ]);

  final reading = ReadingRepo(db, now: () => now);
  await reading.createSource(
    title: 'Designed to Scale',
    url: 'https://designed-to-scale.vercel.app/',
    kind: 'course',
    startDate: today,
    targetDays: 30,
    pages: await _pages(loadAsset, 'designed-to-scale.json'),
  );
  await reading.createSource(
    title: 'Saadho',
    url: 'https://saadho.arushk.tech/',
    kind: 'course',
    startDate: today,
    targetDays: 30,
    pages: await _pages(loadAsset, 'saadho.json'),
  );

  await CpRepo(db, now: () => now).createList(
    'Codeforces 800 warmups',
    parseProblemList(await loadAsset('assets/seed/cp-sample.json')).problems,
    source: 'bundled sample',
  );

  await ResearchRepo(db, now: () => now).project();
}

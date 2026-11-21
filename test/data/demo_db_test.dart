import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/db.dart';
import 'package:pendi/data/demo_db.dart';

void main() {
  DemoDb fresh() => DemoDb(now: () => DateTime.utc(2026, 1, 1));

  test('inserts with defaults, ids, demo user and timestamp', () async {
    final db = fresh();
    final [src] = await db.insert('reading_sources', [
      {
        'title': 'Docs',
        'url': 'https://a.dev/',
        'start_date': '2026-01-01',
        'target_days': 30,
      },
    ]);
    expect(src['status'], 'active');
    expect(src['kind'], 'course');
    expect(src['user_id'], demoUserId);
    expect(src['created_at'], '2026-01-01T00:00:00.000Z');
    expect((src['id']! as String).length, 36);
  });

  test('lists with filters and ordering', () async {
    final db = fresh();
    await db.insert('reading_items', [
      {'source_id': 's', 'title': 'b', 'url': 'u/b', 'position': 2},
      {'source_id': 's', 'title': 'a', 'url': 'u/a', 'position': 1},
      {'source_id': 'x', 'title': 'z', 'url': 'u/z', 'position': 0},
    ]);
    final items = await db.list(
      'reading_items',
      where: {'source_id': 's'},
      orderBy: 'position',
    );
    expect(items.map((r) => r['title']), ['a', 'b']);
    final desc = await db.list(
      'reading_items',
      orderBy: 'position',
      ascending: false,
    );
    expect(desc.first['title'], 'b');
  });

  test('updates, gets, removes; returns copies', () async {
    final db = fresh();
    final [h] = await db.insert('habits', [
      {'name': 'Walk'},
    ]);
    h['name'] = 'mutated';
    expect((await db.get('habits', h['id']! as String))!['name'], 'Walk');
    final u = await db.update('habits', h['id']! as String, {'name': 'Run'});
    expect(u['name'], 'Run');
    await db.remove('habits', h['id']! as String);
    expect(await db.get('habits', h['id']! as String), isNull);
  });

  test('enforces unique constraints', () async {
    final db = fresh();
    await db.insert('habit_logs', [
      {'habit_id': 'h', 'day': '2026-01-01'},
    ]);
    expect(
      () => db.insert('habit_logs', [
        {'habit_id': 'h', 'day': '2026-01-01'},
      ]),
      throwsA(isA<DbConflict>()),
    );
  });

  test('throws not found on missing update', () {
    expect(
      () => fresh().update('habits', 'nope', {'name': 'x'}),
      throwsA(isA<DbNotFound>()),
    );
  });

  test('cascades deletes', () async {
    final db = fresh();
    final [h] = await db.insert('habits', [
      {'name': 'Read'},
    ]);
    await db.insert('habit_logs', [
      {'habit_id': h['id'], 'day': '2026-01-01'},
    ]);
    await db.remove('habits', h['id']! as String);
    expect(await db.list('habit_logs'), isEmpty);
  });
}

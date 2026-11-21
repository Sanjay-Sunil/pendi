import '../../core/result.dart';
import '../db.dart';
import '../models/json.dart';
import '../models/reading.dart';

class ReadingRepo {
  ReadingRepo(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Db _db;
  final DateTime Function() _now;

  Future<List<ReadingSource>> sources({String status = 'active'}) async =>
      (await _db.list(
        'reading_sources',
        where: {'status': status},
        orderBy: 'created_at',
      )).map(ReadingSource.fromJson).toList();

  Future<List<ReadingItem>> items({String? sourceId}) async => (await _db.list(
    'reading_items',
    where: sourceId == null ? const {} : {'source_id': sourceId},
    orderBy: 'position',
  )).map(ReadingItem.fromJson).toList();

  /// Appends pages after the last position, skipping URLs the source already has.
  Future<List<ReadingItem>> _append(
    String sourceId,
    List<NewPage> pages,
  ) async {
    final existing = await items(sourceId: sourceId);
    final seen = existing.map((i) => i.url).toSet();
    var position = existing.fold(-1, (m, i) => i.position > m ? i.position : m);
    final fresh = <Row>[];
    for (final p in pages) {
      if (!seen.add(p.url)) continue;
      fresh.add({
        'source_id': sourceId,
        'title': p.title,
        'url': p.url,
        'position': ++position,
      });
    }
    return (await _db.insert(
      'reading_items',
      fresh,
    )).map(ReadingItem.fromJson).toList();
  }

  Future<Result<ReadingSource>> createSource({
    required String title,
    required String url,
    required String kind,
    required String startDate,
    required Object targetDays,
    required List<NewPage> pages,
  }) => Result.guard(() async {
    final row = {
      'title': requireText(title, 'Title', max: 200),
      'url': requireUrl(url, 'Link'),
      'kind': kind == 'blog' ? 'blog' : 'course',
      'start_date': startDate,
      'target_days': requireInt(targetDays, 'Days', min: 1, max: 365),
    };
    if (pages.isEmpty) throw const ValidationError('Pick at least one page');
    for (final p in pages) {
      requireText(p.title, 'Page title', max: 300);
      requireUrl(p.url, 'Page link');
    }
    final source = ReadingSource.fromJson(
      (await _db.insert('reading_sources', [row])).single,
    );
    await _append(source.id, pages);
    return source;
  });

  Future<Result<int>> addItems(String sourceId, List<NewPage> pages) =>
      Result.guard(() async => (await _append(sourceId, pages)).length);

  Future<Result<ReadingItem>> setDone(
    String id,
    bool done, {
    String? note,
  }) => Result.guard(() async {
    final patch = <String, Object?>{
      'status': done ? 'done' : 'todo',
      'done_at': done ? isoOrNull(_now()) : null,
    };
    if (note != null) patch['note'] = note.trim().isEmpty ? null : note.trim();
    return ReadingItem.fromJson(await _db.update('reading_items', id, patch));
  });

  Future<Result<ReadingItem>> setNote(String id, String note) =>
      Result.guard(() async {
        if (note.length > 280)
          throw const ValidationError('Note is too long (max 280)');
        return ReadingItem.fromJson(
          await _db.update('reading_items', id, {
            'note': note.trim().isEmpty ? null : note.trim(),
          }),
        );
      });

  Future<Result<void>> archive(String id) => Result.guard(
    () => _db.update('reading_sources', id, {'status': 'archived'}),
  );
}

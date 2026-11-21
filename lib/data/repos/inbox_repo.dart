import '../../core/result.dart';
import '../db.dart';
import '../models/json.dart';

class InboxItem {
  const InboxItem({
    required this.id,
    required this.body,
    required this.createdAt,
  });

  factory InboxItem.fromJson(Row r) => InboxItem(
    id: r.str('id'),
    body: r.str('body'),
    createdAt: r.time('created_at')!,
  );

  final String id;
  final String body;
  final DateTime createdAt;
}

class InboxRepo {
  InboxRepo(this._db);

  final Db _db;

  Future<List<InboxItem>> open() async => (await _db.list(
    'inbox',
    where: {'resolved': false},
    orderBy: 'created_at',
    ascending: false,
  )).map(InboxItem.fromJson).toList();

  Future<int> openCount() async => (await open()).length;

  Future<Result<InboxItem>> add(String body) => Result.guard(
    () async => InboxItem.fromJson(
      (await _db.insert('inbox', [
        {'body': requireText(body, 'Note', max: 2000)},
      ])).single,
    ),
  );

  Future<Result<void>> resolve(String id) =>
      Result.guard(() => _db.update('inbox', id, {'resolved': true}));
}

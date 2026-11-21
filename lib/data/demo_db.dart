import 'dart:math';

import 'db.dart';
import 'schema.dart';

const demoUserId = '00000000-0000-4000-8000-000000000001';

String newId([Random? random]) {
  final r = random ?? Random();
  String hex(int n) =>
      List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

Row _copy(Row r) => {
  for (final e in r.entries)
    e.key: e.value is List ? List<Object?>.of(e.value! as List) : e.value,
};

int _compare(Object? a, Object? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  if (a is num && b is num) return a.compareTo(b);
  if (a is bool && b is bool) return a ? 1 : -1;
  return a.toString().compareTo(b.toString());
}

/// In-memory adapter used when Supabase is not configured. Mirrors SQL defaults,
/// unique constraints and cascading deletes, and always returns copies.
class DemoDb implements Db {
  DemoDb({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, List<Row>> _store = {};

  @override
  bool get isDemo => true;

  List<Row> _rows(String table) => _store.putIfAbsent(table, () => []);

  void _assertUnique(String table, Row row, {String? ignoreId}) {
    for (final key in uniqueKeys[table] ?? const <List<String>>[]) {
      final clash = _rows(table)
          .any((r) => r['id'] != ignoreId && key.every((k) => r[k] == row[k]));
      if (clash) throw DbConflict('$table: duplicate ${key.join(', ')}');
    }
  }

  @override
  Future<List<Row>> list(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    bool ascending = true,
  }) async {
    final out = _rows(table)
        .where((r) => where.entries.every((w) => r[w.key] == w.value))
        .map(_copy)
        .toList();
    if (orderBy != null) {
      out.sort(
        (a, b) => (ascending ? 1 : -1) * _compare(a[orderBy], b[orderBy]),
      );
    }
    return out;
  }

  @override
  Future<Row?> get(String table, String id) async {
    for (final r in _rows(table)) {
      if (r['id'] == id) return _copy(r);
    }
    return null;
  }

  @override
  Future<List<Row>> insert(String table, List<Row> rows) async {
    final created = <Row>[];
    for (final v in rows) {
      final row = <String, Object?>{
        ...?columnDefaults[table],
        ...v,
        'id': v['id'] ?? newId(),
        'user_id': demoUserId,
        'created_at': _now().toUtc().toIso8601String(),
      };
      _assertUnique(table, row);
      _rows(table).add(row);
      created.add(_copy(row));
    }
    return created;
  }

  @override
  Future<Row> update(String table, String id, Row patch) async {
    final rows = _rows(table);
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i < 0) throw DbNotFound('$table: $id not found');
    final next = {
      ...rows[i],
      ...patch,
      'id': id,
      'user_id': rows[i]['user_id'],
    };
    _assertUnique(table, next, ignoreId: id);
    rows[i] = next;
    return _copy(next);
  }

  @override
  Future<void> remove(String table, String id) async {
    final rows = _rows(table);
    final i = rows.indexWhere((r) => r['id'] == id);
    if (i < 0) return;
    rows.removeAt(i);
    for (final (child, fk) in cascades[table] ?? const <(String, String)>[]) {
      final orphans = _rows(child)
          .where((r) => r[fk] == id)
          .map((r) => r['id']! as String);
      for (final o in orphans.toList()) {
        await remove(child, o);
      }
    }
  }
}

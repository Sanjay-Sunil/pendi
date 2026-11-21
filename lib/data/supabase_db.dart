import 'package:supabase_flutter/supabase_flutter.dart';

import 'db.dart';

/// Supabase adapter. RLS scopes every query to the signed-in user; `user_id`
/// defaults to `auth.uid()` in SQL so inserts never send it.
class SupabaseDb implements Db {
  SupabaseDb(this._client);

  final SupabaseClient _client;

  @override
  bool get isDemo => false;

  Never _fail(String table, Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') throw DbConflict('$table: ${e.message}');
      if (e.code == 'PGRST116') throw DbNotFound('$table: ${e.message}');
      throw DbBackendError('$table: ${e.message}');
    }
    throw DbBackendError('$table: $e');
  }

  @override
  Future<List<Row>> list(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      PostgrestFilterBuilder<List<Map<String, dynamic>>> q = _client
          .from(table)
          .select();
      for (final w in where.entries) {
        q = w.value == null ? q.isFilter(w.key, null) : q.eq(w.key, w.value!);
      }
      final rows = orderBy == null
          ? await q
          : await q.order(orderBy, ascending: ascending);
      return rows.map(Row.of).toList();
    } catch (e) {
      _fail(table, e);
    }
  }

  @override
  Future<Row?> get(String table, String id) async {
    try {
      final r = await _client.from(table).select().eq('id', id).maybeSingle();
      return r == null ? null : Row.of(r);
    } catch (e) {
      _fail(table, e);
    }
  }

  @override
  Future<List<Row>> insert(String table, List<Row> rows) async {
    if (rows.isEmpty) return [];
    try {
      final out = await _client.from(table).insert(rows).select();
      return out.map(Row.of).toList();
    } catch (e) {
      _fail(table, e);
    }
  }

  @override
  Future<Row> update(String table, String id, Row patch) async {
    try {
      return Row.of(
        await _client.from(table).update(patch).eq('id', id).select().single(),
      );
    } catch (e) {
      _fail(table, e);
    }
  }

  @override
  Future<void> remove(String table, String id) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      _fail(table, e);
    }
  }
}

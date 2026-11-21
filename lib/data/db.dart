/// One row as stored: column name → JSON value.
typedef Row = Map<String, Object?>;

/// The only way repositories touch storage. Implemented by [DemoDb] and [SupabaseDb].
abstract class Db {
  bool get isDemo;

  Future<List<Row>> list(
    String table, {
    Map<String, Object?> where = const {},
    String? orderBy,
    bool ascending = true,
  });

  Future<Row?> get(String table, String id);

  Future<List<Row>> insert(String table, List<Row> rows);

  Future<Row> update(String table, String id, Row patch);

  Future<void> remove(String table, String id);
}

sealed class DbException implements Exception {
  const DbException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DbConflict extends DbException {
  const DbConflict(super.message);
}

class DbNotFound extends DbException {
  const DbNotFound(super.message);
}

class DbBackendError extends DbException {
  const DbBackendError(super.message);
}

/// Outcome of a mutation: a value or a human-readable error. Never throws.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };
  String? get errorOrNull => switch (this) {
    Ok() => null,
    Err(:final message) => message,
  };

  /// Runs [body], turning any exception into an [Err].
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on ValidationError catch (e) {
      return Err(e.message);
    } catch (e) {
      return Err(e.toString());
    }
  }
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}

class ValidationError implements Exception {
  const ValidationError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Small validation helpers for repo inputs.
String requireText(String? v, String field, {int max = 500}) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) throw ValidationError('$field is required');
  if (t.length > max) throw ValidationError('$field is too long (max $max)');
  return t;
}

String requireUrl(String? v, String field) {
  final t = requireText(v, field, max: 2000);
  final u = Uri.tryParse(t);
  if (u == null ||
      !(u.scheme == 'http' || u.scheme == 'https') ||
      u.host.isEmpty) {
    throw ValidationError('$field must be a full http(s) link');
  }
  return t;
}

int requireInt(Object? v, String field, {required int min, required int max}) {
  final n = v is int ? v : int.tryParse('$v'.trim());
  if (n == null || n < min || n > max) {
    throw ValidationError('$field must be a whole number from $min to $max');
  }
  return n;
}

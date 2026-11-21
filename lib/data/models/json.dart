import '../db.dart';

/// Typed readers for loosely typed JSON rows. Throw [FormatException] on bad shape.
extension RowRead on Row {
  String str(String k) {
    final v = this[k];
    if (v is String) return v;
    throw FormatException('Expected string for $k, got $v');
  }

  String? strOrNull(String k) => this[k] as String?;

  int integer(String k) {
    final v = this[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw FormatException('Expected int for $k, got $v');
  }

  int? intOrNull(String k) => this[k] == null ? null : integer(k);

  bool boolean(String k) => this[k] == true;

  DateTime? time(String k) {
    final v = this[k];
    return v is String ? DateTime.parse(v) : null;
  }

  List<String> strings(String k) => [
    ...?(this[k] as List<Object?>?)?.whereType<String>(),
  ];
}

String? isoOrNull(DateTime? t) => t?.toUtc().toIso8601String();

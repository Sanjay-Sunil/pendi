/// Case-insensitive match of every word in [query] against any of [fields].
bool matchesQuery(String query, Iterable<String?> fields) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final hay = fields.whereType<String>().join(' ').toLowerCase();
  return words.every(hay.contains);
}

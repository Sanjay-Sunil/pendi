import 'dart:convert';

typedef ParsedProblem = ({
  int contestId,
  String index,
  String? name,
  int? rating,
});
typedef ImportError = ({int line, String text, String reason});

class ImportResult {
  const ImportResult(this.problems, this.errors);
  final List<ParsedProblem> problems;
  final List<ImportError> errors;
}

final _url = RegExp(
  r'codeforces\.com/(?:contest|gym)/(\d+)/problem/([A-Za-z]\d?)|codeforces\.com/problemset/problem/(\d+)/([A-Za-z]\d?)',
);
final _pair = RegExp(r'^(\d+)\s*[,;\s]\s*([A-Za-z]\d?)\b');
final _joined = RegExp(r'^(\d+)([A-Za-z]\d?)$');

ParsedProblem _p(String contest, String index, {String? name, int? rating}) => (
  contestId: int.parse(contest),
  index: index.toUpperCase(),
  name: name,
  rating: rating,
);

/// Parses pasted problems: Codeforces URLs, `contestId,index` CSV lines, `1950B`,
/// or a JSON array of `{contestId, index, name?, rating?}` / `[contestId, "B"]`.
/// Bad lines are reported, never fatal. Duplicates are dropped.
ImportResult parseProblemList(String text) {
  final trimmed = text.trim();
  final problems = <ParsedProblem>[];
  final errors = <ImportError>[];
  final seen = <String>{};
  void add(ParsedProblem p) {
    if (seen.add('${p.contestId}${p.index}')) problems.add(p);
  }

  if (trimmed.startsWith('[')) {
    try {
      final raw = jsonDecode(trimmed) as List<Object?>;
      for (var i = 0; i < raw.length; i++) {
        final e = raw[i];
        if (e is Map && e['contestId'] is int && e['index'] is String) {
          add(
            _p(
              '${e['contestId']}',
              e['index'] as String,
              name: e['name'] as String?,
              rating: e['rating'] as int?,
            ),
          );
        } else if (e is List &&
            e.length >= 2 &&
            e[0] is int &&
            e[1] is String) {
          add(_p('${e[0]}', e[1] as String));
        } else {
          errors.add((
            line: i + 1,
            text: jsonEncode(e),
            reason: 'Expected {contestId, index}',
          ));
        }
      }
    } on FormatException catch (e) {
      errors.add((
        line: 1,
        text: trimmed.split('\n').first,
        reason: 'Invalid JSON: ${e.message}',
      ));
    }
    return ImportResult(problems, errors);
  }

  final lines = trimmed.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    final skip =
        line.isEmpty ||
        line.startsWith('#') ||
        line.toLowerCase().startsWith('contest');
    if (skip) continue;
    final u = _url.firstMatch(line);
    final m = u == null
        ? (_pair.firstMatch(line) ?? _joined.firstMatch(line))
        : null;
    if (u != null) {
      add(_p(u.group(1) ?? u.group(3)!, u.group(2) ?? u.group(4)!));
    } else if (m != null) {
      add(_p(m.group(1)!, m.group(2)!));
    } else {
      errors.add((line: i + 1, text: line, reason: 'Not a Codeforces problem'));
    }
  }
  return ImportResult(problems, errors);
}

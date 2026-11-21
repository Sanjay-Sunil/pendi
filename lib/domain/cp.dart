enum CpStatus { todo, solved, review, skipped }

/// What the picker needs to know about a problem.
abstract interface class PickableProblem {
  String get id;
  int get position;
  CpStatus get status;
}

/// Stable key for a Codeforces problem, e.g. `1950B`.
String canonicalKey(int contestId, String index) =>
    '$contestId${index.trim().toUpperCase()}';

/// Today's problems. If [alreadyPicked] has ids for the day, those are returned
/// unchanged (idempotent). Otherwise problems in review come first, then todo,
/// each in list order. The caller persists the result.
List<String> pickDaily(
  List<PickableProblem> problems,
  List<String> alreadyPicked, {
  int count = 2,
}) {
  if (alreadyPicked.isNotEmpty) return alreadyPicked;
  final ordered = [...problems]
    ..sort((a, b) => a.position.compareTo(b.position));
  return [
    ...ordered.where((p) => p.status == CpStatus.review),
    ...ordered.where((p) => p.status == CpStatus.todo),
  ].take(count).map((p) => p.id).toList();
}

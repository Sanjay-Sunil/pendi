import '../../domain/cp.dart';
import '../db.dart';
import 'json.dart';

class CpList {
  const CpList({
    required this.id,
    required this.name,
    required this.active,
    this.source,
  });

  factory CpList.fromJson(Row r) => CpList(
    id: r.str('id'),
    name: r.str('name'),
    active: r.boolean('active'),
    source: r.strOrNull('source'),
  );

  final String id;
  final String name;
  final bool active;
  final String? source;
}

class CpProblem implements PickableProblem {
  const CpProblem({
    required this.id,
    required this.listId,
    required this.contestId,
    required this.index,
    required this.position,
    required this.status,
    this.name,
    this.rating,
    this.solvedAt,
    this.note,
  });

  factory CpProblem.fromJson(Row r) => CpProblem(
    id: r.str('id'),
    listId: r.str('list_id'),
    contestId: r.integer('contest_id'),
    index: r.str('idx'),
    position: r.integer('position'),
    status: CpStatus.values.byName(r.str('status')),
    name: r.strOrNull('name'),
    rating: r.intOrNull('rating'),
    solvedAt: r.time('solved_at'),
    note: r.strOrNull('note'),
  );

  @override
  final String id;
  final String listId;
  final int contestId;
  final String index;
  @override
  final int position;
  @override
  final CpStatus status;
  final String? name;
  final int? rating;
  final DateTime? solvedAt;
  final String? note;

  String get key => canonicalKey(contestId, index);
  String get label => name == null ? key : '$key · $name';
  String get url =>
      'https://codeforces.com/problemset/problem/$contestId/$index';
}

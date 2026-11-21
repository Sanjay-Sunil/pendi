import '../../domain/planner.dart';
import '../db.dart';
import 'json.dart';

class ReadingSource {
  const ReadingSource({
    required this.id,
    required this.title,
    required this.url,
    required this.kind,
    required this.startDate,
    required this.targetDays,
    required this.status,
  });

  factory ReadingSource.fromJson(Row r) => ReadingSource(
    id: r.str('id'),
    title: r.str('title'),
    url: r.str('url'),
    kind: r.str('kind'),
    startDate: r.str('start_date'),
    targetDays: r.integer('target_days'),
    status: r.str('status'),
  );

  final String id;
  final String title;
  final String url;
  final String kind;
  final String startDate;
  final int targetDays;
  final String status;
}

class ReadingItem implements PlannerItem {
  const ReadingItem({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.url,
    required this.position,
    required this.status,
    this.doneAt,
    this.note,
  });

  factory ReadingItem.fromJson(Row r) => ReadingItem(
    id: r.str('id'),
    sourceId: r.str('source_id'),
    title: r.str('title'),
    url: r.str('url'),
    position: r.integer('position'),
    status: ItemStatus.values.byName(r.str('status')),
    doneAt: r.time('done_at'),
    note: r.strOrNull('note'),
  );

  final String id;
  final String sourceId;
  final String title;
  final String url;
  @override
  final int position;
  @override
  final ItemStatus status;
  @override
  final DateTime? doneAt;
  final String? note;

  bool get isDone => status == ItemStatus.done;

  ReadingItem copyWith({
    ItemStatus? status,
    DateTime? doneAt,
    bool clearDoneAt = false,
  }) => ReadingItem(
    id: id,
    sourceId: sourceId,
    title: title,
    url: url,
    position: position,
    status: status ?? this.status,
    doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
    note: note,
  );
}

typedef NewPage = ({String title, String url});

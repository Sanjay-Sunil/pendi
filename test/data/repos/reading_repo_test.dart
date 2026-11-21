import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/reading_repo.dart';
import 'package:pendi/domain/planner.dart';

void main() {
  final now = DateTime.utc(2026, 3, 2, 5);
  ReadingRepo repo() => ReadingRepo(DemoDb(), now: () => now);

  Future<String> create(
    ReadingRepo r,
    List<({String title, String url})> pages,
  ) async => (await r.createSource(
    title: 'Designed to Scale',
    url: 'https://designed-to-scale.vercel.app/',
    kind: 'course',
    startDate: '2026-03-01',
    targetDays: 30,
    pages: pages,
  )).valueOrNull!.id;

  test('creates a source with ordered items', () async {
    final r = repo();
    final id = await create(r, [
      (title: 'Intro', url: 'https://d.dev/intro'),
      (title: 'Caching', url: 'https://d.dev/caching'),
    ]);
    final items = await r.items(sourceId: id);
    expect(items.map((i) => [i.title, i.position]), [
      ['Intro', 0],
      ['Caching', 1],
    ]);
    expect(await r.sources(), hasLength(1));
  });

  test('appends after the last position and skips duplicate urls', () async {
    final r = repo();
    final id = await create(r, [(title: 'A', url: 'https://x.dev/a')]);
    final added = await r.addItems(id, [
      (title: 'A again', url: 'https://x.dev/a'),
      (title: 'B', url: 'https://x.dev/b'),
      (title: 'B twice', url: 'https://x.dev/b'),
    ]);
    expect(added.valueOrNull, 1);
    expect((await r.items(sourceId: id)).last.position, 1);
  });

  test('toggles items with a timestamp and note', () async {
    final r = repo();
    final id = await create(r, [(title: 'A', url: 'https://x.dev/a')]);
    final item = (await r.items(sourceId: id)).single;
    final done = (await r.setDone(
      item.id,
      true,
      note: 'Good intro',
    )).valueOrNull!;
    expect(done.status, ItemStatus.done);
    expect(done.doneAt, now);
    expect(done.note, 'Good intro');
    final undone = (await r.setDone(item.id, false)).valueOrNull!;
    expect(undone.status, ItemStatus.todo);
    expect(undone.doneAt, isNull);
    expect(undone.note, 'Good intro');
  });

  test('archives a source', () async {
    final r = repo();
    final id = await create(r, [(title: 'A', url: 'https://x.dev/a')]);
    await r.archive(id);
    expect(await r.sources(), isEmpty);
    expect(await r.sources(status: 'archived'), hasLength(1));
  });

  test('validates input', () async {
    final r = repo();
    final noPages = await r.createSource(
      title: 'T',
      url: 'https://x.dev',
      kind: 'blog',
      startDate: '2026-03-01',
      targetDays: '14',
      pages: [],
    );
    expect(noPages.errorOrNull, 'Pick at least one page');
    final badDays = await r.createSource(
      title: 'T',
      url: 'https://x.dev',
      kind: 'blog',
      startDate: '2026-03-01',
      targetDays: 0,
      pages: [(title: 'p', url: 'https://x.dev/p')],
    );
    expect(badDays.errorOrNull, contains('Days'));
  });
}

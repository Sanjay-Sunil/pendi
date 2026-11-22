import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/models/college.dart';
import 'package:pendi/data/repos/college_repo.dart';

void main() {
  test(
    'deadlines upsert by Moodle id and mirror to Calendar once each',
    () async {
      final mirrored = <String>[];
      final repo = CollegeRepo(
        DemoDb(),
        onTaskDated: (t) async => mirrored.add(t.title),
      );
      final due = DateTime.utc(2026, 11, 26, 12);
      final items = [
        (
          externalId: 'moodle:901',
          title: 'CS311 · Lab 4',
          kind: CollegeKind.assignment,
          dueAt: due,
        ),
        (
          externalId: 'moodle:902',
          title: 'CS312 · Quiz 2',
          kind: CollegeKind.exam,
          dueAt: due,
        ),
      ];
      expect((await repo.syncDeadlines(items)).valueOrNull, (
        added: 2,
        updated: 0,
      ));
      expect((await repo.syncDeadlines(items)).valueOrNull, (
        added: 0,
        updated: 0,
      ));
      final moved = [
        (
          externalId: 'moodle:901',
          title: 'CS311 · Lab 4',
          kind: CollegeKind.assignment,
          dueAt: due.add(const Duration(days: 1)),
        ),
      ];
      expect((await repo.syncDeadlines(moved)).valueOrNull, (
        added: 0,
        updated: 1,
      ));
      expect(await repo.tasks(), hasLength(2));
      expect(mirrored, ['CS311 · Lab 4', 'CS312 · Quiz 2', 'CS311 · Lab 4']);
    },
  );
}

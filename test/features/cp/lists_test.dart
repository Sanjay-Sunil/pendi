import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/repos/cp_repo.dart';
import 'package:pendi/domain/cp_import.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('create, rename, and activate lists', () async {
    final repo = CpRepo(DemoDb());
    final a = (await repo.createList(
      'A',
      parseProblemList('4A\n1A').problems,
    )).valueOrNull!;
    final b = (await repo.createList(
      'B',
      parseProblemList('71A').problems,
    )).valueOrNull!;
    expect(a.active, isTrue);
    expect(b.active, isFalse);
    await repo.activate(b.id);
    expect((await repo.activeList())!.id, b.id);
    expect((await repo.lists()).where((l) => l.active), hasLength(1));
    await repo.rename(b.id, 'Warmups');
    expect((await repo.activeList())!.name, 'Warmups');
    expect((await repo.problems(listId: a.id)).map((p) => p.key), ['4A', '1A']);
    expect(
      (await repo.createList('C', const [])).errorOrNull,
      'No valid problems to import',
    );
  });

  testWidgets('imports a pasted list and reports bad lines', (tester) async {
    await pumpApp(
      tester,
      location: '/cp',
      height: 1400,
      overrides: testOverrides(),
    );
    expect(find.text('Codeforces 800 warmups'), findsOneWidget);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          )
          .at(0),
      'Level 1',
    );
    await tester.enterText(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(TextField),
          )
          .at(1),
      'https://codeforces.com/contest/1950/problem/B\nnot a problem\n4A',
    );
    await tester.pump();
    expect(find.text('2 problems found · 1 skipped'), findsOneWidget);
    expect(find.textContaining('Line 2'), findsOneWidget);
    await tester.tap(find.text('Import 2 problems'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);
  });
}

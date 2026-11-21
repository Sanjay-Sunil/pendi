import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/models/research.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/repos/research_repo.dart';
import 'package:pendi/domain/search.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('matchesQuery needs every word somewhere', () {
    expect(matchesQuery('', ['x']), isTrue);
    expect(
      matchesQuery('graph neural', ['Graph attention', 'neural nets']),
      isTrue,
    );
    expect(matchesQuery('graph lstm', ['Graph attention']), isFalse);
  });

  test('papers move between statuses with done timestamp', () async {
    final repo = ResearchRepo(DemoDb(), now: () => DateTime.utc(2026, 11, 21));
    final p = (await repo.addPaper('Attention Is All You Need')).valueOrNull!;
    expect(p.status, PaperStatus.toRead);
    final r = (await repo.updatePaper(
      p.id,
      status: PaperStatus.reading,
    )).valueOrNull!;
    expect(r.status, PaperStatus.reading);
    final d = (await repo.updatePaper(
      p.id,
      status: PaperStatus.done,
      summary: 'Transformers',
    )).valueOrNull!;
    expect(
      [d.status, d.doneAt, d.summary],
      [PaperStatus.done, DateTime.utc(2026, 11, 21), 'Transformers'],
    );
  });

  testWidgets('one search box filters across all tabs', (tester) async {
    final db = DemoDb();
    final repo = ResearchRepo(db);
    await repo.addPaper('Graph attention networks');
    await repo.addPaper('LSTM survey');
    await repo.addIdea('Try graph pooling on molecules');
    await repo.addExperiment(title: 'Baseline LSTM', day: '2026-11-20');
    await pumpApp(
      tester,
      location: '/work',
      height: 3000,
      overrides: [
        ...testOverrides(),
        dbProvider.overrideWith((ref) async => db),
      ],
    );
    await tester.tap(find.text('Research'));
    await tester.pumpAndSettle();
    expect(find.text('Papers (2)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('library-search')), 'graph');
    await tester.pumpAndSettle();
    expect(find.text('Papers (1)'), findsOneWidget);
    expect(find.text('Ideas (1)'), findsOneWidget);
    expect(find.text('Experiments (0)'), findsOneWidget);
    expect(find.text('LSTM survey'), findsNothing);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/db.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/features/today/today_cache.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('snapshot round-trips; corrupt cache is ignored', () async {
    final prefs = await testPrefs();
    final cache = TodayCache(prefs);
    await cache.save(
      TodaySnapshot(DateTime.utc(2026, 11, 21, 4), [
        ('CP', ['4A · Watermelon']),
      ]),
    );
    expect(cache.load()!.sections.single.$2, ['4A · Watermelon']);
    await prefs.setString(TodayCache.key, '{nope');
    expect(cache.load(), isNull);
  });

  testWidgets('offline shows the cached Today with a friendly banner', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        ...testOverrides(),
        dbProvider.overrideWith(
          (ref) async => throw const DbBackendError('offline'),
        ),
      ],
    );
    expect(find.textContaining("You're offline"), findsOneWidget);
  });
}

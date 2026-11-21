import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/data/export.dart';
import 'package:pendi/data/schema.dart';
import 'package:pendi/domain/dates.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('export round-trips through every model for every table', () async {
    final db = await seededDb();
    final json = await exportAll(db, DateTime.utc(2026, 11, 21));
    final counts = validateExport(json);
    expect(counts.keys.toSet(), tables.toSet());
    expect(counts['reading_items'], 181);
    expect(counts['cp_problems'], 20);
    expect(counts['habits'], 2);
    expect(
      () => validateExport('{"app":"other","tables":{}}'),
      throwsFormatException,
    );
  });

  test('timezone validation', () {
    expect(isValidTimezone('Asia/Kolkata'), isTrue);
    expect(isValidTimezone('Mars/Olympus'), isFalse);
  });

  testWidgets('settings opens from Today and switches theme', (tester) async {
    await pumpApp(tester, height: 1400);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Export all data (JSON)'), findsOneWidget);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(find.text('Codeforces handle'), findsOneWidget);
  });
}

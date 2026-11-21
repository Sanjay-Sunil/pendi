import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('Today loads from one parallel fetch quickly in demo mode', (
    tester,
  ) async {
    final sw = Stopwatch()..start();
    await pumpApp(tester);
    sw.stop();
    debugPrint('PERF today_first_settle_ms=${sw.elapsedMilliseconds}');
    expect(find.text('Good morning'), findsOneWidget);
    // Generous ceiling for CI machines; the real target is checked on device.
    expect(sw.elapsedMilliseconds, lessThan(5000));
  });
}

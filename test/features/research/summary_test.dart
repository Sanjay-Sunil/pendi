import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('weekly summary copies markdown to the clipboard', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    await pumpApp(tester, location: '/work', height: 1800);
    await tester.tap(find.text('Research'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly summary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(
      copied,
      startsWith('# NITC research internship — week of Mon, 16 Nov'),
    );
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });
}

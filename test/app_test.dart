import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/core/env.dart';
import 'package:pendi/main.dart';

void main() {
  test('runs in demo mode without env', () {
    expect(Env.isDemo, isTrue);
    expect(Env.appTimezone, 'Asia/Kolkata');
  });

  testWidgets('shows the placeholder', (tester) async {
    await tester.pumpWidget(const PendiApp());
    expect(find.text('pendi'), findsOneWidget);
  });
}

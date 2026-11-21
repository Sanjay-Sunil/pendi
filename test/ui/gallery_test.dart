import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/features/dev/gallery_screen.dart';
import 'package:pendi/ui/app_checkbox.dart';

import '../helpers/a11y.dart';
import '../helpers/pump.dart';

void main() {
  for (final b in Brightness.values) {
    for (final w in [375.0, 1280.0]) {
      testWidgets('gallery renders accessibly ($b, ${w.toInt()}px)', (
        tester,
      ) async {
        await pumpThemed(
          tester,
          const GalleryScreen(),
          brightness: b,
          width: w,
          height: 2000,
        );
        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
      });
    }
  }

  testWidgets('checkbox toggles and exposes checked state', (tester) async {
    await pumpThemed(tester, const GalleryScreen(), height: 2000);
    final box = find.widgetWithText(AppCheckbox, 'Read chapter 3');
    expect(tester.widget<AppCheckbox>(box).value, isFalse);
    await tester.tap(box);
    await tester.pump();
    expect(tester.widget<AppCheckbox>(box).value, isTrue);
  });

  testWidgets('sheet opens', (tester) async {
    await pumpThemed(tester, const GalleryScreen(), height: 2000);
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet content goes here.'), findsOneWidget);
  });
}

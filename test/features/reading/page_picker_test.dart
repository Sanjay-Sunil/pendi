import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/features/reading/widgets/page_picker.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('long lists scroll inside the picker; rows build lazily', (
    tester,
  ) async {
    final pages = [
      for (var i = 0; i < 361; i++) PickablePage('Page $i', 'https://x.dev/$i'),
    ];
    await pumpThemed(
      tester,
      SingleChildScrollView(
        child: Column(
          children: [
            PagePicker(pages: pages, onChanged: (_) {}),
            const Text('Submit'),
          ],
        ),
      ),
    );
    expect(find.text('Submit').hitTestable(), findsOneWidget);
    expect(find.text('Page 360'), findsNothing); // not built until scrolled
  });
}

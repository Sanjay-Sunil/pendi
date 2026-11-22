import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pendi/domain/timetable.dart';
import 'package:pendi/features/college_portal/timetable_store.dart';

import '../../helpers/pump_app.dart';

/// Saturday 21 Nov 2026 at 09:30 IST (testOverrides' clock).
const saturdayClass = ClassSlot(
  weekday: 6,
  start: '09:00',
  end: '10:00',
  courseCode: 'CS311',
  courseName: 'Operating Systems',
);
const saturdayLab = ClassSlot(
  weekday: 6,
  start: '14:00',
  end: '16:00',
  courseCode: 'CS312',
  courseName: 'Networks lab',
);

void main() {
  testWidgets('College shows the week; Today shows now and next', (
    tester,
  ) async {
    final slots = jsonEncode([saturdayClass.toJson(), saturdayLab.toJson()]);
    await pumpApp(
      tester,
      location: '/college',
      height: 2400,
      prefs: {TimetableStore.key: slots},
    );
    expect(find.text('TIMETABLE'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('lab'), findsOneWidget);

    await pumpApp(tester, height: 2400, prefs: {TimetableStore.key: slots});
    expect(
      find.text('NOW  Operating Systems  09:00–10:00', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('NEXT  Networks lab  14:00–16:00', findRichText: true),
      findsOneWidget,
    );
  });
}

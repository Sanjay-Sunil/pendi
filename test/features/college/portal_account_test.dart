import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pendi/features/college_portal/providers.dart';
import 'package:pendi/integrations/iiitk/attendance_client.dart';
import 'package:pendi/integrations/iiitk/credentials.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

final fixture = File('test/fixtures/iiitk/attendance.json').readAsStringSync();

AttendanceClient portal({bool accept = true}) => AttendanceClient(
  client: MockClient((req) async {
    if (req.url.path == '/api/auth/login') {
      return accept
          ? http.Response('{"access":"t","refresh":"r"}', 200)
          : http.Response('{}', 401);
    }
    return http.Response(fixture, 200);
  }),
);

Future<void> openSettings(
  WidgetTester tester,
  CredentialStore store,
  AttendanceClient client,
) async {
  await pumpApp(
    tester,
    location: '/settings',
    height: 2200,
    overrides: [
      ...testOverrides(portalLogin: store),
      attendanceClientProvider.overrideWithValue(client),
    ],
  );
}

void main() {
  testWidgets('connect validates the login, stores it, and lists courses', (
    tester,
  ) async {
    final store = MemoryCredentialStore();
    await openSettings(tester, store, portal());
    await tester.enterText(
      find.widgetWithText(TextField, 'name@iiitkottayam.ac.in'),
      'me@iiitkottayam.ac.in',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password').first,
      'secret',
    );
    await tester.ensureVisible(find.text('Connect'));
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Connected as me@iiitkottayam.ac.in'), findsOneWidget);
    expect(find.text('CS311 · 33/40'), findsOneWidget);
    expect(store.value, (email: 'me@iiitkottayam.ac.in', password: 'secret'));
  });

  testWidgets('a wrong password is not saved', (tester) async {
    final store = MemoryCredentialStore();
    await openSettings(tester, store, portal(accept: false));
    await tester.enterText(
      find.widgetWithText(TextField, 'name@iiitkottayam.ac.in'),
      'me@iiitkottayam.ac.in',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password').first,
      'nope',
    );
    await tester.ensureVisible(find.text('Connect'));
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong college email or password'), findsOneWidget);
    expect(store.value, isNull);
  });
}

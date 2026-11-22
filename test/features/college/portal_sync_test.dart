import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pendi/data/demo_db.dart';
import 'package:pendi/data/providers.dart';
import 'package:pendi/data/repos/college_repo.dart';
import 'package:pendi/domain/attendance.dart';
import 'package:pendi/features/college_portal/providers.dart';
import 'package:pendi/integrations/iiitk/attendance_client.dart';
import 'package:pendi/integrations/iiitk/credentials.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

final fixture = File('test/fixtures/iiitk/attendance.json').readAsStringSync();

void main() {
  test('upserts by code, keeps manual courses, never duplicates', () async {
    final repo = CollegeRepo(DemoDb());
    await repo.addCourse(name: 'Club hours');
    await repo.addCourse(name: 'Old OS name', code: 'cs311');
    final first = (await repo.syncFromPortal([
      (code: 'CS311', name: 'Operating Systems', present: 33, total: 40),
      (code: 'CS312', name: 'Computer Networks', present: 25, total: 27),
      (code: 'BAD', name: 'x', present: 5, total: 2),
    ])).valueOrNull!;
    expect([first.added, first.updated], [1, 1]);
    final again = (await repo.syncFromPortal([
      (code: 'CS311', name: 'Operating Systems', present: 33, total: 40),
    ])).valueOrNull!;
    expect([again.added, again.updated], [0, 0]);
    final courses = await repo.courses();
    expect(courses.map((c) => c.name), [
      'Club hours',
      'Operating Systems',
      'Computer Networks',
    ]);
    expect(courses.firstWhere((c) => c.code == 'CS312').minPct, 80);
  });

  test('80% rule at the boundary', () {
    expect((canSkip(32, 40, 80) as CanSkip).classes, 0); // exactly 80%
    expect((canSkip(33, 40, 80) as CanSkip).classes, 1); // 33/41 = 80.5%
    expect((canSkip(31, 40, 80) as MustAttend).classes, 5); // 36/45 = 80%
  });

  testWidgets('College shows synced portal attendance with skip advice', (
    tester,
  ) async {
    final db = DemoDb();
    final store = MemoryCredentialStore()
      ..value = (email: 'me@iiitkottayam.ac.in', password: 'pw');
    await pumpApp(
      tester,
      location: '/college',
      height: 2400,
      overrides: [
        ...testOverrides(portalLogin: store),
        dbProvider.overrideWith((ref) async => db),
        attendanceClientProvider.overrideWithValue(
          AttendanceClient(
            now: () => DateTime.utc(2026, 11, 22, 4),
            client: MockClient(
              (req) async => req.url.path == '/api/auth/login'
                  ? http.Response('{"access":"t"}', 200)
                  : http.Response(fixture, 200),
            ),
          ),
        ),
      ],
    );
    expect(find.text('Synced 09:30'), findsOneWidget);
    expect(find.text('CS311 · Operating Systems'), findsOneWidget);
    expect(find.text('33/40 · 83%'), findsOneWidget);
    expect(find.text('You can skip 1 more class.'), findsOneWidget);
  });
}

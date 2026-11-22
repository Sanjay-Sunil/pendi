import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pendi/integrations/iiitk/attendance_client.dart';

final fixture = File('test/fixtures/iiitk/attendance.json').readAsStringSync();
final now = DateTime.utc(2026, 11, 22, 8);

Matcher code(PortalErrorCode c) =>
    throwsA(isA<PortalError>().having((e) => e.code, 'code', c));

void main() {
  test('parses courses (both field styles) and recent sessions', () {
    final s = parseAttendance(jsonDecode(fixture), now);
    expect(s.courses.map((c) => [c.code, c.name, c.present, c.total]), [
      ['CS311', 'Operating Systems', 33, 40],
      ['CS312', 'Computer Networks', 25, 27],
      ['MA301', 'Probability', 0, 0],
    ]);
    expect(s.courses.first.dutyLeaveCredited, 1);
    expect(s.recent, hasLength(2));
    expect(s.recent.first.date, '2026-11-20');
    expect(s.recent.first.status, 'PRESENT');
    expect(
      [s.recent[1].startTime, s.recent[1].endTime, s.recent[1].courseCode],
      ['14:00', '16:00', 'CS312'],
    );
  });

  test('rejects malformed responses', () {
    expect(
      () => parseAttendance(<Object?>[], now),
      code(PortalErrorCode.badResponse),
    );
    expect(
      () => parseAttendance({'overall': <Object?>[]}, now),
      code(PortalErrorCode.badResponse),
    );
  });

  test('logs in, sends the bearer token, and fetches attendance', () async {
    final client = AttendanceClient(
      now: () => now,
      client: MockClient((req) async {
        if (req.url.path == '/api/auth/login') {
          expect(jsonDecode(req.body), {
            'email': 'me@iiitkottayam.ac.in',
            'password': 'pw',
          });
          return http.Response('{"access":"tok","refresh":"r"}', 200);
        }
        expect(req.headers['authorization'], 'Bearer tok');
        return http.Response(fixture, 200);
      }),
    );
    final s = await client.fetch(' me@iiitkottayam.ac.in ', 'pw');
    expect(s.courses, hasLength(3));
    expect(s.fetchedAt, now);
  });

  test('maps failures to friendly typed errors', () async {
    AttendanceClient with_(Future<http.Response> Function(http.Request) f) =>
        AttendanceClient(client: MockClient(f));
    expect(
      () =>
          with_((_) async => http.Response('{"detail":"bad"}', 401))
              .login('a', 'b'),
      code(PortalErrorCode.invalidCredentials),
    );
    expect(
      () =>
          with_((_) async => http.Response('{"needsEmailOtp":true}', 200))
              .login('a', 'b'),
      code(PortalErrorCode.needsVerification),
    );
    expect(
      () => with_((_) async => http.Response('{}', 200)).login('a', 'b'),
      code(PortalErrorCode.badResponse),
    );
    expect(
      () => with_((_) => throw const SocketException('down')).login('a', 'b'),
      code(PortalErrorCode.network),
    );
    expect(
      () => with_((_) async => http.Response('<html>', 502)).login('a', 'b'),
      code(PortalErrorCode.badResponse),
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pendi/integrations/iiitk/attendance_client.dart';
import 'package:pendi/integrations/iiitk/moodle_client.dart';

String fx(String f) => File('test/fixtures/iiitk/$f').readAsStringSync();
const base = 'https://lmsug25.iiitkottayam.ac.in';

Matcher code(PortalErrorCode c) =>
    throwsA(isA<PortalError>().having((e) => e.code, 'code', c));

/// Fake Moodle: sets a session cookie at login, then serves the dashboard and events.
MockClient fakeMoodle({bool acceptPassword = true}) {
  var loggedIn = false;
  return MockClient((req) async {
    final cookie = req.headers['cookie'] ?? '';
    switch ((req.method, req.url.path)) {
      case ('GET', '/login/index.php'):
        return http.Response(
          fx('moodle_login.html'),
          200,
          headers: {'set-cookie': 'MoodleSession=s1; path=/'},
        );
      case ('POST', '/login/index.php'):
        expect(req.bodyFields['logintoken'], 'abc123TOKEN');
        expect(cookie, contains('MoodleSession=s1'));
        loggedIn = acceptPassword && req.bodyFields['password'] == 'pw';
        return http.Response(
          '',
          303,
          headers: {
            'location': '$base/my/',
            if (loggedIn) 'set-cookie': 'MoodleSession=s2; path=/',
          },
        );
      case ('GET', '/my/'):
        return loggedIn && cookie.contains('MoodleSession=s2')
            ? http.Response(fx('moodle_dashboard.html'), 200)
            : http.Response(fx('moodle_login.html'), 200);
      case ('POST', '/lib/ajax/service.php'):
        expect(req.url.queryParameters['sesskey'], 'SeSs9Key');
        final call =
            (jsonDecode(req.body) as List<Object?>).first!
                as Map<String, Object?>;
        expect(
          call['methodname'],
          'core_calendar_get_action_events_by_timesort',
        );
        return http.Response(fx('moodle_events.json'), 200);
    }
    return http.Response('not found', 404);
  });
}

void main() {
  test('host from college email', () {
    expect(
      lmsHostForEmail('sanjay25bcd07@iiitkottayam.ac.in'),
      'https://lmsug25.iiitkottayam.ac.in',
    );
    expect(
      lmsHostForEmail('someone@gmail.com'),
      'https://lmsug24.iiitkottayam.ac.in',
    );
    expect(isOfficialLms('https://lmsug25.iiitkottayam.ac.in'), isTrue);
    expect(isOfficialLms('https://evil.example.com'), isFalse);
    expect(isOfficialLms('http://lmsug25.iiitkottayam.ac.in'), isFalse);
  });

  test('extracts login token and sesskey', () {
    expect(extractLoginToken(fx('moodle_login.html')), 'abc123TOKEN');
    expect(extractSesskey(fx('moodle_dashboard.html')), 'SeSs9Key');
  });

  test('parses deadlines, cleaning "is due" and skipping bad rows', () {
    final d = parseDeadlines(jsonDecode(fx('moodle_events.json')));
    expect(d.map((e) => [e.id, e.name, e.module, e.courseShortName]), [
      [901, 'Lab 4', 'assign', 'CS311'],
      [902, 'Quiz 2 closes', 'quiz', 'CS312'],
    ]);
    expect(
      d.first.dueAt,
      DateTime.fromMillisecondsSinceEpoch(1764163800 * 1000, isUtc: true),
    );
    expect(
      () => parseDeadlines([
        {
          'error': true,
          'exception': {'message': 'Invalid sesskey'},
        },
      ]),
      throwsA(
        isA<PortalError>().having(
          (e) => e.message,
          'message',
          'Invalid sesskey',
        ),
      ),
    );
  });

  test('logs in with cookie + token, then fetches deadlines', () async {
    final m = MoodleClient(base: base, client: fakeMoodle());
    expect((await m.fetch('sanjay', 'pw')).map((e) => e.id), [901, 902]);
  });

  test('wrong password is reported, not crashed', () {
    final m = MoodleClient(base: base, client: fakeMoodle());
    expect(
      () => m.fetch('sanjay', 'nope'),
      code(PortalErrorCode.invalidCredentials),
    );
  });
}

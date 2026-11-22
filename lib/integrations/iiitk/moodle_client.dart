import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'attendance_client.dart' show PortalError, PortalErrorCode;

/// IIIT Kottayam Moodle (lmsugYY.iiitkottayam.ac.in): form login with a session
/// cookie, then Moodle's AJAX web service for upcoming deadlines.
class MoodleDeadline {
  const MoodleDeadline({
    required this.id,
    required this.name,
    required this.dueAt,
    required this.module,
    this.courseName,
    this.courseShortName,
    this.url,
  });

  final int id;
  final String name;
  final DateTime dueAt;

  /// Moodle module type: `assign`, `quiz`, …
  final String module;
  final String? courseName;
  final String? courseShortName;
  final String? url;
}

/// Picks the LMS host from a college email like `name25bcd07@…` → lmsug25.
String lmsHostForEmail(String email) {
  final m = RegExp(r'(\d{2})[a-z]{2,4}\d+@').firstMatch(email.toLowerCase());
  return 'https://lmsug${m?.group(1) ?? '24'}.iiitkottayam.ac.in';
}

/// Only official https lmsugYY hosts are accepted.
bool isOfficialLms(String url) =>
    RegExp(r'^https://lmsug\d{2}\.iiitkottayam\.ac\.in/?$').hasMatch(url);

String? extractLoginToken(String html) =>
    RegExp(r'''name=["']logintoken["']\s+value=["']([^"']+)''')
        .firstMatch(html)
        ?.group(1) ??
    RegExp(r'''value=["']([^"']+)["']\s+name=["']logintoken''')
        .firstMatch(html)
        ?.group(1);

String? extractSesskey(String html) =>
    RegExp(r'''["']sesskey["']\s*:\s*["']([^"']+)''')
        .firstMatch(html)
        ?.group(1) ??
    RegExp(r'''name=["']sesskey["']\s+value=["']([^"']+)''')
        .firstMatch(html)
        ?.group(1);

bool looksLikeLoginPage(String html) => RegExp(
  r'''name=["']logintoken["']|loginerrormessage''',
  caseSensitive: false,
).hasMatch(html);

/// Parses `core_calendar_get_action_events_by_timesort` AJAX output.
List<MoodleDeadline> parseDeadlines(Object? json) {
  if (json is! List<Object?> || json.isEmpty || json.first is! Map) {
    throw const PortalError(
      'Unexpected Moodle response',
      PortalErrorCode.badResponse,
    );
  }
  final first = json.first! as Map<String, Object?>;
  if (first['error'] == true) {
    final ex = first['exception'];
    final msg = ex is Map && ex['message'] is String
        ? ex['message']! as String
        : 'Moodle error';
    throw PortalError(msg, PortalErrorCode.badResponse);
  }
  final data = first['data'];
  final events = data is Map ? data['events'] : null;
  if (events is! List<Object?>) {
    throw const PortalError(
      'Moodle sent no events',
      PortalErrorCode.badResponse,
    );
  }
  return [
    for (final e in events.whereType<Map<String, Object?>>())
      if (e['id'] is int && e['timesort'] is int && e['name'] is String)
        MoodleDeadline(
          id: e['id']! as int,
          name: (e['name']! as String)
              .replaceAll(RegExp(r'\s+is due$'), '')
              .trim(),
          dueAt: DateTime.fromMillisecondsSinceEpoch(
            (e['timesort']! as int) * 1000,
            isUtc: true,
          ),
          module: (e['modulename'] as String?) ?? 'other',
          courseName:
              (e['course'] as Map<String, Object?>?)?['fullname'] as String?,
          courseShortName:
              (e['course'] as Map<String, Object?>?)?['shortname'] as String?,
          url: e['url'] as String?,
        ),
  ];
}

class MoodleClient {
  MoodleClient({
    http.Client? client,
    required this.base,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final http.Client _client;
  final String base;
  final DateTime Function() _now;
  final Map<String, String> _cookies = {};
  static const _timeout = Duration(seconds: 20);

  void _keepCookies(http.BaseResponse res) {
    final raw = res.headers['set-cookie'];
    if (raw == null) return;
    for (final part in raw.split(RegExp(r',(?=\s*[A-Za-z0-9_]+=)'))) {
      final kv = part.split(';').first.split('=');
      if (kv.length >= 2) {
        _cookies[kv.first.trim()] = kv.sublist(1).join('=').trim();
      }
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    bool form = false,
  }) async {
    final req = http.Request(method, Uri.parse('$base$path'))
      ..followRedirects = false
      ..headers['user-agent'] = 'Pendi/1.0'
      ..headers['cookie'] = [
        for (final e in _cookies.entries) '${e.key}=${e.value}',
      ].join('; ');
    if (body is Map<String, String> && form) {
      req.bodyFields = body;
    } else if (body != null) {
      req.headers['content-type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    try {
      final res = await http.Response.fromStream(
        await _client.send(req).timeout(_timeout),
      );
      _keepCookies(res);
      return res;
    } on TimeoutException {
      throw const PortalError(
        'Moodle took too long to answer',
        PortalErrorCode.timeout,
      );
    } catch (e) {
      throw const PortalError("Couldn't reach Moodle", PortalErrorCode.network);
    }
  }

  /// Follows same-site redirects by hand so session cookies are kept.
  Future<http.Response> _get(String path) async {
    var res = await _send('GET', path);
    for (var hops = 0; hops < 5 && res.isRedirect; hops++) {
      final loc = res.headers['location'];
      if (loc == null) break;
      final uri = Uri.parse(base).resolve(loc);
      if (uri.origin != Uri.parse(base).origin) break;
      res = await _send(
        'GET',
        uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path,
      );
    }
    return res;
  }

  Future<String> login(String username, String password) async {
    final page = await _get('/login/index.php');
    final token = extractLoginToken(page.body);
    if (token == null) {
      throw const PortalError(
        'Moodle login page changed; cannot sign in',
        PortalErrorCode.badResponse,
      );
    }
    await _send(
      'POST',
      '/login/index.php',
      form: true,
      body: {
        'username': username.trim(),
        'password': password,
        'logintoken': token,
        'anchor': '',
      },
    );
    final dash = await _get('/my/');
    if (looksLikeLoginPage(dash.body)) {
      throw const PortalError(
        'Wrong LMS username or password',
        PortalErrorCode.invalidCredentials,
      );
    }
    final sesskey = extractSesskey(dash.body);
    if (sesskey == null) {
      throw const PortalError(
        'Signed in, but Moodle sent no session key',
        PortalErrorCode.badResponse,
      );
    }
    return sesskey;
  }

  /// Assignments and quizzes due from now until [days] ahead.
  Future<List<MoodleDeadline>> upcoming(String sesskey, {int days = 45}) async {
    final now = _now().millisecondsSinceEpoch ~/ 1000;
    const method = 'core_calendar_get_action_events_by_timesort';
    final res = await _send(
      'POST',
      '/lib/ajax/service.php?sesskey=$sesskey&info=$method',
      body: [
        {
          'index': 0,
          'methodname': method,
          'args': {
            'limitnum': 50,
            'timesortfrom': now - 86400,
            'timesortto': now + days * 86400,
            'limittononsuspendedevents': true,
          },
        },
      ],
    );
    if (res.statusCode >= 400) {
      throw PortalError(
        'Moodle error (HTTP ${res.statusCode})',
        PortalErrorCode.badResponse,
      );
    }
    try {
      return parseDeadlines(jsonDecode(res.body));
    } on FormatException {
      throw const PortalError(
        'Moodle sent an unreadable reply',
        PortalErrorCode.badResponse,
      );
    }
  }

  Future<List<MoodleDeadline>> fetch(String username, String password) async =>
      upcoming(await login(username, password));
}

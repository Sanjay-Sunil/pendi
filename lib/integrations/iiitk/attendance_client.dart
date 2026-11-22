import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// IIIT Kottayam attendance portal (attendance.iiitkottayam.ac.in) client.
/// Pendi's own implementation against the portal's JSON API.
const attendanceBase = 'https://attendance.iiitkottayam.ac.in';

enum PortalErrorCode {
  invalidCredentials,
  needsVerification,
  network,
  timeout,
  badResponse,
}

class PortalError implements Exception {
  const PortalError(this.message, this.code);
  final String message;
  final PortalErrorCode code;
  @override
  String toString() => message;
}

class PortalCourse {
  const PortalCourse({
    required this.id,
    required this.code,
    required this.name,
    required this.present,
    required this.total,
    this.dutyLeaveCredited = 0,
  });

  final String id;
  final String code;
  final String name;
  final int present;
  final int total;

  /// Approved duty leave already counted as present by the portal.
  final int dutyLeaveCredited;
}

class PortalSession {
  const PortalSession({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.courseCode,
    this.courseName,
  });

  /// `YYYY-MM-DD` local date and `HH:mm` local times as the portal reports them.
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String courseCode;
  final String? courseName;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.courses,
    required this.recent,
    required this.fetchedAt,
  });
  final List<PortalCourse> courses;
  final List<PortalSession> recent;
  final DateTime fetchedAt;
}

// Tolerant readers: the portal has used both camelCase and short names.
String _s(Map<String, Object?> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.isNotEmpty) return v;
    if (v is num) return v.toString();
  }
  return '';
}

int _i(Map<String, Object?> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is num) return v.toInt();
    if (v is String && int.tryParse(v) != null) return int.parse(v);
  }
  return 0;
}

/// Parses `/api/students/me/attendance`. Throws [PortalError] on a bad shape.
AttendanceSummary parseAttendance(Object? json, DateTime fetchedAt) {
  if (json is! Map<String, Object?>) {
    throw const PortalError(
      'Unexpected attendance response',
      PortalErrorCode.badResponse,
    );
  }
  final rawCourses = json['byCourse'] ?? json['courses'];
  if (rawCourses is! List<Object?>) {
    throw const PortalError(
      'Attendance response has no courses',
      PortalErrorCode.badResponse,
    );
  }
  final courses = [
    for (final c in rawCourses.whereType<Map<String, Object?>>())
      PortalCourse(
        id: _s(c, ['courseId', 'id']),
        code: _s(c, ['courseCode', 'code']),
        name: _s(c, ['courseName', 'name']),
        present: _i(c, ['present']),
        total: _i(c, ['total']),
        dutyLeaveCredited: _i(c, ['dlCredited']),
      ),
  ].where((c) => c.code.isNotEmpty).toList();

  final recent = <PortalSession>[];
  for (final s
      in (json['recent'] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()) {
    final course = s['course'] is Map<String, Object?>
        ? s['course']! as Map<String, Object?>
        : <String, Object?>{};
    final date = _s(s, ['date']);
    final code = _s(course, ['code', 'courseCode']).isNotEmpty
        ? _s(course, ['code', 'courseCode'])
        : _s(s, ['courseCode']);
    if (date.length < 10 || code.isEmpty) continue;
    recent.add(
      PortalSession(
        date: date.substring(0, 10),
        startTime: _s(s, ['startTime']),
        endTime: _s(s, ['endTime']),
        status: _s(s, ['status']).toUpperCase(),
        courseCode: code,
        courseName: _s(course, ['name', 'courseName']).isEmpty
            ? null
            : _s(course, ['name', 'courseName']),
      ),
    );
  }
  return AttendanceSummary(
    courses: courses,
    recent: recent,
    fetchedAt: fetchedAt,
  );
}

class AttendanceClient {
  AttendanceClient({
    http.Client? client,
    this.base = attendanceBase,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final http.Client _client;
  final String base;
  final DateTime Function() _now;
  static const _timeout = Duration(seconds: 15);
  String? _access;

  Future<Object?> _send(String method, String path, {Object? body}) async {
    final req = http.Request(method, Uri.parse('$base$path'))
      ..headers['accept'] = 'application/json'
      ..headers['user-agent'] = 'Pendi/1.0';
    if (_access != null) req.headers['authorization'] = 'Bearer $_access';
    if (body != null) {
      req.headers['content-type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(req).timeout(_timeout),
      );
    } on TimeoutException {
      throw const PortalError(
        'The attendance portal took too long to answer',
        PortalErrorCode.timeout,
      );
    } catch (e) {
      throw const PortalError(
        "Couldn't reach the attendance portal",
        PortalErrorCode.network,
      );
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw const PortalError(
        'Wrong college email or password',
        PortalErrorCode.invalidCredentials,
      );
    }
    if (res.statusCode >= 400) {
      throw PortalError(
        'Attendance portal error (HTTP ${res.statusCode})',
        PortalErrorCode.badResponse,
      );
    }
    try {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      throw const PortalError(
        'The attendance portal sent an unreadable reply',
        PortalErrorCode.badResponse,
      );
    }
  }

  /// Signs in with the college email and portal password.
  Future<void> login(String email, String password) async {
    final r = await _send(
      'POST',
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    if (r is! Map<String, Object?>) {
      throw const PortalError(
        'Unexpected sign-in response',
        PortalErrorCode.badResponse,
      );
    }
    if (r['needs2fa'] == true || r['needsEmailOtp'] == true) {
      throw const PortalError(
        'The portal wants a verification code. Sign in once on the portal website, then try again.',
        PortalErrorCode.needsVerification,
      );
    }
    final token = r['access'] ?? r['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const PortalError(
        'Sign-in returned no session',
        PortalErrorCode.badResponse,
      );
    }
    _access = token;
  }

  Future<AttendanceSummary> attendance() async => parseAttendance(
    await _send('GET', '/api/students/me/attendance'),
    _now(),
  );

  /// Signs in and fetches attendance in one go.
  Future<AttendanceSummary> fetch(String email, String password) async {
    await login(email, password);
    return attendance();
  }
}

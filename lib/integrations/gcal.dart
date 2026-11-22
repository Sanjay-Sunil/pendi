import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as cal;

import 'google_auth.dart';

class CalEvent {
  const CalEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
  });
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
}

class CalendarError implements Exception {
  const CalendarError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal Calendar surface the app needs; faked in tests and demo mode.
abstract class CalendarClient {
  Future<List<CalEvent>> listEvents(DateTime from, DateTime to);

  /// Creates the event, or updates it when [eventId] is given. Returns its id.
  Future<String> upsertEvent({
    String? eventId,
    required String title,
    required DateTime start,
    DateTime? end,
  });
}

/// Real client using the Google Sign-In Calendar authorization.
class GoogleCalendarClient implements CalendarClient {
  GoogleCalendarClient({this.calendarId = 'primary'});

  static const scope = 'https://www.googleapis.com/auth/calendar';
  final String calendarId;

  Future<cal.CalendarApi> _api() async {
    final auth = await (await googleSignIn()).authorizationClient
        .authorizationForScopes(const [scope]);
    if (auth == null) {
      throw const CalendarError('Calendar access not granted. Sign in again.');
    }
    return cal.CalendarApi(auth.authClient(scopes: const [scope]));
  }

  @override
  Future<List<CalEvent>> listEvents(DateTime from, DateTime to) async {
    final res = await (await _api()).events.list(
      calendarId,
      timeMin: from.toUtc(),
      timeMax: to.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
      maxResults: 100,
    );
    return [
      for (final e in res.items ?? <cal.Event>[])
        if (e.id != null && (e.start?.dateTime ?? e.start?.date) != null)
          CalEvent(
            id: e.id!,
            title: e.summary ?? '(no title)',
            start: (e.start!.dateTime ?? e.start!.date)!,
            end: e.end?.dateTime ?? e.end?.date,
            allDay: e.start!.dateTime == null,
          ),
    ];
  }

  @override
  Future<String> upsertEvent({
    String? eventId,
    required String title,
    required DateTime start,
    DateTime? end,
  }) async {
    final api = await _api();
    final event = cal.Event(
      summary: title,
      start: cal.EventDateTime(dateTime: start.toUtc()),
      end: cal.EventDateTime(
        dateTime: (end ?? start.add(const Duration(minutes: 30))).toUtc(),
      ),
    );
    final saved = eventId == null
        ? await api.events.insert(event, calendarId)
        : await api.events.patch(event, calendarId, eventId);
    return saved.id!;
  }
}

/// In-memory calendar for demo mode and tests, pre-filled with a sample day.
class FakeCalendarClient implements CalendarClient {
  FakeCalendarClient({List<CalEvent>? events}) : events = events ?? [];

  final List<CalEvent> events;
  int creates = 0;
  int updates = 0;

  static FakeCalendarClient sample(DateTime todayStartUtc) {
    DateTime at(int h, [int m = 0]) =>
        todayStartUtc.add(Duration(hours: h, minutes: m));
    return FakeCalendarClient(
      events: [
        CalEvent(
          id: 'demo-1',
          title: 'Operating Systems lecture',
          start: at(9),
          end: at(10),
        ),
        CalEvent(id: 'demo-2', title: 'DBMS lab', start: at(14), end: at(16)),
        CalEvent(
          id: 'demo-3',
          title: 'Coding club',
          start: at(18, 30),
          end: at(19, 30),
        ),
      ],
    );
  }

  @override
  Future<List<CalEvent>> listEvents(DateTime from, DateTime to) async => [
    for (final e in events)
      if (!e.start.isBefore(from) && e.start.isBefore(to)) e,
  ]..sort((a, b) => a.start.compareTo(b.start));

  @override
  Future<String> upsertEvent({
    String? eventId,
    required String title,
    required DateTime start,
    DateTime? end,
  }) async {
    final i = eventId == null ? -1 : events.indexWhere((e) => e.id == eventId);
    final id = i >= 0 ? eventId! : 'fake-${events.length + 1}';
    final e = CalEvent(id: id, title: title, start: start, end: end);
    if (i >= 0) {
      events[i] = e;
      updates++;
    } else {
      events.add(e);
      creates++;
    }
    return id;
  }
}

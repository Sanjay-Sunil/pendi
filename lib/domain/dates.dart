import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A calendar day in the user's timezone, as `YYYY-MM-DD`.
typedef LocalDay = String;

const defaultTimezone = 'Asia/Kolkata';

bool _initialized = false;

/// Loads the IANA database once; safe to call repeatedly.
void initTimezones() {
  if (_initialized) return;
  tzdata.initializeTimeZones();
  _initialized = true;
}

/// The user's zone, set from their profile at startup and in Settings.
/// Calls that use the default zone resolve to this at runtime.
String activeTimezone = defaultTimezone;

/// Whether [zone] is a known IANA name.
bool isValidTimezone(String zone) {
  initTimezones();
  return zone == 'UTC' || tz.timeZoneDatabase.locations.containsKey(zone);
}

tz.Location _loc(String zone) {
  initTimezones();
  final z = zone == defaultTimezone ? activeTimezone : zone;
  return z == 'UTC' ? tz.UTC : tz.getLocation(z);
}

final _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

void _assertDay(LocalDay day) {
  if (!_dayRe.hasMatch(day)) throw RangeError('Invalid day: $day');
}

String _two(int n) => n.toString().padLeft(2, '0');

String _fmt(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-${_two(m)}-${_two(d)}';

/// The local day an instant falls on in [zone].
LocalDay toLocalDay(DateTime instant, {String zone = defaultTimezone}) {
  final t = tz.TZDateTime.from(instant, _loc(zone));
  return _fmt(t.year, t.month, t.day);
}

/// Today's date in [zone].
LocalDay todayLocal(DateTime now, {String zone = defaultTimezone}) =>
    toLocalDay(now, zone: zone);

/// The UTC instant at which [day] begins in [zone].
DateTime startOfDay(LocalDay day, {String zone = defaultTimezone}) {
  _assertDay(day);
  final [y, m, d] = day.split('-').map(int.parse).toList();
  return tz.TZDateTime(_loc(zone), y, m, d).toUtc();
}

int _dayNumber(LocalDay day) {
  _assertDay(day);
  final [y, m, d] = day.split('-').map(int.parse).toList();
  return DateTime.utc(y, m, d).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int daysBetween(LocalDay from, LocalDay to) =>
    _dayNumber(to) - _dayNumber(from);

LocalDay addDays(LocalDay day, int n) {
  final t = DateTime.fromMillisecondsSinceEpoch(
    (_dayNumber(day) + n) * Duration.millisecondsPerDay,
    isUtc: true,
  );
  return _fmt(t.year, t.month, t.day);
}

/// Monday of the week containing [day].
LocalDay weekStart(LocalDay day) {
  final [y, m, d] = day.split('-').map(int.parse).toList();
  return addDays(day, -(DateTime.utc(y, m, d).weekday - 1));
}

/// "Overdue 2d", "Today", "Tomorrow", "In 5d", or "Mar 14" beyond two weeks.
String formatDue(
  DateTime dueAt,
  DateTime now, {
  String zone = defaultTimezone,
}) {
  final diff = daysBetween(
    todayLocal(now, zone: zone),
    toLocalDay(dueAt, zone: zone),
  );
  if (diff < 0) return 'Overdue ${-diff}d';
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff <= 14) return 'In ${diff}d';
  return DateFormat('MMM d').format(tz.TZDateTime.from(dueAt, _loc(zone)));
}

/// Short label like "Sat, 21 Nov" for headers.
String formatDayLabel(LocalDay day) {
  final [y, m, d] = day.split('-').map(int.parse).toList();
  return DateFormat('EEE, d MMM').format(DateTime.utc(y, m, d));
}

/// Local clock time like "14:30" for an instant.
String formatTime(DateTime instant, {String zone = defaultTimezone}) =>
    DateFormat('HH:mm').format(tz.TZDateTime.from(instant, _loc(zone)));

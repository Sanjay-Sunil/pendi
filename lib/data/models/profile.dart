import '../db.dart';
import 'json.dart';

class Profile {
  const Profile({
    required this.id,
    required this.timezone,
    this.cfHandle,
    this.gcalCalendarId,
  });

  factory Profile.fromJson(Row r) => Profile(
    id: r.str('id'),
    timezone: r.str('timezone'),
    cfHandle: r.strOrNull('cf_handle'),
    gcalCalendarId: r.strOrNull('gcal_calendar_id'),
  );

  final String id;
  final String timezone;
  final String? cfHandle;
  final String? gcalCalendarId;
}

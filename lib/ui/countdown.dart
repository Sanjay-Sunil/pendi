/// "3d 4h", "5h 20m", "12m", or "overdue" until [due].
String countdown(DateTime due, DateTime now) {
  final d = due.difference(now);
  if (d.isNegative) return 'overdue';
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

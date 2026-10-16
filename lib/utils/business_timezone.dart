/// Workshop business calendar — Asia/Riyadh (UTC+3).
///
/// Used for POS filters and display so device timezone (e.g. Pakistan) does not
/// shift invoice day boundaries or session clocks.
class BusinessTimezone {
  BusinessTimezone._();

  static const Duration offset = Duration(hours: 3);

  /// Minutes east of UTC (sent to APIs only when explicitly required).
  static const int utcOffsetMinutes = 180;

  /// Current wall clock in Riyadh (date parts are business-local).
  static DateTime nowWall() => DateTime.now().toUtc().add(offset);

  /// Calendar day at midnight in Riyadh for [instant] (default: now).
  static DateTime calendarToday([DateTime? instant]) {
    final w = instant == null
        ? nowWall()
        : toWall(instant);
    return DateTime(w.year, w.month, w.day);
  }

  /// Map an instant to Riyadh wall time (for labels).
  static DateTime toWall(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(offset);
  }
}

/// Asia/Riyadh business timezone helpers (fixed UTC+03:00, no DST).
///
/// Matches filter-web `src/utils/riyadhBusinessRange.js`.
///
/// Filter pickers store **naive** year/month/day/hour/minute values that mean
/// Riyadh wall clock — never the device timezone. Convert to UTC only when
/// building API query params.
library;

const Duration kRiyadhUtcOffset = Duration(hours: 3);

/// Treat [wall]'s calendar fields as Asia/Riyadh → UTC instant.
DateTime riyadhWallToUtc(DateTime wall) {
  final asIfUtc = DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
    wall.millisecond,
  );
  return asIfUtc.subtract(kRiyadhUtcOffset);
}

/// API ISO (`…Z`) for a Riyadh wall-clock instant (minute precision).
/// Same as web `riyadhRangeToApiIso` / `riyadhWallToUtcDate`.
String riyadhWallToApiIso(DateTime wall) {
  return riyadhWallToUtc(
    DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute),
  ).toIso8601String();
}

/// Current Asia/Riyadh wall clock (naive [DateTime], minute precision).
DateTime riyadhNowWall() {
  final riyadh = DateTime.now().toUtc().add(kRiyadhUtcOffset);
  return DateTime(
    riyadh.year,
    riyadh.month,
    riyadh.day,
    riyadh.hour,
    riyadh.minute,
  );
}

/// Start of the current Riyadh month at 00:00.
DateTime riyadhStartOfMonthWall([DateTime? nowWall]) {
  final n = nowWall ?? riyadhNowWall();
  return DateTime(n.year, n.month, 1);
}

/// Calendar `YYYY-MM-DD` from Riyadh wall fields (no timezone shift).
String riyadhCalendarDateOnly(DateTime wall) {
  final y = wall.year.toString().padLeft(4, '0');
  final m = wall.month.toString().padLeft(2, '0');
  final d = wall.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

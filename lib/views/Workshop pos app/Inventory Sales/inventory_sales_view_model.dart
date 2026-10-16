import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/pos_repository.dart';
import '../../../models/inventory_sales_api_model.dart';
import '../../../services/session_service.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/business_timezone.dart';
import '../../../widgets/app_bar_live_clock.dart';
import '../More Tab/settings_view_model.dart';

/// Drawer tab: sold quantities by product per calendar day for a selected period.
class InventorySalesViewModel extends ChangeNotifier with TranslatableMixin {
  InventorySalesViewModel({
    required this.posRepository,
    required this.sessionService,
    SettingsViewModel? settingsViewModel,
  }) {
    if (settingsViewModel != null) {
      bindLocaleRetranslation(settingsViewModel, retranslate);
    }
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  @override
  void dispose() {
    unbindLocaleRetranslation();
    super.dispose();
  }

  final PosRepository posRepository;
  final SessionService sessionService;

  static const presets = [
    ('Today', InventorySalesPreset.today),
    ('Yesterday', InventorySalesPreset.yesterday),
    ('Last 7 days', InventorySalesPreset.last7),
    ('Last 30 days', InventorySalesPreset.last30),
    ('This month', InventorySalesPreset.thisMonth),
  ];

  InventorySalesPreset _preset = InventorySalesPreset.today;
  DateTime? _customFrom;
  DateTime? _customTo;
  /// Minutes from midnight (device-local intent); used when [_preset] is [custom] with time window.
  int _rangeFromMinutes = 0;
  int _rangeToMinutes = 23 * 60 + 59;

  List<InventorySaleLine> _lines = [];
  InventorySalesSummary? _summary;
  List<InventoryProductPeriodSummary> _productsSummary = [];
  List<InventorySalesDayRollup> _dayRollups = [];

  String? _apiWorkshopId;
  String? _apiBranchId;
  String? _apiPeriodFrom;
  String? _apiPeriodTo;
  String? _apiBusinessTimeZone;

  bool isLoading = false;
  String? errorMessage;

  /// Matches typical backend validation (client-side check).
  static const int maxRangeDaysInclusive = 366;

  InventorySalesPreset get preset => _preset;
  bool get isCustomRange => _preset == InventorySalesPreset.custom;

  int get rangeFromMinutes => _rangeFromMinutes;
  int get rangeToMinutes => _rangeToMinutes;

  static String formatMinutesAsHm(int m) {
    final h = (m.clamp(0, 24 * 60 - 1)) ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  /// 12-hour clock with AM/PM (e.g. noon → 12:00 PM, 13:05 → 1:05 PM).
  static String formatMinutesAs12h(int m) {
    final dayMinute = m.clamp(0, 24 * 60 - 1);
    final dt = DateTime(2000, 1, 1, dayMinute ~/ 60, dayMinute % 60);
    return DateFormat.jm().format(dt);
  }

  List<InventorySaleLine> get lines => List.unmodifiable(_lines);

  InventorySalesSummary? get summary => _summary;

  List<InventoryProductPeriodSummary> get productsSummary =>
      List.unmodifiable(_productsSummary);

  List<InventorySalesDayRollup> get dayRollups =>
      List.unmodifiable(_dayRollups);

  String? get apiWorkshopId => _apiWorkshopId;
  String? get apiBranchId => _apiBranchId;
  String? get apiPeriodFrom => _apiPeriodFrom;
  String? get apiPeriodTo => _apiPeriodTo;
  String? get apiBusinessTimeZone => _apiBusinessTimeZone;

  /// From API `summary.uniqueProducts` when present.
  int get displayUniqueProductsCount =>
      _summary?.uniqueProducts ?? distinctProductsInPeriod;

  /// Prefer API `summary`; otherwise derive from lines / productsSummary.
  double get periodTotalSalesAmount {
    if (_summary != null) return _summary!.totalSalesAmount;
    if (_productsSummary.isNotEmpty) {
      var t = 0.0;
      for (final p in _productsSummary) {
        t += p.totalSales;
      }
      return t;
    }
    var s = 0.0;
    for (final l in _lines) {
      if (l.salesAmount != null) s += l.salesAmount!;
    }
    return s;
  }

  num get displayTotalUnits {
    if (_summary != null) return _summary!.totalUnitsSold;
    return totalQuantitySold;
  }

  /// Prefers API `summary.distinctItems` (products + services); falls back to legacy fields.
  int get displayDistinctItems {
    if (_summary != null) {
      final s = _summary!;
      if (s.distinctItems > 0) return s.distinctItems;
      final recon = s.uniqueProducts + s.uniqueServices;
      if (recon > 0) return recon;
      return s.uniqueProducts;
    }
    return distinctProductsInPeriod;
  }

  int get displayDaysWithActivity {
    if (_summary != null) return _summary!.daysWithActivity;
    return groupedByDay.length;
  }

  ({DateTime from, DateTime toInclusive}) resolveDateRange({DateTime? now}) {
    final n = now ?? BusinessTimezone.nowWall();
    final today = DateTime(n.year, n.month, n.day);

    DateTime clampEnd(DateTime d) => DateTime(d.year, d.month, d.day);

    switch (_preset) {
      case InventorySalesPreset.today:
        return (from: today, toInclusive: today);
      case InventorySalesPreset.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return (from: y, toInclusive: y);
      case InventorySalesPreset.last7:
        final from = today.subtract(const Duration(days: 6));
        return (from: from, toInclusive: today);
      case InventorySalesPreset.last30:
        final from = today.subtract(const Duration(days: 29));
        return (from: from, toInclusive: today);
      case InventorySalesPreset.thisMonth:
        final from = DateTime(today.year, today.month, 1);
        return (from: from, toInclusive: today);
      case InventorySalesPreset.custom:
        final a = _customFrom != null ? clampEnd(_customFrom!) : today.subtract(const Duration(days: 6));
        final b = _customTo != null ? clampEnd(_customTo!) : today;
        if (a.isAfter(b)) {
          return (from: b, toInclusive: a);
        }
        return (from: a, toInclusive: b);
    }
  }

  /// Sections by calendar day (**ascending**); rows per day by **productName** (asc).
  /// (Lines are also globally sorted soldDate ↑, productName ↑ after fetch.)
  List<({DateTime day, List<InventorySaleLine> rows})> get groupedByDay {
    final map = <DateTime, List<InventorySaleLine>>{};
    for (final l in _lines) {
      final d = DateTime(l.soldOn.year, l.soldOn.month, l.soldOn.day);
      map.putIfAbsent(d, () => []).add(l);
    }
    final days = map.keys.toList()..sort((a, b) => a.compareTo(b));
    return [
      for (final d in days)
        (
          day: d,
          rows: () {
            final r = List<InventorySaleLine>.from(map[d]!);
            r.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
            return r;
          }(),
        ),
    ];
  }

  num get totalQuantitySold {
    var t = 0.0;
    for (final l in _lines) {
      t += l.quantitySold.toDouble();
    }
    return t;
  }

  int get distinctProductsInPeriod {
    final keys = <String>{};
    for (final l in _lines) {
      final pid = l.productId?.trim();
      final sid = l.serviceId?.trim();
      final k = (pid != null && pid.isNotEmpty)
          ? 'p:$pid'
          : (sid != null && sid.isNotEmpty)
              ? 's:$sid'
              : 'n:${l.productName.trim().toLowerCase()}';
      keys.add(k);
    }
    return keys.length;
  }

  int get lineCount => _lines.length;

  /// App bar subtitle: same live KSA clock as [AppBarDateTimeBlock] trailing pill.
  String appBarSubtitleForLocale(String languageCode) {
    return formatPosAppBarDateTimeLine(languageCode);
  }

  Future<void> setPreset(InventorySalesPreset p) async {
    _preset = p;
    notifyListeners();
    await fetch();
  }

  Future<void> setCustomRange(DateTime from, DateTime to) async {
    _preset = InventorySalesPreset.custom;
    _customFrom = from;
    _customTo = to;
    notifyListeners();
    await fetch();
  }

  /// Set start/end time of day (minutes from midnight) for custom range; then [fetch].
  Future<void> setCustomRangeTimesAndFetch(int fromMinutes, int toMinutes) async {
    _rangeFromMinutes = fromMinutes.clamp(0, 24 * 60 - 1);
    _rangeToMinutes = toMinutes.clamp(0, 24 * 60 - 1);
    notifyListeners();
    await fetch();
  }

  /// One fetch after setting custom dates + local time window (used by Apply filter).
  Future<void> applyCustomRangeWithTimes(
    DateTime from,
    DateTime toInclusive,
    int fromMinutes,
    int toMinutes,
  ) async {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(toInclusive.year, toInclusive.month, toInclusive.day);
    if (a.isAfter(b)) {
      errorMessage = 'Start date must be on or before end date.';
      notifyListeners();
      return;
    }
    final spanDays = b.difference(a).inDays + 1;
    if (spanDays > maxRangeDaysInclusive) {
      errorMessage = 'Date range cannot exceed $maxRangeDaysInclusive days.';
      notifyListeners();
      return;
    }
    final fMin = fromMinutes.clamp(0, 24 * 60 - 1);
    final tMin = toMinutes.clamp(0, 24 * 60 - 1);
    final start = DateTime(a.year, a.month, a.day, fMin ~/ 60, fMin % 60);
    final end = DateTime(b.year, b.month, b.day, tMin ~/ 60, tMin % 60);
    if (start.isAfter(end)) {
      errorMessage =
          'Start time must be on or before end time for this date range.';
      notifyListeners();
      return;
    }
    errorMessage = null;
    _preset = InventorySalesPreset.custom;
    _customFrom = a;
    _customTo = b;
    _rangeFromMinutes = fMin;
    _rangeToMinutes = tMin;
    notifyListeners();
    await fetch();
  }

  /// Reset to default preset (today in KSA, full day) and reload.
  Future<void> resetFiltersToDefaultAndFetch() async {
    errorMessage = null;
    _preset = InventorySalesPreset.today;
    _customFrom = null;
    _customTo = null;
    _rangeFromMinutes = 0;
    _rangeToMinutes = 23 * 60 + 59;
    notifyListeners();
    await fetch();
  }

  /// Explicit `from` / `to` (inclusive) + fetch; validates order and max span.
  Future<void> setExplicitRangeAndFetch(DateTime from, DateTime to) async {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    if (a.isAfter(b)) {
      errorMessage = 'Start date must be on or before end date.';
      notifyListeners();
      return;
    }
    final spanDays = b.difference(a).inDays + 1;
    if (spanDays > maxRangeDaysInclusive) {
      errorMessage = 'Date range cannot exceed $maxRangeDaysInclusive days.';
      notifyListeners();
      return;
    }
    errorMessage = null;
    _preset = InventorySalesPreset.custom;
    _customFrom = a;
    _customTo = b;
    _rangeFromMinutes = 0;
    _rangeToMinutes = 23 * 60 + 59;
    notifyListeners();
    await fetch();
  }

  void _applyClientSort() {
    _lines.sort((a, b) {
      final da = DateTime(a.soldOn.year, a.soldOn.month, a.soldOn.day);
      final db = DateTime(b.soldOn.year, b.soldOn.month, b.soldOn.day);
      final c = da.compareTo(db);
      if (c != 0) return c;
      return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
    });
  }

  Future<void> fetch({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken(role: 'cashier');
      if (token == null) {
        errorMessage = 'Session expired. Please sign in again.';
        _lines = [];
        _summary = null;
        _productsSummary = [];
        _dayRollups = [];
        _clearApiMeta();
        return;
      }
      final range = resolveDateRange();
      final res = await posRepository.getCashierInventorySales(
        token,
        from: range.from,
        toInclusive: range.toInclusive,
        fromTime:
            isCustomRange ? formatMinutesAsHm(_rangeFromMinutes) : null,
        toTime: isCustomRange ? formatMinutesAsHm(_rangeToMinutes) : null,
      );
      final productLines =
          res.lines.where(inventorySalesLineIsProduct).toList();
      final productRows = res.productsSummary
          .where(inventorySalesPeriodRowIsProduct)
          .toList();
      _lines = productLines;
      _productsSummary = productRows;
      _summary = _buildProductsOnlySummary(
        res.summary,
        productLines,
        productRows,
      );
      _dayRollups = _rebuildDayRollupsFromLines(productLines);
      _apiWorkshopId = res.workshopId;
      _apiBranchId = res.branchId;
      _apiPeriodFrom = res.periodFrom;
      _apiPeriodTo = res.periodTo;
      _apiBusinessTimeZone = res.businessTimeZone;
      _applyClientSort();
      if (res.success == false && (res.message?.isNotEmpty ?? false)) {
        errorMessage = res.message;
      } else {
        errorMessage = null;
      }
    } catch (e) {
      _lines = [];
      _summary = null;
      _productsSummary = [];
      _dayRollups = [];
      _clearApiMeta();
      errorMessage = _shortError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void dismissErrorBanner() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  void _clearApiMeta() {
    _apiWorkshopId = null;
    _apiBranchId = null;
    _apiPeriodFrom = null;
    _apiPeriodTo = null;
    _apiBusinessTimeZone = null;
  }

  /// KPIs + table reflect **products only** (services removed client-side).
  InventorySalesSummary _buildProductsOnlySummary(
    InventorySalesSummary? apiSummary,
    List<InventorySaleLine> productLines,
    List<InventoryProductPeriodSummary> productRows,
  ) {
    if (productRows.isNotEmpty) {
      var totalUnits = 0.0;
      var totalSales = 0.0;
      final productIds = <String>{};
      for (final p in productRows) {
        totalUnits += p.totalQty;
        totalSales += p.totalSales;
        final id = p.productId?.trim();
        if (id != null && id.isNotEmpty) productIds.add(id);
      }
      final uniqueProducts =
          productIds.isNotEmpty ? productIds.length : productRows.length;
      final distinctItems = productRows.length;
      final daySet = <DateTime>{};
      for (final l in productLines) {
        daySet.add(DateTime(l.soldOn.year, l.soldOn.month, l.soldOn.day));
      }
      final days = daySet.isNotEmpty
          ? daySet.length
          : (apiSummary?.daysWithActivity ?? 0);
      return InventorySalesSummary(
        totalUnitsSold: totalUnits,
        totalSalesAmount: totalSales,
        uniqueProducts: uniqueProducts,
        uniqueServices: 0,
        distinctItems: distinctItems,
        daysWithActivity: days,
      );
    }
    if (productLines.isNotEmpty) {
      var totalUnits = 0.0;
      var totalSales = 0.0;
      final keys = <String>{};
      final daySet = <DateTime>{};
      for (final l in productLines) {
        totalUnits += l.quantitySold.toDouble();
        if (l.salesAmount != null) totalSales += l.salesAmount!;
        final pid = l.productId?.trim();
        keys.add((pid != null && pid.isNotEmpty)
            ? 'p:$pid'
            : 'n:${l.productName.trim().toLowerCase()}');
        daySet.add(DateTime(l.soldOn.year, l.soldOn.month, l.soldOn.day));
      }
      final n = keys.length;
      return InventorySalesSummary(
        totalUnitsSold: totalUnits,
        totalSalesAmount: totalSales,
        uniqueProducts: n,
        uniqueServices: 0,
        distinctItems: n,
        daysWithActivity: daySet.length,
      );
    }
    return const InventorySalesSummary(
      totalUnitsSold: 0,
      totalSalesAmount: 0,
      uniqueProducts: 0,
      uniqueServices: 0,
      distinctItems: 0,
      daysWithActivity: 0,
    );
  }

  List<InventorySalesDayRollup> _rebuildDayRollupsFromLines(
    List<InventorySaleLine> lines,
  ) {
    final map = <DateTime, List<InventorySaleLine>>{};
    for (final l in lines) {
      final d = DateTime(l.soldOn.year, l.soldOn.month, l.soldOn.day);
      map.putIfAbsent(d, () => []).add(l);
    }
    final days = map.keys.toList()..sort((a, b) => a.compareTo(b));
    return [
      for (final d in days)
        InventorySalesDayRollup(
          date: d,
          unitsTotal: map[d]!
              .fold<double>(0, (s, l) => s + l.quantitySold.toDouble()),
          salesTotal: map[d]!
              .fold<double>(0, (s, l) => s + (l.salesAmount ?? 0)),
        ),
    ];
  }

  String _shortError(Object e) {
    var s = e.toString();
    if (s.startsWith('Exception: ')) s = s.substring(11);
    if (s.length > 160) return '${s.substring(0, 157)}…';
    return s;
  }
}

enum InventorySalesPreset {
  today,
  yesterday,
  last7,
  last30,
  thisMonth,
  custom,
}

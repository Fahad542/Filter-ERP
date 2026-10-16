import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/technician_models.dart';
import '../../data/repositories/technician_repository.dart';
import '../../services/session_service.dart';
import '../../services/realtime_service.dart';
import '../../models/technician_performance_model.dart';
import '../../models/technician_profile_model.dart';
import '../../models/technician_advance_model.dart';
import '../../models/technician_commission_history_model.dart';
import '../../models/technician_salary_payment_model.dart';
import '../../models/technician_dashboard_kpis_model.dart';
import '../../models/technician_broadcast_model.dart';
import '../../models/auth_response_model.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/toast_service.dart';
import 'widgets/tech_month_filter_bar.dart';

enum TechDashboardKpiFilterMode { month, dateRange }

class TechAppViewModel extends ChangeNotifier {
  final TechnicianRepository _repository;
  final SessionService _sessionService;
  final RealtimeService _realtimeService = RealtimeService();

  Timer? _profileSocketDebounce;

  TechAppViewModel({
    required TechnicianRepository repository,
    required SessionService sessionService,
  })  : _repository = repository,
        _sessionService = sessionService {
    _registerRealtimeListeners();
  }

  void _registerRealtimeListeners() {
    _realtimeService.on(
      RealtimeService.eventTechnicianOrdersUpdated,
      _onAssignedOrdersUpdated,
    );
    _realtimeService.on(
      RealtimeService.eventTechnicianBroadcastCreated,
      _onBroadcastCreated,
    );
    _realtimeService.on(
      RealtimeService.eventTechnicianBroadcastClosed,
      _onBroadcastClosed,
    );
    _realtimeService.on(
      RealtimeService.eventTechnicianProfileUpdated,
      _onProfileUpdatedSocket,
    );
    _realtimeService.addConnectListener(_onRealtimeConnected);
  }

  Future<void> ensureRealtimeConnected() async {
    final token = await _sessionService.getToken(role: 'tech');
    if (token == null) return;
    _realtimeService.connect(token);
    if (_realtimeService.isConnected) {
      unawaited(fetchBroadcasts());
    }
  }

  void _onRealtimeConnected() {
    unawaited(fetchBroadcasts());
  }

  void _onProfileUpdatedSocket(Map<String, dynamic> _) {
    _profileSocketDebounce?.cancel();
    _profileSocketDebounce = Timer(const Duration(milliseconds: 350), () {
      fetchProfile(affectLoading: false);
    });
  }

  void _onAssignedOrdersUpdated(Map<String, dynamic> payload) {
    fetchAssignedOrders(affectLoading: false);
  }

  /// New broadcast(s) from cashier — show popup immediately, then sync with GET.
  void _onBroadcastCreated(Map<String, dynamic> payload) {
    _mergeBroadcastFromSocketPayload(payload);
    unawaited(fetchBroadcasts());
  }

  void _mergeBroadcastFromSocketPayload(Map<String, dynamic> payload) {
    final jobId = _parseJobIdFromSocketPayload(payload);
    if (jobId == null || jobId.isEmpty) return;
    if (_broadcasts.any((b) => b.jobId == jobId)) return;

    final map = Map<String, dynamic>.from(payload);
    if (map['departmentName'] == null && map['department'] is Map) {
      map['departmentName'] = (map['department'] as Map)['name'];
    }
    final customer = map['customer'];
    if (customer is Map && map['customerName'] == null) {
      map['customerName'] = customer['name'];
    }
    final vehicle = map['vehicle'];
    if (vehicle is Map) {
      map.putIfAbsent('vehiclePlate', () => vehicle['plateNo']);
      final make = vehicle['make']?.toString().trim() ?? '';
      final model = vehicle['model']?.toString().trim() ?? '';
      final label = [make, model].where((s) => s.isNotEmpty).join(' ');
      if (label.isNotEmpty) map.putIfAbsent('vehicleLabel', () => label);
    }

    final incoming = TechBroadcast.fromJson(map);
    if (incoming.jobId.isEmpty) return;

    _broadcasts = [
      incoming,
      ..._broadcasts.where((b) => b.jobId != incoming.jobId),
    ];
    _restartBroadcastCountdown();
    notifyListeners();
  }

  /// Broadcast ended (e.g. reason `accepted` by another tech) — drop locally first, then re-fetch.
  void _onBroadcastClosed(Map<String, dynamic> payload) {
    final jobId = _parseJobIdFromSocketPayload(payload);
    if (jobId != null && jobId.isNotEmpty) {
      final before = _broadcasts.length;
      _broadcasts = _broadcasts.where((b) => b.jobId != jobId).toList();
      if (_broadcasts.length != before) {
        _restartBroadcastCountdown();
        notifyListeners();
      }
    }
    fetchBroadcasts();
  }

  /// Best-effort job id from socket payload (shape may vary by server).
  String? _parseJobIdFromSocketPayload(Map<String, dynamic> payload) {
    for (final key in ['jobId', 'job_id']) {
      final v = payload[key]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    final job = payload['job'];
    if (job is Map) {
      final m = Map<String, dynamic>.from(job);
      final id = m['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    final data = payload['data'];
    if (data is Map) {
      return _parseJobIdFromSocketPayload(Map<String, dynamic>.from(data));
    }
    final broadcast = payload['broadcast'];
    if (broadcast is Map) {
      return _parseJobIdFromSocketPayload(Map<String, dynamic>.from(broadcast));
    }
    return null;
  }

  @override
  void dispose() {
    _profileSocketDebounce?.cancel();
    _realtimeService.off(RealtimeService.eventTechnicianOrdersUpdated, _onAssignedOrdersUpdated);
    _realtimeService.off(RealtimeService.eventTechnicianBroadcastCreated, _onBroadcastCreated);
    _realtimeService.off(RealtimeService.eventTechnicianBroadcastClosed, _onBroadcastClosed);
    _realtimeService.off(RealtimeService.eventTechnicianProfileUpdated, _onProfileUpdatedSocket);
    _realtimeService.removeConnectListener(_onRealtimeConnected);
    _realtimeService.disconnect();
    _broadcastTimer?.cancel();
    super.dispose();
  }

  // --- Toggles (workshop / on-call / both / inactive via API dutyMode) ---
  bool _isWorkshopDuty = false;
  bool _isOnCallDuty = false;
  bool _isWorkshopDutyLoading = false;
  bool _isOnCallDutyLoading = false;

  /// From login payload; profile may omit `technicianType` so we keep this for duty defaults.
  String? _sessionTechnicianType;
  String? _sessionDutyMode;

  /// So pull-to-refresh / re-init does not override duty toggles the user already changed.
  bool _initialDutyDefaultsApplied = false;

  /// When this changes (new login), duty defaults run again for the new account.
  String? _lastBootstrappedUserId;

  bool get isWorkshopDuty => _isWorkshopDuty;
  bool get isOnCallDuty => _isOnCallDuty;
  bool get isWorkshopDutyLoading => _isWorkshopDutyLoading;
  bool get isOnCallDutyLoading => _isOnCallDutyLoading;

  /// Presence is **offline** (cashier / system). Duty toggles are hidden until marked online again.
  /// Note: `dutyMode` may be `inactive` while offline — that does **not** mean the technician should
  /// see duty toggles; presence `offline` always shows the offline notice.
  bool get isOfflineLockedByCashier {
    final os = profile?.onlineStatus?.toString().toLowerCase().trim() ?? '';
    if (os == 'offline') return true;
    final dm = profile?.dutyMode?.toString().toLowerCase().trim() ??
        _sessionDutyMode?.toLowerCase().trim() ??
        '';
    return dm == 'offline';
  }

  static String _encodeDutyModeForType(
    String technicianType,
    bool workshop,
    bool onCall,
  ) {
    final t = technicianType.toLowerCase();
    if (t == 'workshop') {
      return workshop ? 'workshop' : 'inactive';
    }
    if (t == 'on_call') {
      return onCall ? 'on_call' : 'inactive';
    }
    if (!workshop && !onCall) return 'inactive';
    if (workshop && onCall) return 'workshop';
    if (workshop) return 'workshop';
    return 'on_call';
  }

  Future<void> toggleWorkshopDuty(BuildContext context, bool value) async {
    if (isOfflineLockedByCashier) {
      if (context.mounted) {
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.techOfflineAskCashier,
        );
      }
      return;
    }
    if (value == _isWorkshopDuty) return;
    final t =
        (_sessionTechnicianType ?? profile?.technicianType ?? 'workshop')
            .toLowerCase();
    var w = value;
    var o = _isOnCallDuty;
    if (t == 'on_call') return;
    if (t == 'workshop') o = false;
    if (t == 'both') {
      if (value) o = false;
    }

    _isWorkshopDutyLoading = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final techType =
            _sessionTechnicianType ?? profile?.technicianType ?? 'workshop';
        final mode = _encodeDutyModeForType(techType, w, o);
        final res = await _repository.updateDutyStatus(token, mode);
        if (res != null) {
          _isWorkshopDuty = w;
          _isOnCallDuty = o;
        }
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ToastService.showError(context, msg);
      }
    } finally {
      _isWorkshopDutyLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleOnCallDuty(BuildContext context, bool value) async {
    if (isOfflineLockedByCashier) {
      if (context.mounted) {
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.techOfflineAskCashier,
        );
      }
      return;
    }
    if (value == _isOnCallDuty) return;
    final t =
        (_sessionTechnicianType ?? profile?.technicianType ?? 'workshop')
            .toLowerCase();
    var w = _isWorkshopDuty;
    var o = value;
    if (t == 'workshop') return;
    if (t == 'on_call') w = false;
    if (t == 'both' && value) w = false;

    _isOnCallDutyLoading = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final techType =
            _sessionTechnicianType ?? profile?.technicianType ?? 'workshop';
        final mode = _encodeDutyModeForType(techType, w, o);
        final res = await _repository.updateDutyStatus(token, mode);
        if (res != null) {
          _isWorkshopDuty = w;
          _isOnCallDuty = o;
        }
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ToastService.showError(context, msg);
      }
    } finally {
      _isOnCallDutyLoading = false;
      notifyListeners();
    }
  }
  String technicianName = '';

  /// Shown under "Welcome Back," — prefers profile, then session name / email local-part.
  String get dashboardGreetingName {
    String? pick(String? s) {
      final t = s?.trim();
      return (t != null && t.isNotEmpty) ? t : null;
    }

    return pick(profile?.name) ??
        pick(technicianName) ??
        pick(profile?.email?.split('@').first) ??
        pick(profile?.mobile) ??
        '';
  }
  int todayCompletedJobs = 0;
  double todayRevenue = 0.0;
  double todayCommission = 0.0;
  double weekCommission = 0.0;
  int monthCompletedJobs = 0;
  double monthRevenue = 0.0;
  List<WeeklyOverview> weeklyOverview = [];
  TechnicianProfile? profile;

  // --- Shared report period (dashboard KPIs, assigned jobs list, commission) ---
  DateTime _reportPeriodFrom = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
    0,
    0,
  );
  DateTime _reportPeriodTo = DateTime.now();

  void _setReportPeriodFrom(DateTime d) {
    var next = DateTime(d.year, d.month, d.day, d.hour, d.minute);
    if (next.isAfter(_reportPeriodTo)) {
      _reportPeriodTo = next;
    }
    _reportPeriodFrom = next;
  }

  void _setReportPeriodTo(DateTime d) {
    var next = DateTime(d.year, d.month, d.day, d.hour, d.minute);
    if (next.isBefore(_reportPeriodFrom)) {
      _reportPeriodFrom = next;
    }
    _reportPeriodTo = next;
  }

  Future<void> _refreshReportPeriodData({bool affectLoading = false}) async {
    await Future.wait([
      fetchDashboardKpis(affectLoading: affectLoading),
      fetchAssignedOrders(affectLoading: false),
      fetchCommissionHistory(),
    ]);
  }

  /// Jobs completed in the shared report period (matches commission + assigned list).
  int get reportPeriodJobCount => dashboardJobsCompleted;

  // --- Dashboard KPI filter ---
  TechDashboardKpiFilterMode dashboardKpiFilterMode =
      TechDashboardKpiFilterMode.dateRange;
  int _dashboardKpiMonth = DateTime.now().month;
  int _dashboardKpiYear = DateTime.now().year;
  int get dashboardKpiMonth => _dashboardKpiMonth;
  int get dashboardKpiYear => _dashboardKpiYear;
  DateTime get dashboardKpiFrom => _reportPeriodFrom;
  DateTime get dashboardKpiTo => _reportPeriodTo;
  bool isLoadingDashboardKpis = false;
  int dashboardJobsCompleted = 0;
  double dashboardRevenueEarned = 0.0;
  double dashboardCommissionEarned = 0.0;
  String dashboardKpiPeriodLabel = '';

  void setDashboardKpiFilterMode(TechDashboardKpiFilterMode mode) {
    dashboardKpiFilterMode = mode;
    notifyListeners();
  }

  void setDashboardKpiMonthYear(int month, int year) {
    _dashboardKpiMonth = month.clamp(1, 12);
    _dashboardKpiYear = year;
    notifyListeners();
  }

  void setDashboardKpiFrom(DateTime d) {
    _setReportPeriodFrom(d);
    notifyListeners();
  }

  void setDashboardKpiTo(DateTime d) {
    _setReportPeriodTo(d);
    notifyListeners();
  }

  Future<void> applyDashboardKpiStartDate(DateTime d) async {
    _setReportPeriodFrom(d);
    notifyListeners();
    await _refreshReportPeriodData();
  }

  Future<void> applyDashboardKpiEndDate(DateTime d) async {
    _setReportPeriodTo(d);
    notifyListeners();
    await _refreshReportPeriodData();
  }

  String _dashboardPeriodLabelFromResponse(TechnicianDashboardKpis response) {
    final from = response.from?.trim();
    final to = response.to?.trim();
    if (from != null &&
        from.isNotEmpty &&
        to != null &&
        to.isNotEmpty) {
      return '$from – $to';
    }
    return TechMonthFilterBar.monthYearLabel(response.month, response.year);
  }

  Future<void> fetchDashboardKpis({bool affectLoading = false}) async {
    if (affectLoading) _setLoading(true);
    isLoadingDashboardKpis = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getDashboardKpis(
          token,
          from: _reportPeriodFrom,
          to: _reportPeriodTo,
        );
        if (response.success) {
          dashboardJobsCompleted = response.jobsCompleted;
          dashboardRevenueEarned = response.revenueEarned;
          dashboardCommissionEarned = response.commissionEarned;
          dashboardKpiPeriodLabel =
              _dashboardPeriodLabelFromResponse(response);
        }
      }
    } catch (_) {
    } finally {
      isLoadingDashboardKpis = false;
      if (affectLoading) _setLoading(false);
      notifyListeners();
    }
  }

  // --- Monthly KPI (Performance + Commission History) ---
  int _kpiMonth = DateTime.now().month;
  int _kpiYear = DateTime.now().year;
  int get kpiMonth => _kpiMonth;
  int get kpiYear => _kpiYear;

  double monthlyTotalCommission = 0.0;
  int monthlyTotalJobs = 0;
  List<MonthlyCommissionDay> monthlyCommissionTimeline = [];
  bool isLoadingMonthlyKpi = false;

  void setKpiMonthYear(int month, int year) {
    _kpiMonth = month.clamp(1, 12);
    _kpiYear = year;
    _reportPeriodFrom = DateTime(_kpiYear, _kpiMonth, 1, 0, 0);
    var monthEnd = DateTime(_kpiYear, _kpiMonth + 1, 0, 23, 59);
    final now = DateTime.now();
    _reportPeriodTo = monthEnd.isAfter(now) ? now : monthEnd;
    notifyListeners();
    unawaited(_refreshReportPeriodData());
  }

  static List<MonthlyCommissionDay> _buildMonthlyTimeline(
    List<CommissionEntry> entries,
  ) {
    final map = <String, double>{};
    for (final e in entries) {
      final ymd = e.displayYmd.trim();
      if (ymd.length != 10) continue;
      map[ymd] = (map[ymd] ?? 0) + e.commission;
    }
    final keys = map.keys.toList()..sort();
    return keys
        .map((ymd) {
          final day = int.tryParse(ymd.substring(8, 10)) ?? 0;
          return MonthlyCommissionDay(day: day, amount: map[ymd] ?? 0);
        })
        .toList();
  }

  Future<void> fetchMonthlyKpi({bool affectLoading = true}) async {
    if (affectLoading) {
      isLoadingMonthlyKpi = true;
      notifyListeners();
    }
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getCommissionHistory(
          token,
          month: _kpiMonth,
          year: _kpiYear,
        );
        if (response.success) {
          monthlyTotalCommission = response.totalCommission;
          monthlyTotalJobs = response.total;
          monthlyCommissionTimeline = _buildMonthlyTimeline(response.entries);
        }
      }
    } catch (_) {
    } finally {
      isLoadingMonthlyKpi = false;
      notifyListeners();
    }
  }

  // --- Commission History ---
  List<CommissionEntry> commissionHistory = [];
  bool isLoadingCommission = false;
  double commissionHistoryTotalCommission = 0.0;
  /// From last successful `/technician/commission-history` response (IANA id).
  String? commissionHistoryBusinessTimeZone;

  DateTime get commissionHistoryFrom => _reportPeriodFrom;
  DateTime get commissionHistoryTo => _reportPeriodTo;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _minutePrecision(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute);

  /// Matches filter pickers and card timestamps (device-local, minute precision).
  bool _instantInReportPeriod(DateTime dt) {
    final ts = _minutePrecision(dt.toLocal());
    final from = _minutePrecision(_reportPeriodFrom);
    final to = _minutePrecision(_reportPeriodTo);
    return !ts.isBefore(from) && !ts.isAfter(to);
  }

  bool _techOrderInSelectedRange(TechOrder o) {
    final ts = o.timestamp;
    if (ts == null) return false;
    return _instantInReportPeriod(ts);
  }

  /// Post-filter commission rows to the selected clock range shown in the UI.
  bool _commissionEntryInSelectedRange(CommissionEntry e) {
    final entryDt = DateTime.tryParse(e.date);
    if (entryDt != null) {
      return _instantInReportPeriod(entryDt);
    }
    return false;
  }

  static int _compareCommissionEntriesDescending(CommissionEntry a, CommissionEntry b) {
    final byYmd = b.displayYmd.compareTo(a.displayYmd);
    if (byYmd != 0) return byYmd;
    final da = DateTime.tryParse(a.date);
    final db = DateTime.tryParse(b.date);
    if (da != null && db != null) return db.compareTo(da);
    return b.date.compareTo(a.date);
  }

  void setCommissionHistoryFrom(DateTime d) {
    _setReportPeriodFrom(d);
    notifyListeners();
  }

  void setCommissionHistoryTo(DateTime d) {
    _setReportPeriodTo(d);
    notifyListeners();
  }

  Future<void> applyCommissionHistoryStartDate(DateTime d) async {
    _setReportPeriodFrom(d);
    notifyListeners();
    await _refreshReportPeriodData();
  }

  Future<void> applyCommissionHistoryEndDate(DateTime d) async {
    _setReportPeriodTo(d);
    notifyListeners();
    await _refreshReportPeriodData();
  }

  Future<void> fetchCommissionHistory() async {
    isLoadingCommission = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getCommissionHistory(
          token,
          from: _reportPeriodFrom,
          to: _reportPeriodTo,
        );
        if (response.success) {
          commissionHistoryBusinessTimeZone = response.businessTimeZone;
          monthlyCommissionTimeline = _buildMonthlyTimeline(response.entries);
          final list = response.entries
              .where(_commissionEntryInSelectedRange)
              .toList()
            ..sort(_compareCommissionEntriesDescending);
          commissionHistory = list;
          commissionHistoryTotalCommission = list.fold(
            0.0,
            (sum, e) => sum + e.commission,
          );
          monthlyTotalCommission = commissionHistoryTotalCommission;
          monthlyTotalJobs = list.length;
        }
      }
    } catch (e) {
    } finally {
      isLoadingCommission = false;
      notifyListeners();
    }
  }

  // --- Salary payments (admin payroll posted) ---
  List<TechSalaryPayment> salaryPayments = [];
  bool isLoadingSalaryPayments = false;
  double salaryPaymentsTotalNet = 0.0;
  int salaryPaymentsTotal = 0;

  List<TechAdvanceTransaction> salaryAdvanceTransactions = [];
  bool isLoadingSalaryAdvances = false;
  double salaryAdvancesTotalOutstanding = 0.0;
  double salaryAdvancesTotalIssued = 0.0;
  double salaryAdvancesTotalDeducted = 0.0;
  int salaryAdvancesTotal = 0;

  /// Dedicated date range for Salaries / Advances tabs (independent of commission filters).
  late DateTime _salaryScreenFrom = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  late DateTime _salaryScreenTo = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime get salaryScreenFrom => _salaryScreenFrom;
  DateTime get salaryScreenTo => _salaryScreenTo;

  void _setSalaryScreenFrom(DateTime d) {
    var next = DateTime(d.year, d.month, d.day);
    final endDay = DateTime(
      _salaryScreenTo.year,
      _salaryScreenTo.month,
      _salaryScreenTo.day,
    );
    if (next.isAfter(endDay)) next = endDay;
    _salaryScreenFrom = next;
  }

  void _setSalaryScreenTo(DateTime d) {
    var next = DateTime(d.year, d.month, d.day);
    final startDay = DateTime(
      _salaryScreenFrom.year,
      _salaryScreenFrom.month,
      _salaryScreenFrom.day,
    );
    if (next.isBefore(startDay)) {
      _salaryScreenFrom = next;
    }
    _salaryScreenTo = next;
  }

  Future<void> applySalaryScreenStartDate(DateTime d) async {
    _setSalaryScreenFrom(d);
    notifyListeners();
    await fetchSalaryScreenData();
  }

  Future<void> applySalaryScreenEndDate(DateTime d) async {
    _setSalaryScreenTo(d);
    notifyListeners();
    await fetchSalaryScreenData();
  }

  Future<void> fetchSalaryPayments() async {
    isLoadingSalaryPayments = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getSalaryPayments(
          token,
          from: _salaryScreenFrom,
          to: _salaryScreenTo,
        );
        if (response.success) {
          salaryPayments = response.payments;
          salaryPaymentsTotalNet = response.totalNetPaid;
          salaryPaymentsTotal = response.total;
        }
      }
    } catch (_) {
    } finally {
      isLoadingSalaryPayments = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalaryAdvances() async {
    isLoadingSalaryAdvances = true;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getSalaryAdvances(
          token,
          from: _salaryScreenFrom,
          to: _salaryScreenTo,
        );
        if (response.success) {
          salaryAdvanceTransactions = response.transactions;
          salaryAdvancesTotalOutstanding = response.totalOutstanding;
          salaryAdvancesTotalIssued = response.totalIssued;
          salaryAdvancesTotalDeducted = response.totalDeducted;
          salaryAdvancesTotal = response.total;
        }
      }
    } catch (_) {
    } finally {
      isLoadingSalaryAdvances = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalaryScreenData() async {
    await Future.wait([
      fetchSalaryPayments(),
      fetchSalaryAdvances(),
    ]);
  }

  final Map<String, String> _salaryAckInFlight = {};

  bool isSalaryRejectInFlight(String paymentId) =>
      _salaryAckInFlight[paymentId] == 'rejected';

  bool isSalaryAcceptInFlight(String paymentId) =>
      _salaryAckInFlight[paymentId] == 'accepted';

  Future<String?> respondToSalaryPayment(
    String paymentId,
    String response, {
    BuildContext? context,
  }) async {
    if (_salaryAckInFlight.containsKey(paymentId)) return null;
    final l10n = context != null ? AppLocalizations.of(context) : null;
    _salaryAckInFlight[paymentId] = response;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return l10n?.techNotSignedIn ?? 'Not signed in';
      final result = await _repository.respondToSalaryPayment(
        token,
        paymentId,
        response,
      );
      if (result['success'] != true) {
        return result['message']?.toString() ??
            (l10n?.techCouldNotSubmitResponse ?? 'Could not submit response');
      }
      final idx = salaryPayments.indexWhere((p) => p.id == paymentId);
      if (idx >= 0) {
        final old = salaryPayments[idx];
        salaryPayments[idx] = TechSalaryPayment(
          id: old.id,
          period: old.period,
          paymentDate: old.paymentDate,
          basicSalary: old.basicSalary,
          commissionAmount: old.commissionAmount,
          advanceDeduction: old.advanceDeduction,
          penalties: old.penalties,
          penaltyNotes: old.penaltyNotes,
          totalDeductions: old.totalDeductions,
          grossSalary: old.grossSalary,
          netSalary: old.netSalary,
          payFromAccountName: old.payFromAccountName,
          method: old.method,
          status: old.status,
          technicianAckStatus:
              result['technicianAckStatus']?.toString() ?? response,
          technicianAckAt: DateTime.tryParse(
                result['technicianAckAt']?.toString() ?? '',
              ) ??
              DateTime.now(),
          notes: old.notes,
          journalId: old.journalId,
          createdAt: old.createdAt,
        );
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _salaryAckInFlight.remove(paymentId);
      notifyListeners();
    }
  }

  // --- Assigned Orders ---
  List<TechOrder> _assignedOrders = [];
  List<TechOrder> get assignedOrders => _assignedOrders;

  /// True while GET assigned-orders is in flight (including `affectLoading: false` from init).
  bool _assignedOrdersRequestInFlight = false;
  bool get isAssignedOrdersRequestInFlight => _assignedOrdersRequestInFlight;

  double assignedOrdersTotalCommission = 0.0;
  int assignedOrdersTotal = 0;

  DateTime get assignedOrdersFrom => _reportPeriodFrom;
  DateTime get assignedOrdersTo => _reportPeriodTo;

  void setAssignedOrdersFrom(DateTime d) {
    _setReportPeriodFrom(d);
    notifyListeners();
  }

  void setAssignedOrdersTo(DateTime d) {
    _setReportPeriodTo(d);
    notifyListeners();
  }

  Future<void> applyAssignedOrdersStartDate(DateTime d) async {
    _setReportPeriodFrom(d);
    notifyListeners();
    await _refreshReportPeriodData();
  }

  Future<void> applyAssignedOrdersEndDate(DateTime d) async {
    _setReportPeriodTo(d);
    notifyListeners();
    await _refreshReportPeriodData();
  }

  /// Home dashboard after init finished (name comes from login session, not GET profile).
  bool get isTechDashboardReady =>
      _isBootstrapped && !_isLoading && technicianName.trim().isNotEmpty;

  TechOrder? _currentOrderDetail;
  TechOrder? get currentOrderDetail => _currentOrderDetail;

  // --- Notifications ---
  List<TechNotification> _notifications = [];
  List<TechNotification> get notifications => _notifications;
  int get unreadNotifications => _notifications.where((n) => !n.isRead).length;

  // --- Loading State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isBootstrapped = false;
  bool get isBootstrapped => _isBootstrapped;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- Broadcast (GET /technician/broadcasts + socket refresh) ---
  List<TechBroadcast> _broadcasts = [];
  int _broadcastTimerSeconds = 0;
  int _broadcastRingTotalSecs = 300;
  int _broadcastWindowSeconds = 300;
  int _broadcastSoonThresholdSeconds = 60;
  int _broadcastActiveCount = 0;
  Timer? _broadcastTimer;
  final Set<String> _broadcastAcceptBusy = {};
  final Set<String> _broadcastRejectBusy = {};

  List<TechBroadcast> get broadcasts => List.unmodifiable(_broadcasts);
  TechBroadcast? get primaryBroadcast =>
      _broadcasts.isEmpty ? null : _broadcasts.first;

  bool get hasActiveBroadcast => _broadcasts.isNotEmpty;

  /// Full-screen popup on any technician screen when a live broadcast is active.
  bool get showBroadcastAcceptanceUi {
    if (_hideBroadcastOverlay) return false;
    final b = primaryBroadcast;
    if (b == null) return false;
    return !broadcastExpired(b);
  }

  bool _hideBroadcastOverlay = false;

  void setHideBroadcastOverlay(bool hide) {
    if (_hideBroadcastOverlay == hide) return;
    _hideBroadcastOverlay = hide;
    notifyListeners();
  }
  int get broadcastTimerSeconds => _broadcastTimerSeconds;
  int get broadcastRingTotalSecs =>
      _broadcastRingTotalSecs <= 0 ? 300 : _broadcastRingTotalSecs;
  int get broadcastWindowSeconds =>
      _broadcastWindowSeconds <= 0 ? 300 : _broadcastWindowSeconds;
  int get broadcastSoonThresholdSeconds =>
      _broadcastSoonThresholdSeconds <= 0 ? 60 : _broadcastSoonThresholdSeconds;
  int get broadcastActiveCountMeta => _broadcastActiveCount;

  bool isBroadcastAcceptBusy(String jobId) =>
      _broadcastAcceptBusy.contains(jobId);

  bool isBroadcastRejectBusy(String jobId) =>
      _broadcastRejectBusy.contains(jobId);

  Duration remainingForBroadcast(TechBroadcast b) {
    final exp = b.expiresAt;
    if (exp != null) return exp.difference(DateTime.now());
    if (b.remainingSecondsBootstrap > 0) {
      return Duration(seconds: b.remainingSecondsBootstrap);
    }
    return Duration.zero;
  }

  bool broadcastExpired(TechBroadcast b) => remainingForBroadcast(b).isNegative;

  bool broadcastShowSoon(TechBroadcast b) {
    final r = remainingForBroadcast(b);
    if (r.isNegative) return false;
    if (b.serverIsSoon) return true;
    return r.inSeconds <= _broadcastSoonThresholdSeconds;
  }

  double broadcastProgress(TechBroadcast b) {
    final max = _broadcastWindowSeconds <= 0 ? 300 : _broadcastWindowSeconds;
    final left = remainingForBroadcast(b).inSeconds.clamp(0, max);
    return left / max;
  }

  Future<void> fetchBroadcasts() async {
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return;
      final result = await _repository.getBroadcasts(token);
      _broadcasts = result.broadcasts;
      _broadcastWindowSeconds = result.windowSeconds;
      _broadcastSoonThresholdSeconds = result.soonThresholdSeconds;
      _broadcastActiveCount = result.activeCount;
      _restartBroadcastCountdown();
      notifyListeners();
    } catch (e) {
    }
  }

  void _restartBroadcastCountdown() {
    _broadcastTimer?.cancel();
    _broadcastRingTotalSecs =
        _broadcastWindowSeconds > 0 ? _broadcastWindowSeconds : 300;

    void tickPrimaryTimer() {
      final current = primaryBroadcast;
      if (current == null) {
        _broadcastTimerSeconds = 0;
        return;
      }
      final left = remainingForBroadcast(current).inSeconds;
      _broadcastTimerSeconds = left < 0 ? 0 : left;
    }

    if (_broadcasts.isEmpty) {
      _broadcastTimerSeconds = 0;
      return;
    }

    tickPrimaryTimer();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      tickPrimaryTimer();
      notifyListeners();
      if (_broadcasts.isEmpty) {
        _broadcastTimer?.cancel();
        return;
      }
      final anyLive =
          _broadcasts.any((b) => !remainingForBroadcast(b).isNegative);
      if (!anyLive) {
        _broadcastTimer?.cancel();
        fetchBroadcasts();
      }
    });
  }

  Future<bool> acceptBroadcastJob(BuildContext context, String jobId) async {
    if (jobId.isEmpty ||
        _broadcastAcceptBusy.contains(jobId) ||
        _broadcastRejectBusy.contains(jobId)) {
      return false;
    }
    _broadcastAcceptBusy.add(jobId);
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return false;
      await _repository.acceptBroadcast(token, jobId);
      await fetchAssignedOrders(affectLoading: false);
      await fetchBroadcasts();
      if (context.mounted) {
        ToastService.showSuccess(
          context,
          AppLocalizations.of(context)!.techJobAccepted,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, e.toString());
      }
      return false;
    } finally {
      _broadcastAcceptBusy.remove(jobId);
      notifyListeners();
    }
  }

  Future<bool> rejectBroadcastJob(BuildContext context, String jobId) async {
    if (jobId.isEmpty ||
        _broadcastAcceptBusy.contains(jobId) ||
        _broadcastRejectBusy.contains(jobId)) {
      return false;
    }
    _broadcastRejectBusy.add(jobId);
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return false;
      await _repository.rejectBroadcast(token, jobId);
      await fetchBroadcasts();
      if (context.mounted) {
        ToastService.showInfo(
          context,
          AppLocalizations.of(context)!.techBroadcastDeclined,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, e.toString());
      }
      return false;
    } finally {
      _broadcastRejectBusy.remove(jobId);
      notifyListeners();
    }
  }

  Future<bool> acceptCurrentBroadcast() async {
    final jobId = primaryBroadcast?.jobId;
    if (jobId == null) return false;
    _acceptingJobId = jobId;
    _acceptMessage = null;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return false;
      await _repository.acceptBroadcast(token, jobId);
      await fetchAssignedOrders(affectLoading: false);
      await fetchBroadcasts();
      return true;
    } catch (e) {
      _acceptMessage = e.toString();
      return false;
    } finally {
      _acceptingJobId = null;
      notifyListeners();
    }
  }

  Future<bool> rejectCurrentBroadcast() async {
    final jobId = primaryBroadcast?.jobId;
    if (jobId == null) return false;
    _cancellingJobId = jobId;
    _cancelMessage = null;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return false;
      await _repository.rejectBroadcast(token, jobId);
      await fetchBroadcasts();
      return true;
    } catch (e) {
      _cancelMessage = e.toString();
      return false;
    } finally {
      _cancellingJobId = null;
      notifyListeners();
    }
  }

  Future<void> fetchTodayPerformance({bool affectLoading = true}) async {
    if (affectLoading) _setLoading(true);
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final performance = await _repository.getTodayPerformance(token);
        if (performance.success == true) {
          todayCompletedJobs = performance.completedJobs ?? 0;
          todayRevenue = performance.dailyRevenue ?? 0.0;
          todayCommission = performance.todayEarned ?? 0.0;
          weekCommission = performance.weeklyEarned ?? 0.0;
          monthCompletedJobs = performance.monthCompletedJobs ?? 0;
          monthRevenue = performance.monthRevenue ?? 0.0;
        }
      }
    } catch (e) {
    } finally {
      if (affectLoading) _setLoading(false);
    }
  }

  Future<void> fetchProfile({bool affectLoading = true}) async {
    if (affectLoading) _setLoading(true);
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getTechnicianProfile(token);
        if (response.success == true) {
          profile = response.profile;
          final fromProfile = profile?.name?.trim();
          if (fromProfile != null && fromProfile.isNotEmpty) {
            technicianName = fromProfile;
          } else if (technicianName.trim().isEmpty) {
            final emailLocal = profile?.email?.split('@').first.trim();
            if (emailLocal != null && emailLocal.isNotEmpty) {
              technicianName = emailLocal;
            } else {
              final mobile = profile?.mobile?.trim();
              if (mobile != null && mobile.isNotEmpty) {
                technicianName = mobile;
              }
            }
          }
          
          // Duty toggles: `dutyMode` is the source of truth when the API sends it.
          final dm =
              profile?.dutyMode?.toString().toLowerCase().trim() ?? '';
          if (dm == 'workshop') {
            _isWorkshopDuty = true;
            _isOnCallDuty = false;
          } else if (dm == 'on_call') {
            _isWorkshopDuty = false;
            _isOnCallDuty = true;
          } else if (dm == 'both') {
            _isWorkshopDuty = true;
            _isOnCallDuty = false;
          } else if (dm == 'inactive') {
            _isWorkshopDuty = false;
            _isOnCallDuty = false;
          } else if (dm == 'offline') {
            _isWorkshopDuty = false;
            _isOnCallDuty = false;
          } else {
            if (profile?.workshopDuty != null) {
              _isWorkshopDuty = profile!.workshopDuty!;
            } else {
              _isWorkshopDuty = false;
            }
            if (profile?.onCallDuty != null) {
              _isOnCallDuty = profile!.onCallDuty!;
            } else {
              _isOnCallDuty = false;
            }
          }

          notifyListeners();
        }
      }
    } catch (e) {
    } finally {
      if (affectLoading) _setLoading(false);
    }
  }

  /// Workshop-only (or on-call / both) accounts should show the matching duty ON when online.
  /// The profile API often returns `workshopDuty: false` while `technicianType` is `workshop`, which hid the toggle.
  void _applyDefaultDutyForTechnicianType() {
    final dm =
        profile?.dutyMode?.toString().toLowerCase().trim() ?? '';
    if (dm == 'workshop') {
      _isOnCallDuty = false;
      _isWorkshopDuty = true;
      notifyListeners();
      return;
    }
    if (dm == 'on_call') {
      _isWorkshopDuty = false;
      _isOnCallDuty = true;
      notifyListeners();
      return;
    }
    if (dm == 'both') {
      _isWorkshopDuty = true;
      _isOnCallDuty = false;
      notifyListeners();
      return;
    }
    if (dm == 'inactive' || dm == 'offline') {
      _isWorkshopDuty = false;
      _isOnCallDuty = false;
      notifyListeners();
      return;
    }

    final type = (profile?.technicianType ?? _sessionTechnicianType)
        ?.toLowerCase()
        .trim();
    if (type == null || type.isEmpty) return;

    if (type == 'workshop') {
      _isOnCallDuty = false;
      _isWorkshopDuty = true;
    } else if (type == 'on_call') {
      _isWorkshopDuty = false;
      _isOnCallDuty = true;
    } else if (type == 'both') {
      if (!_isWorkshopDuty && !_isOnCallDuty) {
        _isWorkshopDuty = true;
        _isOnCallDuty = false;
      }
    }
    notifyListeners();
  }

  /// Keeps server duty mode aligned when we default the toggles from `technicianType`.
  Future<void> _syncDutyStateToBackendAfterInitialDefault() async {
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token == null) return;
      final techType =
          _sessionTechnicianType ?? profile?.technicianType ?? 'workshop';
      final mode =
          _encodeDutyModeForType(techType, _isWorkshopDuty, _isOnCallDuty);
      await _repository.updateDutyStatus(token, mode);
    } catch (e) {
    }
  }

  Future<void> fetchDailyPerformance({bool affectLoading = true}) async {
    if (affectLoading) _setLoading(true);
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final performance = await _repository.getDailyPerformance(token);
        if (performance.success == true) {
          todayCompletedJobs = performance.totalJobs ?? 0;
          todayRevenue = performance.earned ?? 0.0;
          // Note: API response doesn't seem to have todayCommission directly, using earned for now or placeholder
          todayCommission = performance.earned ?? 0.0; 
          weeklyOverview = performance.weeklyOverview ?? [];
          
          // Calculate weekly commission total
          weekCommission = weeklyOverview.fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));
        }
      }
    } catch (e) {
    } finally {
      if (affectLoading) _setLoading(false);
    }
  }

  Future<void> fetchAssignedOrders({bool affectLoading = true}) async {
    _assignedOrdersRequestInFlight = true;
    notifyListeners();
    if (affectLoading) _setLoading(true);
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getAssignedOrders(
          token,
          from: _reportPeriodFrom,
          to: _reportPeriodTo,
        );
        if (response.success) {
          _assignedOrders = response.orders
              .map((o) => TechOrder.fromAssignedOrder(o))
              .where(_techOrderInSelectedRange)
              .toList();
          assignedOrdersTotal = _assignedOrders.length;
          assignedOrdersTotalCommission = _assignedOrders.fold(
            0.0,
            (sum, o) => sum + o.commission,
          );
        }
      }
    } catch (e) {
    } finally {
      _assignedOrdersRequestInFlight = false;
      if (affectLoading) _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetails(String jobId) async {
    _setLoading(true);
    _currentOrderDetail = null; // Clear previous
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        final response = await _repository.getOrderDetails(token, jobId);
        if (response.success && response.order != null) {
          _currentOrderDetail = TechOrder.fromOrderDetails(response.order!);
        }
      }
    } catch (e) {
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  String? _completingJobId;
  String? get completingJobId => _completingJobId;

  String? _completeMessage;
  String? get completeMessage => _completeMessage;

  Future<bool> completeOrder(String jobId) async {
    _completingJobId = jobId;
    _completeMessage = null;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        await _repository.completeOrder(token, jobId);
        // Refresh orders and current detail
        await fetchAssignedOrders();
        await fetchOrderDetails(jobId);
        return true;
      }
      return false;
    } catch (e) {
      _completeMessage = e.toString();
      return false;
    } finally {
      _completingJobId = null;
      notifyListeners();
    }
  }

  String? _acceptingJobId;
  String? get acceptingJobId => _acceptingJobId;

  String? _acceptMessage;
  String? get acceptMessage => _acceptMessage;

  Future<bool> acceptOrder(String jobId) async {
    _acceptingJobId = jobId;
    _acceptMessage = null;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        await _repository.acceptOrder(token, jobId);
        await fetchAssignedOrders();
        await fetchBroadcasts();
        return true;
      }
      return false;
    } catch (e) {
      _acceptMessage = e.toString();
      return false;
    } finally {
      _acceptingJobId = null;
      notifyListeners();
    }
  }

  String? _cancellingJobId;
  String? get cancellingJobId => _cancellingJobId;

  String? _cancelMessage;
  String? get cancelMessage => _cancelMessage;

  Future<bool> cancelOrder(String jobId) async {
    _cancellingJobId = jobId;
    _cancelMessage = null;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        await _repository.cancelOrder(token, jobId);
        await fetchAssignedOrders();
        await fetchBroadcasts();
        return true;
      }
      return false;
    } catch (e) {
      _cancelMessage = e.toString();
      return false;
    } finally {
      _cancellingJobId = null;
      notifyListeners();
    }
  }

  String? _startingJobId;
  String? get startingJobId => _startingJobId;

  String? _startMessage;
  String? get startMessage => _startMessage;

  Future<bool> startOrder(String jobId) async {
    _startingJobId = jobId;
    _startMessage = null;
    notifyListeners();
    try {
      final token = await _sessionService.getToken(role: 'tech');
      if (token != null) {
        await _repository.startOrder(token, jobId);
        await fetchAssignedOrders();
        return true;
      }
      return false;
    } catch (e) {
      _startMessage = e.toString();
      return false;
    } finally {
      _startingJobId = null;
      notifyListeners();
    }
  }

  /// Duty toggles from persisted login payload (before GET profile).
  void _applySessionTechnicianDutyFromUser(User? user) {
    final t = user?.technician;
    final dm = t?.dutyMode?.toLowerCase().trim();
    if (dm != null && dm.isNotEmpty) {
      switch (dm) {
        case 'workshop':
          _isWorkshopDuty = true;
          _isOnCallDuty = false;
          return;
        case 'on_call':
          _isWorkshopDuty = false;
          _isOnCallDuty = true;
          return;
        case 'both':
          _isWorkshopDuty = true;
          _isOnCallDuty = false;
          return;
        case 'inactive':
          _isWorkshopDuty = false;
          _isOnCallDuty = false;
          return;
        case 'offline':
          _isWorkshopDuty = false;
          _isOnCallDuty = false;
          return;
      }
    }
    if (t?.workshopDuty == true && t?.onCallDuty != true) {
      _isWorkshopDuty = true;
      _isOnCallDuty = false;
      return;
    }
    if (t?.onCallDuty == true) {
      _isWorkshopDuty = false;
      _isOnCallDuty = true;
      return;
    }
    final type = t?.technicianType?.toLowerCase();
    if (type == 'workshop') {
      _isWorkshopDuty = true;
      _isOnCallDuty = false;
    } else if (type == 'on_call') {
      _isOnCallDuty = true;
      _isWorkshopDuty = false;
    } else if (type == 'both') {
      _isWorkshopDuty = true;
      _isOnCallDuty = false;
    }
  }

  // --- Initialize Logged In User ---
  Future<void> init() async {
    _isBootstrapped = false;
    _setLoading(true);
    final user = await _sessionService.getUser(role: 'tech');
    final uid = user?.id?.toString();
    if (uid != null && uid != _lastBootstrappedUserId) {
      _initialDutyDefaultsApplied = false;
      _lastBootstrappedUserId = uid;
    } else if (user == null) {
      _lastBootstrappedUserId = null;
    }
    if (user != null) {
      final n = user.name?.trim();
      if (n != null && n.isNotEmpty) {
        technicianName = n;
      } else {
        final email = user.email?.trim();
        if (email != null && email.isNotEmpty) {
          final local = email.split('@').first.trim();
          technicianName = local.isNotEmpty ? local : '';
        } else {
          technicianName = '';
        }
      }
      _applySessionTechnicianDutyFromUser(user);
      _sessionTechnicianType = user.technician?.technicianType;
      _sessionDutyMode = user.technician?.dutyMode;
    } else {
      _sessionTechnicianType = null;
      _sessionDutyMode = null;
    }
    notifyListeners();

    await ensureRealtimeConnected();

    // Dashboard + assigned jobs + commission share one date range.
    await _refreshReportPeriodData(affectLoading: false);
    await fetchTodayPerformance(affectLoading: false);
    if (!_initialDutyDefaultsApplied) {
      _applyDefaultDutyForTechnicianType();
      _initialDutyDefaultsApplied = true;
      if (!isOfflineLockedByCashier) {
        unawaited(_syncDutyStateToBackendAfterInitialDefault());
      }
    }

    _isBootstrapped = true;
    _setLoading(false);

    // Background: broadcast popup (assigned orders already loaded above).
    unawaited(fetchBroadcasts());
    
    // Notifications remain mock for now as per image focus
    _notifications = [
      TechNotification(
        id: '1',
        title: 'Commission Credited',
        message: '45.00|ORD-7721',
        timestamp: DateTime.now(),
        type: 'Commission',
      ),
    ];
    notifyListeners();
  }

  void clearSession() {
    _sessionTechnicianType = null;
    _sessionDutyMode = null;
    _lastBootstrappedUserId = null;
    _initialDutyDefaultsApplied = false;
    _isWorkshopDuty = false;
    _isOnCallDuty = false;
    _isWorkshopDutyLoading = false;
    _isOnCallDutyLoading = false;
    _isBootstrapped = false;
    technicianName = '';
    todayCompletedJobs = 0;
    todayRevenue = 0.0;
    todayCommission = 0.0;
    weekCommission = 0.0;
    monthCompletedJobs = 0;
    monthRevenue = 0.0;
    final now = DateTime.now();
    dashboardKpiFilterMode = TechDashboardKpiFilterMode.dateRange;
    _dashboardKpiMonth = now.month;
    _dashboardKpiYear = now.year;
    _reportPeriodFrom = DateTime(now.year, now.month, 1, 0, 0);
    _reportPeriodTo = now;
    isLoadingDashboardKpis = false;
    dashboardJobsCompleted = 0;
    dashboardRevenueEarned = 0.0;
    dashboardCommissionEarned = 0.0;
    dashboardKpiPeriodLabel = '';
    weeklyOverview = [];
    profile = null;
    commissionHistory = [];
    commissionHistoryBusinessTimeZone = null;
    salaryPayments = [];
    salaryPaymentsTotalNet = 0;
    salaryPaymentsTotal = 0;
    isLoadingSalaryPayments = false;
    salaryAdvanceTransactions = [];
    salaryAdvancesTotalOutstanding = 0;
    salaryAdvancesTotalIssued = 0;
    salaryAdvancesTotalDeducted = 0;
    salaryAdvancesTotal = 0;
    isLoadingSalaryAdvances = false;
    _salaryScreenFrom = DateTime(now.year, now.month, 1);
    _salaryScreenTo = DateTime(now.year, now.month, now.day);
    _reportPeriodFrom = DateTime(now.year, now.month, 1, 0, 0);
    _reportPeriodTo = now;
    assignedOrdersTotalCommission = 0;
    assignedOrdersTotal = 0;
    _assignedOrders = [];
    _assignedOrdersRequestInFlight = false;
    _currentOrderDetail = null;
    _notifications = [];
    _broadcasts = [];
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _broadcastTimerSeconds = 0;
    _hideBroadcastOverlay = false;
    _isLoading = false;
    notifyListeners();
  }
}

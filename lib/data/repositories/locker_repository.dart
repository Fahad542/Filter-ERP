import '../../../../models/locker_financial_models.dart';
import '../../../../models/locker_models.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

export '../../models/locker_models.dart'
    show CollectionHistoryPage, CollectionHistoryEntry,
    CollectionHistorySummary;
export '../../../../models/locker_models.dart'
    show LockerBranch, LockerVarianceApproval, LockerFundRequest, LockerHistoryPage,
    LockerHistoryItem, LockerMatchStatus, LockerOverviewData, LockerOverviewDeposit,
    LockerOverviewKpis;

/// Bank register returned by GET /locker/bank-registers.
class BankRegisterModel {
  final String id;
  final String name;
  final String accountNumber;

  const BankRegisterModel({
    required this.id,
    required this.name,
    required this.accountNumber,
  });

  factory BankRegisterModel.fromJson(Map<String, dynamic> json) {
    return BankRegisterModel(
      id           : json['id']?.toString() ?? '',
      name         : json['name']          as String? ??
          json['bankName']       as String? ?? '',
      accountNumber: json['accountNumber'] as String? ??
          json['account']        as String? ?? '',
    );
  }
}

/// Typed cashier returned by GET /locker/cashiers.
/// The API uses `userId` as the primary key (not `id`).
class LockerCashierModel {
  final String userId;
  final String name;
  final String email;
  final String branchId;
  final String branchName;

  const LockerCashierModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.branchId,
    required this.branchName,
  });

  factory LockerCashierModel.fromJson(Map<String, dynamic> json) {
    return LockerCashierModel(
      userId    : json['userId']?.toString() ??
          json['id']?.toString() ?? '',
      name      : json['name']       as String? ?? '',
      email     : json['email']      as String? ?? '',
      branchId  : json['branchId']?.toString() ?? '',
      branchName: json['branchName'] as String? ?? '',
    );
  }
}

/// Typed response for POST /locker/deposit-to-bank.
///
/// Example payload:
/// `{ success, message, depositId, journalId, reference, amount }`
class LockerDepositResult {
  final bool success;
  final String message;
  final String depositId;
  final String journalId;
  final String reference;
  final double amount;

  const LockerDepositResult({
    required this.success,
    required this.message,
    required this.depositId,
    required this.journalId,
    required this.reference,
    required this.amount,
  });

  factory LockerDepositResult.fromJson(Map<String, dynamic> json) {
    return LockerDepositResult(
      success  : json['success'] as bool? ?? false,
      message  : json['message'] as String? ?? '',
      depositId: json['depositId']?.toString() ?? '',
      journalId: json['journalId']?.toString() ?? '',
      reference: json['reference'] as String? ?? '',
      amount   : _parseDepositAmount(json['amount']),
    );
  }
}

double _parseDepositAmount(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

/// Locker portal API wrapper (dashboard, requests, financials, notifications).
class LockerRepository {
  final BaseApiService _apiService = BaseApiService();

  Map<String, String> _auth(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _asJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    throw FetchDataException('Unexpected response shape');
  }

  /// Prefer `data` when the backend wraps payloads.
  Map<String, dynamic> _preferData(Map<String, dynamic> root) {
    final data = root['data'];
    if (data is Map<String, dynamic>) return data;
    return root;
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List<dynamic>) return raw;
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is List<dynamic>) return nested;
      final items = raw['items'] ??
          raw['branches'] ??
          raw['approvals'] ??
          raw['officers'];
      if (items is List<dynamic>) return items;
    }
    return const [];
  }

  Future<LockerDashboardData> getDashboard({
    required String view,
    required String token,
  }) async {
    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerDashboardEndpoint,
      {'view': view},
      token,
    );
    return LockerDashboardData.fromJson(_preferData(_asJsonMap(raw)));
  }

  /// Filters: date range / branch / cashier / min-max expected amount are
  /// sent as query params when provided — names match the same filter
  /// fields used by the web "Cashier Collection Requests" filter bar.
  /// NOTE: param key names (`fromDate`, `toDate`, `branchId`, `cashierId`,
  /// `minExpected`, `maxExpected`) are assumed to match the backend; adjust
  /// here if the actual API uses different keys.
  Future<LockerRequestsPage> getCollectionRequests({
    required String token,
    required String view,
    String? status,
    String? search,
    required int page,
    required int limit,
    DateTime? fromDate,
    DateTime? toDate,
    String? branchId,
    String? cashierId,
    double? minExpected,
    double? maxExpected,
  }) async {
    final params = <String, String>{
      'view': view,
      'page': '$page',
      'limit': '$limit',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (fromDate != null) {
      params['fromDate'] = fromDate.toUtc().toIso8601String();
    }
    if (toDate != null) {
      params['toDate'] = toDate.toUtc().toIso8601String();
    }
    if (branchId != null && branchId.isNotEmpty) {
      params['branchId'] = branchId;
    }
    if (cashierId != null && cashierId.isNotEmpty) {
      params['cashierId'] = cashierId;
    }
    if (minExpected != null) params['minExpected'] = '$minExpected';
    if (maxExpected != null) params['maxExpected'] = '$maxExpected';

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerCollectionRequestsEndpoint,
      params,
      token,
    );
    return LockerRequestsPage.fromJson(_preferData(_asJsonMap(raw)));
  }

  Future<LockerRequestDetail> getRequestDetail({
    required String token,
    required String requestId,
  }) async {
    final raw = await _apiService.get(
      ApiConstants.lockerCollectionRequestById(requestId),
      headers: _auth(token),
    );
    return LockerRequestDetail.fromJson(_preferData(_asJsonMap(raw)));
  }

  Future<String> assignOfficer({
    required String token,
    required String requestId,
    required String officerUserId,
  }) async {
    final raw = await _apiService.patch(
      ApiConstants.lockerAssignOfficerEndpoint(requestId),
      {'officerUserId': officerUserId},
      headers: _auth(token),
    );
    final map = _preferData(_asJsonMap(raw));
    final returned =
        map['assignedOfficerId'] ?? map['officerUserId'] ?? map['officerId'];
    return returned?.toString() ?? officerUserId;
  }

  Future<CollectionResult> recordCollection({
    required String token,
    required String requestId,
    required double receivedAmount,
    required String notes,
    required String proofUrl,
  }) async {
    final raw = await _apiService.post(
      ApiConstants.lockerRecordCollectionEndpoint,
      {
        'requestId': requestId,
        'receivedAmount': receivedAmount,
        'notes': notes,
        'proofUrl': proofUrl,
      },
      headers: _auth(token),
    );
    return CollectionResult.fromJson(_preferData(_asJsonMap(raw)));
  }

  Future<void> approveDifference({
    required String token,
    required String collectionId,
    required String status,
    required String rejectionReason,
  }) async {
    await _apiService.post(
      ApiConstants.lockerApproveDifferenceEndpoint,
      {
        'collectionId': collectionId,
        'status': status,
        'rejectionReason': rejectionReason,
      },
      headers: _auth(token),
    );
  }

  Future<AuditLogPage> getFinancialHistory({
    required String token,
    String? search,
    String? branchId,
    DateTime? from,
    DateTime? to,
    required int page,
    required int limit,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerFinancialHistoryEndpoint,
      params,
      token,
    );
    return AuditLogPage.fromJson(_preferData(_asJsonMap(raw)));
  }

  /// Standalone "Collections History" screen — same `GET
  /// /locker/financial/history` endpoint as [getFinancialHistory], but
  /// parsed into [CollectionHistoryPage] so the response's `summary` block
  /// (totalExpected / totalReceived / totalDifference / over-short-matched
  /// counts) is available for the KPI cards, not just the raw item list.
  ///
  /// `cashierId` / `officerId` mirror the web "Collections History" filter
  /// bar (Branch / Cashier / Officer dropdowns); sent only when provided so
  /// existing callers / behaviour are unaffected. NOTE: param key names are
  /// assumed to match `branchId`/`from`/`to`'s convention — adjust here if
  /// the backend uses different keys for these two.
  Future<CollectionHistoryPage> getCollectionHistory({
    required String token,
    String? search,
    String? branchId,
    String? cashierId,
    String? officerId,
    DateTime? from,
    DateTime? to,
    required int page,
    required int limit,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;
    if (cashierId != null && cashierId.isNotEmpty) {
      params['cashierId'] = cashierId;
    }
    if (officerId != null && officerId.isNotEmpty) {
      params['officerId'] = officerId;
    }
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerFinancialHistoryEndpoint,
      params,
      token,
    );
    return CollectionHistoryPage.fromJson(_preferData(_asJsonMap(raw)));
  }

  /// Fetches the most recent [limit] history entries for the dashboard preview.
  /// Uses the same `/locker/financial/history` endpoint with page=1.
  Future<LockerHistoryPage> getRecentHistory({
    required String token,
    int limit = 5,
  }) async {
    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerFinancialHistoryEndpoint,
      {'page': '1', 'limit': '$limit'},
      token,
    );
    return LockerHistoryPage.fromJson(_preferData(_asJsonMap(raw)));
  }

  Future<LockerAnalyticsData> getFinancialAnalytics({
    required String token,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerFinancialAnalyticsEndpoint,
      params,
      token,
    );
    return LockerAnalyticsData.fromJson(_preferData(_asJsonMap(raw)));
  }

  /// Returns the raw analytics JSON map so callers that need fields not
  /// present in [LockerAnalyticsData] (e.g. `totalShort`, `totalOver`,
  /// `netVariance`, `recentVariances`, `differencesSummary`) can parse
  /// them directly without depending on the generated model class.
  ///
  /// Used by [LockerDifferencesReportViewModel].
  Future<Map<String, dynamic>> getFinancialAnalyticsRaw({
    required String token,
    DateTime? from,
    DateTime? to,
    String? branchId,
    String? cashierUserId,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toUtc().toIso8601String();
    if (to != null) params['to'] = to.toUtc().toIso8601String();
    if (branchId != null && branchId.isNotEmpty) {
      params['branchId'] = branchId;
    }
    if (cashierUserId != null && cashierUserId.isNotEmpty) {
      params['cashierUserId'] = cashierUserId;
    }

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerFinancialAnalyticsEndpoint,
      params,
      token,
    );
    // Return the top-level map (not unwrapped via _preferData) so all
    // root-level keys like totalShort / recentVariances are accessible.
    return _asJsonMap(raw);
  }

  Future<List<LockerBranch>> getBranches({required String token}) async {
    final raw = await _apiService.get(
      ApiConstants.lockerBranchesEndpoint,
      headers: _auth(token),
    );
    final list = _extractList(raw);
    return list
        .map((e) => LockerBranch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LockerVarianceApproval>> getApprovals(
      {required String token}) async {
    final raw = await _apiService.get(
      ApiConstants.lockerApprovalsEndpoint,
      headers: _auth(token),
    );
    final list = _extractList(raw);
    return list
        .map((e) =>
        LockerVarianceApproval.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LockerFundRequest>> getPettyCashFundRequests({
    required String token,
    String status = 'pending',
  }) async {
    final raw = await _apiService.get(
      '${ApiConstants.lockerPettyCashFundRequestsEndpoint}?status=$status',
      headers: _auth(token),
    );
    final map = _asJsonMap(raw);
    final list = map['requests'] ?? map['data'] ?? map['items'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(LockerFundRequest.fromJson)
        .toList();
  }

  Future<void> approvePettyCashFundRequest({
    required String token,
    required String requestId,
  }) async {
    final raw = await _apiService.post(
      ApiConstants.lockerApprovePettyCashFundRequestEndpoint(requestId),
      const <String, dynamic>{},
      headers: _auth(token),
    );
    final map = _preferData(_asJsonMap(raw));
    if (map['success'] == false) {
      throw BadRequestException(
        'Invalid Request: ${map['message'] ?? 'Approve failed'}',
      );
    }
  }

  Future<void> rejectPettyCashFundRequest({
    required String token,
    required String requestId,
    required String rejectionReason,
  }) async {
    final raw = await _apiService.post(
      ApiConstants.lockerRejectPettyCashFundRequestEndpoint(requestId),
      {'rejectionReason': rejectionReason},
      headers: _auth(token),
    );
    final map = _preferData(_asJsonMap(raw));
    if (map['success'] == false) {
      throw BadRequestException(
        'Invalid Request: ${map['message'] ?? 'Reject failed'}',
      );
    }
  }

  Future<LockerNotificationsPage> getNotifications({
    required String token,
    required int page,
    int limit = 20,
  }) async {
    final endpoint = ApiConstants.lockerGetNotificationsEndpoint(page, limit);
    final raw = await _apiService.get(endpoint, headers: _auth(token));
    return LockerNotificationsPage.fromJson(_preferData(_asJsonMap(raw)));
  }

  Future<void> markNotificationRead({
    required String token,
    required String notificationId,
  }) async {
    await _apiService.post(
      ApiConstants.lockerNotificationsMarkReadEndpoint,
      {'notificationId': notificationId},
      headers: _auth(token),
    );
  }

  Future<List<LockerOfficer>> getFieldOfficers({required String token}) async {
    final raw = await _apiService.get(
      ApiConstants.lockerFieldOfficersEndpoint,
      headers: _auth(token),
    );
    final list = _extractList(raw);
    return list
        .map((e) => LockerOfficer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /locker/bank-registers — bank registers available for deposits.
  Future<List<BankRegisterModel>> getBankRegisters(
      {required String token}) async {
    final raw = await _apiService.get(
      ApiConstants.lockerBankRegistersEndpoint,
      headers: _auth(token),
    );
    final map = _asJsonMap(raw);
    final list = (map['registers'] ?? map['data'] ?? map['items'])
    as List<dynamic>? ?? [];
    return list
        .map((e) => BankRegisterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /workshop-staff/locker-management/overview — typed response.
  /// Returns KPIs, recentBankDeposits, recentPettyCashIssues, etc.
  Future<LockerOverviewData> getOverview({required String token}) async {
    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerOverviewEndpoint,
      {'_t': '${DateTime.now().millisecondsSinceEpoch}'},
      token,
    );
    return LockerOverviewData.fromJson(_asJsonMap(raw));
  }

  /// Fetches the locker overview as a raw map so callers can pick
  /// any fields not yet in [LockerOverviewData] (e.g. recentPettyCashIssues).
  Future<Map<String, dynamic>> getLockerOverview({
    required String token,
  }) async {
    final raw = await _apiService.get(
      ApiConstants.lockerOverviewEndpoint,
      headers: _auth(token),
    );
    return _asJsonMap(raw);
  }

  /// GET /locker/cashiers — typed list of cashiers for filter dropdown / petty cash.
  ///
  /// API response: `{ "success": true, "cashiers": [ { "userId": "...", ... } ] }`
  /// Falls back to `data` / `items` / raw list if `cashiers` key is absent.
  Future<List<LockerCashierModel>> getCashiers({
    required String token,
  }) async {
    final raw = await _apiService.get(
      ApiConstants.lockerCashiersEndpoint,
      headers: _auth(token),
    );
    final map = _asJsonMap(raw);

    // API wraps under "cashiers"; fall back gracefully to other common keys.
    final dynamic rawList =
        map['cashiers'] ?? map['data'] ?? map['items'] ?? raw;

    if (rawList is! List) return const [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(LockerCashierModel.fromJson)
        .toList();
  }

  /// Issues a petty-cash float.
  /// Returns the raw response map (caller may inspect `walletTransactionId`, `journalId`, etc.).
  Future<Map<String, dynamic>> issuePettyCash({
    required String token,
    required String cashierUserId,
    required double amount,
    required DateTime issueDate,
    required String reference,
  }) async {
    // Backend accepts ISO or date-only; send full ISO for consistent timezone.
    final issuedAt = issueDate.toUtc().toIso8601String();
    final ref = reference.trim();

    final raw = await _apiService.post(
      ApiConstants.lockerIssuePettyCashEndpoint,
      {
        'cashierUserId': cashierUserId,
        'amount': amount,
        'issuedAt': issuedAt,
        if (ref.isNotEmpty) 'reference': ref,
      },
      headers: _auth(token),
    );
    final map = _preferData(_asJsonMap(raw));
    if (map['success'] == false) {
      throw BadRequestException(
        'Invalid Request: ${map['message'] ?? 'Failed to issue petty cash'}',
      );
    }
    return map;
  }

  /// POST /locker/deposit-to-bank — moves cash from the locker vault into a
  /// bank register and posts the matching GL journal entry.
  ///
  /// Network resilience:
  /// - A 25s client-side timeout guards against a stalled/slow connection so
  ///   the submit button never hangs indefinitely; on timeout this throws a
  ///   [FetchDataException] with a user-friendly message, same as every
  ///   other failure path here, so callers only need one set of catch blocks.
  /// - `success: false` in an otherwise-200 response is treated as a real
  ///   failure (some backends return 200 + success:false instead of a 4xx),
  ///   so the caller doesn't have to special-case that shape.
  Future<LockerDepositResult> postDeposit({
    required String token,
    required String cashBankAccountId,
    required double amount,
    required DateTime depositedAt,
    required String reference,
  }) async {
    // Backend expects date-only string: "yyyy-MM-dd"
    final depositedAtStr =
        '${depositedAt.year.toString().padLeft(4, '0')}-'
        '${depositedAt.month.toString().padLeft(2, '0')}-'
        '${depositedAt.day.toString().padLeft(2, '0')}';

    final raw = await _apiService
        .post(
      ApiConstants.lockerDepositToBankEndpoint,
      {
        'cashBankAccountId': cashBankAccountId,
        'amount': amount,
        'reference': reference,
        'depositedAt': depositedAtStr,
      },
      headers: _auth(token),
    )
        .timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw FetchDataException(
        'Error During Communication: Request timed out. Please check your '
            'connection and try again.',
      ),
    );

    final result = LockerDepositResult.fromJson(_preferData(_asJsonMap(raw)));
    if (!result.success) {
      throw FetchDataException(
        'Error During Communication: '
            '${result.message.isNotEmpty ? result.message : 'Deposit failed.'}',
      );
    }
    return result;
  }

  /// GET /locker/petty-cash-issues — log of vault → cashier float issues.
  Future<PettyCashIssueLogPage> getPettyCashIssues({
    required String token,
    DateTime? from,
    DateTime? to,
    String? branchId,
    String? cashierId,
    int page = 1,
    int limit = 100,
  }) async {
    String? dateOnly(DateTime? d) {
      if (d == null) return null;
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    final fromStr = dateOnly(from);
    final toStr = dateOnly(to);
    if (fromStr != null) params['from'] = fromStr;
    if (toStr != null) params['to'] = toStr;
    if (branchId != null && branchId.isNotEmpty) {
      params['branchId'] = branchId;
    }
    if (cashierId != null && cashierId.isNotEmpty) {
      params['cashierId'] = cashierId;
    }

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerPettyCashIssuesEndpoint,
      params,
      token,
    );
    return PettyCashIssueLogPage.fromJson(_asJsonMap(raw));
  }

  /// GET /locker/expense-categories — hard-coded locker expense categories.
  Future<List<String>> getExpenseCategories({required String token}) async {
    final raw = await _apiService.get(
      ApiConstants.lockerExpenseCategoriesEndpoint,
      headers: _auth(token),
    );
    final map = _asJsonMap(raw);
    final list = map['categories'];
    if (list is! List) return const [];
    return list
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// GET /locker/expenses — pending / posted / rejected locker vault expenses.
  Future<LockerExpensesPage> getExpenses({
    required String token,
    DateTime? from,
    DateTime? to,
    String? branchId,
    String? category,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    String? dateOnly(DateTime? d) {
      if (d == null) return null;
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    final fromStr = dateOnly(from);
    final toStr = dateOnly(to);
    if (fromStr != null) params['from'] = fromStr;
    if (toStr != null) params['to'] = toStr;
    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      params['branchId'] = branchId;
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      params['category'] = category;
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }

    final raw = await _apiService.getWithQueryParams(
      ApiConstants.lockerExpensesEndpoint,
      params,
      token,
    );
    return LockerExpensesPage.fromJson(_asJsonMap(raw));
  }

  /// POST /locker/expenses/bulk — submit multiple expense lines for approval.
  Future<LockerBulkExpenseResult> createExpensesBulk({
    required String token,
    required List<Map<String, dynamic>> items,
  }) async {
    final raw = await _apiService.post(
      ApiConstants.lockerExpensesBulkEndpoint,
      {'items': items},
      headers: _auth(token),
    );
    final result =
        LockerBulkExpenseResult.fromJson(_preferData(_asJsonMap(raw)));
    if (!result.success) {
      throw FetchDataException(
        'Error During Communication: '
            '${result.message.isNotEmpty ? result.message : 'Submit failed.'}',
      );
    }
    return result;
  }
}

/// Summary block from GET /locker/petty-cash-issues.
class PettyCashIssueLogSummary {
  final double lockerVaultBalance;
  final double totalAmount;
  final int issueCount;
  final double averageAmount;

  const PettyCashIssueLogSummary({
    required this.lockerVaultBalance,
    required this.totalAmount,
    required this.issueCount,
    required this.averageAmount,
  });

  factory PettyCashIssueLogSummary.empty() => const PettyCashIssueLogSummary(
        lockerVaultBalance: 0,
        totalAmount: 0,
        issueCount: 0,
        averageAmount: 0,
      );

  factory PettyCashIssueLogSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PettyCashIssueLogSummary.empty();
    return PettyCashIssueLogSummary(
      lockerVaultBalance: _parseDepositAmount(json['lockerVaultBalance']),
      totalAmount: _parseDepositAmount(json['totalAmount']),
      issueCount: (json['issueCount'] as num?)?.toInt() ?? 0,
      averageAmount: _parseDepositAmount(json['averageAmount']),
    );
  }
}

/// One row from GET /locker/petty-cash-issues `issues[]`.
class PettyCashIssueLogEntry {
  final String id;
  final String journalId;
  final String journalEntryNumber;
  final String date;
  final double amount;
  final String description;
  final String branchId;
  final String branchName;
  final String cashierId;
  final String cashierName;

  const PettyCashIssueLogEntry({
    required this.id,
    required this.journalId,
    required this.journalEntryNumber,
    required this.date,
    required this.amount,
    required this.description,
    required this.branchId,
    required this.branchName,
    required this.cashierId,
    required this.cashierName,
  });

  factory PettyCashIssueLogEntry.fromJson(Map<String, dynamic> json) {
    return PettyCashIssueLogEntry(
      id: json['id']?.toString() ?? '',
      journalId: json['journalId']?.toString() ?? '',
      journalEntryNumber: json['journalEntryNumber'] as String? ?? '',
      date: json['date'] as String? ?? '',
      amount: _parseDepositAmount(json['amount']),
      description: json['description'] as String? ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName'] as String? ?? '',
      cashierId: json['cashierId']?.toString() ?? '',
      cashierName: json['cashierName'] as String? ?? '',
    );
  }
}

class PettyCashIssueLogPage {
  final bool success;
  final int total;
  final int page;
  final int limit;
  final PettyCashIssueLogSummary summary;
  final List<PettyCashIssueLogEntry> issues;

  const PettyCashIssueLogPage({
    required this.success,
    required this.total,
    required this.page,
    required this.limit,
    required this.summary,
    required this.issues,
  });

  factory PettyCashIssueLogPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['issues'];
    return PettyCashIssueLogPage(
      success: json['success'] as bool? ?? true,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      summary: PettyCashIssueLogSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : null,
      ),
      issues: rawList is List
          ? rawList
              .whereType<Map<String, dynamic>>()
              .map(PettyCashIssueLogEntry.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Summary from GET /locker/expenses.
class LockerExpensesSummary {
  final double lockerVaultBalance;
  final double totalAmount;
  final int expenseCount;
  final double averageAmount;
  final int pendingCount;

  const LockerExpensesSummary({
    required this.lockerVaultBalance,
    required this.totalAmount,
    required this.expenseCount,
    required this.averageAmount,
    required this.pendingCount,
  });

  factory LockerExpensesSummary.empty() => const LockerExpensesSummary(
        lockerVaultBalance: 0,
        totalAmount: 0,
        expenseCount: 0,
        averageAmount: 0,
        pendingCount: 0,
      );

  factory LockerExpensesSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LockerExpensesSummary.empty();
    return LockerExpensesSummary(
      lockerVaultBalance: _parseDepositAmount(json['lockerVaultBalance']),
      totalAmount: _parseDepositAmount(json['totalAmount']),
      expenseCount: (json['expenseCount'] as num?)?.toInt() ?? 0,
      averageAmount: _parseDepositAmount(json['averageAmount']),
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One row from GET /locker/expenses `expenses[]`.
class LockerExpenseEntry {
  final String id;
  final String branchId;
  final String branchName;
  final String category;
  final String? description;
  final double amount;
  final String expenseDate;
  final String? proofUrl;
  final String status;
  final String? journalEntryNumber;
  final String? createdByName;
  final String? approvedByName;
  final String? rejectionReason;

  const LockerExpenseEntry({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    required this.proofUrl,
    required this.status,
    required this.journalEntryNumber,
    required this.createdByName,
    required this.approvedByName,
    required this.rejectionReason,
  });

  factory LockerExpenseEntry.fromJson(Map<String, dynamic> json) {
    return LockerExpenseEntry(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      amount: _parseDepositAmount(json['amount']),
      expenseDate: json['expenseDate']?.toString().split('T').first ?? '',
      proofUrl: json['proofUrl'] as String?,
      status: json['status'] as String? ?? '',
      journalEntryNumber: json['journalEntryNumber'] as String?,
      createdByName: json['createdByName'] as String?,
      approvedByName: json['approvedByName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}

class LockerExpensesPage {
  final bool success;
  final int total;
  final int page;
  final int limit;
  final LockerExpensesSummary summary;
  final List<LockerExpenseEntry> expenses;

  const LockerExpensesPage({
    required this.success,
    required this.total,
    required this.page,
    required this.limit,
    required this.summary,
    required this.expenses,
  });

  factory LockerExpensesPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['expenses'];
    return LockerExpensesPage(
      success: json['success'] as bool? ?? true,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      summary: LockerExpensesSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : null,
      ),
      expenses: rawList is List
          ? rawList
              .whereType<Map<String, dynamic>>()
              .map(LockerExpenseEntry.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Response from POST /locker/expenses/bulk.
class LockerBulkExpenseResult {
  final bool success;
  final String message;
  final double totalAmount;
  final int count;

  const LockerBulkExpenseResult({
    required this.success,
    required this.message,
    required this.totalAmount,
    required this.count,
  });

  factory LockerBulkExpenseResult.fromJson(Map<String, dynamic> json) {
    final items = json['expenses'] ?? json['items'] ?? json['submitted'];
    final count = items is List
        ? items.length
        : (json['count'] as num?)?.toInt() ?? 0;
    return LockerBulkExpenseResult(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      totalAmount: _parseDepositAmount(json['totalAmount']),
      count: count,
    );
  }
}
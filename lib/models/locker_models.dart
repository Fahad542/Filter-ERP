// ── NOTE: translatedBranchName, translatedOfficerName, translatedCashierName
// are nullable fields populated at runtime by the ViewModel via TranslatableMixin.
// They default to null (no translation) so the view falls back to the raw API value.

enum LockerStatus {
  pending,
  assigned,
  collected,
  awaitingApproval,
  approved,
  rejected
}

class LockerRequest {
  final String id;
  final String referenceCode;
  final String branchName;
  final String cashierName;
  final DateTime closingDate;
  final double lockedCashAmount;
  final LockerStatus status;
  final String? assignedOfficerId;
  final String? assignedOfficerName;

  // ── Translation fields (set by ViewModel after API translation) ──
  final String? translatedBranchName;
  final String? translatedCashierName;
  final String? translatedOfficerName;

  LockerRequest({
    required this.id,
    required this.referenceCode,
    required this.branchName,
    required this.cashierName,
    required this.closingDate,
    required this.lockedCashAmount,
    this.status = LockerStatus.pending,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.translatedBranchName,
    this.translatedCashierName,
    this.translatedOfficerName,
  });

  factory LockerRequest.fromJson(Map<String, dynamic> json) {
    return LockerRequest(
      id               : json['id']?.toString() ?? '',
      referenceCode    : json['referenceCode']   as String? ?? 'LCK-${json['id']}',
      branchName       : json['branchName']      as String? ?? '',
      cashierName      : json['cashierName']     as String? ?? '',
      lockedCashAmount : _parseDouble(json['expectedAmount']),
      closingDate      : DateTime.tryParse(
        json['shiftCloseAt'] as String? ?? '',
      ) ?? DateTime.now(),
      status           : _parseStatus(json['requestStatus'] as String? ?? ''),
      assignedOfficerId  : json['assignedOfficerId']?.toString(),
      assignedOfficerName: json['assignedOfficerName'] as String?,
    );
  }

  LockerRequest copyWith({
    LockerStatus? status,
    String? assignedOfficerId,
    String? assignedOfficerName,
    String? translatedBranchName,
    String? translatedCashierName,
    String? translatedOfficerName,
  }) {
    return LockerRequest(
      id                   : id,
      referenceCode        : referenceCode,
      branchName           : branchName,
      cashierName          : cashierName,
      closingDate          : closingDate,
      lockedCashAmount     : lockedCashAmount,
      status               : status              ?? this.status,
      assignedOfficerId    : assignedOfficerId   ?? this.assignedOfficerId,
      assignedOfficerName  : assignedOfficerName ?? this.assignedOfficerName,
      translatedBranchName : translatedBranchName ?? this.translatedBranchName,
      translatedCashierName: translatedCashierName ?? this.translatedCashierName,
      translatedOfficerName: translatedOfficerName ?? this.translatedOfficerName,
    );
  }
}

// ─── Rich detail model (single-request endpoint) ─────────────────────────────

class LockerPosSession {
  final String id;
  final DateTime openedAt;
  final DateTime closedAt;
  final String status;

  const LockerPosSession({
    required this.id,
    required this.openedAt,
    required this.closedAt,
    required this.status,
  });

  factory LockerPosSession.fromJson(Map<String, dynamic> json) {
    return LockerPosSession(
      id      : json['id']?.toString() ?? '',
      openedAt: DateTime.tryParse(json['openedAt'] as String? ?? '') ?? DateTime.now(),
      closedAt: DateTime.tryParse(json['closedAt'] as String? ?? '') ?? DateTime.now(),
      status  : json['status'] as String? ?? '',
    );
  }
}

/// One payment-method breakdown row (e.g. the `cash`, `bank`, `tabby`,
/// `tamara`, or `corporate` object nested inside `counterClosing`).
class LockerPaymentBreakdown {
  final double physical;
  final double system;
  final double diff;

  const LockerPaymentBreakdown({
    required this.physical,
    required this.system,
    required this.diff,
  });

  factory LockerPaymentBreakdown.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LockerPaymentBreakdown(physical: 0, system: 0, diff: 0);
    }
    return LockerPaymentBreakdown(
      physical: _parseDouble(json['physical']),
      system  : _parseDouble(json['system']),
      diff    : _parseDouble(json['diff']),
    );
  }
}

class LockerCounterClosing {
  final String id;

  // ── Flat/legacy cash fields (top-level on counterClosing) ──────────────────
  final double cashDiff;
  final double systemCashTotal;
  final double physicalCash;

  // ── Flat fields for the other payment methods ───────────────────────────────
  final double bankDiff;
  final double systemBankTotal;
  final double physicalBank;
  final double corporateDiff;
  final double systemCorporateTotal;
  final double physicalCorporate;
  final double tamaraDiff;
  final double systemTamaraTotal;
  final double physicalTamara;
  final double tabbyDiff;
  final double systemTabbyTotal;
  final double physicalTabby;
  final double systemTotalSales;

  // ── Nested per-method breakdowns (cash/bank/tabby/tamara/corporate) ────────
  final LockerPaymentBreakdown cash;
  final LockerPaymentBreakdown bank;
  final LockerPaymentBreakdown tabby;
  final LockerPaymentBreakdown tamara;
  final LockerPaymentBreakdown corporate;

  const LockerCounterClosing({
    required this.id,
    required this.cashDiff,
    required this.systemCashTotal,
    required this.physicalCash,
    this.bankDiff = 0,
    this.systemBankTotal = 0,
    this.physicalBank = 0,
    this.corporateDiff = 0,
    this.systemCorporateTotal = 0,
    this.physicalCorporate = 0,
    this.tamaraDiff = 0,
    this.systemTamaraTotal = 0,
    this.physicalTamara = 0,
    this.tabbyDiff = 0,
    this.systemTabbyTotal = 0,
    this.physicalTabby = 0,
    this.systemTotalSales = 0,
    this.cash = const LockerPaymentBreakdown(physical: 0, system: 0, diff: 0),
    this.bank = const LockerPaymentBreakdown(physical: 0, system: 0, diff: 0),
    this.tabby = const LockerPaymentBreakdown(physical: 0, system: 0, diff: 0),
    this.tamara = const LockerPaymentBreakdown(physical: 0, system: 0, diff: 0),
    this.corporate = const LockerPaymentBreakdown(physical: 0, system: 0, diff: 0),
  });

  factory LockerCounterClosing.fromJson(Map<String, dynamic> json) {
    return LockerCounterClosing(
      id                   : json['id']?.toString() ?? '',
      cashDiff             : _parseDouble(json['cashDiff']),
      systemCashTotal      : _parseDouble(json['systemCashTotal']),
      physicalCash         : _parseDouble(json['physicalCash']),
      bankDiff             : _parseDouble(json['bankDiff']),
      systemBankTotal      : _parseDouble(json['systemBankTotal']),
      physicalBank         : _parseDouble(json['physicalBank']),
      corporateDiff        : _parseDouble(json['corporateDiff']),
      systemCorporateTotal : _parseDouble(json['systemCorporateTotal']),
      physicalCorporate    : _parseDouble(json['physicalCorporate']),
      tamaraDiff           : _parseDouble(json['tamaraDiff']),
      systemTamaraTotal    : _parseDouble(json['systemTamaraTotal']),
      physicalTamara       : _parseDouble(json['physicalTamara']),
      tabbyDiff            : _parseDouble(json['tabbyDiff']),
      systemTabbyTotal     : _parseDouble(json['systemTabbyTotal']),
      physicalTabby        : _parseDouble(json['physicalTabby']),
      systemTotalSales     : _parseDouble(json['systemTotalSales']),
      cash     : LockerPaymentBreakdown.fromJson(json['cash'] as Map<String, dynamic>?),
      bank     : LockerPaymentBreakdown.fromJson(json['bank'] as Map<String, dynamic>?),
      tabby    : LockerPaymentBreakdown.fromJson(json['tabby'] as Map<String, dynamic>?),
      tamara   : LockerPaymentBreakdown.fromJson(json['tamara'] as Map<String, dynamic>?),
      corporate: LockerPaymentBreakdown.fromJson(json['corporate'] as Map<String, dynamic>?),
    );
  }
}

class LockerRequestDetail {
  final String id;
  final String referenceCode;
  final LockerStatus status;
  final String uiStatus;
  final double totalSecuredAsset;
  final String currency;

  final String branchId;
  final String branchName;
  final String cashierId;
  final String cashierName;
  final DateTime shiftCloseTime;
  final LockerPosSession? posSession;
  final LockerCounterClosing? counterClosing;

  final String? assignedOfficerId;
  final String? assignedOfficerName;

  final LockerCollection? collection;

  // ── Translation fields ────────────────────────────────────────────────────
  final String? translatedBranchName;
  final String? translatedCashierName;
  final String? translatedOfficerName;

  const LockerRequestDetail({
    required this.id,
    required this.referenceCode,
    required this.status,
    required this.uiStatus,
    required this.totalSecuredAsset,
    required this.currency,
    required this.branchId,
    required this.branchName,
    required this.cashierId,
    required this.cashierName,
    required this.shiftCloseTime,
    this.posSession,
    this.counterClosing,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.collection,
    this.translatedBranchName,
    this.translatedCashierName,
    this.translatedOfficerName,
  });

  factory LockerRequestDetail.fromJson(Map<String, dynamic> json) {
    final branch  = json['branch']  as Map<String, dynamic>? ?? {};
    final cashier = json['cashier'] as Map<String, dynamic>? ?? {};
    final officer = json['assignedOfficer'] as Map<String, dynamic>?;

    return LockerRequestDetail(
      id                 : json['id']?.toString() ?? '',
      referenceCode      : json['referenceCode'] as String? ?? '',
      status             : _parseStatus(json['systemStatus'] as String? ?? ''),
      uiStatus           : json['uiStatus'] as String? ?? '',
      totalSecuredAsset  : _parseDouble(json['totalSecuredAsset']),
      currency           : json['currency'] as String? ?? 'SAR',
      branchId           : branch['id']?.toString() ?? '',
      branchName         : branch['name'] as String? ?? '',
      cashierId          : cashier['id']?.toString() ?? '',
      cashierName        : cashier['name'] as String? ?? '',
      shiftCloseTime     : DateTime.tryParse(
        json['shiftCloseTime'] as String? ?? '',
      ) ?? DateTime.now(),
      posSession: json['posSession'] != null
          ? LockerPosSession.fromJson(json['posSession'] as Map<String, dynamic>)
          : null,
      counterClosing: json['counterClosing'] != null
          ? LockerCounterClosing.fromJson(json['counterClosing'] as Map<String, dynamic>)
          : null,
      assignedOfficerId  : officer?['id']?.toString(),
      assignedOfficerName: officer?['name'] as String?,
      collection: json['collection'] != null
          ? LockerCollection.fromJson(json['collection'] as Map<String, dynamic>)
          : null,
    );
  }

  LockerRequestDetail copyWithAssignment({
    required String officerId,
    required String officerName,
  }) {
    return LockerRequestDetail(
      id                 : id,
      referenceCode      : referenceCode,
      status             : LockerStatus.assigned,
      uiStatus           : 'ASSIGNED',
      totalSecuredAsset  : totalSecuredAsset,
      currency           : currency,
      branchId           : branchId,
      branchName         : branchName,
      cashierId          : cashierId,
      cashierName        : cashierName,
      shiftCloseTime     : shiftCloseTime,
      posSession         : posSession,
      counterClosing     : counterClosing,
      assignedOfficerId  : officerId,
      assignedOfficerName: officerName,
      collection         : collection,
    );
  }

  LockerRequestDetail copyWithCollection(LockerCollection newCollection) {
    return LockerRequestDetail(
      id                 : id,
      referenceCode      : referenceCode,
      status             : LockerStatus.collected,
      uiStatus           : 'COLLECTED',
      totalSecuredAsset  : totalSecuredAsset,
      currency           : currency,
      branchId           : branchId,
      branchName         : branchName,
      cashierId          : cashierId,
      cashierName        : cashierName,
      shiftCloseTime     : shiftCloseTime,
      posSession         : posSession,
      counterClosing     : counterClosing,
      assignedOfficerId  : assignedOfficerId,
      assignedOfficerName: assignedOfficerName,
      collection         : newCollection,
    );
  }
}

// ─── Status parser ───────────────────────────────────────────────────────────

LockerStatus _parseStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'pending':           return LockerStatus.pending;
    case 'assigned':          return LockerStatus.assigned;
    case 'collected':         return LockerStatus.collected;
    case 'awaiting_approval':
    case 'pending_approval':  return LockerStatus.awaitingApproval;
    case 'approved':          return LockerStatus.approved;
    case 'rejected':          return LockerStatus.rejected;
    default:                  return LockerStatus.pending;
  }
}

// ─── Paginated requests response ─────────────────────────────────────────────

class LockerRequestsPage {
  final bool success;
  final int page;
  final int limit;
  final int total;
  final List<LockerRequest> items;

  const LockerRequestsPage({
    required this.success,
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  factory LockerRequestsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return LockerRequestsPage(
      success: json['success'] as bool? ?? false,
      page   : json['page']    as int?  ?? 1,
      limit  : json['limit']   as int?  ?? 20,
      total  : json['total']   as int?  ?? 0,
      items  : rawItems
          .map((e) => LockerRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Collection record ───────────────────────────────────────────────────────

class LockerCollection {
  final String id;
  final String requestId;
  final String officerId;
  final double receivedAmount;
  final DateTime collectionDate;
  final double difference;
  final String? proofUrl;
  final String? notes;

  LockerCollection({
    required this.id,
    required this.requestId,
    required this.officerId,
    required this.receivedAmount,
    required this.collectionDate,
    required this.difference,
    this.proofUrl,
    this.notes,
  });

  factory LockerCollection.fromJson(Map<String, dynamic> json) {
    return LockerCollection(
      id             : json['id']?.toString() ?? '',
      requestId      : json['requestId']?.toString() ?? '',
      officerId      : json['officerId']?.toString() ?? '',
      receivedAmount : _parseDouble(json['receivedAmount']),
      collectionDate : DateTime.tryParse(
        json['collectedAt'] as String? ?? '',
      ) ?? DateTime.now(),
      difference     : _parseDouble(json['difference']),
      proofUrl       : json['proofUrl']  as String?,
      notes          : json['notes']     as String?,
    );
  }
}

// ─── Record-collection API response ──────────────────────────────────────────

class CollectionResult {
  final bool success;
  final String message;
  final String collectionId;
  final double receivedAmount;
  final double difference;
  final String collectionStatus;

  const CollectionResult({
    required this.success,
    required this.message,
    required this.collectionId,
    required this.receivedAmount,
    required this.difference,
    required this.collectionStatus,
  });

  factory CollectionResult.fromJson(Map<String, dynamic> json) {
    final col = json['collection'] as Map<String, dynamic>? ?? {};
    return CollectionResult(
      success          : json['success'] as bool? ?? false,
      message          : json['message'] as String? ?? '',
      collectionId     : col['id']?.toString() ?? '',
      receivedAmount   : _parseDouble(col['receivedAmount']),
      difference       : _parseDouble(col['difference']),
      collectionStatus : col['status'] as String? ?? '',
    );
  }

  bool get hasDifference => difference.abs() > 0;
  bool get isPendingApproval => collectionStatus == 'pending_approval';
}

// ─── Officer ─────────────────────────────────────────────────────────────────

class LockerOfficer {
  final String id;
  final String displayCode;
  final String name;
  final String email;
  final String? mobile;
  final String userType;

  // ── Translation field ─────────────────────────────────────────────────────
  final String? translatedName;

  const LockerOfficer({
    required this.id,
    required this.displayCode,
    required this.name,
    required this.email,
    this.mobile,
    required this.userType,
    this.translatedName,
  });

  factory LockerOfficer.fromJson(Map<String, dynamic> json) {
    return LockerOfficer(
      id         : json['id']?.toString() ?? '',
      displayCode: json['displayCode'] as String? ?? '',
      name       : json['name'] as String? ?? '',
      email      : json['email'] as String? ?? '',
      mobile     : json['mobile'] as String?,
      userType   : json['userType'] as String? ?? '',
    );
  }
}

// ─── Dashboard API Models ────────────────────────────────────────────────────

class LockerSupervisorStats {
  final int pending;
  final int awaiting;
  final int overdue;
  final double varianceAmount;

  const LockerSupervisorStats({
    required this.pending,
    required this.awaiting,
    required this.overdue,
    required this.varianceAmount,
  });

  factory LockerSupervisorStats.fromJson(Map<String, dynamic> json) {
    return LockerSupervisorStats(
      pending       : _parseInt(json['pending']),
      awaiting      : _parseInt(json['awaiting']),
      overdue       : _parseInt(json['overdue']),
      varianceAmount: _parseDouble(json['varianceAmount']),
    );
  }

  factory LockerSupervisorStats.empty() => const LockerSupervisorStats(
    pending: 0, awaiting: 0, overdue: 0, varianceAmount: 0,
  );
}

class LockerCollectorStats {
  final int myOpenAssignments;

  const LockerCollectorStats({required this.myOpenAssignments});

  factory LockerCollectorStats.fromJson(Map<String, dynamic> json) {
    return LockerCollectorStats(
      myOpenAssignments: _parseInt(json['myOpenAssignments']),
    );
  }

  factory LockerCollectorStats.empty() =>
      const LockerCollectorStats(myOpenAssignments: 0);
}

class LockerPendingCollections {
  final int total;
  final int overdue;

  const LockerPendingCollections({required this.total, required this.overdue});

  factory LockerPendingCollections.fromJson(Map<String, dynamic> json) {
    return LockerPendingCollections(
      total  : _parseInt(json['total']),
      overdue: _parseInt(json['overdue']),
    );
  }

  factory LockerPendingCollections.empty() =>
      const LockerPendingCollections(total: 0, overdue: 0);
}

class LockerTodaysCollections {
  final int requestCount;

  const LockerTodaysCollections({required this.requestCount});

  factory LockerTodaysCollections.fromJson(Map<String, dynamic> json) {
    return LockerTodaysCollections(
      requestCount: _parseInt(json['requestCount']),
    );
  }

  factory LockerTodaysCollections.empty() =>
      const LockerTodaysCollections(requestCount: 0);
}

class LockerDashboardData {
  final bool success;
  final String view;
  final LockerSupervisorStats supervisor;
  final LockerCollectorStats collector;
  final LockerPendingCollections pendingCollections;
  final LockerTodaysCollections todaysCollections;
  final double monthlyCollected;
  final int pendingApprovals;
  /// Locker vault balance from the dashboard API (`lockerVaultBalance`).
  final double lockerVaultBalance;

  const LockerDashboardData({
    required this.success,
    required this.view,
    required this.supervisor,
    required this.collector,
    required this.pendingCollections,
    required this.todaysCollections,
    required this.monthlyCollected,
    required this.pendingApprovals,
    this.lockerVaultBalance = 0.0,
  });

  factory LockerDashboardData.fromJson(Map<String, dynamic> json) {
    return LockerDashboardData(
      success: json['success'] as bool? ?? false,
      view   : json['view']?.toString() ?? 'supervisor',
      supervisor: json['supervisor'] != null
          ? LockerSupervisorStats.fromJson(
          json['supervisor'] as Map<String, dynamic>)
          : LockerSupervisorStats.empty(),
      collector: json['collector'] != null
          ? LockerCollectorStats.fromJson(
          json['collector'] as Map<String, dynamic>)
          : LockerCollectorStats.empty(),
      pendingCollections: json['pendingCollections'] != null
          ? LockerPendingCollections.fromJson(
          json['pendingCollections'] as Map<String, dynamic>)
          : LockerPendingCollections.empty(),
      todaysCollections: json['todaysCollections'] != null
          ? LockerTodaysCollections.fromJson(
          json['todaysCollections'] as Map<String, dynamic>)
          : LockerTodaysCollections.empty(),
      monthlyCollected  : _parseDouble(json['monthlyCollected']),
      pendingApprovals  : _parseInt(json['pendingApprovals']),
      lockerVaultBalance: _parseDouble(json['lockerVaultBalance']),
    );
  }
}

// ── Financial-history item (GET /locker/financial/history) ────────────────────

/// Match status values returned by the API.
enum LockerMatchStatus { matched, pendingApproval, unknown }

LockerMatchStatus _parseMatchStatus(String raw) {
  switch (raw.toUpperCase()) {
    case 'MATCHED':
      return LockerMatchStatus.matched;
    case 'PENDING_APPROVAL':
      return LockerMatchStatus.pendingApproval;
    default:
      return LockerMatchStatus.unknown;
  }
}

class LockerHistoryItem {
  final String id;
  final String collectionId;
  final String referenceCode;
  final String transactionRef;
  final LockerMatchStatus matchStatus;
  /// Raw collection-status string (e.g. "approved", "pending_approval").
  final String collectionStatus;
  final double receivedAmount;
  final double expectedAmount;
  final double difference;
  final String currency;
  final String branchName;
  final String cashierName;
  final String cashierId;
  final String officerName;
  final String officerId;
  final DateTime collectedAt;

  const LockerHistoryItem({
    required this.id,
    required this.collectionId,
    required this.referenceCode,
    required this.transactionRef,
    required this.matchStatus,
    required this.collectionStatus,
    required this.receivedAmount,
    required this.expectedAmount,
    required this.difference,
    required this.currency,
    required this.branchName,
    required this.cashierName,
    required this.cashierId,
    required this.officerName,
    required this.officerId,
    required this.collectedAt,
  });

  factory LockerHistoryItem.fromJson(Map<String, dynamic> json) {
    return LockerHistoryItem(
      id              : json['id']?.toString() ?? '',
      collectionId    : json['collectionId']?.toString() ?? '',
      referenceCode   : json['referenceCode']   as String? ??
          json['requestReference'] as String? ?? '',
      transactionRef  : json['transactionRef']  as String? ?? '',
      matchStatus     : _parseMatchStatus(json['matchStatus'] as String? ?? ''),
      collectionStatus: json['collectionStatus'] as String? ??
          json['status'] as String? ?? '',
      receivedAmount  : _parseDouble(json['receivedAmount'] ?? json['receivedFund']),
      expectedAmount  : _parseDouble(json['expectedAmount']),
      difference      : _parseDouble(json['difference']),
      currency        : json['currency'] as String? ?? 'SAR',
      branchName      : json['branchName']  as String? ?? '',
      cashierName     : json['cashierName'] as String? ?? '',
      cashierId       : json['cashierId']?.toString() ?? '',
      officerName     : json['officerName'] as String? ?? '',
      officerId       : json['officerId']?.toString() ?? '',
      collectedAt     : DateTime.tryParse(json['collectedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  bool get isMatched        => matchStatus == LockerMatchStatus.matched;
  bool get isPendingApproval => matchStatus == LockerMatchStatus.pendingApproval;
  bool get hasVariance      => difference.abs() > 0;
}

class LockerHistoryPage {
  final bool success;
  final int page;
  final int limit;
  final int total;
  final List<LockerHistoryItem> items;

  const LockerHistoryPage({
    required this.success,
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  factory LockerHistoryPage.fromJson(Map<String, dynamic> json) {
    // API may return items under "items" or "auditLogs"
    final rawItems =
        (json['items'] ?? json['auditLogs'] ?? json['data']) as List<dynamic>? ?? [];
    return LockerHistoryPage(
      success: json['success'] as bool? ?? false,
      page   : _parseInt(json['page']),
      limit  : _parseInt(json['limit']),
      total  : _parseInt(json['total']),
      items  : rawItems
          .map((e) => LockerHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory LockerHistoryPage.empty() => const LockerHistoryPage(
    success: false, page: 1, limit: 5, total: 0, items: [],
  );
}

// ── Locker Notification Model ─────────────────────────────────────────────────

enum LockerNotificationType {
  newRequest,
  status,
  warning,
  unknown,
}

class LockerNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final LockerNotificationType type;
  final bool isUnread;

  // ── Translation fields ────────────────────────────────────────────────────
  final String? translatedTitle;
  final String? translatedBody;

  const LockerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.isUnread,
    this.translatedTitle,
    this.translatedBody,
  });

  factory LockerNotification.fromJson(Map<String, dynamic> json) {
    final bool isUnread;
    if (json.containsKey('readAt')) {
      isUnread = json['readAt'] == null;
    } else if (json.containsKey('isUnread')) {
      isUnread = json['isUnread'] as bool? ?? false;
    } else {
      isUnread = json['read'] == false;
    }

    return LockerNotification(
      id      : json['id']?.toString() ?? '',
      title   : json['title']   as String? ?? '',
      body    : json['body']    as String? ?? json['message'] as String? ?? '',
      time    : DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.tryParse(json['time']      as String? ?? '') ??
          DateTime.now(),
      type    : _parseType(json['type'] as String? ?? ''),
      isUnread: isUnread,
    );
  }

  LockerNotification markRead() => LockerNotification(
    id      : id,
    title   : title,
    body    : body,
    time    : time,
    type    : type,
    isUnread: false,
    translatedTitle: translatedTitle,
    translatedBody : translatedBody,
  );
}

class LockerNotificationsPage {
  final int page;
  final int limit;
  final int total;
  final int unreadCount;
  final List<LockerNotification> items;

  const LockerNotificationsPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.unreadCount,
    required this.items,
  });

  factory LockerNotificationsPage.fromJson(Map<String, dynamic> json) {
    final rawList =
        (json['items'] ?? json['notifications'] ?? json['data'])
        as List<dynamic>? ?? [];

    final items = rawList
        .map((e) => LockerNotification.fromJson(e as Map<String, dynamic>))
        .toList();

    final unreadCount = json.containsKey('unreadCount')
        ? _parseInt(json['unreadCount'])
        : items.where((n) => n.isUnread).length;

    return LockerNotificationsPage(
      page       : _parseInt(json['page']),
      limit      : _parseInt(json['limit']),
      total      : _parseInt(json['total']),
      unreadCount: unreadCount,
      items      : items,
    );
  }

  factory LockerNotificationsPage.empty() => const LockerNotificationsPage(
    page: 1, limit: 20, total: 0, unreadCount: 0, items: [],
  );
}

// ── Parse helpers ─────────────────────────────────────────────────────────────

LockerNotificationType _parseType(String raw) {
  switch (raw) {
    case 'locker_demo_collection_new':
    case 'locker_collection_new':
      return LockerNotificationType.newRequest;

    case 'locker_demo_variance_review':
    case 'locker_variance_review':
    case 'locker_demo_overdue_reminder':
    case 'locker_overdue_reminder':
      return LockerNotificationType.warning;

    case 'locker_demo_status_update':
    case 'locker_status_update':
      return LockerNotificationType.status;
  }

  final lower = raw.toLowerCase();
  if (lower.contains('new') || lower.contains('collection')) {
    return LockerNotificationType.newRequest;
  }
  if (lower.contains('variance') || lower.contains('overdue') ||
      lower.contains('warning') || lower.contains('reminder')) {
    return LockerNotificationType.warning;
  }
  if (lower.contains('status') || lower.contains('update') ||
      lower.contains('approved') || lower.contains('rejected')) {
    return LockerNotificationType.status;
  }
  return LockerNotificationType.unknown;
}

// ─── Branch list & variance approvals (reports / supervisor workflows) ─────

class LockerBranch {
  final String id;
  final String name;

  const LockerBranch({required this.id, required this.name});

  factory LockerBranch.fromJson(Map<String, dynamic> json) {
    return LockerBranch(
      id  : json['id']?.toString() ?? '',
      name: json['name'] as String? ??
          json['branchName'] as String? ??
          '',
    );
  }
}

/// One pending variance row from GET /locker/approvals (shape may vary slightly).
class LockerVarianceApproval {
  final String id;
  final bool isShort;
  final double difference;
  final String branchName;
  final DateTime date;
  final String cashierName;
  final String officerName;
  final double expectedAmount;
  final double receivedAmount;
  final String notes;

  const LockerVarianceApproval({
    required this.id,
    required this.isShort,
    required this.difference,
    required this.branchName,
    required this.date,
    required this.cashierName,
    required this.officerName,
    required this.expectedAmount,
    required this.receivedAmount,
    required this.notes,
  });

  factory LockerVarianceApproval.fromJson(Map<String, dynamic> json) {
    final expected = _parseDouble(json['expectedAmount'] ?? json['expected']);
    final received = _parseDouble(json['receivedAmount'] ?? json['received']);
    final rawDiff = json['difference'];
    final difference = rawDiff != null
        ? _parseDouble(rawDiff)
        : (received - expected);

    final match = (json['matchStatus'] as String? ?? '').toUpperCase();
    final bool isShort;
    switch (match) {
      case 'SHORT':
        isShort = true;
        break;
      case 'OVER':
        isShort = false;
        break;
      default:
        isShort = expected > received;
    }

    return LockerVarianceApproval(
      id            : json['collectionId']?.toString() ?? json['id']?.toString() ?? '',
      isShort       : isShort,
      difference    : difference,
      branchName    : json['branchName'] as String? ?? '',
      date          : DateTime.tryParse(json['collectedAt'] as String? ?? '') ??
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      cashierName   : json['cashierName'] as String? ?? '',
      officerName   : json['officerName'] as String? ?? '',
      expectedAmount: expected,
      receivedAmount: received,
      notes         : json['notes'] as String? ?? '',
    );
  }
}

/// Cashier fund replenishment row from GET /locker/petty-cash/fund-requests.
class LockerFundRequest {
  final String id;
  final double amount;
  final String status;
  final String? description;
  final String? rejectionReason;
  final DateTime createdAt;
  final String cashierName;
  final String branchName;

  const LockerFundRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.cashierName,
    required this.branchName,
    this.description,
    this.rejectionReason,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  factory LockerFundRequest.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'];
    final branch = json['branch'];
    return LockerFundRequest(
      id: json['id']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      description: json['description']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      cashierName: cashier is Map
          ? (cashier['name']?.toString() ?? '')
          : (json['cashierName']?.toString() ?? ''),
      branchName: branch is Map
          ? (branch['name']?.toString() ?? '')
          : (json['branchName']?.toString() ?? ''),
    );
  }
}

// ─── Locker Management Overview ──────────────────────────────────────────────
//  GET /workshop-staff/locker-management/overview

class LockerOverviewKpis {
  final int pendingRequests;
  final int assignedRequests;
  final int overdueRequests;
  final int pendingApprovals;
  final int collectionsToday;
  final double monthlyCollected;
  final double openShiftVariance;
  final double lockerVaultBalance;

  const LockerOverviewKpis({
    required this.pendingRequests,
    required this.assignedRequests,
    required this.overdueRequests,
    required this.pendingApprovals,
    required this.collectionsToday,
    required this.monthlyCollected,
    required this.openShiftVariance,
    required this.lockerVaultBalance,
  });

  factory LockerOverviewKpis.fromJson(Map<String, dynamic> json) {
    return LockerOverviewKpis(
      pendingRequests   : _parseInt(json['pendingRequests']),
      assignedRequests  : _parseInt(json['assignedRequests']),
      overdueRequests   : _parseInt(json['overdueRequests']),
      pendingApprovals  : _parseInt(json['pendingApprovals']),
      collectionsToday  : _parseInt(json['collectionsToday']),
      monthlyCollected  : _parseDouble(json['monthlyCollected']),
      openShiftVariance : _parseDouble(json['openShiftVariance']),
      lockerVaultBalance: _parseDouble(json['lockerVaultBalance']),
    );
  }

  factory LockerOverviewKpis.empty() => const LockerOverviewKpis(
    pendingRequests: 0, assignedRequests: 0, overdueRequests: 0,
    pendingApprovals: 0, collectionsToday: 0,
    monthlyCollected: 0, openShiftVariance: 0, lockerVaultBalance: 0,
  );
}

/// One entry from `recentBankDeposits` in the overview response.
class LockerOverviewDeposit {
  final String id;
  final String reference;
  final String registerName;
  final String branchName;
  final double amount;
  final String currency;
  final DateTime depositedAt;

  const LockerOverviewDeposit({
    required this.id,
    required this.reference,
    required this.registerName,
    required this.branchName,
    required this.amount,
    required this.currency,
    required this.depositedAt,
  });

  factory LockerOverviewDeposit.fromJson(Map<String, dynamic> json) {
    return LockerOverviewDeposit(
      id          : json['id']?.toString() ?? '',
      reference   : json['reference']    as String? ??
          json['referenceCode'] as String? ?? '',
      registerName: json['registerName'] as String? ??
          json['bankName']     as String? ?? '',
      branchName  : json['branchName']   as String? ?? '',
      amount      : _parseDouble(json['amount'] ?? json['depositedAmount']),
      currency    : json['currency']     as String? ?? 'SAR',
      depositedAt : DateTime.tryParse(
        json['depositedAt'] as String? ??
            json['createdAt']   as String? ?? '',
      ) ?? DateTime.now(),
    );
  }
}

class LockerOverviewData {
  final bool success;
  final LockerOverviewKpis kpis;
  final List<LockerOverviewDeposit> recentBankDeposits;

  const LockerOverviewData({
    required this.success,
    required this.kpis,
    required this.recentBankDeposits,
  });

  factory LockerOverviewData.fromJson(Map<String, dynamic> json) {
    final rawDeposits =
        (json['recentBankDeposits']) as List<dynamic>? ?? [];
    return LockerOverviewData(
      success: json['success'] as bool? ?? false,
      kpis: json['kpis'] != null
          ? LockerOverviewKpis.fromJson(json['kpis'] as Map<String, dynamic>)
          : LockerOverviewKpis.empty(),
      recentBankDeposits: rawDeposits
          .map((e) =>
          LockerOverviewDeposit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory LockerOverviewData.empty() => LockerOverviewData(
    success: false,
    kpis: LockerOverviewKpis.empty(),
    recentBankDeposits: const [],
  );
}

// ─── Shared parse helpers ────────────────────────────────────────────────────

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  return double.tryParse(value.toString()) ?? 0.0;
}

/// Models for the standalone "Collections History" screen.
///
/// Backed by the existing `GET /locker/financial/history` endpoint — the
/// exact same data source as `locker_reports_view.dart`'s History tab — but
/// this screen additionally surfaces the `summary` block the API already
/// returns (`totalExpected`, `totalReceived`, `totalDifference`, `overCount`,
/// `shortCount`, `matchedCount`, `overAmount`, `shortAmount`, `currency`),
/// which the existing `AuditLogPage`/`AuditLogEntry` models (in
/// `locker_financial_models.dart`) do not parse.
///
/// Sample response shape this file parses:
/// ```json
/// {
///   "success": true,
///   "page": 1,
///   "limit": 100,
///   "total": 81,
///   "summary": {
///     "totalExpected": "52168.25",
///     "totalReceived": "29010.75",
///     "totalDifference": "-23157.50",
///     "overCount": 5,
///     "shortCount": 21,
///     "matchedCount": 55,
///     "overAmount": "292.50",
///     "shortAmount": "23450.00",
///     "currency": "SAR"
///   },
///   "items": [ { "id": "83", "referenceCode": "CCR-B6-CC241", ... } ]
/// }
/// ```

double _parseAmount(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}



DateTime _parseDate(dynamic v) {
  if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString())?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

// ── Summary (KPI cards) ──────────────────────────────────────────────────────

/// The `summary` block — drives the Expected / Received / Differences KPI
/// cards plus the Over/Short/Matched mini-stats and quick-filter chip counts.
class CollectionHistorySummary {
  final double totalExpected;
  final double totalReceived;
  final double totalDifference;
  final int overCount;
  final int shortCount;
  final int matchedCount;
  final double overAmount;
  final double shortAmount;
  final String currency;

  const CollectionHistorySummary({
    required this.totalExpected,
    required this.totalReceived,
    required this.totalDifference,
    required this.overCount,
    required this.shortCount,
    required this.matchedCount,
    required this.overAmount,
    required this.shortAmount,
    required this.currency,
  });

  factory CollectionHistorySummary.empty({String currency = 'SAR'}) =>
      CollectionHistorySummary(
        totalExpected: 0,
        totalReceived: 0,
        totalDifference: 0,
        overCount: 0,
        shortCount: 0,
        matchedCount: 0,
        overAmount: 0,
        shortAmount: 0,
        currency: currency,
      );

  factory CollectionHistorySummary.fromJson(Map<String, dynamic> json) {
    return CollectionHistorySummary(
      totalExpected: _parseAmount(json['totalExpected']),
      totalReceived: _parseAmount(json['totalReceived']),
      totalDifference: _parseAmount(json['totalDifference']),
      overCount: _parseInt(json['overCount']),
      shortCount: _parseInt(json['shortCount']),
      matchedCount: _parseInt(json['matchedCount']),
      overAmount: _parseAmount(json['overAmount']),
      shortAmount: _parseAmount(json['shortAmount']),
      currency: json['currency'] as String? ?? 'SAR',
    );
  }
}

// ── Entry (list / card rows) ─────────────────────────────────────────────────

/// One row from `items[]` — a single cash-collection record.
class CollectionHistoryEntry {
  final String id;
  final String collectionId;
  final String referenceCode;
  final String requestReference;
  final String transactionRef;
  final String matchStatus; // MATCHED | OVER | SHORT | PENDING_APPROVAL
  final String status;
  final String collectionStatus;
  final double receivedAmount;
  final double receivedFund;
  final double expectedAmount;
  final double difference;
  final String currency;
  final String branchName;
  final String cashierName;
  final String cashierId;
  final String officerName;
  final String officerId;
  final DateTime collectedAt;

  const CollectionHistoryEntry({
    required this.id,
    required this.collectionId,
    required this.referenceCode,
    required this.requestReference,
    required this.transactionRef,
    required this.matchStatus,
    required this.status,
    required this.collectionStatus,
    required this.receivedAmount,
    required this.receivedFund,
    required this.expectedAmount,
    required this.difference,
    required this.currency,
    required this.branchName,
    required this.cashierName,
    required this.cashierId,
    required this.officerName,
    required this.officerId,
    required this.collectedAt,
  });

  /// True for rows awaiting supervisor approval (no funds received yet).
  bool get isPendingApproval =>
      matchStatus == 'PENDING_APPROVAL' ||
          status == 'pending_approval' ||
          collectionStatus == 'pending_approval';

  factory CollectionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CollectionHistoryEntry(
      id: json['id']?.toString() ?? '',
      collectionId:
      json['collectionId']?.toString() ?? json['id']?.toString() ?? '',
      referenceCode: json['referenceCode'] as String? ??
          json['requestReference'] as String? ??
          json['requestRef'] as String? ??
          '',
      requestReference: json['requestReference'] as String? ??
          json['requestRef'] as String? ??
          '',
      transactionRef: json['transactionRef'] as String? ?? '',
      matchStatus:
      (json['matchStatus'] as String? ?? 'PENDING_APPROVAL').toUpperCase(),
      status: json['status'] as String? ?? '',
      collectionStatus: json['collectionStatus'] as String? ?? '',
      receivedAmount: _parseAmount(json['receivedAmount']),
      receivedFund: _parseAmount(json['receivedFund'] ?? json['receivedAmount']),
      expectedAmount: _parseAmount(json['expectedAmount']),
      difference: _parseAmount(json['difference']),
      currency: json['currency'] as String? ?? 'SAR',
      branchName: json['branchName'] as String? ?? '',
      cashierName: json['cashierName'] as String? ?? '',
      cashierId: json['cashierId']?.toString() ?? '',
      officerName: json['officerName'] as String? ?? '',
      officerId: json['officerId']?.toString() ?? '',
      collectedAt: _parseDate(json['collectedAt']),
    );
  }
}

// ── Page wrapper ──────────────────────────────────────────────────────────────

/// Full page response: pagination metadata + [CollectionHistorySummary] +
/// the list of [CollectionHistoryEntry].
class CollectionHistoryPage {
  final bool success;
  final int page;
  final int limit;
  final int total;
  final CollectionHistorySummary summary;
  final List<CollectionHistoryEntry> items;

  const CollectionHistoryPage({
    required this.success,
    required this.page,
    required this.limit,
    required this.total,
    required this.summary,
    required this.items,
  });

  factory CollectionHistoryPage.empty() => CollectionHistoryPage(
    success: true,
    page: 1,
    limit: 0,
    total: 0,
    summary: CollectionHistorySummary.empty(),
    items: const [],
  );

  factory CollectionHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final summaryJson = json['summary'];
    return CollectionHistoryPage(
      success: json['success'] as bool? ?? true,
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      total: _parseInt(json['total']),
      summary: summaryJson is Map<String, dynamic>
          ? CollectionHistorySummary.fromJson(summaryJson)
          : CollectionHistorySummary.empty(),
      items: rawItems is List
          ? rawItems
          .whereType<Map<String, dynamic>>()
          .map(CollectionHistoryEntry.fromJson)
          .toList()
          : const [],
    );
  }
}
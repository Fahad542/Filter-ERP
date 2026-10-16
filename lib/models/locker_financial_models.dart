// ── Locker Financial Models ───────────────────────────────────────────────────
// Covers both:
//   GET /locker/financial/history
//   GET /locker/financial/analytics

// ── History ───────────────────────────────────────────────────────────────────

/// One row returned by GET /locker/financial/history
class AuditLogEntry {
  final String collectionId;
  final String transactionRef;
  final String matchStatus;       // 'MATCHED' | 'OVER' | 'SHORT' | 'PENDING_APPROVAL'
  final String collectionStatus;  // 'approved' | 'pending_approval' etc.
  final double receivedFund;
  final double expectedAmount;
  final double difference;
  final String currency;
  final String branchName;
  final String requestRef;
  final String officerName;
  final DateTime collectedAt;

  const AuditLogEntry({
    required this.collectionId,
    required this.transactionRef,
    required this.matchStatus,
    required this.collectionStatus,
    required this.receivedFund,
    required this.expectedAmount,
    required this.difference,
    required this.currency,
    required this.branchName,
    required this.requestRef,
    required this.officerName,
    required this.collectedAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      collectionId    : json['collectionId']?.toString() ?? '',
      transactionRef  : json['transactionRef'] as String? ?? '',
      matchStatus     : json['matchStatus'] as String? ?? '',
      collectionStatus: json['collectionStatus'] as String? ?? '',
      receivedFund    : _parseDouble(json['receivedFund']),
      expectedAmount  : _parseDouble(json['expectedAmount']),
      difference      : _parseDouble(json['difference']),
      currency        : json['currency'] as String? ?? 'SAR',
      branchName      : json['branchName'] as String? ?? '',
      requestRef      : json['requestRef'] as String? ?? '',
      officerName     : json['officerName'] as String? ?? '',
      collectedAt     : DateTime.tryParse(
            json['collectedAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  /// Convenience label for UI chips.
  bool get isMatched         => matchStatus == 'MATCHED';
  bool get isOver            => matchStatus == 'OVER';
  bool get isShort           => matchStatus == 'SHORT';
  bool get isPendingApproval => matchStatus == 'PENDING_APPROVAL';
}

/// Paginated response from GET /locker/financial/history
class AuditLogPage {
  final int page;
  final int limit;
  final int total;
  final List<AuditLogEntry> items;

  const AuditLogPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.items,
  });

  factory AuditLogPage.fromJson(Map<String, dynamic> json) {
    final rawList = json['auditLogs'] as List<dynamic>? ?? [];
    return AuditLogPage(
      page  : _parseInt(json['page']),
      limit : _parseInt(json['limit']),
      total : _parseInt(json['total']),
      items : rawList
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Analytics ─────────────────────────────────────────────────────────────────

class AnalyticsRange {
  final DateTime from;
  final DateTime to;

  const AnalyticsRange({required this.from, required this.to});

  factory AnalyticsRange.fromJson(Map<String, dynamic> json) {
    return AnalyticsRange(
      from: DateTime.tryParse(json['from'] as String? ?? '') ?? DateTime.now(),
      to  : DateTime.tryParse(json['to']   as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DifferencesSummary {
  final double totalShort;
  final double totalOver;
  final double netDifference;
  final String currency;

  const DifferencesSummary({
    required this.totalShort,
    required this.totalOver,
    required this.netDifference,
    required this.currency,
  });

  factory DifferencesSummary.fromJson(Map<String, dynamic> json) {
    return DifferencesSummary(
      totalShort   : _parseDouble(json['totalShort']),
      totalOver    : _parseDouble(json['totalOver']),
      netDifference: _parseDouble(json['netDifference']),
      currency     : json['currency'] as String? ?? 'SAR',
    );
  }

  factory DifferencesSummary.zero() => const DifferencesSummary(
    totalShort: 0, totalOver: 0, netDifference: 0, currency: 'SAR',
  );
}

class WeeklyVolumeEntry {
  final String day;
  final double totalReceived;

  const WeeklyVolumeEntry({required this.day, required this.totalReceived});

  factory WeeklyVolumeEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyVolumeEntry(
      day          : json['day'] as String? ?? '',
      totalReceived: _parseDouble(json['totalReceived']),
    );
  }
}

class OfficerComplianceEntry {
  final String name;
  final double compliancePercent;
  final int collectionsCount;

  const OfficerComplianceEntry({
    required this.name,
    required this.compliancePercent,
    required this.collectionsCount,
  });

  factory OfficerComplianceEntry.fromJson(Map<String, dynamic> json) {
    return OfficerComplianceEntry(
      name             : json['name'] as String? ?? '',
      compliancePercent: _parseDouble(json['compliancePercent']),
      collectionsCount : _parseInt(json['collectionsCount']),
    );
  }
}

class LockerAnalyticsData {
  final AnalyticsRange range;
  final DifferencesSummary differencesSummary;
  final List<WeeklyVolumeEntry> weeklyCollectionVolume;
  final List<OfficerComplianceEntry> officerCompliance;

  const LockerAnalyticsData({
    required this.range,
    required this.differencesSummary,
    required this.weeklyCollectionVolume,
    required this.officerCompliance,
  });

  factory LockerAnalyticsData.fromJson(Map<String, dynamic> json) {
    return LockerAnalyticsData(
      range: json['range'] != null
          ? AnalyticsRange.fromJson(json['range'] as Map<String, dynamic>)
          : AnalyticsRange(from: DateTime.now(), to: DateTime.now()),
      differencesSummary: json['differencesSummary'] != null
          ? DifferencesSummary.fromJson(
              json['differencesSummary'] as Map<String, dynamic>)
          : DifferencesSummary.zero(),
      weeklyCollectionVolume: (json['weeklyCollectionVolume'] as List<dynamic>? ?? [])
          .map((e) => WeeklyVolumeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      officerCompliance: (json['officerCompliance'] as List<dynamic>? ?? [])
          .map((e) => OfficerComplianceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Parse helpers (private to this file) ─────────────────────────────────────

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

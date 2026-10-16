class DepartmentSalesRow {
  final String departmentId;
  final String departmentName;
  final int ordersCount;
  final double revenueSar;

  DepartmentSalesRow({
    required this.departmentId,
    required this.departmentName,
    required this.ordersCount,
    required this.revenueSar,
  });

  factory DepartmentSalesRow.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return DepartmentSalesRow(
      departmentId: json['departmentId']?.toString() ??
          json['department_id']?.toString() ??
          '',
      departmentName: json['departmentName']?.toString() ??
          json['department_name']?.toString() ??
          '—',
      ordersCount: json['ordersCount'] is int
          ? json['ordersCount'] as int
          : int.tryParse(
                json['ordersCount']?.toString() ??
                    json['orders_count']?.toString() ??
                    '',
              ) ??
              0,
      revenueSar: toD(json['revenueSar'] ?? json['revenue_sar']),
    );
  }
}

List<DepartmentSalesRow> parseDepartmentBreakdown(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => DepartmentSalesRow.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

class ClosingReturnItemRow {
  final String name;
  final double qty;
  final double amountSar;

  ClosingReturnItemRow({
    required this.name,
    required this.qty,
    required this.amountSar,
  });

  factory ClosingReturnItemRow.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return ClosingReturnItemRow(
      name: json['name']?.toString() ??
          json['itemName']?.toString() ??
          '—',
      qty: toD(json['qty'] ?? json['quantity']),
      amountSar: toD(json['amountSar'] ?? json['amount'] ?? json['lineTotal']),
    );
  }
}

List<ClosingReturnItemRow> parseClosingReturnItems(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => ClosingReturnItemRow.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

class ReconciliationBucket {
  /// Net-of-sales-returns system amount (used for [difference] vs physical).
  final double system;
  /// POS payment total for this bucket before sales-return scale-down (display).
  final double systemGross;
  final double physical;
  final double difference; // system - physical (positive = system > physical)

  ReconciliationBucket({
    required this.system,
    required this.systemGross,
    required this.physical,
    required this.difference,
  });

  factory ReconciliationBucket.fromJson(Map<String, dynamic> json) {
    final system = (json['system'] ?? 0).toDouble();
    return ReconciliationBucket(
      system: system,
      systemGross: (json['systemGross'] ?? system).toDouble(),
      physical: (json['physical'] ?? 0).toDouble(),
      difference: (json['difference'] ?? 0).toDouble(),
    );
  }
}

class StoreClosingReport {
  final String id;
  final DateTime timestamp;
  final String branch;
  final String workshopName;
  final String cashierName;

  // System totals (payments before returns scaledown; aligned with cashier counter-closing POST)
  final double grossSystemSales;
  final double salesReturnsTotal;
  /// Net headline after returns (= payment buckets net of returns; authoritative for reconciliation).
  final double systemSales;
  /// Per-bucket system amounts **after** sales-return allocation (matches DB / diff logic).
  final double systemCash;
  final double systemBank;
  final double systemCorporate;
  final double systemTamara;
  final double systemTabby;
  final double systemOthers;
  /// Same buckets **before** sales-return scale-down (shown in System column).
  final double systemCashGross;
  final double systemBankGross;
  final double systemCorporateGross;
  final double systemTamaraGross;
  final double systemTabbyGross;
  final double systemOthersGross;

  // Physical Counts
  final double physicalCash;
  final double physicalBank;
  final double physicalCorporate;
  final double physicalTamara;
  final double physicalTabby;
  final double physicalOthers;

  // API-provided differences (system - physical)
  final double? apiCashDiff;
  final double? apiBankDiff;
  final double? apiCorporateDiff;
  final double? apiTamaraDiff;
  final double? apiTabbyDiff;
  final double? apiOthersDiff;
  final double? apiTotalDifference;
  final DateTime? sessionOpenedAt;
  final DateTime? sessionClosedAt;
  final List<DepartmentSalesRow> departmentBreakdown;

  StoreClosingReport({
    required this.id,
    required this.timestamp,
    required this.branch,
    this.workshopName = '',
    required this.cashierName,
    required this.grossSystemSales,
    required this.salesReturnsTotal,
    required this.systemSales,
    required this.systemCash,
    required this.systemBank,
    required this.systemCorporate,
    required this.systemTamara,
    required this.systemTabby,
    required this.systemOthers,
    required this.systemCashGross,
    required this.systemBankGross,
    required this.systemCorporateGross,
    required this.systemTamaraGross,
    required this.systemTabbyGross,
    required this.systemOthersGross,
    required this.physicalCash,
    required this.physicalBank,
    required this.physicalCorporate,
    required this.physicalTamara,
    required this.physicalTabby,
    required this.physicalOthers,
    this.apiCashDiff,
    this.apiBankDiff,
    this.apiCorporateDiff,
    this.apiTamaraDiff,
    this.apiTabbyDiff,
    this.apiOthersDiff,
    this.apiTotalDifference,
    this.sessionOpenedAt,
    this.sessionClosedAt,
    this.departmentBreakdown = const [],
    this.commissionPercent = 0,
    this.commissionBaseSales = 0,
    this.commissionAmount = 0,
  });

  final double commissionPercent;
  final double commissionBaseSales;
  final double commissionAmount;

  // Uses API-provided diffs if available, otherwise calculates locally
  double get cashDiff => apiCashDiff ?? (systemCash - physicalCash);
  double get bankDiff => apiBankDiff ?? (systemBank - physicalBank);
  double get corporateDiff => apiCorporateDiff ?? (systemCorporate - physicalCorporate);
  double get tamaraDiff => apiTamaraDiff ?? (systemTamara - physicalTamara);
  double get tabbyDiff => apiTabbyDiff ?? (systemTabby - physicalTabby);
  double get othersDiff => apiOthersDiff ?? (systemOthers - physicalOthers);
  double get netDifference =>
      apiTotalDifference ??
      (cashDiff + bankDiff + corporateDiff + tamaraDiff + tabbyDiff + othersDiff);

  double get physicalTotal =>
      physicalCash +
      physicalBank +
      physicalCorporate +
      physicalTamara +
      physicalTabby +
      physicalOthers;

  /// Sum of net system buckets (after returns).
  double get systemBucketsSum =>
      systemCash +
      systemBank +
      systemCorporate +
      systemTamara +
      systemTabby +
      systemOthers;

  /// Sum of gross system buckets (pre–sales-return; reconciliation table System column).
  double get systemBucketsSumGross =>
      systemCashGross +
      systemBankGross +
      systemCorporateGross +
      systemTamaraGross +
      systemTabbyGross +
      systemOthersGross;

  /// Sum of bucket differences (equals [netDifference] when API diffs are consistent).
  double get diffBucketsSum =>
      cashDiff + bankDiff + corporateDiff + tamaraDiff + tabbyDiff + othersDiff;

  factory StoreClosingReport.fromApiResponse({
    required String closingId,
    required String branch,
    required String cashierName,
    String workshopName = '',
    required Map<String, dynamic> json,
  }) {
    final apiWorkshop = json['workshopName']?.toString().trim() ?? '';
    final resolvedWorkshop = apiWorkshop.isNotEmpty ? apiWorkshop : workshopName.trim();
    final rec = json['reconciliation'] as Map<String, dynamic>? ?? {};

    ReconciliationBucket bucket(String key) {
      final raw = rec[key];
      if (raw is Map<String, dynamic>) return ReconciliationBucket.fromJson(raw);
      return ReconciliationBucket(
          system: 0, systemGross: 0, physical: 0, difference: 0);
    }

    final cash = bucket('physicalCash');
    final bank = bucket('bankCardSlips');
    final corp = bucket('corporateInvoice');
    final tamara = bucket('tamaraCredits');
    final tabby = bucket('tabbyCredits');
    final others = bucket('others');

    final netFromApi =
        (json['systemTotalSales'] ?? json['totalAmount'] ?? 0).toDouble();
    final grossFromApi =
        (json['grossSystemSales'] ?? netFromApi).toDouble();
    final returnsFromApi =
        (json['salesReturnsTotal'] ?? 0).toDouble();

    DateTime? sessionOpenedAt;
    final openedRaw = json['openedAt']?.toString();
    if (openedRaw != null && openedRaw.isNotEmpty) {
      sessionOpenedAt = DateTime.tryParse(openedRaw);
    }

    DateTime? sessionClosedAt;
    final closedRaw = json['closedAt']?.toString();
    if (closedRaw != null && closedRaw.isNotEmpty) {
      sessionClosedAt = DateTime.tryParse(closedRaw);
    }

    return StoreClosingReport(
      id: closingId,
      timestamp: DateTime.now(),
      branch: branch,
      workshopName: resolvedWorkshop,
      cashierName: cashierName,
      grossSystemSales: grossFromApi,
      salesReturnsTotal: returnsFromApi,
      systemSales: netFromApi,
      systemCash: cash.system,
      systemBank: bank.system,
      systemCorporate: corp.system,
      systemTamara: tamara.system,
      systemTabby: tabby.system,
      systemOthers: others.system,
      systemCashGross: cash.systemGross,
      systemBankGross: bank.systemGross,
      systemCorporateGross: corp.systemGross,
      systemTamaraGross: tamara.systemGross,
      systemTabbyGross: tabby.systemGross,
      systemOthersGross: others.systemGross,
      physicalCash: cash.physical,
      physicalBank: bank.physical,
      physicalCorporate: corp.physical,
      physicalTamara: tamara.physical,
      physicalTabby: tabby.physical,
      physicalOthers: others.physical,
      apiCashDiff: cash.difference,
      apiBankDiff: bank.difference,
      apiCorporateDiff: corp.difference,
      apiTamaraDiff: tamara.difference,
      apiTabbyDiff: tabby.difference,
      apiOthersDiff: others.difference,
      apiTotalDifference: (json['totalDifference'] ?? 0).toDouble(),
      sessionOpenedAt: sessionOpenedAt,
      sessionClosedAt: sessionClosedAt,
      departmentBreakdown: parseDepartmentBreakdown(json['departmentBreakdown']),
      commissionPercent: () {
        final v = json['commissionPercent'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }(),
      commissionBaseSales: () {
        final v = json['commissionBaseSales'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }(),
      commissionAmount: () {
        final v = json['commissionAmount'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }(),
    );
  }
}

/// System totals fetched from GET store-closing summary before submitting
class StoreClosingSummary {
  final double systemCash;
  final double systemBank;
  final double systemCorporate;
  final double systemTamara;
  final double systemTabby;
  final double systemOthers;
  final double systemCashGross;
  final double systemBankGross;
  final double systemCorporateGross;
  final double systemTamaraGross;
  final double systemTabbyGross;
  final double systemOthersGross;
  final double totalAmount;
  final int totalInvoices;
  final DateTime? sessionOpenedAt;
  final List<DepartmentSalesRow> departmentBreakdown;

  StoreClosingSummary({
    required this.systemCash,
    required this.systemBank,
    required this.systemCorporate,
    required this.systemTamara,
    required this.systemTabby,
    required this.systemOthers,
    required this.systemCashGross,
    required this.systemBankGross,
    required this.systemCorporateGross,
    required this.systemTamaraGross,
    required this.systemTabbyGross,
    required this.systemOthersGross,
    required this.totalAmount,
    required this.totalInvoices,
    this.sessionOpenedAt,
    this.departmentBreakdown = const [],
    this.commissionPercent = 0,
    this.commissionBaseSales = 0,
    this.commissionAmount = 0,
  });

  final double commissionPercent;
  final double commissionBaseSales;
  final double commissionAmount;

  factory StoreClosingSummary.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v, [double alt = 0]) {
      if (v == null) return alt;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? alt;
    }

    final totals = json['paymentCategoryTotals'] as Map<String, dynamic>? ?? {};
    final gross =
        json['paymentCategoryTotalsGross'] as Map<String, dynamic>? ?? totals;

    DateTime? sessionOpenedAt;
    final openedRaw = json['openedAt']?.toString();
    if (openedRaw != null && openedRaw.isNotEmpty) {
      sessionOpenedAt = DateTime.tryParse(openedRaw);
    }

    return StoreClosingSummary(
      systemCash: toD(totals['cash'] ?? json['cashAmount']),
      systemBank: toD(totals['bankCardSlips'] ?? json['bankAmount']),
      systemCorporate:
          toD(totals['corporateInvoice'] ?? json['corporateAmount']),
      systemTamara: toD(totals['tamaraCredits']),
      systemTabby: toD(totals['tabbyCredits']),
      systemOthers: toD(totals['others']),
      systemCashGross: toD(gross['cash'] ?? json['cashAmount']),
      systemBankGross: toD(gross['bankCardSlips'] ?? json['bankAmount']),
      systemCorporateGross:
          toD(gross['corporateInvoice'] ?? json['corporateAmount']),
      systemTamaraGross: toD(gross['tamaraCredits']),
      systemTabbyGross: toD(gross['tabbyCredits']),
      systemOthersGross: toD(gross['others']),
      totalAmount: toD(json['totalAmount']),
      totalInvoices: (json['totalInvoices'] is int)
          ? json['totalInvoices'] as int
          : int.tryParse(json['totalInvoices']?.toString() ?? '') ?? 0,
      sessionOpenedAt: sessionOpenedAt,
      departmentBreakdown: parseDepartmentBreakdown(json['departmentBreakdown']),
      commissionPercent: toD(json['commissionPercent']),
      commissionBaseSales: toD(json['commissionBaseSales']),
      commissionAmount: toD(json['commissionAmount']),
    );
  }
}

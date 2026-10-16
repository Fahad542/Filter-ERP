import 'store_closing_model.dart';

class CashierClosingHistoryItem {
  const CashierClosingHistoryItem({
    required this.posSessionId,
    required this.closingId,
    required this.cashierName,
    required this.branchName,
    required this.openedAt,
    required this.closedAt,
    required this.systemTotalSales,
    required this.physicalTotal,
    required this.reconciliationTotalDifference,
    required this.systemCash,
    required this.systemBank,
    required this.systemCorporate,
    required this.systemTamara,
    required this.systemTabby,
    required this.systemOthers,
    required this.physicalCash,
    required this.physicalBank,
    required this.physicalCorporate,
    required this.physicalTamara,
    required this.physicalTabby,
    required this.physicalOthers,
    this.commissionPercent = 0,
    this.commissionBaseSales = 0,
    this.commissionAmount = 0,
    this.departmentBreakdown = const [],
    this.returnItems = const [],
  });

  final String posSessionId;
  final String? closingId;
  final String cashierName;
  final String? branchName;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double systemTotalSales;
  final double physicalTotal;
  final double reconciliationTotalDifference;
  final double systemCash;
  final double systemBank;
  final double systemCorporate;
  final double systemTamara;
  final double systemTabby;
  final double systemOthers;
  final double physicalCash;
  final double physicalBank;
  final double physicalCorporate;
  final double physicalTamara;
  final double physicalTabby;
  final double physicalOthers;
  final double commissionPercent;
  final double commissionBaseSales;
  final double commissionAmount;
  final List<DepartmentSalesRow> departmentBreakdown;
  final List<ClosingReturnItemRow> returnItems;

  factory CashierClosingHistoryItem.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      if (v is int) {
        return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
      }
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s)?.toLocal();
    }

    return CashierClosingHistoryItem(
      posSessionId: json['posSessionId']?.toString() ?? '',
      closingId: json['closingId']?.toString(),
      cashierName: json['cashierName']?.toString() ?? 'Cashier',
      branchName: json['branchName']?.toString(),
      openedAt: parseDt(json['openedAtEpochMs']) ?? parseDt(json['openedAt']),
      closedAt: parseDt(json['closedAtEpochMs']) ?? parseDt(json['closedAt']),
      systemTotalSales: n(json['systemTotalSales']),
      physicalTotal: n(json['physicalTotal']),
      reconciliationTotalDifference: n(json['reconciliationTotalDifference']),
      systemCash: n(json['systemCash']),
      systemBank: n(json['systemBank']),
      systemCorporate: n(json['systemCorporate']),
      systemTamara: n(json['systemTamara']),
      systemTabby: n(json['systemTabby']),
      systemOthers: n(json['systemOthers']),
      physicalCash: n(json['physicalCash']),
      physicalBank: n(json['physicalBank']),
      physicalCorporate: n(json['physicalCorporate']),
      physicalTamara: n(json['physicalTamara']),
      physicalTabby: n(json['physicalTabby']),
      physicalOthers: n(json['physicalOthers']),
      commissionPercent: n(json['commissionPercent']),
      commissionBaseSales: n(json['commissionBaseSales']),
      commissionAmount: n(json['commissionAmount']),
      departmentBreakdown: parseDepartmentBreakdown(json['departmentBreakdown']),
      returnItems: parseClosingReturnItems(json['returnItems']),
    );
  }
}

class CashierClosingHistoryResponse {
  const CashierClosingHistoryResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    this.totalCommission = 0,
    this.totalSales = 0,
  });

  final List<CashierClosingHistoryItem> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final double totalCommission;
  final double totalSales;

  factory CashierClosingHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => CashierClosingHistoryItem.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <CashierClosingHistoryItem>[];

    final pagination = json['pagination'];
    final p = pagination is Map
        ? Map<String, dynamic>.from(pagination)
        : <String, dynamic>{};

    int i(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return CashierClosingHistoryResponse(
      items: items,
      page: i(p['page'], 1),
      pageSize: i(p['pageSize'], 20),
      total: i(p['total']),
      totalPages: i(p['totalPages'], 1),
      totalCommission: () {
        final v = json['totalCommission'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }(),
      totalSales: () {
        final v = json['totalSales'] ?? json['total_sales'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0;
      }(),
    );
  }
}

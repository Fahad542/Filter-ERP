/// GET /cashier/inventory-sales?from=&to= — cashier product quantity sold per day.

/// Period aggregate totals returned alongside `days` / `productsSummary`.
class InventorySalesSummary {
  const InventorySalesSummary({
    required this.totalUnitsSold,
    required this.totalSalesAmount,
    required this.uniqueProducts,
    required this.daysWithActivity,
    this.distinctItems = 0,
    this.uniqueServices = 0,
  });

  final double totalUnitsSold;
  final double totalSalesAmount;
  /// Products-only count (when API separates products vs services).
  final int uniqueProducts;
  /// Services-only count (`itemType: service`).
  final int uniqueServices;
  /// Combined distinct sellable rows (often products + services); preferred for KPI when present.
  final int distinctItems;
  final int daysWithActivity;

  factory InventorySalesSummary.fromJson(Map<String, dynamic> json) {
    return InventorySalesSummary(
      totalUnitsSold: _parseDouble(json['totalUnitsSold']),
      totalSalesAmount: _parseDouble(json['totalSalesAmount']),
      uniqueProducts: _parseInt(json['uniqueProducts']),
      uniqueServices: _parseInt(json['uniqueServices']),
      distinctItems: _parseInt(json['distinctItems']),
      daysWithActivity: _parseInt(json['daysWithActivity']),
    );
  }
}

/// One row from `productsSummary[]` — sold qty & revenue for the selected period.
///
/// APIs may mix catalog products (`itemType: product`) and services (`itemType: service`);
/// only one of [productId] / [serviceId] is set per row.
class InventoryProductPeriodSummary {
  const InventoryProductPeriodSummary({
    required this.productName,
    required this.totalQty,
    required this.totalSales,
    this.productId,
    this.serviceId,
    this.itemType = 'product',
    this.sku,
    this.itemName,
    this.departmentId,
    this.departmentName,
    this.salePrice,
    this.avgUnitPrice,
  });

  final String productName;
  final String? productId;
  final String? serviceId;
  /// Typically `product` or `service`.
  final String itemType;
  final String? sku;
  final String? itemName;
  final String? departmentId;
  final String? departmentName;
  final double? salePrice;
  final double? avgUnitPrice;
  final double totalQty;
  final double totalSales;

  factory InventoryProductPeriodSummary.fromJson(Map<String, dynamic> json) {
    final itemTypeRaw =
        (json['itemType'] ?? 'product').toString().trim().toLowerCase();
    final nameRaw =
        (json['itemName'] ?? json['productName'])?.toString().trim() ?? '';
    final pid = json['productId']?.toString().trim();
    final sid = json['serviceId']?.toString().trim();
    return InventoryProductPeriodSummary(
      productId: (pid != null && pid.isNotEmpty) ? pid : null,
      serviceId: (sid != null && sid.isNotEmpty) ? sid : null,
      itemType: itemTypeRaw.isEmpty ? 'product' : itemTypeRaw,
      productName: nameRaw.isEmpty ? 'Unknown' : nameRaw,
      sku: json['sku']?.toString(),
      itemName: json['itemName']?.toString(),
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      salePrice: json.containsKey('salePrice')
          ? _parseDouble(json['salePrice'])
          : null,
      avgUnitPrice: json.containsKey('avgUnitPrice')
          ? _parseDouble(json['avgUnitPrice'])
          : null,
      totalQty: _parseDouble(json['totalQty']),
      totalSales: _parseDouble(json['totalSales']),
    );
  }
}

/// Inventory Sales screen shows **products only** (exclude catalog services).
bool inventorySalesLineIsProduct(InventorySaleLine l) {
  final t = (l.itemType ?? '').trim().toLowerCase();
  if (t == 'service') return false;
  if (t == 'product') return true;
  final sid = l.serviceId?.trim() ?? '';
  if (sid.isNotEmpty) return false;
  return true;
}

bool inventorySalesPeriodRowIsProduct(InventoryProductPeriodSummary p) {
  final t = p.itemType.trim().toLowerCase();
  if (t == 'service') return false;
  if (t == 'product') return true;
  final sid = p.serviceId?.trim() ?? '';
  if (sid.isNotEmpty) return false;
  return true;
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _parseDayOnly(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return DateTime(v.year, v.month, v.day);
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  try {
    final d = DateTime.parse(s);
    return DateTime(d.year, d.month, d.day);
  } catch (_) {
    return null;
  }
}

/// Per-calendar-day rollups from `days[]` (`unitsTotal`, `salesTotal`).
class InventorySalesDayRollup {
  const InventorySalesDayRollup({
    required this.date,
    required this.unitsTotal,
    required this.salesTotal,
  });

  final DateTime date;
  final double unitsTotal;
  final double salesTotal;

  static InventorySalesDayRollup? tryParse(Map<String, dynamic> dayMap) {
    final d = _parseDayOnly(dayMap['date']);
    if (d == null) return null;
    return InventorySalesDayRollup(
      date: d,
      unitsTotal: _parseDouble(dayMap['unitsTotal']),
      salesTotal: _parseDouble(dayMap['salesTotal']),
    );
  }
}

class InventorySaleLine {
  const InventorySaleLine({
    required this.productName,
    required this.quantitySold,
    required this.soldOn,
    this.productId,
    this.serviceId,
    this.sku,
    this.salesAmount,
    this.itemType,
    this.departmentId,
    this.departmentName,
    this.salePrice,
    this.avgUnitPrice,
  });

  final String productName;
  final String? productId;
  final String? serviceId;
  final String? sku;
  final DateTime soldOn;
  final num quantitySold;

  /// Net sales amount for this line when API sends `netAmount` / `totalSales`.
  final double? salesAmount;

  final String? itemType;
  final String? departmentId;
  final String? departmentName;
  final double? salePrice;
  final double? avgUnitPrice;

  String quantityDisplay({int fractionDigits = 2}) {
    final v = quantitySold;
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toDouble().toStringAsFixed(fractionDigits);
  }

  factory InventorySaleLine.fromJson(Map<String, dynamic> json) {
    final rawName = json['itemName'] ??
        json['productName'] ??
        json['name'] ??
        json['product_name'] ??
        json['title'] ??
        '';
    final qty = _parseQty(
      json['quantitySold'] ??
          json['netQty'] ??
          json['qty'] ??
          json['quantity'] ??
          json['soldQty'] ??
          json['sold_qty'],
    );
    final sold = _parseDate(
      json['soldDate'] ??
          json['saleDate'] ??
          json['date'] ??
          json['soldOn'] ??
          json['sold_on'],
    );

    final amtRaw =
        json['netAmount'] ?? json['totalSales'] ?? json['salesAmount'];

    final pid = json['productId']?.toString() ?? json['product_id']?.toString();
    final sid = json['serviceId']?.toString() ?? json['service_id']?.toString();
    final itemTypeRaw = json['itemType']?.toString().trim();
    return InventorySaleLine(
      productName: rawName.toString().trim().isEmpty
          ? 'Unknown'
          : rawName.toString().trim(),
      productId: (pid != null && pid.trim().isNotEmpty) ? pid.trim() : null,
      serviceId: (sid != null && sid.trim().isNotEmpty) ? sid.trim() : null,
      sku: json['sku']?.toString() ?? json['SKU']?.toString(),
      soldOn: sold ?? DateTime.now(),
      quantitySold: qty,
      salesAmount:
          amtRaw != null ? _parseDouble(amtRaw) : null,
      itemType: (itemTypeRaw != null && itemTypeRaw.isNotEmpty)
          ? itemTypeRaw
          : null,
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      salePrice: json.containsKey('salePrice')
          ? _parseDouble(json['salePrice'])
          : null,
      avgUnitPrice: json.containsKey('avgUnitPrice')
          ? _parseDouble(json['avgUnitPrice'])
          : null,
    );
  }

  static num _parseQty(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return DateTime(v.year, v.month, v.day);
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    try {
      final d = DateTime.parse(s);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }
}

class InventorySalesResponse {
  const InventorySalesResponse({
    required this.lines,
    this.success = true,
    this.message,
    this.summary,
    this.productsSummary = const [],
    this.dayRollups = const [],
    this.workshopId,
    this.branchId,
    this.periodFrom,
    this.periodTo,
    this.businessTimeZone,
  });

  final bool success;
  final String? message;
  final List<InventorySaleLine> lines;
  final InventorySalesSummary? summary;
  final List<InventoryProductPeriodSummary> productsSummary;

  /// Per-day totals when API sends `days[]`.
  final List<InventorySalesDayRollup> dayRollups;

  /// Echo from API (`GET /cashier/inventory-sales`).
  final String? workshopId;
  final String? branchId;
  final String? periodFrom;
  final String? periodTo;
  final String? businessTimeZone;

  factory InventorySalesResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true || json['success'] == null;
    final message = json['message']?.toString();

    InventorySalesSummary? summary;
    final sumRaw = json['summary'];
    if (sumRaw is Map<String, dynamic>) {
      summary = InventorySalesSummary.fromJson(sumRaw);
    } else if (sumRaw is Map) {
      summary =
          InventorySalesSummary.fromJson(Map<String, dynamic>.from(sumRaw));
    }

    final productsSummary = <InventoryProductPeriodSummary>[];
    final psRaw = json['productsSummary'];
    if (psRaw is List) {
      for (final e in psRaw) {
        if (e is Map<String, dynamic>) {
          productsSummary.add(InventoryProductPeriodSummary.fromJson(e));
        } else if (e is Map) {
          productsSummary.add(
            InventoryProductPeriodSummary.fromJson(
              Map<String, dynamic>.from(e),
            ),
          );
        }
      }
    }

    dynamic raw = json['sales'] ??
        json['entries'] ??
        json['items'] ??
        json['data'] ??
        json['lines'];
    if (raw is! List) raw = <dynamic>[];

    final lines = <InventorySaleLine>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        lines.add(InventorySaleLine.fromJson(e));
      } else if (e is Map) {
        lines.add(InventorySaleLine.fromJson(Map<String, dynamic>.from(e)));
      }
    }

    final dayRollups = <InventorySalesDayRollup>[];
    final daysRaw = json['days'];
    if (daysRaw is List) {
      for (final dayEntry in daysRaw) {
        if (dayEntry is! Map) continue;
        final dayMap = Map<String, dynamic>.from(dayEntry);
        final r = InventorySalesDayRollup.tryParse(dayMap);
        if (r != null) dayRollups.add(r);
      }
      dayRollups.sort((a, b) => a.date.compareTo(b.date));
    }

    /// Backend shape: `{ "days": [ { "date": "...", "products": [ {...} ] } ] }`
    if (lines.isEmpty && daysRaw is List) {
      for (final dayEntry in daysRaw) {
        if (dayEntry is! Map) continue;
        final dayMap = Map<String, dynamic>.from(dayEntry);
        final dayDate = dayMap['date'];
        final products = dayMap['products'];
        if (products is! List) continue;
        for (final rawProduct in products) {
          Map<String, dynamic> productMap;
          if (rawProduct is Map<String, dynamic>) {
            productMap = Map<String, dynamic>.from(rawProduct);
          } else if (rawProduct is Map) {
            productMap = Map<String, dynamic>.from(rawProduct);
          } else {
            continue;
          }
          if (dayDate != null) {
            productMap.putIfAbsent('soldDate', () => dayDate);
            productMap.putIfAbsent('date', () => dayDate);
          }
          lines.add(InventorySaleLine.fromJson(productMap));
        }
      }
    }

    return InventorySalesResponse(
      success: success,
      message: message,
      lines: lines,
      summary: summary,
      productsSummary: productsSummary,
      dayRollups: dayRollups,
      workshopId: json['workshopId']?.toString(),
      branchId: json['branchId']?.toString(),
      periodFrom: json['from']?.toString(),
      periodTo: json['to']?.toString(),
      businessTimeZone: json['businessTimeZone']?.toString(),
    );
  }
}

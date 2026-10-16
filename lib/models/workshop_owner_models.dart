import 'package:flutter/material.dart';


// ─── Inventory Management Models ─────────────────────────────────────────────

// ─── Dummy Data Models ────────────────────────────────────────────────────────

class InvProduct {
  final String id;
  final String name;
  final String sku;
  final String department;
  final String departmentId;
  final String category;
  final int openingStock;
  final int currentStock;
  final int criticalStock;
  final String unit;           // workshop unit (sales/inventory)
  final String warehouseUnit;  // purchase/bulk unit (may equal unit)
  final int conversionFactor;  // 1 warehouseUnit = N unit
  final double salePrice;
  final double purchasePrice;
  final bool isActive;
  final String? uomProfileId;  // null = no profile
  /// When set (All Branches low-stock rows), this alert is for that branch only.
  final String? branchId;
  final String? branchName;

  const InvProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.department,
    required this.departmentId,
    required this.category,
    required this.openingStock,
    required this.currentStock,
    required this.criticalStock,
    required this.unit,
    required this.warehouseUnit,
    required this.conversionFactor,
    required this.salePrice,
    required this.purchasePrice,
    required this.isActive,
    this.uomProfileId,
    this.branchId,
    this.branchName,
  });

  bool get isLowStock => criticalStock > 0 && currentStock <= criticalStock;
  bool get isOutOfStock => currentStock <= 0;

  /// Stable list/selection key (product may appear once per branch in All Branches).
  String get rowKey {
    final b = branchId?.trim() ?? '';
    return b.isEmpty ? id : '$id::$b';
  }

  InvProduct copyWithBranch({
    required String branchId,
    required String branchName,
  }) {
    return InvProduct(
      id: id,
      name: name,
      sku: sku,
      department: department,
      departmentId: departmentId,
      category: category,
      openingStock: openingStock,
      currentStock: currentStock,
      criticalStock: criticalStock,
      unit: unit,
      warehouseUnit: warehouseUnit,
      conversionFactor: conversionFactor,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      isActive: isActive,
      uomProfileId: uomProfileId,
      branchId: branchId,
      branchName: branchName,
    );
  }

  /// Parse from GET /workshop-catalog/branches/{id}/products **or**
  /// flattened GET /workshop-staff/branches/{id}/products rows (same as web).
  factory InvProduct.fromBranchJson(Map<String, dynamic> j) {
    final productMap = j['product'] is Map
        ? Map<String, dynamic>.from(j['product'] as Map)
        : <String, dynamic>{};

    num? pickNum(List<dynamic> vals) {
      for (final v in vals) {
        if (v == null) continue;
        if (v is num) return v;
        final n = num.tryParse(v.toString());
        if (n != null) return n;
      }
      return null;
    }

    // Prefer branch_inventory qty when nested (staff / catalog variants).
    num? invQty;
    final bi = j['branchInventory'] ?? j['branch_inventory'] ?? productMap['branchInventory'];
    if (bi is Map) {
      invQty = pickNum([bi['qtyOnHand'], bi['qty_on_hand']]);
    } else if (bi is List && bi.isNotEmpty && bi.first is Map) {
      final first = Map<String, dynamic>.from(bi.first as Map);
      invQty = pickNum([first['qtyOnHand'], first['qty_on_hand']]);
    }

    final current = pickNum([
          invQty,
          j['currentQty'],
          j['current_qty'],
          j['qtyOnHand'],
          j['qty_on_hand'],
          j['qtyOnHandWorkshop'],
          j['stockQty'],
          j['stock_qty'],
          productMap['currentQty'],
          productMap['qtyOnHand'],
        ]) ??
        0;

    final critical = pickNum([
          j['criticalStockPoint'],
          j['critical_stock_point'],
          j['critical_level'],
          productMap['criticalStockPoint'],
          productMap['critical_stock_point'],
        ]) ??
        0;

    final opening = pickNum([
          j['openingQty'],
          j['opening_qty'],
          productMap['openingQty'],
        ]) ??
        0;

    final id = (j['id'] ??
            j['productId'] ??
            j['product_id'] ??
            productMap['id'] ??
            '')
        .toString();
    final name = (j['name'] ?? productMap['name'] ?? '').toString();
    final sku = (j['sku'] ?? productMap['sku'] ?? '').toString();

    return InvProduct(
      id: id,
      name: name,
      sku: sku,
      department: (j['departmentName'] ??
              j['department_name'] ??
              (j['department'] is Map ? (j['department'] as Map)['name'] : null) ??
              productMap['departmentName'] ??
              '')
          .toString(),
      departmentId: (j['departmentId'] ??
              j['department_id'] ??
              productMap['departmentId'] ??
              '')
          .toString(),
      category: (j['categoryName'] ??
              j['category_name'] ??
              (j['category'] is Map ? (j['category'] as Map)['name'] : null) ??
              productMap['categoryName'] ??
              '')
          .toString(),
      openingStock: opening.toInt(),
      currentStock: current.toInt(),
      criticalStock: critical.toInt(),
      unit: (j['workshopUnit'] ??
              j['unit'] ??
              productMap['unit'] ??
              'pcs')
          .toString(),
      warehouseUnit:
          (j['warehouseUnit'] ?? productMap['warehouseUnit'] ?? 'pcs').toString(),
      conversionFactor:
          (pickNum([j['conversionFactor'], productMap['conversionFactor']]) ?? 1)
              .toInt(),
      salePrice: (pickNum([
                j['salePrice'],
                j['sale_price'],
                productMap['salePrice'],
              ]) ??
              0)
          .toDouble(),
      purchasePrice: (pickNum([
                j['purchasePrice'],
                j['purchase_price'],
                j['purchasePriceOverride'],
                productMap['purchasePrice'],
              ]) ??
              0)
          .toDouble(),
      isActive: j['isActive'] as bool? ?? productMap['isActive'] as bool? ?? true,
      uomProfileId: j['uomProfileId']?.toString() ?? productMap['uomProfileId']?.toString(),
    );
  }
}

class UomProfile {
  final String id;
  final String name;
  final String warehouseUnit;
  final String workshopUnit;
  final int factor;
  final String? notes;
  // Products linked to this profile
  List<String> linkedProductIds;

  UomProfile({
    required this.id,
    required this.name,
    required this.warehouseUnit,
    required this.workshopUnit,
    required this.factor,
    this.notes,
    List<String>? linkedProductIds,
  }) : linkedProductIds = linkedProductIds ?? [];

  String get ruleLabel => '1 $warehouseUnit = $factor $workshopUnit';
}

class StockTimelineEntry {
  final DateTime when;
  final String type; // 'OPENING (ADOPTION)', 'MANUAL ADJUST', 'SALE', 'PURCHASE', etc.
  final int from;
  final int to;
  final String reason;
  final String sourceRef;
  final String by;

  const StockTimelineEntry({
    required this.when,
    required this.type,
    required this.from,
    required this.to,
    required this.reason,
    required this.sourceRef,
    required this.by,
  });

  int get delta => to - from;
}



class WorkshopRegistration {
  final String workshopName;
  final String branch;
  final String vatId;
  final String crNo;
  final String manualAddress;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? frontPhotoUrl;
  final String? crAttachmentUrl;
  final String ownerName;
  final String contactPerson;
  final String? referralPerson;
  final double investmentAmount;

  WorkshopRegistration({
    required this.workshopName,
    required this.branch,
    required this.vatId,
    required this.crNo,
    required this.manualAddress,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.frontPhotoUrl,
    this.crAttachmentUrl,
    required this.ownerName,
    required this.contactPerson,
    this.referralPerson,
    required this.investmentAmount,
  });
}



class Branch {
  final String id;
  final String name;
  final String location;
  final String vat;
  final String cr;
  final double? gpsLat;
  final double? gpsLng;
  final String status;
  final double salesMTD;

  // ── New fields required by BranchManagementViewModel ──────────────────────
  final String? branchCode;
  final String? phone;
  final String? email;
  final String? vatId;
  final String? crNumber;
  final String? egsSerial;
  final String? contactPerson;
  final int?    employeeCount;
  final String? adminName;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedLocation;

  Branch({
    required this.id,
    required this.name,
    required this.location,
    required this.vat,
    required this.cr,
    this.gpsLat,
    this.gpsLng,
    required this.status,
    required this.salesMTD,
    this.branchCode,
    this.phone,
    this.email,
    this.vatId,
    this.crNumber,
    this.egsSerial,
    this.contactPerson,
    this.employeeCount,
    this.adminName,
    this.translatedName,
    this.translatedLocation,
  });

  Branch copyWith({
    String? id,
    String? name,
    String? location,
    String? vat,
    String? cr,
    double? gpsLat,
    double? gpsLng,
    String? status,
    double? salesMTD,
    String? branchCode,
    String? phone,
    String? email,
    String? vatId,
    String? crNumber,
    String? egsSerial,
    String? contactPerson,
    int?    employeeCount,
    String? adminName,
    String? translatedName,
    String? translatedLocation,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      vat: vat ?? this.vat,
      cr: cr ?? this.cr,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      status: status ?? this.status,
      salesMTD: salesMTD ?? this.salesMTD,
      branchCode: branchCode ?? this.branchCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vatId: vatId ?? this.vatId,
      crNumber: crNumber ?? this.crNumber,
      egsSerial: egsSerial ?? this.egsSerial,
      contactPerson: contactPerson ?? this.contactPerson,
      employeeCount: employeeCount ?? this.employeeCount,
      adminName: adminName ?? this.adminName,
      translatedName: translatedName ?? this.translatedName,
      translatedLocation: translatedLocation ?? this.translatedLocation,
    );
  }

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['address'] ?? json['location'] ?? '',
      vat: json['vat'] ?? '',
      cr: json['cr'] ?? '',
      gpsLat: double.tryParse(json['gpsLat']?.toString() ?? ''),
      gpsLng: double.tryParse(json['gpsLng']?.toString() ?? ''),
      status: (json['isActive'] == true ||
          (json['isActive'] == null && json['status'] == 'active'))
          ? 'active'
          : 'inactive',
      salesMTD: double.tryParse(
            (json['salesMTD'] ?? json['monthlySales'] ?? 0).toString()) ??
          0.0,
      // New fields — all nullable so old API responses keep working
      branchCode: json['branchCode']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      vatId: json['vatId']?.toString(),
      crNumber: json['crNumber']?.toString(),
      egsSerial: json['egsSerial']?.toString() ?? json['egs_serial']?.toString(),
      contactPerson: json['contactPerson']?.toString(),
      employeeCount: json['employeeCount'] is int
          ? json['employeeCount']
          : int.tryParse(json['employeeCount']?.toString() ?? ''),
      adminName: json['adminName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': location,
      'vat': vat,
      'cr': cr,
      if (gpsLat != null) 'gpsLat': gpsLat,
      if (gpsLng != null) 'gpsLng': gpsLng,
      'isActive': status == 'active',
      'salesMTD': salesMTD,
      if (branchCode != null) 'branchCode': branchCode,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (vatId != null) 'vatId': vatId,
      if (crNumber != null) 'crNumber': crNumber,
      if (egsSerial != null) 'egsSerial': egsSerial,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (employeeCount != null) 'employeeCount': employeeCount,
      if (adminName != null) 'adminName': adminName,
    };
  }
}
class EmployeeSlots {
  final int total;
  final int active;
  final int available;

  EmployeeSlots({
    required this.total,
    required this.active,
    required this.available,
  });

  factory EmployeeSlots.fromJson(Map<String, dynamic> json) {
    return EmployeeSlots(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      active: int.tryParse(json['active']?.toString() ?? '0') ?? 0,
      available: int.tryParse(json['available']?.toString() ?? '0') ?? 0,
    );
  }
}

class OwnerEmployee {
  final String id;
  final String name;
  final String mobile;
  final String branchId;
  final String? email;
  final String role;
  final List<String> departmentIds;
  final double? basicSalary;
  final double commissionPercent;
  final String? technicianType; // 'workshop', 'oncall', 'both'
  final bool workshopDuty;
  final bool onCallAvailable;
  final bool? isAvailable;
  final String technicianStatus;
  /// Account / employment active flag from API (`isActive` / `active`).
  final bool isActive;
  final String status;
  final String lastSeenAt;
  final String? userId; // Added userId
  final EmployeeSlots? slots;
  final String? branchName;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON. Raw fields above are always kept in
  /// English so API payloads (create/update/delete) stay correct.
  final String? translatedName;
  final String? translatedRole;
  final String? translatedBranchName;
  final List<String>? translatedDepartmentLabels;

  String get displayName => translatedName ?? name;
  String get displayRole => translatedRole ?? role;
  String? get displayBranchName => translatedBranchName ?? branchName;
  List<String> get displayDepartmentLabels =>
      translatedDepartmentLabels ?? departmentIds;

  bool get isOnline => isAvailable == true;
  bool get isTechnicianAvailable =>
      technicianStatus.toLowerCase() == 'available' ||
          technicianStatus.toLowerCase() == 'online';

  String get technicianStatusLabel {
    final s = technicianStatus.trim().toLowerCase();
    if (s == 'available') return 'AVAILABLE';
    if (s == 'online') return 'ONLINE';
    if (s == 'busy') return 'BUSY';
    if (s == 'offline') return 'OFFLINE';
    return isTechnicianAvailable ? 'AVAILABLE' : 'OFFLINE';
  }

  String get formattedLastSeen {
    if (lastSeenAt.isEmpty) return 'Never';
    try {
      final dateTime = DateTime.parse(lastSeenAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return lastSeenAt.split('T')[0];
    } catch (e) {
      return '';
    }
  }

  OwnerEmployee({
    required this.id,
    required this.name,
    required this.mobile,
    required this.branchId,
    this.email,
    required this.role,
    required this.departmentIds,
    this.basicSalary,
    required this.commissionPercent,
    this.technicianType,
    this.workshopDuty = false,
    this.onCallAvailable = false,
    this.isAvailable,
    this.technicianStatus = '',
    this.isActive = true,
    this.status = 'active',
    this.lastSeenAt = '',
    this.userId,
    this.slots,
    this.branchName,
    this.translatedName,
    this.translatedRole,
    this.translatedBranchName,
    this.translatedDepartmentLabels,
  });

  // Alias for commissionPercent used in some views
  double get techCommission => commissionPercent;

  OwnerEmployee copyWith({
    String? id,
    String? name,
    String? mobile,
    String? branchId,
    String? email,
    String? role,
    List<String>? departmentIds,
    double? basicSalary,
    double? commissionPercent,
    String? technicianType,
    bool? workshopDuty,
    bool? onCallAvailable,
    bool? isAvailable,
    String? technicianStatus,
    bool? isActive,
    String? status,
    String? lastSeenAt,
    String? userId,
    EmployeeSlots? slots,
    String? branchName,
    String? translatedName,
    String? translatedRole,
    String? translatedBranchName,
    List<String>? translatedDepartmentLabels,
  }) {
    return OwnerEmployee(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      branchId: branchId ?? this.branchId,
      email: email ?? this.email,
      role: role ?? this.role,
      departmentIds: departmentIds ?? this.departmentIds,
      basicSalary: basicSalary ?? this.basicSalary,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      technicianType: technicianType ?? this.technicianType,
      workshopDuty: workshopDuty ?? this.workshopDuty,
      onCallAvailable: onCallAvailable ?? this.onCallAvailable,
      isAvailable: isAvailable ?? this.isAvailable,
      technicianStatus: technicianStatus ?? this.technicianStatus,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      userId: userId ?? this.userId,
      slots: slots ?? this.slots,
      branchName: branchName ?? this.branchName,
      translatedName: translatedName ?? this.translatedName,
      translatedRole: translatedRole ?? this.translatedRole,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
      translatedDepartmentLabels:
          translatedDepartmentLabels ?? this.translatedDepartmentLabels,
    );
  }

  factory OwnerEmployee.fromJson(Map<String, dynamic> json) {
    final techStatus = json['technicianStatus'] ?? json['technician_status'];
    final techStatusMap =
        techStatus is Map ? Map<String, dynamic>.from(techStatus) : null;
    final statusRaw = json['status'];
    final statusMap =
        statusRaw is Map ? Map<String, dynamic>.from(statusRaw) : null;
    final branchRaw = json['branch'];
    final branchMap =
        branchRaw is Map ? Map<String, dynamic>.from(branchRaw) : null;

    final techStatusStr =
        (techStatusMap?['status'] ?? statusMap?['status'] ?? '').toString();

    return OwnerEmployee(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      branchId: json['branchId']?.toString() ??
          json['branch_id']?.toString() ??
          branchMap?['id']?.toString() ??
          '',
      email: json['email']?.toString(),
      role: json['employeeType']?.toString() ??
          json['employee_type']?.toString() ??
          json['role']?.toString() ??
          '',
      departmentIds: _parseEmployeeDepartmentLabels(json),
      basicSalary: double.tryParse(
              (json['basicSalary'] ?? json['basic_salary'] ?? '0').toString()) ??
          0.0,
      commissionPercent: double.tryParse((json['commissionPercent'] ??
                  json['commission_percent'] ??
                  '0')
              .toString()) ??
          0.0,
      technicianType: json['technicianType']?.toString() ??
          json['technician_type']?.toString(),
      workshopDuty: json['workshop_duty'] == true ||
          json['workshopDuty'] == true,
      onCallAvailable: json['oncall_available'] == true ||
          json['onCallAvailable'] == true,
      isAvailable: techStatusStr == 'online' ||
          techStatusStr == 'available' ||
          json['is_available'] == true,
      technicianStatus: techStatusStr,
      lastSeenAt: (techStatusMap?['lastSeenAt'] ??
              techStatusMap?['last_seen_at'] ??
              statusMap?['lastSeenAt'] ??
              '')
          .toString(),
      isActive: () {
        if (json['isActive'] == false || json['active'] == false) return false;
        if (statusRaw is String) {
          final st = statusRaw.toLowerCase();
          if (st == 'inactive' || st == 'disabled') return false;
        }
        return true;
      }(),
      status: (json['isActive'] == false || json['active'] == false)
          ? 'inactive'
          : (statusRaw is String ? statusRaw : 'active'),
      userId: json['userId']?.toString() ??
          json['user_id']?.toString() ??
          json['cashierUserId']?.toString(),
      branchName: branchMap?['name']?.toString() ??
          json['branchName']?.toString(),
      slots: json['slots'] is Map
          ? EmployeeSlots.fromJson(
              Map<String, dynamic>.from(json['slots'] as Map))
          : null,
    );
  }
}

List<String> _parseEmployeeDepartmentLabels(Map<String, dynamic> json) {
  final departments = json['departments'];
  if (departments is List) {
    final labels = <String>[];
    for (final d in departments) {
      if (d is Map) {
        final name = d['name']?.toString();
        final id = d['id']?.toString();
        if (name != null && name.isNotEmpty) {
          labels.add(name);
        } else if (id != null && id.isNotEmpty) {
          labels.add(id);
        }
      } else if (d != null) {
        final s = d.toString();
        if (s.isNotEmpty) labels.add(s);
      }
    }
    if (labels.isNotEmpty) return labels;
  }
  final ids = json['department_ids'] ?? json['departmentIds'];
  if (ids is List) {
    return ids.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

bool _parseOwnerIsPriceEditable(Map<String, dynamic> json) {
  const keys = <String>[
    'isPriceEditable',
    'is_price_editable',
    'priceEditable',
    'price_editable',
  ];
  var anyTrue = false;
  var anyExplicitFalse = false;
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v == true || (v is num && v != 0)) {
      anyTrue = true;
      continue;
    }
    if (v == false || (v is num && v == 0)) {
      anyExplicitFalse = true;
      continue;
    }
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') {
        anyTrue = true;
      } else if (s == 'false' || s == '0' || s == 'no') {
        anyExplicitFalse = true;
      }
    }
  }
  if (anyTrue) return true;
  if (anyExplicitFalse) return false;
  return false;
}

class OwnerProduct {
  final String id;
  final String name;
  final String type; // 'product', 'service'
  final String? category;
  final String? subCategoryName;
  final String? departmentName;
  final List<String> departmentIds;
  final String unit;
  final double conversionFactor;
  final double purchasePrice;
  final double salePrice;
  final double? corporateBasePrice;
  final double? corporateLowerLimit;
  final double? corporateUpperLimit;
  final double stockQty;
  final double criticalLevel;
  final double reorderLevel;
  final String? imageUrl;
  final bool isPriceEditable;
  final int kmTypeValue;
  final bool allowDecimalQty;
  final bool isActive;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedCategory;
  final String? translatedSubCategoryName;
  final String? translatedDepartmentName;

  // Aliases for consistency with views
  double get stock => stockQty;
  double get criticalStockPoint => criticalLevel;
  double? get minPriceCorporate => corporateLowerLimit;
  double? get maxPriceCorporate => corporateUpperLimit;

  String get displayName => translatedName ?? name;
  String? get displayCategory => translatedCategory ?? category;
  String? get displaySubCategoryName =>
      translatedSubCategoryName ?? subCategoryName;
  String? get displayDepartmentName =>
      translatedDepartmentName ?? departmentName;

  OwnerProduct({
    required this.id,
    required this.name,
    required this.type,
    this.category,
    this.subCategoryName,
    this.departmentName,
    required this.departmentIds,
    required this.unit,
    this.conversionFactor = 1.0,
    required this.purchasePrice,
    required this.salePrice,
    this.corporateBasePrice,
    this.corporateLowerLimit,
    this.corporateUpperLimit,
    required this.stockQty,
    required this.criticalLevel,
    required this.reorderLevel,
    this.imageUrl,
    this.isPriceEditable = false,
    this.kmTypeValue = 0,
    this.allowDecimalQty = false,
    this.isActive = true,
    this.translatedName,
    this.translatedCategory,
    this.translatedSubCategoryName,
    this.translatedDepartmentName,
  });

  OwnerProduct copyWith({
    String? id,
    String? name,
    String? type,
    String? category,
    String? subCategoryName,
    String? departmentName,
    List<String>? departmentIds,
    String? unit,
    double? conversionFactor,
    double? purchasePrice,
    double? salePrice,
    double? corporateBasePrice,
    double? corporateLowerLimit,
    double? corporateUpperLimit,
    double? stockQty,
    double? criticalLevel,
    double? reorderLevel,
    String? imageUrl,
    bool? isPriceEditable,
    int? kmTypeValue,
    bool? allowDecimalQty,
    bool? isActive,
    String? translatedName,
    String? translatedCategory,
    String? translatedSubCategoryName,
    String? translatedDepartmentName,
  }) {
    return OwnerProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategoryName: subCategoryName ?? this.subCategoryName,
      departmentName: departmentName ?? this.departmentName,
      departmentIds: departmentIds ?? this.departmentIds,
      unit: unit ?? this.unit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      corporateBasePrice: corporateBasePrice ?? this.corporateBasePrice,
      corporateLowerLimit: corporateLowerLimit ?? this.corporateLowerLimit,
      corporateUpperLimit: corporateUpperLimit ?? this.corporateUpperLimit,
      stockQty: stockQty ?? this.stockQty,
      criticalLevel: criticalLevel ?? this.criticalLevel,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      isPriceEditable: isPriceEditable ?? this.isPriceEditable,
      kmTypeValue: kmTypeValue ?? this.kmTypeValue,
      allowDecimalQty: allowDecimalQty ?? this.allowDecimalQty,
      isActive: isActive ?? this.isActive,
      translatedName: translatedName ?? this.translatedName,
      translatedCategory: translatedCategory ?? this.translatedCategory,
      translatedSubCategoryName:
          translatedSubCategoryName ?? this.translatedSubCategoryName,
      translatedDepartmentName:
          translatedDepartmentName ?? this.translatedDepartmentName,
    );
  }

  factory OwnerProduct.fromJson(Map<String, dynamic> json) {
    return OwnerProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'product',
      category: json['categoryName'] ?? json['category'] ?? '',
      subCategoryName: json['subCategoryName'],
      departmentName: json['departmentName'],
      departmentIds: [json['departmentId']?.toString() ?? ''].where((id) => id.isNotEmpty).toList(),
      unit: json['unit'] ?? 'pcs',
      conversionFactor: (json['conversion_factor'] ?? 1.0).toDouble(),
      purchasePrice: double.tryParse(json['purchasePrice']?.toString() ?? '0') ?? (json['purchase_price_excl'] ?? 0.0).toDouble(),
      salePrice: double.tryParse(json['salePrice']?.toString() ?? json['sellingPrice']?.toString() ?? '0') ?? (json['sale_price_incl'] ?? 0.0).toDouble(),
      corporateBasePrice: double.tryParse(json['corporate_price']?.toString() ?? '0') ?? 0.0,
      corporateLowerLimit: double.tryParse(json['corporate_lower_limit']?.toString() ?? json['minPriceCorporate']?.toString() ?? '0') ?? 0.0,
      corporateUpperLimit: double.tryParse(json['corporate_upper_limit']?.toString() ?? json['maxPriceCorporate']?.toString() ?? '0') ?? 0.0,
      stockQty: double.tryParse(json['openingQty']?.toString() ?? '0') ?? (json['stock_qty'] ?? 0.0).toDouble(),
      criticalLevel: double.tryParse(json['criticalStockPoint']?.toString() ?? '0') ?? (json['critical_level'] ?? 0.0).toDouble(),
      reorderLevel: (json['reorder_level'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      isPriceEditable: _parseOwnerIsPriceEditable(json),
      kmTypeValue: int.tryParse(json['kmTypeValue']?.toString() ?? '0') ?? (json['km_type_value'] ?? 0),
      allowDecimalQty: json['allowDecimalQty'] ?? json['allow_decimal_qty'] ?? false,
      isActive: json['isActive'] ?? json['active'] ?? true,
    );
  }
}

class OwnerSubCategory {
  final String id;
  final String name;
  final String? departmentId;
  final String? departmentName;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedDepartmentName;

  String get displayName => translatedName ?? name;
  String? get displayDepartmentName =>
      translatedDepartmentName ?? departmentName;

  OwnerSubCategory({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
    this.translatedName,
    this.translatedDepartmentName,
  });

  OwnerSubCategory copyWith({
    String? id,
    String? name,
    String? departmentId,
    String? departmentName,
    String? translatedName,
    String? translatedDepartmentName,
  }) {
    return OwnerSubCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      translatedName: translatedName ?? this.translatedName,
      translatedDepartmentName:
          translatedDepartmentName ?? this.translatedDepartmentName,
    );
  }

  factory OwnerSubCategory.fromJson(Map<String, dynamic> json) {
    return OwnerSubCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
    );
  }
}

class OwnerCategory {
  final String id;
  final String name;
  final String type;
  final String workshopId;
  final List<OwnerSubCategory> subCategories;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;

  String get displayName => translatedName ?? name;

  OwnerCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.workshopId,
    this.subCategories = const [],
    this.translatedName,
  });

  OwnerCategory copyWith({
    String? id,
    String? name,
    String? type,
    String? workshopId,
    List<OwnerSubCategory>? subCategories,
    String? translatedName,
  }) {
    return OwnerCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      workshopId: workshopId ?? this.workshopId,
      subCategories: subCategories ?? this.subCategories,
      translatedName: translatedName ?? this.translatedName,
    );
  }

  factory OwnerCategory.fromJson(Map<String, dynamic> json) {
    return OwnerCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      subCategories: (json['subCategories'] as List?)
          ?.map((e) => OwnerSubCategory.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class CorporateCustomer {
  final String id;
  final String companyName;
  final String vatNumber;
  final String contactName;
  final String mobile;
  final String email;
  final double creditLimit;
  final double dueBalance;
  final List<String> selectedBranchIds;
  final String status;
  final String category;
  final double totalSales;
  final int vehicleCount;
  final String address;
  final String contactPerson;

  CorporateCustomer({
    required this.id,
    required this.companyName,
    required this.vatNumber,
    required this.contactName,
    required this.mobile,
    required this.email,
    this.creditLimit = 0.0,
    this.dueBalance = 0.0,
    required this.selectedBranchIds,
    this.status = 'active',
    this.category = 'Bronze',
    this.totalSales = 0.0,
    this.vehicleCount = 0,
    this.address = '',
    this.contactPerson = '',
  });

  factory CorporateCustomer.fromJson(Map<String, dynamic> json) {
    return CorporateCustomer(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName'] ?? json['company_name'] ?? '',
      vatNumber: (json['customer'] != null && json['customer']['taxId'] != null)
          ? json['customer']['taxId'].toString()
          : (json['vatNumber'] ?? json['vat_number'] ?? ''),
      contactName: json['contactPerson'] ?? json['contact_name'] ?? '',
      mobile: (json['customer'] != null && json['customer']['mobile'] != null)
          ? json['customer']['mobile'].toString()
          : (json['mobile'] ?? ''),
      email: json['email'] ?? '',
      creditLimit: double.tryParse(json['creditLimit']?.toString() ?? '0') ?? 0.0,
      dueBalance: double.tryParse(json['dueBalance']?.toString() ?? '0') ?? 0.0,
      selectedBranchIds: List<String>.from(json['selectedBranchIds'] ?? json['allowed_branch_ids'] ?? []),
      status: json['status'] ?? 'active',
      category: json['category'] ?? 'Bronze',
      totalSales: (json['total_sales'] ?? json['totalSales'] ?? 0.0).toDouble(),
      vehicleCount: json['vehicle_count'] ?? json['vehicleCount'] ?? 0,
      address: json['address'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
    );
  }
}

class MonthlyBill {
  final String id;
  final String corporateCustomerId;
  final String customerName;
  final int month;
  final int year;
  final double totalAmount;
  final double paidAmount;
  final DateTime dueDate;
  final String status; // 'Pending', 'Partially Paid', 'Paid', 'Overdue'
  final String? pdfUrl;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedCustomerName;
  final String? translatedStatus;

  MonthlyBill({
    required this.id,
    required this.corporateCustomerId,
    required this.customerName,
    required this.month,
    required this.year,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.dueDate,
    this.status = 'Pending',
    this.pdfUrl,
    this.translatedCustomerName,
    this.translatedStatus,
  });

  MonthlyBill copyWith({
    String? id,
    String? corporateCustomerId,
    String? customerName,
    int? month,
    int? year,
    double? totalAmount,
    double? paidAmount,
    DateTime? dueDate,
    String? status,
    String? pdfUrl,
    String? translatedCustomerName,
    String? translatedStatus,
  }) {
    return MonthlyBill(
      id: id ?? this.id,
      corporateCustomerId: corporateCustomerId ?? this.corporateCustomerId,
      customerName: customerName ?? this.customerName,
      month: month ?? this.month,
      year: year ?? this.year,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      translatedCustomerName: translatedCustomerName ?? this.translatedCustomerName,
      translatedStatus: translatedStatus ?? this.translatedStatus,
    );
  }

  factory MonthlyBill.fromJson(Map<String, dynamic> json) {
    int parsedMonth = 1;
    int parsedYear = 2026;

    final periodStr = json['billingPeriod']?.toString() ?? '';
    // Expected format: "Month: 2/2025"
    if (periodStr.contains('/')) {
      final parts = periodStr.replaceAll('Month:', '').trim().split('/');
      if (parts.length == 2) {
        parsedMonth = int.tryParse(parts[0]) ?? 1;
        parsedYear = int.tryParse(parts[1]) ?? 2026;
      }
    }

    // Capitalize status
    String statusStr = json['status']?.toString() ?? 'Pending';
    if (statusStr.isNotEmpty) {
      statusStr = statusStr[0].toUpperCase() + statusStr.substring(1);
    }

    return MonthlyBill(
      id: json['invoiceId']?.toString() ?? '',
      corporateCustomerId: '', // Not provided directly in this list API
      customerName: json['customerName'] ?? 'Unknown Customer',
      month: parsedMonth,
      year: parsedYear,
      totalAmount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: statusStr.toLowerCase() == 'paid' ? (double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0) : 0.0,
      dueDate: json['invoiceDate'] != null ? DateTime.tryParse(json['invoiceDate']) ?? DateTime.now() : DateTime.now(),
      status: statusStr,
    );
  }

  double get outstandingAmount => totalAmount - paidAmount;
}

class MonthlyBillPayment {
  final String id;
  final String billId;
  final double amount;
  final DateTime date;
  final String method; // 'Bank Transfer', 'Cash', 'Cheque', 'Online'
  final String? reference;
  final String? proofUrl;

  MonthlyBillPayment({
    required this.id,
    required this.billId,
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
    this.proofUrl,
  });
}

// ─── Supplier ───────────────────────────────────────
class Supplier {
  final String id;
  final String name;
  final String category;
  final String mobile;
  final String? email;
  final String? address;
  final String? vatNumber;
  final String? crNumber;
  final String? contactPerson;
  final double outstanding;
  final double openingBalance;
  final String status;

  Supplier({
    required this.id,
    required this.name,
    required this.category,
    required this.mobile,
    this.email,
    this.address,
    this.vatNumber,
    this.crNumber,
    this.contactPerson,
    this.outstanding = 0.0,
    this.openingBalance = 0.0,
    this.status = 'active',
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Parts', // Defaulting as category isn't in JSON
      mobile: json['mobile'] ?? '',
      email: json['email'],
      address: json['address'],
      vatNumber: json['vatNumber'], // Assuming it might be added later
      crNumber: json['crNumber'],
      contactPerson: json['contactPerson'],
      outstanding: double.tryParse(json['outstanding']?.toString() ?? '0') ?? 0.0,
      openingBalance: double.tryParse(json['openingBalance']?.toString() ?? '0') ?? 0.0,
      status: (json['isActive'] == true) ? 'active' : 'inactive',
    );
  }
}

class PurchaseItem {
  final String productName;
  final double qty;
  final String unit;
  final double unitPrice;
  double get total => qty * unitPrice;

  PurchaseItem({
    required this.productName,
    required this.qty,
    required this.unit,
    required this.unitPrice,
  });
}

class PurchaseInvoice {
  final String id;
  final String supplierId;
  final String supplierName;
  final DateTime date;
  final List<PurchaseItem> items;
  final String status; // 'pending', 'approved', 'rejected'
  final bool isInternal;

  PurchaseInvoice({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    required this.items,
    this.status = 'pending',
    this.isInternal = false,
  });

  double get totalAmount => items.fold(0, (sum, i) => sum + i.total);
}

// ─── POS Monitoring ────────────────────────────────
class PosCounter {
  final String id;
  final String cashierName;
  final String branchName;
  final String status;
  final double shiftSales;
  final int openOrders;
  final DateTime openedAt;
  final DateTime? closedAt;

  // Per-category system totals
  final double systemCash;
  final double systemBank;
  final double systemCorporate;
  final double systemTamara;
  final double systemTabby;
  final double systemOthers;
  final double systemTotalSales;

  // Per-category physical totals
  final double physicalCash;
  final double physicalBank;
  final double physicalCorporate;
  final double physicalTamara;
  final double physicalTabby;
  final double physicalOthers;

  // Per-category diffs (physical − system, same sign as DB)
  final double diffCash;
  final double diffBank;
  final double diffCorporate;
  final double diffTamara;
  final double diffTabby;
  final double diffOthers;

  // Overall reconciliation difference (system − physical)
  final double reconciliationTotalDifference;
  final String? closingId;
  final int schemaVersion; // closingReportSchemaVersion: 1 legacy, 2 full breakdown, 3 + start/end times

  // Backend-computed summary fields (v2+)
  final double systemSummary;    // json['system'] = systemTotalSales headline
  final double physicalSummary;  // json['physicalTotal'] = sum of all physical buckets
  final double lockerDiff;       // json['lockerDiff'] = system − physicalTotal

  /// ISO timestamp from [`startTime`]; same instant as [openedAt] when API sends schema v3+.
  final DateTime? startTime;

  /// Session/counter close instant; **null while shift is OPEN** (live counters).
  final DateTime? endTime;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedCashierName;
  final String? translatedBranchName;

  PosCounter({
    required this.id,
    required this.cashierName,
    required this.branchName,
    required this.status,
    required this.shiftSales,
    this.openOrders = 0,
    required this.openedAt,
    this.closedAt,
    this.startTime,
    this.endTime,
    this.systemCash = 0,
    this.systemBank = 0,
    this.systemCorporate = 0,
    this.systemTamara = 0,
    this.systemTabby = 0,
    this.systemOthers = 0,
    this.systemTotalSales = 0,
    this.physicalCash = 0,
    this.physicalBank = 0,
    this.physicalCorporate = 0,
    this.physicalTamara = 0,
    this.physicalTabby = 0,
    this.physicalOthers = 0,
    this.diffCash = 0,
    this.diffBank = 0,
    this.diffCorporate = 0,
    this.diffTamara = 0,
    this.diffTabby = 0,
    this.diffOthers = 0,
    this.reconciliationTotalDifference = 0,
    this.closingId,
    this.schemaVersion = 1,
    this.systemSummary = 0,
    this.physicalSummary = 0,
    this.lockerDiff = 0,
    this.translatedCashierName,
    this.translatedBranchName,
  });

  String get displayCashierName => translatedCashierName ?? cashierName;
  String get displayBranchName => translatedBranchName ?? branchName;

  PosCounter copyWith({
    String? translatedCashierName,
    String? translatedBranchName,
  }) {
    return PosCounter(
      id: id,
      cashierName: cashierName,
      branchName: branchName,
      status: status,
      shiftSales: shiftSales,
      openOrders: openOrders,
      openedAt: openedAt,
      closedAt: closedAt,
      startTime: startTime,
      endTime: endTime,
      systemCash: systemCash,
      systemBank: systemBank,
      systemCorporate: systemCorporate,
      systemTamara: systemTamara,
      systemTabby: systemTabby,
      systemOthers: systemOthers,
      systemTotalSales: systemTotalSales,
      physicalCash: physicalCash,
      physicalBank: physicalBank,
      physicalCorporate: physicalCorporate,
      physicalTamara: physicalTamara,
      physicalTabby: physicalTabby,
      physicalOthers: physicalOthers,
      diffCash: diffCash,
      diffBank: diffBank,
      diffCorporate: diffCorporate,
      diffTamara: diffTamara,
      diffTabby: diffTabby,
      diffOthers: diffOthers,
      reconciliationTotalDifference: reconciliationTotalDifference,
      closingId: closingId,
      schemaVersion: schemaVersion,
      systemSummary: systemSummary,
      physicalSummary: physicalSummary,
      lockerDiff: lockerDiff,
      translatedCashierName: translatedCashierName ?? this.translatedCashierName,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
    );
  }

  /// True when the backend returned the full v2 breakdown payload
  bool get isV2 => schemaVersion >= 2;

  /// Prefer explicit `startTime`, else legacy [`openedAt`].
  DateTime get sessionStart => startTime ?? openedAt;

  /// Prefer API [`endTime`], else legacy [`closedAt`] (OPEN shifts omit both ends).
  DateTime? get sessionEnd => endTime ?? closedAt;

  /// The single "SYSTEM" headline: prefer backend-computed summary, else sum of categories
  double get effectiveSystemTotal =>
      systemSummary > 0 ? systemSummary : systemTotalSales;

  /// The single "PHYSICAL" headline: prefer backend-computed total, else sum of categories
  double get effectivePhysicalTotal {
    if (physicalSummary > 0) return physicalSummary;
    return physicalCash + physicalBank + physicalCorporate + physicalTamara + physicalTabby + physicalOthers;
  }

  /// The single "DIFF" headline: prefer lockerDiff, else reconciliationTotalDifference
  double get effectiveDiff =>
      lockerDiff != 0 ? lockerDiff : reconciliationTotalDifference;

  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final p = DateTime.tryParse(s);
    if (p != null) return p;
    return null;
  }

  /// UTC instant from backend millis (preferred over parsing zoned ISO strings on the client).
  static DateTime? _fromEpochMs(dynamic v) {
    if (v == null) return null;
    final n = v is int ? v : int.tryParse(v.toString());
    if (n == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
  }

  factory PosCounter.fromJson(Map<String, dynamic> json) {
    final schemaVersion =
        int.tryParse(json['closingReportSchemaVersion']?.toString() ?? '1') ?? 1;

    final openEpoch = _fromEpochMs(json['openedAtEpochMs']);
    final closeEpoch = _fromEpochMs(json['closedAtEpochMs']);

    final startT = _parseDt(json['startTime']);
    final endT = _parseDt(json['endTime']);

    final legacyOpened =
    _parseDt(json['openedAt'] ??
        json['shiftStartedAt'] ??
        json['startedAt'] ??
        json['openTime']);
    final openedFinal = openEpoch ?? legacyOpened ?? startT ?? DateTime.now();

    final legacyClosed =
    _parseDt(json['closedAt'] ??
        json['shiftEndedAt'] ??
        json['endedAt'] ??
        json['closingTime']);

    final startResolved = openEpoch ?? startT;
    final endResolved = closeEpoch ?? endT;
    final closedResolved = closeEpoch ?? legacyClosed ?? endT;

    final sysCash = _d(json['systemCash']);
    final sysBank = _d(json['systemBank']);
    final sysCorp = _d(json['systemCorporate']);
    final sysTamara = _d(json['systemTamara']);
    final sysTabby = _d(json['systemTabby']);
    final sysOthers = _d(
        json['systemOthers'] ?? json['systemOthersTotal']);
    // v2: 'system' = systemTotalSales headline. v1 fallback: shiftSales
    final sysTotalSales = _d(
        json['systemTotalSales'] ?? json['system'] ?? json['shiftSales']);

    final phyCash = _d(json['physicalCash']);
    final phyBank = _d(json['physicalBank']);
    final phyCorp = _d(json['physicalCorporate']);
    final phyTamara = _d(json['physicalTamara']);
    final phyTabby = _d(json['physicalTabby']);
    final phyOthers = _d(
        json['physicalOthers'] ?? json['physical_others']);

    // v2 summary fields
    final systemSummary = _d(json['system'] ?? json['systemTotalSales']);
    final physicalSummary = _d(json['physicalTotal']);
    final lockerDiff = _d(json['lockerDiff']);

    // Per-category diffs: prefer explicit fields, fall back to computing
    final dCash = json['diffCash'] != null ? _d(json['diffCash']) : sysCash - phyCash;
    final dBank = json['diffBank'] != null ? _d(json['diffBank']) : sysBank - phyBank;
    final dCorp = json['diffCorporate'] != null ? _d(json['diffCorporate']) : sysCorp - phyCorp;
    final dTamara = json['diffTamara'] != null ? _d(json['diffTamara']) : sysTamara - phyTamara;
    final dTabby = json['diffTabby'] != null ? _d(json['diffTabby']) : sysTabby - phyTabby;
    final dOthers = json['diffOthers'] != null
        ? _d(json['diffOthers'])
        : json['othersDiff'] != null
        ? _d(json['othersDiff'])
        : sysOthers - phyOthers;

    // Prefer explicit reconciliation total, then lockerDiff, then compute
    final reconTotal = json['reconciliationTotalDifference'] != null
        ? _d(json['reconciliationTotalDifference'])
        : (json['lockerDiff'] != null
        ? _d(json['lockerDiff'])
        : dCash + dBank + dCorp + dTamara + dTabby + dOthers);

    return PosCounter(
      id: json['posSessionId']?.toString() ?? '',
      cashierName: json['cashierName'] ?? '',
      branchName: json['branchName'] ?? '',
      status: json['shiftStatus']?.toString().toLowerCase() ?? 'open',
      shiftSales: _d(json['shiftSales']),
      openOrders: int.tryParse(json['shiftOpenOrders']?.toString() ?? '0') ?? 0,
      openedAt: openedFinal,
      closedAt: closedResolved,
      startTime: startResolved,
      endTime: endResolved,
      systemCash: sysCash,
      systemBank: sysBank,
      systemCorporate: sysCorp,
      systemTamara: sysTamara,
      systemTabby: sysTabby,
      systemOthers: sysOthers,
      systemTotalSales: sysTotalSales,
      physicalCash: phyCash,
      physicalBank: phyBank,
      physicalCorporate: phyCorp,
      physicalTamara: phyTamara,
      physicalTabby: phyTabby,
      physicalOthers: phyOthers,
      diffCash: dCash,
      diffBank: dBank,
      diffCorporate: dCorp,
      diffTamara: dTamara,
      diffTabby: dTabby,
      diffOthers: dOthers,
      reconciliationTotalDifference: reconTotal,
      closingId: json['closingId']?.toString(),
      schemaVersion: schemaVersion,
      systemSummary: systemSummary,
      physicalSummary: physicalSummary,
      lockerDiff: lockerDiff,
    );
  }
}

/// Echo of UTC [`from`] / [`to`] (`YYYY-MM-DD`) when a filtered POS monitoring request succeeded.
class PosMonitoringDateRangeEcho {
  final String? from;
  final String? to;

  PosMonitoringDateRangeEcho({this.from, this.to});

  factory PosMonitoringDateRangeEcho.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return PosMonitoringDateRangeEcho();
    return PosMonitoringDateRangeEcho(
      from: json['from']?.toString(),
      to: json['to']?.toString(),
    );
  }
}

class PosMonitoringResponse {
  final bool success;
  final int liveCountersCount;
  final int openOrdersCount;
  final double todaySales;
  final List<PosCounter> liveCounters;
  final List<PosCounter> closingReports;

  /// Total invoice sales in UTC range when [`from`] / [`to`] query was sent (exclusive of unscoped todaySales semantics).
  final double? salesInDateRange;

  /// Present when backend echoes the applied UTC date filter strings.
  final PosMonitoringDateRangeEcho? dateRangeFilter;

  PosMonitoringResponse({
    required this.success,
    required this.liveCountersCount,
    required this.openOrdersCount,
    required this.todaySales,
    required this.liveCounters,
    required this.closingReports,
    this.salesInDateRange,
    this.dateRangeFilter,
  });

  factory PosMonitoringResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? rangeMap;
    final rawRange = json['dateRangeFilter'];
    if (rawRange is Map<String, dynamic>) {
      rangeMap = rawRange;
    } else if (rawRange is Map) {
      rangeMap = Map<String, dynamic>.from(rawRange);
    }

    return PosMonitoringResponse(
      success: json['success'] ?? false,
      liveCountersCount: int.tryParse(json['liveCountersCount']?.toString() ?? '0') ?? 0,
      openOrdersCount: int.tryParse(json['openOrdersCount']?.toString() ?? '0') ?? 0,
      todaySales: double.tryParse(json['todaySales']?.toString() ?? '0') ?? 0.0,
      liveCounters: (json['liveCounters'] as List?)
          ?.map((e) => PosCounter.fromJson(e))
          .toList() ??
          [],
      closingReports: (json['closingReports'] as List?)
          ?.map((e) => PosCounter.fromJson(e))
          .toList() ??
          [],
      salesInDateRange: json['salesInDateRange'] == null
          ? null
          : double.tryParse(json['salesInDateRange'].toString()),
      dateRangeFilter:
      rangeMap != null ? PosMonitoringDateRangeEcho.fromJson(rangeMap) : null,
    );
  }

  PosMonitoringResponse copyWith({
    List<PosCounter>? liveCounters,
    List<PosCounter>? closingReports,
  }) {
    return PosMonitoringResponse(
      success: success,
      liveCountersCount: liveCountersCount,
      openOrdersCount: openOrdersCount,
      todaySales: todaySales,
      liveCounters: liveCounters ?? this.liveCounters,
      closingReports: closingReports ?? this.closingReports,
      salesInDateRange: salesInDateRange,
      dateRangeFilter: dateRangeFilter,
    );
  }
}

// ─── Reports & Analytics ─────────────────────────────
class DailyRevenue {
  final String day;
  final String date;
  final double amount;

  DailyRevenue({required this.day, required this.date, required this.amount});

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      day: json['day'] ?? '',
      date: json['date'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class FinancialOverview {
  final double totalRevenue;
  final double revenueChangePercent;
  final List<DailyRevenue> dailyRevenue;

  FinancialOverview({
    required this.totalRevenue,
    required this.revenueChangePercent,
    required this.dailyRevenue,
  });

  factory FinancialOverview.fromJson(Map<String, dynamic> json) {
    return FinancialOverview(
      totalRevenue: double.tryParse(json['totalRevenue']?.toString() ?? '0') ?? 0.0,
      revenueChangePercent: double.tryParse(json['revenueChangePercent']?.toString() ?? '0') ?? 0.0,
      dailyRevenue: (json['dailyRevenue'] as List?)
          ?.map((e) => DailyRevenue.fromJson(e))
          .toList() ?? [],
    );
  }
}

class OperationalPerformance {
  final String employeeId;
  final String name;
  final int totalJobs;
  final double commission;

  OperationalPerformance({
    required this.employeeId,
    required this.name,
    required this.totalJobs,
    required this.commission,
  });

  factory OperationalPerformance.fromJson(Map<String, dynamic> json) {
    return OperationalPerformance(
      employeeId: json['employeeId']?.toString() ?? '',
      name: json['name'] ?? '',
      totalJobs: int.tryParse(json['totalJobs']?.toString() ?? '0') ?? 0,
      commission: double.tryParse(json['commission']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class InventoryValuation {
  final double stockValueCost;
  final double potentialProfit;
  final int activeSkus;

  InventoryValuation({
    required this.stockValueCost,
    required this.potentialProfit,
    required this.activeSkus,
  });

  factory InventoryValuation.fromJson(Map<String, dynamic> json) {
    return InventoryValuation(
      stockValueCost: double.tryParse(json['stockValueCost']?.toString() ?? '0') ?? 0.0,
      potentialProfit: double.tryParse(json['potentialProfit']?.toString() ?? '0') ?? 0.0,
      activeSkus: int.tryParse(json['activeSkus']?.toString() ?? '0') ?? 0,
    );
  }
}

class ReportsAnalyticsResponse {
  final FinancialOverview financialOverview;
  final List<OperationalPerformance> operationalPerformance;
  final InventoryValuation inventoryValuation;

  ReportsAnalyticsResponse({
    required this.financialOverview,
    required this.operationalPerformance,
    required this.inventoryValuation,
  });

  factory ReportsAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return ReportsAnalyticsResponse(
      financialOverview: FinancialOverview.fromJson(json['financialOverview'] ?? {}),
      operationalPerformance: (json['operationalPerformance'] as List?)
          ?.map((e) => OperationalPerformance.fromJson(e))
          .toList() ?? [],
      inventoryValuation: InventoryValuation.fromJson(json['inventoryValuation'] ?? {}),
    );
  }
}

// ─── Promo Codes ────────────────────────────────────
class PromoCode {
  final String id;
  final String workshopId;
  final String code;
  final String discountType;
  final double discountValue;
  final String validFrom;
  final String validTo;
  final int usageLimit;
  final int usageCount;
  final double minOrderAmount;
  final String description;
  final bool isActive;
  final String createdAt;

  PromoCode({
    required this.id,
    required this.workshopId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validTo,
    required this.usageLimit,
    required this.usageCount,
    required this.minOrderAmount,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id']?.toString() ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? '',
      discountValue: double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0.0,
      validFrom: json['validFrom'] ?? '',
      validTo: json['validTo'] ?? '',
      usageLimit: int.tryParse(json['usageLimit']?.toString() ?? '0') ?? 0,
      usageCount: int.tryParse(json['usageCount']?.toString() ?? '0') ?? 0,
      minOrderAmount: double.tryParse(json['minOrderAmount']?.toString() ?? '0') ?? 0.0,
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class PromoCodesResponse {
  final bool success;
  final int total;
  final int limit;
  final int offset;
  final List<PromoCode> promoCodes;

  PromoCodesResponse({
    required this.success,
    required this.total,
    required this.limit,
    required this.offset,
    required this.promoCodes,
  });

  factory PromoCodesResponse.fromJson(Map<String, dynamic> json) {
    return PromoCodesResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      promoCodes: (json['promoCodes'] as List?)
          ?.map((e) => PromoCode.fromJson(e))
          .toList() ?? [],
    );
  }
}

// ─── Approvals ─────────────────────────────────────
class OwnerApproval {
  final String id;
  final String type; // 'Expense', 'Payment', 'Advance', 'Locker', 'PurchaseInvoice', 'PhysicalCount'
  final String submittedBy;
  final String branchName;
  final double amount;
  final DateTime date;
  final String description;
  String status; // 'pending', 'approved', 'rejected'

  OwnerApproval({
    required this.id,
    required this.type,
    required this.submittedBy,
    required this.branchName,
    required this.amount,
    required this.date,
    required this.description,
    this.status = 'pending',
  });
}

// ─── Accounting ────────────────────────────────────
class AccountEntry {
  final String id;
  final String type; // 'payable', 'receivable', 'expense', 'payment', 'advance'
  final String party;
  final double amount;
  final DateTime date;
  final String reference;
  final String status; // 'pending', 'settled', 'overdue'
  final String? notes;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedParty;
  final String? translatedStatus;

  AccountEntry({
    required this.id,
    required this.type,
    required this.party,
    required this.amount,
    required this.date,
    required this.reference,
    required this.status,
    this.notes,
    this.translatedParty,
    this.translatedStatus,
  });

  AccountEntry copyWith({
    String? id,
    String? type,
    String? party,
    double? amount,
    DateTime? date,
    String? reference,
    String? status,
    String? notes,
    String? translatedParty,
    String? translatedStatus,
  }) {
    return AccountEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      party: party ?? this.party,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      translatedParty: translatedParty ?? this.translatedParty,
      translatedStatus: translatedStatus ?? this.translatedStatus,
    );
  }

  factory AccountEntry.fromJson(Map<String, dynamic> json) {
    return AccountEntry(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'payable',
      party: json['name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      reference: json['ref'] ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      notes: json['notes'],
    );
  }
}

// ─── Notifications ─────────────────────────────────
class OwnerNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'expense', 'invoice', 'stock', 'payment', 'locker'
  final DateTime timestamp;
  bool isRead;

  OwnerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

// ─── Dashboard ─────────────────────────────────────
class BranchPerformance {
  final String id;
  final String name;
  final String address;
  final double monthlySales;

  BranchPerformance({
    required this.id,
    required this.name,
    required this.address,
    required this.monthlySales,
  });

  factory BranchPerformance.fromJson(Map<String, dynamic> json) {
    return BranchPerformance(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      monthlySales: double.tryParse(
            (json['monthlySales'] ?? json['salesMTD'] ?? '0').toString()) ??
          0.0,
    );
  }
}

class OwnerDashboardResponse {
  final bool success;
  final String dataScope;
  final String dataScopeLabel;
  final String? branchId;
  final double totalSalesToday;
  final double purchaseCostToday;
  final double grossMarginProfit;
  final double totalSalesThisMonth;
  final int pendingInvoicesCount;
  final int lowStockAlertsCount;
  final List<BranchPerformance> branchPerformance;

  OwnerDashboardResponse({
    required this.success,
    required this.dataScope,
    required this.dataScopeLabel,
    this.branchId,
    required this.totalSalesToday,
    this.purchaseCostToday = 0,
    this.grossMarginProfit = 0,
    required this.totalSalesThisMonth,
    required this.pendingInvoicesCount,
    required this.lowStockAlertsCount,
    required this.branchPerformance,
  });

  factory OwnerDashboardResponse.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardResponse(
      success: json['success'] ?? false,
      dataScope: json['dataScope'] ?? '',
      dataScopeLabel: json['dataScopeLabel'] ?? '',
      branchId: json['branchId']?.toString(),
      totalSalesToday: double.tryParse(json['totalSalesToday']?.toString() ?? '0') ?? 0.0,
      purchaseCostToday:
          double.tryParse(json['purchaseCostToday']?.toString() ?? '0') ?? 0.0,
      grossMarginProfit:
          double.tryParse(json['grossMarginProfit']?.toString() ?? '0') ?? 0.0,
      totalSalesThisMonth: double.tryParse(json['totalSalesThisMonth']?.toString() ?? '0') ?? 0.0,
      pendingInvoicesCount: int.tryParse(json['pendingInvoicesCount']?.toString() ?? '0') ?? 0,
      lowStockAlertsCount: int.tryParse(json['lowStockAlertsCount']?.toString() ?? '0') ?? 0,
      branchPerformance: ((json['branchPerformance'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => BranchPerformance.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// ─── Supplier Stats ────────────────────────────────
class SupplierStatsResponse {
  final bool success;
  final int totalSuppliers;
  final double totalOutstanding;
  final int pendingPurchaseOrders;
  final String currencyCode;

  SupplierStatsResponse({
    required this.success,
    required this.totalSuppliers,
    required this.totalOutstanding,
    required this.pendingPurchaseOrders,
    required this.currencyCode,
  });

  factory SupplierStatsResponse.fromJson(Map<String, dynamic> json) {
    return SupplierStatsResponse(
      success: json['success'] ?? false,
      totalSuppliers: json['totalSuppliers'] ?? 0,
      totalOutstanding: double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      pendingPurchaseOrders: json['pendingPurchaseOrders'] ?? 0,
      currencyCode: json['currencyCode'] ?? 'SAR',
    );
  }
}

class AccountingSummary {
  final double payables;
  final double receivables;
  final double overdue;

  AccountingSummary({
    required this.payables,
    required this.receivables,
    required this.overdue,
  });

  factory AccountingSummary.fromJson(Map<String, dynamic> json) {
    return AccountingSummary(
      payables: double.tryParse(json['payables']?.toString() ?? '0') ?? 0.0,
      receivables: double.tryParse(json['receivables']?.toString() ?? '0') ?? 0.0,
      overdue: double.tryParse(json['overdue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AccountingSummaryResponse {
  final bool success;
  final String currency;
  final AccountingSummary summary;

  AccountingSummaryResponse({
    required this.success,
    required this.currency,
    required this.summary,
  });

  factory AccountingSummaryResponse.fromJson(Map<String, dynamic> json) {
    return AccountingSummaryResponse(
      success: json['success'] ?? false,
      currency: json['currency'] ?? 'SAR',
      summary: json['summary'] != null
          ? AccountingSummary.fromJson(json['summary'])
          : AccountingSummary(payables: 0, receivables: 0, overdue: 0),
    );
  }
}

class PettyCashRequestItem {
  final String id;
  final double amount;
  final String reason;
  final String status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String branchId;
  final String branchName;
  final String cashierId;
  final String cashierName;
  final String? approvedBy;
  /// `fund_request` | `expense` (workshop petty-cash queue).
  final String? kind;
  final String? categoryLabel;
  final String? employeeName;
  final String? proofUrl;
  final String? payFrom;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedPartyName;
  final String? translatedBranchName;
  final String? translatedCashierName;
  final String? translatedStatus;

  /// Alias used by ApprovalsViewModel for the request party name.
  /// Falls back to [cashierName] since petty-cash requests have no separate
  /// party — the cashier is the requesting party.
  String? get partyName => cashierName.isNotEmpty ? cashierName : null;

  PettyCashRequestItem({
    required this.id,
    required this.amount,
    required this.reason,
    required this.status,
    this.requestedAt,
    this.approvedAt,
    this.rejectionReason,
    required this.branchId,
    required this.branchName,
    required this.cashierId,
    required this.cashierName,
    this.approvedBy,
    this.kind,
    this.categoryLabel,
    this.employeeName,
    this.proofUrl,
    this.payFrom,
    this.translatedPartyName,
    this.translatedBranchName,
    this.translatedCashierName,
    this.translatedStatus,
  });

  PettyCashRequestItem copyWith({
    String? id,
    double? amount,
    String? reason,
    String? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    String? rejectionReason,
    String? branchId,
    String? branchName,
    String? cashierId,
    String? cashierName,
    String? approvedBy,
    String? kind,
    String? categoryLabel,
    String? employeeName,
    String? proofUrl,
    String? payFrom,
    String? translatedPartyName,
    String? translatedBranchName,
    String? translatedCashierName,
    String? translatedStatus,
  }) {
    return PettyCashRequestItem(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      approvedBy: approvedBy ?? this.approvedBy,
      kind: kind ?? this.kind,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      employeeName: employeeName ?? this.employeeName,
      proofUrl: proofUrl ?? this.proofUrl,
      payFrom: payFrom ?? this.payFrom,
      translatedPartyName: translatedPartyName ?? this.translatedPartyName,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
      translatedCashierName: translatedCashierName ?? this.translatedCashierName,
      translatedStatus: translatedStatus ?? this.translatedStatus,
    );
  }

  bool get isExpenseKind {
    final k = kind?.toLowerCase() ?? '';
    return k == 'expense';
  }

  factory PettyCashRequestItem.fromJson(Map<String, dynamic> json) {
    final branch = (json['branch'] as Map<String, dynamic>?) ?? {};
    final cashier = (json['cashier'] as Map<String, dynamic>?) ?? {};

    String? categoryLabel;
    final cat = json['category'];
    if (cat is Map<String, dynamic>) {
      categoryLabel = cat['name']?.toString() ?? cat['id']?.toString();
    } else if (cat is String) {
      categoryLabel = cat;
    }

    String? employeeName;
    final emp = json['employee'];
    if (emp is Map<String, dynamic>) {
      employeeName = emp['name']?.toString() ?? emp['fullName']?.toString();
    } else {
      employeeName = json['employeeName']?.toString();
    }

    final reasonText = json['reason']?.toString() ??
        json['description']?.toString() ??
        json['notes']?.toString() ??
        '';

    return PettyCashRequestItem(
      id: json['id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      reason: reasonText,
      status: json['status']?.toString() ?? 'pending',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
      branchId: branch['id']?.toString() ?? json['branchId']?.toString() ?? '',
      branchName: branch['name']?.toString() ?? 'Unknown Branch',
      cashierId: cashier['id']?.toString() ?? '',
      cashierName: cashier['name']?.toString() ?? 'Unknown Cashier',
      approvedBy: json['approvedBy']?.toString(),
      kind: json['kind']?.toString(),
      categoryLabel: categoryLabel,
      employeeName: employeeName,
      proofUrl: json['proofUrl']?.toString() ?? json['proof']?.toString(),
      payFrom: json['payFrom']?.toString(),
    );
  }
}

class PettyCashRequestsResponse {
  final bool success;
  final String currency;
  final int total;
  final int limit;
  final int offset;
  final List<PettyCashRequestItem> requests;

  PettyCashRequestsResponse({
    required this.success,
    required this.currency,
    required this.total,
    required this.limit,
    required this.offset,
    required this.requests,
  });

  factory PettyCashRequestsResponse.fromJson(Map<String, dynamic> json) {
    return PettyCashRequestsResponse(
      success: json['success'] == true,
      currency: json['currency']?.toString() ?? 'SAR',
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      offset: int.tryParse(json['offset']?.toString() ?? '0') ?? 0,
      requests: ((json['requests'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PettyCashRequestItem.fromJson)
          .toList(),
    );
  }


}

// ─────────────────────────────────────────────────────────────────────────────
// PASTE THESE CLASSES INTO workshop_owner_models.dart
// ─────────────────────────────────────────────────────────────────────────────

// ── MobileDashboard ──────────────────────────────────────────────────────────

class MobileDashboardSummary {
  final double totalSalesToday;
  final double purchaseCostToday;
  final double grossMarginProfit;
  final double totalSalesThisMonth;
  final int pendingInvoicesCount;
  final int lowStockAlertsCount;
  final int pendingApprovalsCount;

  const MobileDashboardSummary({
    required this.totalSalesToday,
    required this.purchaseCostToday,
    required this.grossMarginProfit,
    required this.totalSalesThisMonth,
    required this.pendingInvoicesCount,
    required this.lowStockAlertsCount,
    required this.pendingApprovalsCount,
  });

  factory MobileDashboardSummary.fromJson(Map<String, dynamic> json) {
    return MobileDashboardSummary(
      totalSalesToday: _d(json['totalSalesToday']),
      purchaseCostToday: _d(json['purchaseCostToday']),
      grossMarginProfit: _d(json['grossMarginProfit']),
      totalSalesThisMonth: _d(json['totalSalesThisMonth']),
      pendingInvoicesCount: _i(json['pendingInvoicesCount']),
      lowStockAlertsCount: _i(json['lowStockAlertsCount']),
      pendingApprovalsCount: _i(json['pendingApprovalsCount']),
    );
  }

  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;
  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  MobileDashboardSummary copyWith({
    double? totalSalesToday,
    double? purchaseCostToday,
    double? grossMarginProfit,
    double? totalSalesThisMonth,
    int? pendingInvoicesCount,
    int? lowStockAlertsCount,
    int? pendingApprovalsCount,
  }) =>
      MobileDashboardSummary(
        totalSalesToday: totalSalesToday ?? this.totalSalesToday,
        purchaseCostToday: purchaseCostToday ?? this.purchaseCostToday,
        grossMarginProfit: grossMarginProfit ?? this.grossMarginProfit,
        totalSalesThisMonth: totalSalesThisMonth ?? this.totalSalesThisMonth,
        pendingInvoicesCount:
        pendingInvoicesCount ?? this.pendingInvoicesCount,
        lowStockAlertsCount: lowStockAlertsCount ?? this.lowStockAlertsCount,
        pendingApprovalsCount:
        pendingApprovalsCount ?? this.pendingApprovalsCount,
      );
}

class DashboardTechnicianSlots {
  final int total;
  final int active;
  final int available;

  const DashboardTechnicianSlots({
    required this.total,
    required this.active,
    required this.available,
  });

  factory DashboardTechnicianSlots.fromJson(Map<String, dynamic> json) {
    return DashboardTechnicianSlots(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      active: int.tryParse(json['active']?.toString() ?? '0') ?? 0,
      available: int.tryParse(json['available']?.toString() ?? '0') ?? 0,
    );
  }
}

class DashboardTechnicianDepartment {
  final String id;
  final String name;

  /// Translated display field — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;

  const DashboardTechnicianDepartment({
    required this.id,
    required this.name,
    this.translatedName,
  });

  String get displayName => translatedName ?? name;

  DashboardTechnicianDepartment copyWith({
    String? id,
    String? name,
    String? translatedName,
  }) {
    return DashboardTechnicianDepartment(
      id: id ?? this.id,
      name: name ?? this.name,
      translatedName: translatedName ?? this.translatedName,
    );
  }

  factory DashboardTechnicianDepartment.fromJson(Map<String, dynamic> json) {
    return DashboardTechnicianDepartment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class DashboardTechnician {
  final String id;
  final String name;
  final String mobile;
  final String branchId;
  final String branchName;
  final String technicianType; // 'workshop' | 'oncall' | 'both'
  final String onlineStatus; // 'online' | 'offline'
  final DateTime? lastSeenAt;
  final DashboardTechnicianSlots slots;
  final List<DashboardTechnicianDepartment> departments;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedBranchName;

  bool get isOnline => onlineStatus == 'online';

  String get displayName => translatedName ?? name;
  String get displayBranchName => translatedBranchName ?? branchName;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get techTypeLabel {
    switch (technicianType) {
      case 'workshop':
        return 'Workshop';
      case 'oncall':
        return 'On-Call';
      case 'both':
        return 'Workshop + On-Call';
      default:
        return technicianType;
    }
  }

  const DashboardTechnician({
    required this.id,
    required this.name,
    required this.mobile,
    required this.branchId,
    required this.branchName,
    required this.technicianType,
    required this.onlineStatus,
    this.lastSeenAt,
    required this.slots,
    required this.departments,
    this.translatedName,
    this.translatedBranchName,
  });

  DashboardTechnician copyWith({
    String? id,
    String? name,
    String? mobile,
    String? branchId,
    String? branchName,
    String? technicianType,
    String? onlineStatus,
    DateTime? lastSeenAt,
    DashboardTechnicianSlots? slots,
    List<DashboardTechnicianDepartment>? departments,
    String? translatedName,
    String? translatedBranchName,
  }) {
    return DashboardTechnician(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      technicianType: technicianType ?? this.technicianType,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      slots: slots ?? this.slots,
      departments: departments ?? this.departments,
      translatedName: translatedName ?? this.translatedName,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
    );
  }

  factory DashboardTechnician.fromJson(Map<String, dynamic> json) {
    return DashboardTechnician(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      technicianType: json['technicianType']?.toString() ?? 'workshop',
      onlineStatus: json['onlineStatus']?.toString() ?? 'offline',
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      slots: json['slots'] != null
          ? DashboardTechnicianSlots.fromJson(
          json['slots'] as Map<String, dynamic>)
          : const DashboardTechnicianSlots(
          total: 0, active: 0, available: 0),
      departments: ((json['departments'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardTechnicianDepartment.fromJson)
          .toList(),
    );
  }
}

class DashboardTechniciansSection {
  final int total;
  final int showing;
  final List<DashboardTechnician> items;

  const DashboardTechniciansSection({
    required this.total,
    required this.showing,
    required this.items,
  });

  factory DashboardTechniciansSection.fromJson(Map<String, dynamic> json) {
    return DashboardTechniciansSection(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      showing: int.tryParse(json['showing']?.toString() ?? '0') ?? 0,
      items: ((json['items'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardTechnician.fromJson)
          .toList(),
    );
  }
}

class DashboardLowStockItem {
  final String id;
  final String name;
  final double stockQty;
  final double criticalLevel;
  final String unit;
  final String? branchName;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedBranchName;

  const DashboardLowStockItem({
    required this.id,
    required this.name,
    required this.stockQty,
    required this.criticalLevel,
    required this.unit,
    this.branchName,
    this.translatedName,
    this.translatedBranchName,
  });

  /// Display-ready name — falls back to the raw API value.
  String get displayName => translatedName ?? name;

  /// Display-ready branch name — falls back to the raw API value.
  String? get displayBranchName => translatedBranchName ?? branchName;

  DashboardLowStockItem copyWith({
    String? id,
    String? name,
    double? stockQty,
    double? criticalLevel,
    String? unit,
    String? branchName,
    String? translatedName,
    String? translatedBranchName,
  }) {
    return DashboardLowStockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      stockQty: stockQty ?? this.stockQty,
      criticalLevel: criticalLevel ?? this.criticalLevel,
      unit: unit ?? this.unit,
      branchName: branchName ?? this.branchName,
      translatedName: translatedName ?? this.translatedName,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
    );
  }

  factory DashboardLowStockItem.fromJson(Map<String, dynamic> json) {
    return DashboardLowStockItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['productName']?.toString() ??
          '',
      stockQty: double.tryParse(
            json['stockQty']?.toString() ??
                json['currentQty']?.toString() ??
                json['qty']?.toString() ??
                '0',
          ) ??
          0.0,
      criticalLevel: double.tryParse(
            json['criticalLevel']?.toString() ??
                json['criticalStockPoint']?.toString() ??
                '0',
          ) ??
          0.0,
      unit: json['unit']?.toString() ??
          json['workshopUnit']?.toString() ??
          'pcs',
      branchName: json['branchName']?.toString() ??
          json['branch']?.toString(),
    );
  }
}

class DashboardLowStockSection {
  final int total;
  final int showing;
  final List<DashboardLowStockItem> items;

  const DashboardLowStockSection({
    required this.total,
    required this.showing,
    required this.items,
  });

  factory DashboardLowStockSection.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ??
        (json['products'] as List?) ??
        const [];
    final parsed = <DashboardLowStockItem>[];
    for (final e in rawItems) {
      if (e is Map) {
        parsed.add(
          DashboardLowStockItem.fromJson(Map<String, dynamic>.from(e)),
        );
      }
    }
    final total = int.tryParse(json['total']?.toString() ?? '0') ?? parsed.length;
    final showing =
        int.tryParse(json['showing']?.toString() ?? '0') ?? parsed.length;
    return DashboardLowStockSection(
      total: total > 0 ? total : parsed.length,
      showing: showing > 0 ? showing : parsed.length,
      items: parsed,
    );
  }
}

class DashboardBranchPerformanceItem {
  final String id;
  final String name;
  final String address;
  final double monthlySales;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedAddress;

  const DashboardBranchPerformanceItem({
    required this.id,
    required this.name,
    required this.address,
    required this.monthlySales,
    this.translatedName,
    this.translatedAddress,
  });

  String get displayName => translatedName ?? name;
  String get displayAddress => translatedAddress ?? address;

  DashboardBranchPerformanceItem copyWith({
    String? id,
    String? name,
    String? address,
    double? monthlySales,
    String? translatedName,
    String? translatedAddress,
  }) {
    return DashboardBranchPerformanceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      monthlySales: monthlySales ?? this.monthlySales,
      translatedName: translatedName ?? this.translatedName,
      translatedAddress: translatedAddress ?? this.translatedAddress,
    );
  }

  factory DashboardBranchPerformanceItem.fromJson(
      Map<String, dynamic> json) {
    return DashboardBranchPerformanceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      monthlySales:
      double.tryParse(json['monthlySales']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class MobileDashboardResponse {
  final bool success;
  final String currency;
  final String dataScope;
  final String dataScopeLabel;
  final String? branchId;
  final MobileDashboardSummary summary;
  final DashboardTechniciansSection technicians;
  final DashboardLowStockSection lowStock;
  final List<DashboardBranchPerformanceItem> branchPerformance;

  const MobileDashboardResponse({
    required this.success,
    required this.currency,
    required this.dataScope,
    required this.dataScopeLabel,
    this.branchId,
    required this.summary,
    required this.technicians,
    required this.lowStock,
    required this.branchPerformance,
  });

  factory MobileDashboardResponse.fromJson(Map<String, dynamic> json) {
    return MobileDashboardResponse(
      success: json['success'] == true,
      currency: json['currency']?.toString() ?? 'SAR',
      dataScope: json['dataScope']?.toString() ?? '',
      dataScopeLabel: json['dataScopeLabel']?.toString() ?? '',
      branchId: json['branchId']?.toString(),
      summary: json['summary'] != null
          ? MobileDashboardSummary.fromJson(
          json['summary'] as Map<String, dynamic>)
          : MobileDashboardSummary(
        totalSalesToday: 0,
        purchaseCostToday: 0,
        grossMarginProfit: 0,
        totalSalesThisMonth: 0,
        pendingInvoicesCount: 0,
        lowStockAlertsCount: 0,
        pendingApprovalsCount: 0,
      ),
      technicians: json['technicians'] != null
          ? DashboardTechniciansSection.fromJson(
          json['technicians'] as Map<String, dynamic>)
          : const DashboardTechniciansSection(
          total: 0, showing: 0, items: []),
      lowStock: json['lowStock'] != null
          ? DashboardLowStockSection.fromJson(
          json['lowStock'] as Map<String, dynamic>)
          : const DashboardLowStockSection(
          total: 0, showing: 0, items: []),
      branchPerformance: ((json['branchPerformance'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardBranchPerformanceItem.fromJson)
          .toList(),
    );
  }
}

// ─── catalog_models.dart ──────────────────────────────────────────────────────
// Strongly-typed models that map 1-to-1 with the real API JSON payloads used
// by the Branch Catalog screen (departments, products, services, categories,
// branches, product-units endpoints).

// ─── Branch ───────────────────────────────────────────────────────────────────

class CatalogBranch {
  final String id;
  final String workshopId;
  final String name;
  final String? branchCode;
  final String address;
  final double? gpsLat;
  final double? gpsLng;
  final String contactPerson;
  final String phone;
  final String email;
  final String? vatId;
  final String crNumber;
  final bool isActive;
  final String status;

  const CatalogBranch({
    required this.id,
    required this.workshopId,
    required this.name,
    this.branchCode,
    required this.address,
    this.gpsLat,
    this.gpsLng,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.vatId,
    required this.crNumber,
    required this.isActive,
    required this.status,
  });

  factory CatalogBranch.fromJson(Map<String, dynamic> json) {
    return CatalogBranch(
      id: json['id']?.toString() ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchCode: json['branchCode']?.toString(),
      address: json['address']?.toString() ?? '',
      gpsLat: double.tryParse(json['gpsLat']?.toString() ?? ''),
      gpsLng: double.tryParse(json['gpsLng']?.toString() ?? ''),
      contactPerson: json['contactPerson']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      vatId: json['vatId']?.toString(),
      crNumber: json['crNumber']?.toString() ?? '',
      isActive: json['isActive'] == true,
      status: json['status']?.toString() ?? 'active',
    );
  }
}

// ─── Department ───────────────────────────────────────────────────────────────

class CatalogBranchRef {
  final String id;
  final String name;

  const CatalogBranchRef({required this.id, required this.name});

  factory CatalogBranchRef.fromJson(Map<String, dynamic> json) =>
      CatalogBranchRef(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class CatalogDepartmentModel {
  final String id;
  final String name;
  final bool isActive;
  final List<CatalogBranchRef> branches;
  final List<String> branchNames;

  const CatalogDepartmentModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.branches,
    required this.branchNames,
  });

  factory CatalogDepartmentModel.fromJson(Map<String, dynamic> json) {
    return CatalogDepartmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
      branches: ((json['branches'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogBranchRef.fromJson)
          .toList(),
      branchNames: List<String>.from(json['branchNames'] ?? []),
    );
  }
}

// ─── Category ─────────────────────────────────────────────────────────────────

class CatalogCategoryModel {
  final String id;
  final String name;
  final String type; // 'product' | 'service'
  final String departmentId;
  final String departmentName;
  final bool isActive;
  final List<CatalogBranchRef> branches;
  final List<String> branchNames;

  const CatalogCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.departmentId,
    required this.departmentName,
    required this.isActive,
    required this.branches,
    required this.branchNames,
  });

  factory CatalogCategoryModel.fromJson(Map<String, dynamic> json) {
    return CatalogCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'product',
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      isActive: json['isActive'] == true,
      branches: ((json['branches'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogBranchRef.fromJson)
          .toList(),
      branchNames: List<String>.from(json['branchNames'] ?? []),
    );
  }
}


List<String> _parseCatalogStringList(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }
  return const [];
}

List<CatalogBranchModel> _parseCatalogBranches(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(CatalogBranchModel.fromJson)
        .toList();
  }
  return const [];
}

// ─── Product (inside products response categories) ────────────────────────────

class CatalogProductModel {
  final String workshopProductId;
  final String id;
  final String name;
  final String arabicName;
  final String unit;
  final String sku;
  final String brandName;
  final double purchasePrice;
  final double salePrice;
  final double salePriceBeforeVat;
  final double minPriceCorporate;
  final double maxPriceCorporate;
  final double openingQty;
  final double criticalStockPoint;
  final double qtyOnHand;
  final double currentQty;
  final bool allowDecimalQty;
  final bool isActive;
  final String departmentId;
  final String departmentName;
  final String categoryId;
  final String categoryName;
  final String? subCategoryId;
  final String? subCategoryName;
  final List<CatalogBranchModel> branches;
  final List<String> branchNames;

  bool get isLowStock => currentQty <= criticalStockPoint;

  String get branchDisplayName {
    if (branchNames.isNotEmpty) return branchNames.join(', ');

    final names = branches
        .map((b) => b.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (names.isNotEmpty) return names.join(', ');
    return 'All Branches';
  }

  const CatalogProductModel({
    this.workshopProductId = '',
    required this.id,
    required this.name,
    this.arabicName = '',
    this.unit = 'pcs',
    this.sku = '',
    this.brandName = '',
    required this.purchasePrice,
    required this.salePrice,
    required this.salePriceBeforeVat,
    required this.minPriceCorporate,
    required this.maxPriceCorporate,
    required this.openingQty,
    required this.criticalStockPoint,
    required this.qtyOnHand,
    required this.currentQty,
    required this.allowDecimalQty,
    required this.isActive,
    required this.departmentId,
    required this.departmentName,
    required this.categoryId,
    required this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.branches = const [],
    this.branchNames = const [],
  });

  factory CatalogProductModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

    return CatalogProductModel(
      workshopProductId: json['workshopProductId']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      arabicName: (json['arabicName'] ?? json['productNameArabic'] ?? '').toString(),
      unit: (json['unit'] ?? json['unitOfMeasurement'] ?? 'pcs').toString(),
      sku: json['sku']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      purchasePrice: d(json['purchasePrice']),
      salePrice: d(json['salePrice'] ?? json['sellingPrice']),
      salePriceBeforeVat: d(json['salePriceBeforeVat'] ?? json['sale_price_before_vat']),
      minPriceCorporate: d(json['minPriceCorporate']),
      maxPriceCorporate: d(json['maxPriceCorporate']),
      openingQty: d(json['openingQty']),
      criticalStockPoint: d(json['criticalStockPoint']),
      qtyOnHand: d(json['qtyOnHand'] ?? json['openingQty']),
      currentQty: d(json['currentQty'] ?? json['openingQty']),
      allowDecimalQty: json['allowDecimalQty'] == true,
      isActive: json['isActive'] != false,
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      subCategoryId: json['subCategoryId']?.toString(),
      subCategoryName: json['subCategoryName']?.toString(),
      branches: _parseCatalogBranches(json['branches']),
      branchNames: _parseCatalogStringList(json['branchNames']),
    );
  }
}

/// Top-level shape of the products response:
/// { success, workshopId, categories: [ { id, name, type, subCategories, productsWithoutSub } ] }
class CatalogProductCategory {
  final String id;
  final String name;
  final String type;
  final List<CatalogProductModel> products; // productsWithoutSub flattened

  const CatalogProductCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.products,
  });

  factory CatalogProductCategory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawProducts =
        (json['productsWithoutSub'] as List?) ??
            (json['products'] as List?) ??
            [];
    return CatalogProductCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'product',
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(CatalogProductModel.fromJson)
          .toList(),
    );
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

class CatalogServiceResponse {
  final bool success;
  final List<CatalogServiceModel> services;

  const CatalogServiceResponse({
    required this.success,
    required this.services,
  });

  factory CatalogServiceResponse.fromJson(Map<String, dynamic> json) {
    return CatalogServiceResponse(
      success: json['success'] == true,
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => CatalogServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CatalogServiceModel {
  final String workshopServiceId;
  final String id;
  final String name;
  final String arabicName;
  final String sku;
  final String? description;
  final String unitOfMeasurement;

  final double? sellingPrice;
  final double? sellingPriceBeforeVat;
  final bool isPriceEditable;
  final bool isActive;

  final String departmentId;
  final String departmentName;
  final String categoryId;
  final String categoryName;

  final List<CatalogBranchModel> branches;
  final List<String> branchNames;

  const CatalogServiceModel({
    required this.workshopServiceId,
    required this.id,
    required this.name,
    required this.arabicName,
    required this.sku,
    this.description,
    required this.unitOfMeasurement,
    this.sellingPrice,
    this.sellingPriceBeforeVat,
    required this.isPriceEditable,
    required this.isActive,
    required this.departmentId,
    required this.departmentName,
    required this.categoryId,
    required this.categoryName,
    this.branches = const [],
    this.branchNames = const [],
  });

  factory CatalogServiceModel.fromJson(Map<String, dynamic> json) {
    double? dOpt(dynamic v) {
      if (v == null || v.toString() == 'null') return null;
      return double.tryParse(v.toString());
    }

    return CatalogServiceModel(
      workshopServiceId: json['workshopServiceId']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      arabicName: json['arabicName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      description: json['description']?.toString(),
      unitOfMeasurement: json['unitOfMeasurement']?.toString() ?? '',

      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',

      sellingPrice: dOpt(json['sellingPrice']),
      sellingPriceBeforeVat: dOpt(
        json['sellingPriceBeforeVat'] ?? json['selling_price_before_vat'],
      ),

      isPriceEditable: json['isPriceEditable'] == true,
      isActive: json['isActive'] == true,

      branches: (json['branches'] as List<dynamic>? ?? [])
          .map((e) => CatalogBranchModel.fromJson(e as Map<String, dynamic>))
          .toList(),

      branchNames: (json['branchNames'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  String get branchDisplayName {
    if (branchNames.isNotEmpty) {
      return branchNames.join(', ');
    }

    if (branches.isNotEmpty) {
      return branches
          .map((b) => b.name)
          .where((name) => name.isNotEmpty)
          .join(', ');
    }

    return 'All Branches';
  }
}

class CatalogBranchModel {
  final String id;
  final String name;

  const CatalogBranchModel({
    required this.id,
    required this.name,
  });

  factory CatalogBranchModel.fromJson(Map<String, dynamic> json) {
    return CatalogBranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
/// Top-level shape of the services response:
/// { success, workshopId, categories: [ { id, name, type, subCategories, servicesWithoutSub } ] }
class CatalogServiceCategory {
  final String id;
  final String name;
  final String type;
  final List<CatalogServiceModel> services; // servicesWithoutSub flattened

  const CatalogServiceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.services,
  });

  factory CatalogServiceCategory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawServices =
        (json['servicesWithoutSub'] as List?) ??
            (json['services'] as List?) ??
            [];
    return CatalogServiceCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'service',
      services: rawServices
          .whereType<Map<String, dynamic>>()
          .map(CatalogServiceModel.fromJson)
          .toList(),
    );
  }
}

// ─── Aggregate response wrappers ──────────────────────────────────────────────

class BranchesResponse {
  final bool success;
  final List<CatalogBranch> branches;

  const BranchesResponse({required this.success, required this.branches});

  factory BranchesResponse.fromJson(Map<String, dynamic> json) {
    return BranchesResponse(
      success: json['success'] == true,
      branches: ((json['branches'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogBranch.fromJson)
          .toList(),
    );
  }
}

class DepartmentsResponse {
  final bool success;
  final List<CatalogDepartmentModel> departments;

  const DepartmentsResponse(
      {required this.success, required this.departments});

  factory DepartmentsResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentsResponse(
      success: json['success'] == true,
      departments: ((json['departments'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogDepartmentModel.fromJson)
          .toList(),
    );
  }
}

class CategoriesResponse {
  final bool success;
  final List<CatalogCategoryModel> categories;

  const CategoriesResponse({required this.success, required this.categories});

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(
      success: json['success'] == true,
      categories: ((json['categories'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogCategoryModel.fromJson)
          .toList(),
    );
  }
}

class ProductsResponse {
  final bool success;
  final String workshopId;
  final List<CatalogProductCategory> categories;
  final List<CatalogProductModel> products;

  /// Flat list of all products. Supports both API shapes:
  /// 1) { products: [...] }
  /// 2) { categories: [{ productsWithoutSub: [...] }] }
  List<CatalogProductModel> get allProducts {
    if (products.isNotEmpty) return products;
    return categories.expand((c) => c.products).toList();
  }

  const ProductsResponse({
    required this.success,
    required this.workshopId,
    this.categories = const [],
    this.products = const [],
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      success: json['success'] == true,
      workshopId: json['workshopId']?.toString() ?? '',
      products: ((json['products'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogProductModel.fromJson)
          .toList(),
      categories: ((json['categories'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogProductCategory.fromJson)
          .toList(),
    );
  }
}

class ServicesResponse {
  final bool success;
  final String workshopId;
  final List<CatalogServiceCategory> categories;
  final List<CatalogServiceModel> services;

  /// Flat list of all services. Supports both API shapes:
  /// 1) { services: [...] }
  /// 2) { categories: [{ servicesWithoutSub: [...] }] }
  List<CatalogServiceModel> get allServices {
    if (services.isNotEmpty) return services;
    return categories.expand((c) => c.services).toList();
  }

  const ServicesResponse({
    required this.success,
    required this.workshopId,
    this.categories = const [],
    this.services = const [],
  });

  factory ServicesResponse.fromJson(Map<String, dynamic> json) {
    return ServicesResponse(
      success: json['success'] == true,
      workshopId: json['workshopId']?.toString() ?? '',
      services: ((json['services'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogServiceModel.fromJson)
          .toList(),
      categories: ((json['categories'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogServiceCategory.fromJson)
          .toList(),
    );
  }
}

class ProductUnitsResponse {
  final bool success;
  final List<String> units;
  final String defaultUnit;

  const ProductUnitsResponse({
    required this.success,
    required this.units,
    required this.defaultUnit,
  });

  factory ProductUnitsResponse.fromJson(Map<String, dynamic> json) {
    return ProductUnitsResponse(
      success: json['success'] == true,
      units: List<String>.from(json['units'] ?? []),
      defaultUnit: json['defaultUnit']?.toString() ?? 'pcs',
    );
  }
}

// ─── ActiveTechnicianItem ─────────────────────────────────────────────────────
// Returned by GET /workshop-staff/technicians?isActive=true.
// Used as a fallback data source for the dashboard technician section when the
// mobile-dashboard endpoint returns an empty technician list.

class ActiveTechnicianSlots {
  final int total;
  final int active;
  final int available;

  const ActiveTechnicianSlots({
    required this.total,
    required this.active,
    required this.available,
  });

  factory ActiveTechnicianSlots.fromJson(Map<String, dynamic> json) {
    return ActiveTechnicianSlots(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      active: int.tryParse(json['active']?.toString() ?? '0') ?? 0,
      available: int.tryParse(json['available']?.toString() ?? '0') ?? 0,
    );
  }
}

class ActiveTechnicianItem {
  final String id;
  final String name;
  final String mobile;
  final String branchId;
  final String branchName;
  final String technicianType; // 'workshop' | 'oncall' | 'both'
  final double commissionPercent;
  final String onlineStatus; // 'online' | 'offline'
  final DateTime? lastSeenAt;
  final ActiveTechnicianSlots slots;
  final List<DashboardTechnicianDepartment> departments;

  /// Translated display fields — set by the ViewModel after fetching,
  /// never populated from JSON.
  final String? translatedName;
  final String? translatedBranchName;

  bool get isOnline => onlineStatus == 'online';

  String get displayName => translatedName ?? name;
  String get displayBranchName => translatedBranchName ?? branchName;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get techTypeLabel {
    switch (technicianType) {
      case 'workshop':
        return 'Workshop';
      case 'oncall':
        return 'On-Call';
      case 'both':
        return 'Workshop + On-Call';
      default:
        return technicianType;
    }
  }

  const ActiveTechnicianItem({
    required this.id,
    required this.name,
    required this.mobile,
    required this.branchId,
    required this.branchName,
    required this.technicianType,
    required this.commissionPercent,
    required this.onlineStatus,
    this.lastSeenAt,
    required this.slots,
    required this.departments,
    this.translatedName,
    this.translatedBranchName,
  });

  ActiveTechnicianItem copyWith({
    String? id,
    String? name,
    String? mobile,
    String? branchId,
    String? branchName,
    String? technicianType,
    double? commissionPercent,
    String? onlineStatus,
    DateTime? lastSeenAt,
    ActiveTechnicianSlots? slots,
    List<DashboardTechnicianDepartment>? departments,
    String? translatedName,
    String? translatedBranchName,
  }) {
    return ActiveTechnicianItem(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      technicianType: technicianType ?? this.technicianType,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      slots: slots ?? this.slots,
      departments: departments ?? this.departments,
      translatedName: translatedName ?? this.translatedName,
      translatedBranchName: translatedBranchName ?? this.translatedBranchName,
    );
  }

  factory ActiveTechnicianItem.fromJson(Map<String, dynamic> json) {
    return ActiveTechnicianItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      technicianType: json['technicianType']?.toString() ?? 'workshop',
      commissionPercent:
      double.tryParse(json['commissionPercent']?.toString() ?? '0') ?? 0.0,
      onlineStatus: json['onlineStatus']?.toString() ?? 'offline',
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      slots: json['slots'] != null
          ? ActiveTechnicianSlots.fromJson(
          json['slots'] as Map<String, dynamic>)
          : const ActiveTechnicianSlots(total: 0, active: 0, available: 0),
      departments: ((json['departments'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DashboardTechnicianDepartment.fromJson)
          .toList(),
    );
  }

  /// Converts to [DashboardTechnician] so the dashboard view can render it
  /// using the same UI widget regardless of which endpoint provided the data.
  DashboardTechnician toDashboardTechnician() {
    return DashboardTechnician(
      id: id,
      name: name,
      mobile: mobile,
      branchId: branchId,
      branchName: branchName,
      technicianType: technicianType,
      onlineStatus: onlineStatus,
      lastSeenAt: lastSeenAt,
      slots: DashboardTechnicianSlots(
        total: slots.total,
        active: slots.active,
        available: slots.available,
      ),
      departments: departments,
      translatedName: translatedName,
      translatedBranchName: translatedBranchName,
    );
  }
}

class WorkshopProfile {
  final String id;
  final String name;
  final String ownerName;
  final String mobile;
  final String email;
  final String currencyCode;
  final double vatPercent;
  final bool vatInclusiveDefault;
  final String status;
  final double? gpsLat;
  final double? gpsLng;
  final String address;
  final String createdAt;

  WorkshopProfile({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.currencyCode,
    required this.vatPercent,
    required this.vatInclusiveDefault,
    required this.status,
    this.gpsLat,
    this.gpsLng,
    required this.address,
    required this.createdAt,
  });

  factory WorkshopProfile.fromJson(Map<String, dynamic> json) {
    return WorkshopProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      ownerName: json['ownerName'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      currencyCode: json['currencyCode'] ?? 'SAR',
      vatPercent: (json['vatPercent'] ?? 0).toDouble(),
      vatInclusiveDefault: json['vatInclusiveDefault'] == true,
      status: json['status'] ?? '',
      gpsLat: double.tryParse(json['gpsLat']?.toString() ?? ''),
      gpsLng: double.tryParse(json['gpsLng']?.toString() ?? ''),
      address: json['address'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  WorkshopProfile copyWith({
    String? name,
    String? ownerName,
    String? mobile,
    String? email,
    String? address,
  }) {
    return WorkshopProfile(
      id: id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      currencyCode: currencyCode,
      vatPercent: vatPercent,
      vatInclusiveDefault: vatInclusiveDefault,
      status: status,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }
}

// ─── ActiveTechniciansResponse ────────────────────────────────────────────────
// Typed wrapper for GET /workshop-staff/technicians?isActive=true response.
// { "success": true, "technicians": [ ... ] }

class ActiveTechniciansResponse {
  final bool success;
  final List<ActiveTechnicianItem> technicians;

  const ActiveTechniciansResponse({
    required this.success,
    required this.technicians,
  });

  factory ActiveTechniciansResponse.fromJson(Map<String, dynamic> json) {
    final list = ((json['technicians'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ActiveTechnicianItem.fromJson)
        .toList();

    // Sort: online first, then alphabetically by name
    list.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      return a.name.compareTo(b.name);
    });

    return ActiveTechniciansResponse(
      success: json['success'] == true,
      technicians: list,
    );
  }
}
// ─── Locker Management ─────────────────────────────────────────────────────

/// Locker staff account (supervisor or collection officer).
/// Created from the Employees page with role `locker_supervisor` /
/// `locker_collector`; surfaced here read-only.
class LockerStaff {
  final String id;
  final String name;
  final String? email;
  final String mobile;
  final String role; // 'locker_supervisor' | 'locker_collector'
  final bool isActive;
  final String status;

  LockerStaff({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    required this.role,
    this.isActive = true,
    this.status = 'active',
  });

  factory LockerStaff.fromJson(Map<String, dynamic> json) {
    return LockerStaff(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      mobile: json['mobile'] ?? '',
      role: json['role']?.toString() ?? json['employeeType']?.toString() ?? '',
      isActive: json['isActive'] != false,
      status: (json['isActive'] == false || json['active'] == false)
          ? 'inactive'
          : (json['status']?.toString() ?? 'active'),
    );
  }
}




// Aggregated KPIs for the locker management dashboard header.
class LockerSummary {
  final int pendingPickups;
  final int assignedToOfficer;
  final int overdue;
  final int pendingApprovals;
  final int collectedToday;
  final double monthlyCollected;
  final double openShiftVariance;
  final double lockerVaultBalance;

  LockerSummary({
    this.pendingPickups = 0,
    this.assignedToOfficer = 0,
    this.overdue = 0,
    this.pendingApprovals = 0,
    this.collectedToday = 0,
    this.monthlyCollected = 0,
    this.openShiftVariance = 0,
    this.lockerVaultBalance = 0,
  });

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  factory LockerSummary.fromJson(Map<String, dynamic> json) {
    return LockerSummary(
      pendingPickups: _i(json['pendingPickups']),
      assignedToOfficer: _i(json['assignedToOfficer']),
      overdue: _i(json['overdue']),
      pendingApprovals: _i(json['pendingApprovals']),
      collectedToday: _i(json['collectedToday']),
      monthlyCollected: _d(json['monthlyCollected']),
      openShiftVariance: _d(json['openShiftVariance']),
      lockerVaultBalance: _d(json['lockerVaultBalance']),
    );
  }
}

/// Full payload for the owner's Locker Management view.
class LockerMonitoringResponse {
  final bool success;
  final LockerSummary summary;
  final List<LockerStaff> supervisors;
  final List<LockerStaff> officers;
  final List<LockerCollectionRequest> collectionRequests;
  final List<LockerCollectionRecord> collections;
  final List<LockerBankDeposit> bankDeposits;
  final List<LockerPettyCash> pettyCash;

  LockerMonitoringResponse({
    required this.success,
    required this.summary,
    required this.supervisors,
    required this.officers,
    required this.collectionRequests,
    required this.collections,
    required this.bankDeposits,
    required this.pettyCash,
  });

  factory LockerMonitoringResponse.fromJson(Map<String, dynamic> json) {
    return LockerMonitoringResponse(
      success: json['success'] == true,
      summary: LockerSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>() ?? {}),
      supervisors: (json['supervisors'] as List?)
          ?.whereType<Map>()
          .map((e) => LockerStaff.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      officers: (json['officers'] as List?)
          ?.whereType<Map>()
          .map((e) => LockerStaff.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      collectionRequests: (json['collectionRequests'] as List?)
          ?.whereType<Map>()
          .map((e) =>
          LockerCollectionRequest.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      collections: (json['collections'] as List?)
          ?.whereType<Map>()
          .map((e) =>
          LockerCollectionRecord.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      bankDeposits: (json['bankDeposits'] as List?)
          ?.whereType<Map>()
          .map((e) => LockerBankDeposit.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      pettyCash: (json['pettyCashIssued'] as List?)
          ?.whereType<Map>()
          .map((e) => LockerPettyCash.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
    );
  }
}
// ─── Locker Management ─────────────────────────────────────────────────────

/// KPI block from `GET /workshop-staff/locker-management/overview`.
class LockerKpis {
  final int pendingRequests;
  final int assignedRequests;
  final int overdueRequests;
  final int pendingApprovals;
  final int collectionsToday;
  final double monthlyCollected;
  final double openShiftVariance;
  final double lockerVaultBalance;

  LockerKpis({
    this.pendingRequests = 0,
    this.assignedRequests = 0,
    this.overdueRequests = 0,
    this.pendingApprovals = 0,
    this.collectionsToday = 0,
    this.monthlyCollected = 0,
    this.openShiftVariance = 0,
    this.lockerVaultBalance = 0,
  });

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;
  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;

  factory LockerKpis.fromJson(Map<String, dynamic>? json) {
    if (json == null) return LockerKpis();
    return LockerKpis(
      pendingRequests: _i(json['pendingRequests']),
      assignedRequests: _i(json['assignedRequests']),
      overdueRequests: _i(json['overdueRequests']),
      pendingApprovals: _i(json['pendingApprovals']),
      collectionsToday: _i(json['collectionsToday']),
      monthlyCollected: _d(json['monthlyCollected']),
      openShiftVariance: _d(json['openShiftVariance']),
      lockerVaultBalance: _d(json['lockerVaultBalance']),
    );
  }
}

/// Locker staff account (supervisor or collection officer) — `lockerUsers[]`.
/// Created from the Employees page with role `locker_supervisor` /
/// `locker_collector`; surfaced here read-only.
class LockerUser {
  final String id;
  final String name;
  final String? email;
  final String mobile;
  final String role; // e.g. 'locker_supervisor' | 'locker_collector'
  final bool isActive;
  final String status;

  LockerUser({
    required this.id,
    required this.name,
    this.email,
    required this.mobile,
    required this.role,
    this.isActive = true,
    this.status = 'active',
  });

  bool get isSupervisor => role.toLowerCase().contains('supervisor');
  bool get isCollector => role.toLowerCase().contains('collector');

  factory LockerUser.fromJson(Map<String, dynamic> json) {
    final isActiveVal = json['isActive'];
    final active = isActiveVal == null ? true : isActiveVal == true;
    return LockerUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? json['employeeType']?.toString() ?? '',
      isActive: active,
      status: active ? (json['status']?.toString() ?? 'active') : 'inactive',
    );
  }
}

/// A cash-collection request raised when a cashier closes a POS session;
/// awaits assignment/pickup by a collection officer — `recentRequests[]`.
class LockerCollectionRequest {
  final String id;
  final String referenceCode;
  final String branchId;
  final String branchName;
  final String cashierId;
  final String cashierName;
  final double expectedAmount;
  final String status;   // 'pending' | 'assigned' | 'collected' ...
  final String uiStatus; // 'ASSIGN' | 'COLLECT' | 'COLLECTED' ... (drives the UI label/action)
  final String? assignedOfficerId;
  final String? assignedOfficerName;
  final double closingCashDiff;
  final double closingPhysicalCash;
  final DateTime createdAt;
  final Map<String, dynamic>? collection;

  LockerCollectionRequest({
    required this.id,
    required this.referenceCode,
    required this.branchId,
    required this.branchName,
    required this.cashierId,
    required this.cashierName,
    required this.expectedAmount,
    required this.status,
    required this.uiStatus,
    this.assignedOfficerId,
    this.assignedOfficerName,
    required this.closingCashDiff,
    required this.closingPhysicalCash,
    required this.createdAt,
    this.collection,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAssigned =>
      status.toLowerCase() == 'assigned' || assignedOfficerId != null;
  bool get isOverdue =>
      isPending && DateTime.now().difference(createdAt).inHours > 24;

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory LockerCollectionRequest.fromJson(Map<String, dynamic> json) {
    return LockerCollectionRequest(
      id: json['id']?.toString() ?? '',
      referenceCode: json['referenceCode']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      cashierId: json['cashierId']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? '',
      expectedAmount: _d(json['expectedAmount']),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      uiStatus: json['uiStatus']?.toString() ?? '',
      assignedOfficerId: json['assignedOfficerId']?.toString(),
      assignedOfficerName: json['assignedOfficerName']?.toString(),
      closingCashDiff: _d(json['closingCashDiff']),
      closingPhysicalCash: _d(json['closingPhysicalCash']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      collection: (json['collection'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// A completed cash handover from a cashier session into the locker vault —
/// `recentCollections[]`. Shape inferred; backend currently returns `[]`.
class LockerCollectionRecord {
  final String id;
  final String referenceCode;
  final String branchName;
  final String cashierName;
  final String? officerName;
  final double expectedAmount;
  final double receivedAmount;
  final double difference;
  final String status;
  final DateTime collectedAt;

  LockerCollectionRecord({
    required this.id,
    required this.referenceCode,
    required this.branchName,
    required this.cashierName,
    this.officerName,
    required this.expectedAmount,
    required this.receivedAmount,
    required this.difference,
    required this.status,
    required this.collectedAt,
  });

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory LockerCollectionRecord.fromJson(Map<String, dynamic> json) {
    final expected = _d(json['expectedAmount']);
    final received = _d(json['receivedAmount'] ?? json['amountCollected']);
    final diff = json['difference'] != null ? _d(json['difference']) : (received - expected);
    return LockerCollectionRecord(
      id: json['id']?.toString() ?? '',
      // API returns the request's reference under `requestReference`
      // (not `referenceCode`) for this endpoint — support both shapes.
      referenceCode: json['referenceCode']?.toString() ??
          json['requestReference']?.toString() ??
          '',
      branchName: json['branchName']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? '',
      officerName: json['officerName']?.toString() ?? json['collectedByName']?.toString(),
      expectedAmount: expected,
      receivedAmount: received,
      difference: diff,
      status: json['status']?.toString().toLowerCase() ?? 'matched',
      collectedAt: DateTime.tryParse(json['collectedAt']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Cash deposit made from the locker vault to the bank — `recentBankDeposits[]`.
/// Shape inferred; backend currently returns `[]`.
class LockerBankDeposit {
  final String id;
  final String referenceCode;
  final String registerName;
  final String branchName;
  final double amount;
  final DateTime date;

  LockerBankDeposit({
    required this.id,
    required this.referenceCode,
    required this.registerName,
    required this.branchName,
    required this.amount,
    required this.date,
  });

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory LockerBankDeposit.fromJson(Map<String, dynamic> json) {
    return LockerBankDeposit(
      id: json['id']?.toString() ?? '',
      referenceCode: json['referenceCode']?.toString() ?? json['reference']?.toString() ?? '',
      registerName: json['register']?.toString() ?? json['registerName']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      amount: _d(json['amount']),
      date: DateTime.tryParse(json['date']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Petty-cash float issued from the locker vault to a cashier/employee —
/// `recentPettyCashIssues[]`. Shape inferred; backend currently returns `[]`.
class LockerPettyCash {
  final String id;
  final String cashierName;
  final double amount;
  final String description;
  final DateTime date;

  LockerPettyCash({
    required this.id,
    required this.cashierName,
    required this.amount,
    required this.description,
    required this.date,
  });

  static double _d(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory LockerPettyCash.fromJson(Map<String, dynamic> json) {
    return LockerPettyCash(
      id: json['id']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? '',
      amount: _d(json['amount']),
      description: json['description']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Full payload for `GET /workshop-staff/locker-management/overview`.
class LockerOverviewResponse {
  final bool success;
  final LockerKpis kpis;
  final List<LockerUser> lockerUsers;
  final List<LockerCollectionRequest> recentRequests;
  final List<LockerCollectionRecord> recentCollections;
  final List<LockerBankDeposit> recentBankDeposits;
  final List<LockerPettyCash> recentPettyCashIssues;

  LockerOverviewResponse({
    required this.success,
    required this.kpis,
    required this.lockerUsers,
    required this.recentRequests,
    required this.recentCollections,
    required this.recentBankDeposits,
    required this.recentPettyCashIssues,
  });

  List<LockerUser> get supervisors =>
      lockerUsers.where((u) => u.isSupervisor).toList();

  List<LockerUser> get officers =>
      lockerUsers.where((u) => u.isCollector).toList();

  factory LockerOverviewResponse.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      return (json[key] as List?)
          ?.whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [];
    }

    return LockerOverviewResponse(
      success: json['success'] == true,
      kpis: LockerKpis.fromJson((json['kpis'] as Map?)?.cast<String, dynamic>()),
      lockerUsers: list('lockerUsers', LockerUser.fromJson),
      recentRequests: list('recentRequests', LockerCollectionRequest.fromJson),
      recentCollections: list('recentCollections', LockerCollectionRecord.fromJson),
      recentBankDeposits: list('recentBankDeposits', LockerBankDeposit.fromJson),
      recentPettyCashIssues: list('recentPettyCashIssues', LockerPettyCash.fromJson),
    );
  }
}

// ─── Commission Models ─────────────────────────────────────────────────────

/// A single commission rule from `commission_rules`.
class CommissionRule {
  final String id;
  final int priority;
  final String status; // 'active' | 'inactive'
  final String? serviceId;
  final String? serviceName; // custom or linked service name
  final String? employeeRole;
  final String type; // 'percentage' | 'fixed'
  final double value;
  final String? notes;

  CommissionRule({
    required this.id,
    required this.priority,
    required this.status,
    this.serviceId,
    this.serviceName,
    this.employeeRole,
    required this.type,
    required this.value,
    this.notes,
  });

  bool get isPercentage => type == 'percentage';
  bool get isActive => status.toLowerCase() == 'active';

  String get displayValue => isPercentage
      ? '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}%'
      : 'SAR ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';

  String get displayService =>
      (serviceName == null || serviceName!.trim().isEmpty) ? 'Any service' : serviceName!;

  String get displayRole =>
      (employeeRole == null || employeeRole!.trim().isEmpty) ? 'Any role' : employeeRole!;

  CommissionRule copyWith({
    String? id,
    int? priority,
    String? status,
    String? serviceId,
    String? serviceName,
    String? employeeRole,
    String? type,
    double? value,
    String? notes,
  }) {
    return CommissionRule(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      employeeRole: employeeRole ?? this.employeeRole,
      type: type ?? this.type,
      value: value ?? this.value,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'status': status,
      if (serviceId != null && serviceId!.isNotEmpty) 'serviceId': serviceId,
      'serviceName': serviceName ?? '',
      'employeeRole': employeeRole,
      'commissionType': isPercentage ? 'Percentage' : 'Fixed',
      'value': value,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    };
  }

  factory CommissionRule.fromJson(Map<String, dynamic> json) {
    final rawType = (json['commissionType'] ??
            json['commission_type'] ??
            json['type'] ??
            'percentage')
        .toString();
    final type = rawType.toLowerCase().startsWith('fix')
        ? 'fixed'
        : rawType.toLowerCase().contains('percent')
            ? 'percentage'
            : rawType.toLowerCase();
    return CommissionRule(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      priority: int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString().toLowerCase() ?? 'active',
      serviceId: json['serviceId']?.toString() ?? json['service_id']?.toString(),
      serviceName:
          json['serviceName']?.toString() ?? json['service_name']?.toString(),
      employeeRole:
          json['employeeRole']?.toString() ?? json['employee_role']?.toString(),
      type: type,
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }
}

/// A simple option for service dropdowns (catalog service + custom services
/// already used in commission rules).
class CommissionServiceOption {
  final String? id; // null => custom / no link
  final String name;

  const CommissionServiceOption({this.id, required this.name});

  factory CommissionServiceOption.fromJson(Map<String, dynamic> json) {
    return CommissionServiceOption(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
    );
  }
}

// ─── Workshop Role / Permissions ─────────────────────────────────────────────

/// A custom permission role created by the workshop owner.
/// Maps to POST/GET /workshop-staff/permissions/roles
class WorkshopRole {
  final String id;
  final String name;
  final String description;
  /// Portal scope: super_admin | workshop | cashier | technician | corporate | supplier
  final String portal;
  /// Flat list of permission strings e.g. ["sales.invoices.view"]
  final List<String> permissions;
  final String? workshopId;

  // ── Derived display helpers (not from API) ────────────────────────────────
  int get permissionCount => permissions.length;

  const WorkshopRole({
    required this.id,
    required this.name,
    this.description = '',
    required this.portal,
    this.permissions = const [],
    this.workshopId,
  });

  WorkshopRole copyWith({
    String? id,
    String? name,
    String? description,
    String? portal,
    List<String>? permissions,
    String? workshopId,
  }) =>
      WorkshopRole(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        portal: portal ?? this.portal,
        permissions: permissions ?? this.permissions,
        workshopId: workshopId ?? this.workshopId,
      );

  factory WorkshopRole.fromJson(Map<String, dynamic> json) {
    return WorkshopRole(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      portal: json['portal']?.toString() ?? 'workshop',
      permissions: (json['permissions'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
      workshopId: json['workshopId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description.isNotEmpty) 'description': description,
    'portal': portal,
    'permissions': permissions,
    if (workshopId != null) 'workshopId': workshopId,
  };
}


class CommissionLedgerEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String service;
  final String jobCardNumber;
  final String? jobCardId;
  final DateTime date;
  final double rate; // percent or fixed used at the time
  final bool isPercentageRate;
  final double amount;
  final String status; // 'accrued' | 'paid'

  CommissionLedgerEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.service,
    required this.jobCardNumber,
    this.jobCardId,
    required this.date,
    required this.rate,
    required this.isPercentageRate,
    required this.amount,
    required this.status,
  });

  bool get isAccrued => status.toLowerCase() == 'accrued';
  bool get isPaid => status.toLowerCase() == 'paid';

  String get displayRate =>
      isPercentageRate ? '${rate.toStringAsFixed(2)}%' : 'SAR ${rate.toStringAsFixed(2)}';

  String get displayAmount => 'SAR ${amount.toStringAsFixed(2)}';

  factory CommissionLedgerEntry.fromJson(Map<String, dynamic> json) {
    final rateRaw = json['rate_percent'] ?? json['ratePercent'] ?? json['rate'];
    final dateRaw = json['date'] ?? json['commission_date'] ?? json['commissionDate'];
    DateTime parsedDate = DateTime.now();
    if (dateRaw != null) {
      if (dateRaw is num) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(dateRaw.toInt());
      } else {
        parsedDate = DateTime.tryParse(dateRaw.toString()) ?? DateTime.now();
      }
    }
    return CommissionLedgerEntry(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ??
          json['employeeId']?.toString() ??
          '',
      employeeName: json['employee_name']?.toString() ??
          json['employeeName']?.toString() ??
          '',
      service: json['service_name']?.toString() ??
          json['serviceName']?.toString() ??
          json['service']?.toString() ??
          '',
      jobCardNumber: json['job_card_ref']?.toString() ??
          json['jobCardRef']?.toString() ??
          json['jobCardNumber']?.toString() ??
          '',
      jobCardId: json['job_id']?.toString() ??
          json['jobId']?.toString() ??
          json['jobCardId']?.toString(),
      date: parsedDate,
      rate: double.tryParse(rateRaw?.toString() ?? '0') ?? 0.0,
      isPercentageRate: rateRaw != null ||
          json['rateType']?.toString() != 'fixed',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'accrued',
    );
  }
}

/// Aggregated pending-payout summary for a single employee.
class CommissionEmployeeSummary {
  final String employeeId;
  final String employeeName;
  final int entriesCount;
  final double totalAmount;

  CommissionEmployeeSummary({
    required this.employeeId,
    required this.employeeName,
    required this.entriesCount,
    required this.totalAmount,
  });

  factory CommissionEmployeeSummary.fromJson(Map<String, dynamic> json) {
    return CommissionEmployeeSummary(
      employeeId: json['employee_id']?.toString() ??
          json['employeeId']?.toString() ??
          '',
      employeeName: json['name']?.toString() ??
          json['employeeName']?.toString() ??
          json['employee_name']?.toString() ??
          '',
      entriesCount: int.tryParse(
            (json['entry_count'] ?? json['entriesCount'] ?? json['count'])
                ?.toString() ??
                '0',
          ) ??
          0,
      totalAmount: double.tryParse(
            (json['pending_amount'] ??
                    json['totalAmount'] ??
                    json['amount'] ??
                    '0')
                .toString(),
          ) ??
          0.0,
    );
  }
}

/// KPI summary block at the top of the Commission screen.
class CommissionKpis {
  final double totalAccrued;
  final double totalPaid;
  final int pendingEmployees;
  final double selectedForPayout;

  CommissionKpis({
    required this.totalAccrued,
    required this.totalPaid,
    required this.pendingEmployees,
    required this.selectedForPayout,
  });

  factory CommissionKpis.empty() => CommissionKpis(
    totalAccrued: 0,
    totalPaid: 0,
    pendingEmployees: 0,
    selectedForPayout: 0,
  );

  factory CommissionKpis.fromJson(Map<String, dynamic> json) {
    return CommissionKpis(
      totalAccrued: double.tryParse(
            (json['total_accrued'] ?? json['totalAccrued'] ?? '0').toString(),
          ) ??
          0.0,
      totalPaid: double.tryParse(
            (json['total_paid'] ?? json['totalPaid'] ?? '0').toString(),
          ) ??
          0.0,
      pendingEmployees: int.tryParse(
            (json['pending_employee_count'] ??
                    json['pendingEmployeeCount'] ??
                    json['pendingEmployees'] ??
                    '0')
                .toString(),
          ) ??
          0,
      selectedForPayout: double.tryParse(
            (json['selectedForPayout'] ?? '0').toString(),
          ) ??
          0.0,
    );
  }
}

/// Full payload for the Commission overview (Ledger tab).
class CommissionOverviewResponse {
  final bool success;
  final CommissionKpis kpis;
  final List<CommissionEmployeeSummary> pendingByEmployee;
  final List<CommissionLedgerEntry> entries;

  CommissionOverviewResponse({
    required this.success,
    required this.kpis,
    required this.pendingByEmployee,
    required this.entries,
  });

  factory CommissionOverviewResponse.empty() => CommissionOverviewResponse(
    success: true,
    kpis: CommissionKpis.empty(),
    pendingByEmployee: [],
    entries: [],
  );

  factory CommissionOverviewResponse.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      return (json[key] as List?)
          ?.whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [];
    }

    return CommissionOverviewResponse(
      success: json['success'] == true,
      kpis: CommissionKpis.fromJson((json['kpis'] as Map?)?.cast<String, dynamic>() ?? {}),
      pendingByEmployee: list('pendingByEmployee', CommissionEmployeeSummary.fromJson),
      entries: list('entries', CommissionLedgerEntry.fromJson),
    );
  }
}

/// Full payload for the Commission Rules (Rules tab).
class CommissionRulesResponse {
  final bool success;
  final List<CommissionRule> rules;
  final List<CommissionServiceOption> serviceOptions;
  final List<String> employeeRoles;

  CommissionRulesResponse({
    required this.success,
    required this.rules,
    required this.serviceOptions,
    required this.employeeRoles,
  });

  factory CommissionRulesResponse.empty() => CommissionRulesResponse(
    success: true,
    rules: [],
    serviceOptions: [],
    employeeRoles: const [
      'Technician',
      'Senior Technician',
      'Master Technician',
      'Supervisor',
      'Manager',
    ],
  );

  factory CommissionRulesResponse.fromJson(Map<String, dynamic> json) {
    return CommissionRulesResponse(
      success: json['success'] == true,
      rules: (json['rules'] as List?)
          ?.whereType<Map>()
          .map((e) => CommissionRule.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      serviceOptions: (json['serviceOptions'] as List?)
          ?.whereType<Map>()
          .map((e) => CommissionServiceOption.fromJson(e.cast<String, dynamic>()))
          .toList() ??
          [],
      employeeRoles: (json['employeeRoles'] as List?)?.map((e) => e.toString()).toList() ??
          const [
            'Technician',
            'Senior Technician',
            'Master Technician',
            'Supervisor',
            'Manager',
          ],
    );
  }
}


class ToggleDepartmentUpdatedCounts {
  final int branchDepartments;
  final int categories;
  final int branchCategories;
  final int products;
  final int services;

  const ToggleDepartmentUpdatedCounts({
    required this.branchDepartments,
    required this.categories,
    required this.branchCategories,
    required this.products,
    required this.services,
  });

  factory ToggleDepartmentUpdatedCounts.fromJson(Map<String, dynamic> json) {
    return ToggleDepartmentUpdatedCounts(
      branchDepartments: _i(json['branchDepartments']),
      categories: _i(json['categories']),
      branchCategories: _i(json['branchCategories']),
      products: _i(json['products']),
      services: _i(json['services']),
    );
  }

  static int _i(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}

class ToggleDepartmentActiveResponse {
  final bool success;
  final String message;
  final String departmentId;
  final bool isActive;
  final ToggleDepartmentUpdatedCounts? updated;

  const ToggleDepartmentActiveResponse({
    required this.success,
    required this.message,
    required this.departmentId,
    required this.isActive,
    this.updated,
  });

  factory ToggleDepartmentActiveResponse.fromJson(Map<String, dynamic> json) {
    return ToggleDepartmentActiveResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      isActive: json['isActive'] == true,
      updated: json['updated'] != null
          ? ToggleDepartmentUpdatedCounts.fromJson(
          json['updated'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── POST /workshop-staff/department/create ─────────────────────────────────────

class CreatedDepartment {
  final String id;
  final String name;
  final String? workshopId;
  final bool isActive;

  const CreatedDepartment({
    required this.id,
    required this.name,
    this.workshopId,
    required this.isActive,
  });

  factory CreatedDepartment.fromJson(Map<String, dynamic> json) {
    return CreatedDepartment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      workshopId: json['workshopId']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}

class CreateDepartmentResponse {
  final bool success;
  final String message;
  final CreatedDepartment? department;

  const CreateDepartmentResponse({
    required this.success,
    required this.message,
    this.department,
  });

  factory CreateDepartmentResponse.fromJson(Map<String, dynamic> json) {
    return CreateDepartmentResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      department: json['department'] != null
          ? CreatedDepartment.fromJson(
          json['department'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── POST /workshop-staff/category/create ──────────────────────────────────────

class CreatedCategory {
  final String id;
  final String name;
  final String type;
  final String departmentId;

  const CreatedCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.departmentId,
  });

  factory CreatedCategory.fromJson(Map<String, dynamic> json) {
    return CreatedCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'product',
      departmentId: json['departmentId']?.toString() ?? '',
    );
  }
}

class CreateCategoryResponse {
  final bool success;
  final String message;
  final CreatedCategory? category;

  const CreateCategoryResponse({
    required this.success,
    required this.message,
    this.category,
  });

  factory CreateCategoryResponse.fromJson(Map<String, dynamic> json) {
    return CreateCategoryResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      category: json['category'] != null
          ? CreatedCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── POST /workshop-staff/product/create ───────────────────────────────────────

/// Full request body for creating a product.
/// The `unit` field MUST be one of the values returned by GET /workshop-staff/product-units.
/// Sending an invalid unit returns HTTP 400: "unit must be one of: pcs, box, ..."
class CreateProductRequest {
  final String workshopId;
  final String branchId;
  final String name;
  final String departmentId;
  final String categoryId;
  final String unit; // must be from ProductUnitsResponse.units
  final double purchasePrice;
  final double salePrice;
  final double openingQty;
  final double minPriceCorporate;
  final double maxPriceCorporate;
  final double criticalStockPoint;
  final int kmTypeValue;
  final bool allowDecimalQty;
  final bool isActive;
  // Optional
  final String? arabicName;
  final String? brandName;
  final String? description;
  final String? sku;

  const CreateProductRequest({
    required this.workshopId,
    required this.branchId,
    required this.name,
    required this.departmentId,
    required this.categoryId,
    required this.unit,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.openingQty = 0,
    this.minPriceCorporate = 0,
    this.maxPriceCorporate = 0,
    this.criticalStockPoint = 0,
    this.kmTypeValue = 0,
    this.allowDecimalQty = false,
    this.isActive = true,
    this.arabicName,
    this.brandName,
    this.description,
    this.sku,
  });

  Map<String, dynamic> toJson() => {
    'workshopId': workshopId,
    'branchId': branchId,
    'name': name,
    'departmentId': departmentId,
    'categoryId': categoryId,
    'unit': unit,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'openingQty': openingQty,
    'minPriceCorporate': minPriceCorporate,
    'maxPriceCorporate': maxPriceCorporate,
    'criticalStockPoint': criticalStockPoint,
    'kmTypeValue': kmTypeValue,
    'allowDecimalQty': allowDecimalQty,
    'isActive': isActive,
    if (arabicName != null && arabicName!.isNotEmpty) 'arabicName': arabicName,
    if (brandName != null && brandName!.isNotEmpty) 'brandName': brandName,
    if (description != null && description!.isNotEmpty) 'description': description,
    if (sku != null && sku!.isNotEmpty) 'sku': sku,
  };
}

class CreateProductResponse {
  final bool success;
  final String message;
  // product data echoed back on success — reuse CatalogProductModel if present
  final Map<String, dynamic>? rawProduct;

  const CreateProductResponse({
    required this.success,
    required this.message,
    this.rawProduct,
  });

  factory CreateProductResponse.fromJson(Map<String, dynamic> json) {
    return CreateProductResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      rawProduct: json['product'] as Map<String, dynamic>?,
    );
  }
}

// ── DELETE /workshop-staff/workshop-products|{productId} remove-from-workshop ──
//

class DeleteProductFailure {
  final String id;
  final String reason;

  const DeleteProductFailure({required this.id, required this.reason});

  factory DeleteProductFailure.fromJson(Map<String, dynamic> json) {
    return DeleteProductFailure(
      id: json['id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class DeleteProductResponse {
  final bool success;
  final List<String> removedIds;
  final List<DeleteProductFailure> failed;

  const DeleteProductResponse({
    required this.success,
    required this.removedIds,
    required this.failed,
  });

  /// True only when the product was actually removed (not blocked by inventory).
  bool get wasRemoved => removedIds.isNotEmpty && failed.isEmpty;

  /// Human-readable reason when blocked, e.g. "Has inventory on hand".
  String? get blockReason => failed.isNotEmpty ? failed.first.reason : null;

  factory DeleteProductResponse.fromJson(Map<String, dynamic> json) {
    return DeleteProductResponse(
      success: json['success'] == true,
      removedIds: List<String>.from(json['removedIds'] ?? []),
      failed: ((json['failed'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DeleteProductFailure.fromJson)
          .toList(),
    );
  }
}

// ── GET /workshop-catalog/catalog/departments?listScope=master ─────────────────

class MasterDepartmentItem {
  final String id;
  final String name;
  final bool isActive;
  final bool inWorkshop; // true = already added to this workshop

  const MasterDepartmentItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.inWorkshop,
  });

  factory MasterDepartmentItem.fromJson(Map<String, dynamic> json) {
    return MasterDepartmentItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] == true,
      inWorkshop: json['inWorkshop'] == true,
    );
  }
}

class MasterDepartmentsResponse {
  final bool success;
  final List<MasterDepartmentItem> departments;

  const MasterDepartmentsResponse({
    required this.success,
    required this.departments,
  });

  factory MasterDepartmentsResponse.fromJson(Map<String, dynamic> json) {
    return MasterDepartmentsResponse(
      success: json['success'] == true,
      departments: ((json['departments'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MasterDepartmentItem.fromJson)
          .toList(),
    );
  }
}

// ── GET /workshop-catalog/catalog/categories?departmentId=...&type=...&listScope=master ──

class MasterCategoryItem {
  final String id;
  final String name;
  final String type;
  final String departmentId;
  final String departmentName;
  final bool inWorkshop;

  const MasterCategoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.departmentId,
    required this.departmentName,
    required this.inWorkshop,
  });

  factory MasterCategoryItem.fromJson(Map<String, dynamic> json) {
    return MasterCategoryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'product',
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      inWorkshop: json['inWorkshop'] == true,
    );
  }
}

class MasterCategoriesResponse {
  final bool success;
  final List<MasterCategoryItem> categories;

  const MasterCategoriesResponse({
    required this.success,
    required this.categories,
  });

  factory MasterCategoriesResponse.fromJson(Map<String, dynamic> json) {
    return MasterCategoriesResponse(
      success: json['success'] == true,
      categories: ((json['categories'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MasterCategoryItem.fromJson)
          .toList(),
    );
  }
}

// ── POST /workshop-staff/catalog/product-request ──────────────────────────────
//
// Used when a workshop requests a product that doesn't exist yet in their catalog.
// Status starts as "pending" and is reviewed by the platform.
//
// ⚠️  Wrong path: /workshop-catalog/catalog/product-requests → 404
//     Correct path: /workshop-staff/catalog/product-request   → 201

class CatalogProductRequest {
  final String workshopId;
  final String branchId;
  final String name;
  final String brandName;
  final String unit; // must be from product-units
  final double salePriceInclusiveVat;
  final String masterDepartmentId;
  final String masterCategoryId;
  // Optional
  final String? arabicName;
  final String? description;
  final String? notes;

  const CatalogProductRequest({
    required this.workshopId,
    required this.branchId,
    required this.name,
    required this.brandName,
    required this.unit,
    required this.salePriceInclusiveVat,
    required this.masterDepartmentId,
    required this.masterCategoryId,
    this.arabicName,
    this.description,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'workshopId': workshopId,
    'branchId': branchId,
    'name': name,
    'brandName': brandName,
    'unit': unit,
    'salePriceInclusiveVat': salePriceInclusiveVat,
    'masterDepartmentId': masterDepartmentId,
    'masterCategoryId': masterCategoryId,
    if (arabicName != null && arabicName!.isNotEmpty) 'arabicName': arabicName,
    if (description != null && description!.isNotEmpty) 'description': description,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}

class CatalogProductRequestResponse {
  final bool success;
  final String id;
  final String name;
  final String? sku;
  final String? brandName;
  final String unit;
  final String status; // 'pending'
  final String? departmentId;
  final String? categoryId;
  final String createdAt;

  const CatalogProductRequestResponse({
    required this.success,
    required this.id,
    required this.name,
    this.sku,
    this.brandName,
    required this.unit,
    required this.status,
    this.departmentId,
    this.categoryId,
    required this.createdAt,
  });

  factory CatalogProductRequestResponse.fromJson(Map<String, dynamic> json) {
    return CatalogProductRequestResponse(
      success: json['success'] == true,
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString(),
      brandName: json['brandName']?.toString(),
      unit: json['unit']?.toString() ?? 'pcs',
      status: json['status']?.toString() ?? 'pending',
      departmentId: json['departmentId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}


class WorkshopSalesReturnLineItem {
  final String id;
  final String salesOrderItemId;
  final int qty;
  final double lineTotal;
  final String reason;

  WorkshopSalesReturnLineItem({
    required this.id,
    required this.salesOrderItemId,
    required this.qty,
    required this.lineTotal,
    required this.reason,
  });

  factory WorkshopSalesReturnLineItem.fromJson(Map<String, dynamic> json) {
    return WorkshopSalesReturnLineItem(
      id: json['id']?.toString() ?? '',
      salesOrderItemId: json['salesOrderItemId']?.toString() ?? '',
      qty: int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      lineTotal: double.tryParse(json['lineTotal']?.toString() ?? '0') ?? 0,
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class WorkshopSalesReturn {
  final String id;
  final String returnNo;
  final String creditNoteNo;
  final String returnScope; // 'full' | 'partial'
  final String invoiceId;
  final String invoiceNo;
  final String orderId;
  final String customerId;
  final String customerName;
  final String customerMobile;
  final String branchId;
  final String branchName;
  final String cashierUserId;
  final String cashierName;
  final DateTime returnDate;
  final DateTime createdAt;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String reason;
  final String status; // backend values: 'pending' | 'completed' | 'rejected'
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String? invoicePublicToken;
  final List<WorkshopSalesReturnLineItem> items;

  WorkshopSalesReturn({
    required this.id,
    required this.returnNo,
    required this.creditNoteNo,
    required this.returnScope,
    required this.invoiceId,
    required this.invoiceNo,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.branchId,
    required this.branchName,
    required this.cashierUserId,
    required this.cashierName,
    required this.returnDate,
    required this.createdAt,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    required this.reason,
    required this.status,
    this.rejectionReason,
    this.reviewedAt,
    this.invoicePublicToken,
    this.items = const [],
  });

  factory WorkshopSalesReturn.fromJson(Map<String, dynamic> json) {
    final returnDate = DateTime.tryParse(json['returnDate']?.toString() ?? '');
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');

    return WorkshopSalesReturn(
      id: json['id']?.toString() ?? '',
      returnNo: json['returnNo']?.toString() ?? '',
      creditNoteNo: json['creditNoteNo']?.toString() ?? '',
      returnScope: json['returnScope']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerMobile: json['customerMobile']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      cashierUserId: json['cashierUserId']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? '',
      returnDate: returnDate ?? createdAt ?? DateTime.now(),
      createdAt: createdAt ?? returnDate ?? DateTime.now(),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      vatAmount: double.tryParse(json['vatAmount']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString(),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
      invoicePublicToken: json['invoicePublicToken']?.toString(),
      items: ((json['items'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WorkshopSalesReturnLineItem.fromJson)
          .toList(),
    );
  }
}

class WorkshopSalesReturnsResponse {
  final bool success;
  final int total;
  final int limit;
  final int offset;
  final List<WorkshopSalesReturn> salesReturns;

  WorkshopSalesReturnsResponse({
    required this.success,
    required this.total,
    required this.limit,
    required this.offset,
    required this.salesReturns,
  });

  factory WorkshopSalesReturnsResponse.fromJson(Map<String, dynamic> json) {
    return WorkshopSalesReturnsResponse(
      success: json['success'] == true,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '0') ?? 0,
      offset: int.tryParse(json['offset']?.toString() ?? '0') ?? 0,
      salesReturns: ((json['salesReturns'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WorkshopSalesReturn.fromJson)
          .toList(),
    );
  }
}

// =============================================================================
// Admin Wallet Approvals Models
// GET /workshop-staff/admin-wallet-approvals
// =============================================================================

class AdminWalletApproval {
  final String id;
  /// `admin_wallet_fund` | `admin_wallet_expense`
  final String kind;
  final String? requestNumber;
  final String workshopId;
  final String workshopName;
  final String status; // 'pending' | 'approved' | 'rejected'
  final double amount;
  final String? description;
  final String? expenseCategory;
  final String? proofUrl;
  final String? requestedBy;
  final DateTime requestedAt;
  final String? branchId;
  final String? branchName;
  final String? rejectionReason;

  const AdminWalletApproval({
    required this.id,
    required this.kind,
    this.requestNumber,
    required this.workshopId,
    required this.workshopName,
    required this.status,
    required this.amount,
    this.description,
    this.expenseCategory,
    this.proofUrl,
    this.requestedBy,
    required this.requestedAt,
    this.branchId,
    this.branchName,
    this.rejectionReason,
  });

  factory AdminWalletApproval.fromJson(Map<String, dynamic> json) {
    final requestedAt = DateTime.tryParse(
          json['requestedAt']?.toString() ??
              json['createdAt']?.toString() ??
              '',
        ) ??
        DateTime.now();
    return AdminWalletApproval(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'admin_wallet_fund',
      requestNumber: json['requestNumber']?.toString(),
      workshopId: json['workshopId']?.toString() ?? '',
      workshopName: json['workshopName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? json['notes']?.toString(),
      expenseCategory: json['expenseCategory']?.toString(),
      proofUrl: json['proofUrl']?.toString(),
      requestedBy: json['requestedBy']?.toString() ??
          json['adminUserName']?.toString(),
      requestedAt: requestedAt,
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

/// GET /workshop-staff/affiliated-purchase-returns → items[]
class AffiliatedPurchaseReturnItem {
  final String id;
  final String returnNumber;
  final String status;
  final double grandTotal;
  final String? supplierName;
  final String? supplierId;
  final String? branchId;
  final String? branchName;
  final String? invoiceNo;
  final String? supplierSalesReturnNo;
  final String? initiationMode;
  final DateTime issueDate;

  const AffiliatedPurchaseReturnItem({
    required this.id,
    required this.returnNumber,
    required this.status,
    required this.grandTotal,
    this.supplierName,
    this.supplierId,
    this.branchId,
    this.branchName,
    this.invoiceNo,
    this.supplierSalesReturnNo,
    this.initiationMode,
    required this.issueDate,
  });

  factory AffiliatedPurchaseReturnItem.fromJson(Map<String, dynamic> json) {
    final issue = DateTime.tryParse(
          json['issueDate']?.toString() ??
              json['createdAt']?.toString() ??
              '',
        ) ??
        DateTime.now();
    return AffiliatedPurchaseReturnItem(
      id: json['id']?.toString() ?? '',
      returnNumber: json['returnNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      grandTotal:
          double.tryParse(json['grandTotal']?.toString() ?? '0') ?? 0,
      supplierName: json['supplierName']?.toString(),
      supplierId: json['supplierId']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      invoiceNo: json['sourcePurchaseInvoiceNumber']?.toString() ??
          json['invoiceNo']?.toString(),
      supplierSalesReturnNo: json['supplierSalesReturnNo']?.toString(),
      initiationMode: json['mode']?.toString() ?? json['initiationMode']?.toString(),
      issueDate: issue,
    );
  }
}

class AffiliatedPurchaseReturnsResponse {
  final bool success;
  final List<AffiliatedPurchaseReturnItem> items;

  const AffiliatedPurchaseReturnsResponse({
    required this.success,
    required this.items,
  });

  factory AffiliatedPurchaseReturnsResponse.fromJson(
      Map<String, dynamic> json) {
    return AffiliatedPurchaseReturnsResponse(
      success: json['success'] == true,
      items: ((json['items'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => AffiliatedPurchaseReturnItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class AdminWalletApprovalsResponse {
  final bool success;
  final String workshopId;
  final String workshopName;
  final List<AdminWalletApproval> requests;

  const AdminWalletApprovalsResponse({
    required this.success,
    required this.workshopId,
    required this.workshopName,
    required this.requests,
  });

  factory AdminWalletApprovalsResponse.fromJson(Map<String, dynamic> json) {
    return AdminWalletApprovalsResponse(
      success:      json['success'] == true,
      workshopId:   json['workshopId']?.toString() ?? '',
      workshopName: json['workshopName']?.toString() ?? '',
      requests:     ((json['requests'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminWalletApproval.fromJson)
          .toList(),
    );
  }
}

// =============================================================================
// Discounts Models  (add to workshop_owner_models.dart)
// =============================================================================
//
// API: GET /workshop-staff/discounts?limit=200&offset=0&dateFrom=...&dateTo=...&department=...
//
// Response shape:
// {
//   "success": true,
//   "summary": {
//     "lineDiscount": 0,
//     "invoiceDiscount": 0,
//     "promoDiscount": 0,
//     "totalDiscount": 0,
//     "invoiceCount": 0
//   },
//   "invoices": [
//     {
//       "id": "...",
//       "invoiceNo": "INV-00001",
//       "customerName": "...",
//       "customerMobile": "...",
//       "vehiclePlate": "...",
//       "cashierName": "...",
//       "branchName": "...",
//       "departmentName": "...",
//       "lineDiscount": 0.0,
//       "invoiceDiscount": 0.0,
//       "promoDiscount": 0.0,
//       "totalDiscount": 0.0,
//       "invoiceTotal": 0.0,
//       "createdAt": "2025-01-01T10:00:00.000Z"
//     }
//   ],
//   "total": 0,
//   "limit": 200,
//   "offset": 0
// }
// =============================================================================

class WorkshopDiscountSummary {
  final double lineDiscount;
  final double invoiceDiscount;
  final double promoDiscount;
  final double totalDiscount;
  final int invoiceCount;

  const WorkshopDiscountSummary({
    required this.lineDiscount,
    required this.invoiceDiscount,
    required this.promoDiscount,
    required this.totalDiscount,
    required this.invoiceCount,
  });

  static double _d(dynamic v) =>
      v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

  factory WorkshopDiscountSummary.fromJson(Map<String, dynamic> j) =>
      WorkshopDiscountSummary(
        lineDiscount:    _d(j['lineDiscount']),
        invoiceDiscount: _d(j['invoiceDiscount']),
        promoDiscount:   _d(j['promoDiscount']),
        totalDiscount:   _d(j['totalDiscount']),
        invoiceCount:    (j['invoiceCount'] as num? ?? 0).toInt(),
      );

  static const empty = WorkshopDiscountSummary(
    lineDiscount: 0,
    invoiceDiscount: 0,
    promoDiscount: 0,
    totalDiscount: 0,
    invoiceCount: 0,
  );
}

class WorkshopDiscountInvoice {
  final String id;
  final String invoiceNo;
  final String customerName;
  final String customerMobile;
  final String vehiclePlate;
  final String cashierName;
  final String branchName;
  final String departmentName;
  final double lineDiscount;
  final double invoiceDiscount;
  final double promoDiscount;
  final double totalDiscount;
  final double invoiceTotal;
  final DateTime createdAt;

  const WorkshopDiscountInvoice({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.customerMobile,
    required this.vehiclePlate,
    required this.cashierName,
    required this.branchName,
    required this.departmentName,
    required this.lineDiscount,
    required this.invoiceDiscount,
    required this.promoDiscount,
    required this.totalDiscount,
    required this.invoiceTotal,
    required this.createdAt,
  });

  static double _d(dynamic v) =>
      v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

  factory WorkshopDiscountInvoice.fromJson(Map<String, dynamic> j) =>
      WorkshopDiscountInvoice(
        id:              j['id']?.toString() ?? '',
        invoiceNo:       j['invoiceNo']?.toString() ?? j['invoiceNumber']?.toString() ?? '',
        customerName:    j['customerName']?.toString() ?? '',
        customerMobile:  j['customerMobile']?.toString() ?? '',
        vehiclePlate:    j['vehiclePlate']?.toString() ?? j['vehicle']?.toString() ?? '',
        cashierName:     j['cashierName']?.toString() ?? '',
        branchName:      j['branchName']?.toString() ?? '',
        departmentName:  j['departmentName']?.toString() ?? '',
        lineDiscount:    _d(j['lineDiscount']),
        invoiceDiscount: _d(j['invoiceDiscount']),
        promoDiscount:   _d(j['promoDiscount']),
        totalDiscount:   _d(j['totalDiscount']),
        invoiceTotal:    _d(j['invoiceTotal']),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}

class WorkshopDiscountsResponse {
  final bool success;
  final WorkshopDiscountSummary summary;
  final List<WorkshopDiscountInvoice> invoices;
  final int total;

  const WorkshopDiscountsResponse({
    required this.success,
    required this.summary,
    required this.invoices,
    required this.total,
  });

  factory WorkshopDiscountsResponse.fromJson(Map<String, dynamic> j) =>
      WorkshopDiscountsResponse(
        success:  j['success'] as bool? ?? false,
        summary:  j['summary'] != null
            ? WorkshopDiscountSummary.fromJson(j['summary'] as Map<String, dynamic>)
            : WorkshopDiscountSummary.empty,
        invoices: ((j['invoices'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map(WorkshopDiscountInvoice.fromJson)
            .toList(),
        total: (j['total'] as num? ?? 0).toInt(),
      );
}

class RegisteredSupplier {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String? address;
  final bool isActive;
  final String? crNumber;
  final String? vatId;
  final String? contactPerson;
  final double outstanding;
  final bool isLinkedToWorkshop;

  const RegisteredSupplier({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.isActive = true,
    this.crNumber,
    this.vatId,
    this.contactPerson,
    this.outstanding = 0,
    this.isLinkedToWorkshop = true,
  });

  factory RegisteredSupplier.fromJson(Map<String, dynamic> j) {
    String? _str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    double _d(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return RegisteredSupplier(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? j['supplierName'] ?? '').toString(),
      mobile: (j['mobile'] ?? j['phone'] ?? '').toString(),
      email: _str(j['email']),
      address: _str(j['address']),
      isActive: j['isActive'] as bool? ?? (j['status']?.toString() == 'active'),
      crNumber: _str(j['crNumber'] ?? j['cr_no'] ?? j['tradeLicenseNo']),
      vatId: _str(j['vatId'] ?? j['taxId']),
      contactPerson: _str(j['contactPerson']),
      outstanding: _d(j['outstanding']),
      isLinkedToWorkshop: j['isLinkedToWorkshop'] as bool? ?? true,
    );
  }
}

class WorkshopSuppliersResponse {
  final bool success;
  final int total;
  final String? currencyCode;
  final List<RegisteredSupplier> suppliers;

  const WorkshopSuppliersResponse({
    required this.success,
    required this.total,
    required this.suppliers,
    this.currencyCode,
  });

  factory WorkshopSuppliersResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['suppliers'] as List?) ?? const [];
    return WorkshopSuppliersResponse(
      success: j['success'] as bool? ?? false,
      total: (j['total'] as num?)?.toInt() ?? list.length,
      currencyCode: j['currencyCode']?.toString(),
      suppliers: list
          .map((e) => RegisteredSupplier.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class RegisteredSuppliersResponse {
  final bool success;
  final int total;
  final List<RegisteredSupplier> suppliers;

  const RegisteredSuppliersResponse({
    required this.success,
    required this.total,
    required this.suppliers,
  });

  factory RegisteredSuppliersResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['suppliers'] as List?) ?? const [];
    return RegisteredSuppliersResponse(
      success: j['success'] as bool? ?? false,
      total: (j['total'] as num?)?.toInt() ?? list.length,
      suppliers: list
          .map((e) => RegisteredSupplier.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class LinkSuppliersResponse {
  final bool success;
  final String message;
  final int linkedCount;
  final List<String> linkedSupplierIds;

  const LinkSuppliersResponse({
    required this.success,
    required this.message,
    required this.linkedCount,
    required this.linkedSupplierIds,
  });

  factory LinkSuppliersResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['linkedSuppliers'] as List?) ?? const [];
    return LinkSuppliersResponse(
      success: j['success'] as bool? ?? false,
      message: (j['message'] ?? '').toString(),
      linkedCount: (j['linkedCount'] as num?)?.toInt() ?? list.length,
      linkedSupplierIds: list
          .map((e) => (e as Map<String, dynamic>)['supplierId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
    );
  }
}
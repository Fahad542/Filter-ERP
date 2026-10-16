import 'package:flutter/material.dart';

import '../utils/app_formatters.dart';
import 'order_payment_method_draft.dart';

/// Normalizes API `vehicle.year` / `vehicle.vin` (may be int or string; empty → null).
String? _orderVehicleJsonString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final v in values) {
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

bool _asBool(dynamic value) {
  if (value == true) return true;
  if (value == false || value == null) return false;
  final s = value.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes';
}

/// `{ checks: boolean[6] }` from GET /cashier/orders — bilingual invoice checklist.
List<bool>? _parseMaintenanceChecks(dynamic raw) {
  if (raw == null || raw is! Map) return null;
  final c = raw['checks'];
  if (c is! List || c.length != 6) return null;
  return List<bool>.generate(6, (i) => _asBool(c[i]));
}

/// GET /cashier/orders omits top-level [items] when lines live under [jobs] only.
List<dynamic> _resolveOrderItemsList(
  Map<String, dynamic> json,
  List<PosOrderJob> jobs,
) {
  final raw = json['items'] ?? json['products'];
  if (raw is List && raw.isNotEmpty) {
    return List<dynamic>.from(raw);
  }
  if (jobs.isEmpty) return const [];
  return jobs
      .expand(
        (j) => j.items.map(
          (i) => <String, dynamic>{
            'id': i.id,
            'itemType': i.itemType,
            'productId': i.productId,
            'productName': i.productName,
            'productNameArabic': i.productNameArabic,
            'departmentId': i.departmentId,
            'departmentName': i.departmentName,
            'jobId': i.jobId,
            'qty': i.qty,
            'unitPrice': i.unitPrice,
            'lineTotal': i.lineTotal,
            'unitPriceExcludingVat': i.unitPriceExcludingVat,
            'lineTotalExcludingVat': i.lineTotalExcludingVat,
            'lineVatAmount': i.lineVatAmount,
            'discountType': i.discountType,
            'discountValue': i.discountValue,
          },
        ),
      )
      .toList();
}

int _firstNonZeroInt(List<dynamic> values) {
  for (final v in values) {
    if (v == null) continue;
    int? n;
    if (v is int) {
      n = v;
    } else if (v is num) {
      n = v.round();
    } else {
      final raw = v.toString().trim();
      if (raw.isEmpty) continue;
      n = int.tryParse(raw);
      n ??= double.tryParse(raw)?.round();
    }
    if (n != null && n > 0) return n;
  }
  return 0;
}

class CashierOrdersResponse {
  final bool success;
  final OrderStats stats;
  final int total;
  final int limit;
  final int offset;
  final List<PosOrder> orders;

  CashierOrdersResponse({
    required this.success,
    required this.stats,
    required this.total,
    required this.limit,
    required this.offset,
    required this.orders,
  });

  factory CashierOrdersResponse.fromJson(Map<String, dynamic> json) {
    return CashierOrdersResponse(
      success: json['success'] ?? false,
      stats: OrderStats.fromJson(json['stats'] ?? {}),
      total: json['total'] ?? 0,
      limit: (json['limit'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          ((json['orders'] as List?)?.length ?? 0),
      offset: json['offset'] ?? 0,
      orders:
          (json['orders'] as List?)
              ?.map((o) => PosOrder.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class OrderStats {
  final int total;
  final int draft;
  final int inProgress;
  final int readyForInvoice;
  final int invoiced;
  final int cancelled;
  final int waitingForCorporateApproval;
  final int corporateApproved;
  final int rejectedByCorporate;

  OrderStats({
    required this.total,
    required this.draft,
    required this.inProgress,
    required this.readyForInvoice,
    required this.invoiced,
    required this.cancelled,
    this.waitingForCorporateApproval = 0,
    this.corporateApproved = 0,
    this.rejectedByCorporate = 0,
  });

  static int _statInt(Map<String, dynamic> json, Object key) {
    final v = json[key.toString()];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      total: _statInt(json, 'total'),
      draft: _statInt(json, 'draft'),
      inProgress: _statInt(json, 'in progress') != 0
          ? _statInt(json, 'in progress')
          : _statInt(json, 'in_progress'),
      readyForInvoice: _statInt(json, 'ready_for_invoice'),
      invoiced: _statInt(json, 'invoiced') != 0
          ? _statInt(json, 'invoiced')
          : _statInt(json, 'completed'),
      cancelled: _statInt(json, 'cancelled'),
      waitingForCorporateApproval: _statInt(json, 'waiting for corporate approval'),
      corporateApproved: _statInt(json, 'corporate approved'),
      rejectedByCorporate: _statInt(json, 'rejected by corporate'),
    );
  }

  factory OrderStats.empty() => OrderStats(
        total: 0,
        draft: 0,
        inProgress: 0,
        readyForInvoice: 0,
        invoiced: 0,
        cancelled: 0,
        waitingForCorporateApproval: 0,
        corporateApproved: 0,
        rejectedByCorporate: 0,
      );
}

double _parseJobTotalAmount(Map<String, dynamic> json) {
  for (final key in [
    'totalAmount',
    'total_amount',
    'grandTotal',
    'grand_total',
    'finalTotal',
    'final_total',
  ]) {
    final raw = json[key];
    if (raw == null) continue;
    final v = double.tryParse(raw.toString());
    if (v != null && v > 0) return v;
  }
  return double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0;
}

double _parseJobDoubleField(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw == null) continue;
    final v = double.tryParse(raw.toString());
    if (v != null) return v;
  }
  return 0.0;
}

double _parseFirstDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw == null) continue;
    final parsed = double.tryParse(raw.toString());
    if (parsed != null) return parsed;
  }
  return 0.0;
}

class PosOrderJob {
  final String id;
  final String status;
  final String department;
  /// Backend department id when provided (speeds up cashier flows).
  final String? departmentId;
  final List<PosOrderJobItem> items;
  final List<JobTechnician> technicians;
  
  // Job-level API pricing (GET /cashier/orders is authoritative).
  // All amounts are now VAT-exclusive from the backend.
  /// Gross excl. VAT (before any discounts).
  final double amountBeforeDiscount;
  /// After line discounts (excl. VAT).
  final double amountAfterDiscount;
  /// Total taxable amount (after all discounts, before VAT).
  final double amountAfterPromo;
  final double totalAmount;
  final double vatAmount;
  final double vatPercent;
  final String? promoCodeId;
  final String? promoCodeName;
  final String? promoDiscountType;
  final double promoDiscountValue;
  final double promoDiscountAmount;
  final String? totalDiscountType;
  final double totalDiscountValue;

  PosOrderJob({
    required this.id,
    required this.status,
    required this.department,
    this.departmentId,
    this.items = const [],
    this.technicians = const [],
    this.amountBeforeDiscount = 0.0,
    this.amountAfterDiscount = 0.0,
    this.amountAfterPromo = 0.0,
    this.totalAmount = 0.0,
    this.vatAmount = 0.0,
    this.vatPercent = 15.0,
    this.promoCodeId,
    this.promoCodeName,
    this.promoDiscountType,
    this.promoDiscountValue = 0.0,
    this.promoDiscountAmount = 0.0,
    this.totalDiscountType,
    this.totalDiscountValue = 0.0,
  });

  /// Rows that are not clearly terminated (cancelled / removed). May still include many
  /// historical `completed` slices — use [distinctActiveTechnicians] for cashier UI counts.
  List<JobTechnician> get activeTechnicians =>
      technicians.where((t) => t.isActiveAssignment).toList();

  /// One row per employee for cashier UI / assign picker. GET /cashier/orders returns full
  /// **assignments** history (`completed`, `cancelled`, `in progress`, …). We pick the **best
  /// current** row per employee: prefer `in progress` over `completed`, then latest `assignedAt`.
  List<JobTechnician> get distinctActiveTechnicians {
    final candidates =
        technicians.where((t) => _assignmentRowNotTerminated(t)).toList();
    if (candidates.isEmpty) return [];
    final byEmployee = <String, List<JobTechnician>>{};
    for (final t in candidates) {
      final key = t.pickerEmployeeId.trim().isNotEmpty
          ? t.pickerEmployeeId.trim()
          : t.id.trim();
      if (key.isEmpty) continue;
      byEmployee.putIfAbsent(key, () => []).add(t);
    }
    final out = <JobTechnician>[];
    for (final list in byEmployee.values) {
      if (list.isEmpty) continue;
      var best = list.first;
      for (var i = 1; i < list.length; i++) {
        best = _preferCurrentAssignmentRow(best, list[i]);
      }
      out.add(best);
    }
    // Same person often appears twice when one row has [employeeId] and another only assignment [id].
    return _dedupeActiveTechniciansByName(out);
  }

  /// When the API omits [JobTechnician.employeeId] on some rows, [pickerEmployeeId] falls back to
  /// assignment [id] and the same person becomes multiple buckets — merge by normalized [name].
  static List<JobTechnician> _dedupeActiveTechniciansByName(List<JobTechnician> rows) {
    if (rows.length <= 1) return rows;
    final byName = <String, List<JobTechnician>>{};
    var unnamed = 0;
    for (final t in rows) {
      final k = t.name.trim().toLowerCase();
      byName.putIfAbsent(k.isEmpty ? '__noname_${unnamed++}' : k, () => []).add(t);
    }
    final out = <JobTechnician>[];
    for (final list in byName.values) {
      if (list.isEmpty) continue;
      if (list.length == 1) {
        out.add(list.first);
        continue;
      }
      var best = list.first;
      for (var i = 1; i < list.length; i++) {
        best = _preferCurrentAssignmentRow(best, list[i]);
      }
      out.add(best);
    }
    return out;
  }

  static bool _assignmentRowNotTerminated(JobTechnician t) {
    final s = (t.status ?? '').trim().toLowerCase();
    if (s == 'cancelled' || s == 'canceled') return false;
    if (s == 'removed' || s == 'rejected') return false;
    return true;
  }

  /// Higher = more "current" for roster purposes.
  static int _assignmentStatusRank(String? status) {
    var s = (status ?? '').trim().toLowerCase();
    if (s == 'in progress' || s == 'in_progress') return 5;
    if (s == 'accepted' || s == 'accepted_by_technician') return 4;
    if (s == 'pending' || s == 'assigned') return 3;
    if (s.isEmpty) return 2;
    if (s == 'completed') return 1;
    return 2;
  }

  static JobTechnician _preferCurrentAssignmentRow(JobTechnician a, JobTechnician b) {
    final ra = _assignmentStatusRank(a.status);
    final rb = _assignmentStatusRank(b.status);
    if (ra != rb) return ra > rb ? a : b;
    final da = DateTime.tryParse(a.assignedAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final db = DateTime.tryParse(b.assignedAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (da != db) return da.isAfter(db) ? a : b;
    final ida = int.tryParse(a.id) ?? 0;
    final idb = int.tryParse(b.id) ?? 0;
    return ida >= idb ? a : b;
  }

  bool get isCancelledJob {
    final s = status.trim().toLowerCase();
    return s == 'cancelled' || s == 'canceled';
  }

  factory PosOrderJob.fromJson(Map<String, dynamic> json) {
    final jobId = json['id']?.toString() ?? '';
    final rawDept = json['department'];
    final deptObj = rawDept is Map ? Map<String, dynamic>.from(rawDept) : null;
    final parsedDeptName =
        deptObj?['name']?.toString() ??
        json['departmentName']?.toString() ??
        (rawDept is String ? rawDept : '');
    final parsedDeptId =
        deptObj?['id']?.toString() ??
        json['departmentId']?.toString() ??
        json['department_id']?.toString();
    return PosOrderJob(
      id: jobId,
      status: json['status'] ?? '',
      department: parsedDeptName,
      departmentId: parsedDeptId,
      amountBeforeDiscount: _parseJobDoubleField(json, [
        'amountBeforeDiscount',
        'amount_before_discount',
      ]),
      amountAfterDiscount: _parseJobDoubleField(json, [
        'amountAfterDiscount',
        'amount_after_discount',
      ]),
      amountAfterPromo: _parseJobDoubleField(json, [
        'amountAfterPromo',
        'amount_after_promo',
      ]),
      totalAmount: _parseJobTotalAmount(json),
      vatAmount: double.tryParse(json['vatAmount']?.toString() ?? json['vat_amount']?.toString() ?? '0') ?? 0.0,
      vatPercent: double.tryParse(json['vatPercent']?.toString() ?? '15') ?? 15.0,
      promoCodeId: json['promoCodeId']?.toString(),
      promoCodeName: json['promoCodeName']?.toString(),
      promoDiscountType: json['promoDiscountType']?.toString(),
      promoDiscountValue: double.tryParse(json['promoDiscountValue']?.toString() ?? '0') ?? 0.0,
      promoDiscountAmount: double.tryParse(json['promoDiscountAmount']?.toString() ?? '0') ?? 0.0,
      totalDiscountType: json['totalDiscountType']?.toString(),
      totalDiscountValue: double.tryParse(json['totalDiscountValue']?.toString() ?? '0') ?? 0.0,
      items:
          (json['items'] as List?)
              ?.map((i) => PosOrderJobItem.fromJson(i))
              .where((item) => item.jobId == null || item.jobId == jobId)
              .toList() ??
          [],
      technicians: _parseJobTechniciansList(json),
    );
  }

  /// GET /cashier/orders may use `technicians` and/or `assignments` (same shape as assign response).
  /// Prefer **`technicians`** when non-empty — that is the job’s current roster from the API. Do not
  /// merge with `assignments` (full history); merging re‑showed removed technicians after product
  /// pricing updates. Fall back to `assignments` only when `technicians` is missing or empty.
  static List<JobTechnician> _parseJobTechniciansList(Map<String, dynamic> json) {
    List<JobTechnician> parseList(List<dynamic>? list) {
      if (list == null) return [];
      return list
          .map((t) {
            if (t is! Map) return null;
            return JobTechnician.fromJson(Map<String, dynamic>.from(t));
          })
          .whereType<JobTechnician>()
          .toList();
    }

    final tech = parseList(json['technicians'] as List?);
    if (tech.isNotEmpty) {
      sortJobTechniciansList(tech);
      return tech;
    }
    final assignments = parseList(json['assignments'] as List?);
    sortJobTechniciansList(assignments);
    return assignments;
  }

  PosOrderJob copyWith({
    String? status,
    List<PosOrderJobItem>? items,
    List<JobTechnician>? technicians,
  }) {
    return PosOrderJob(
      id: id,
      status: status ?? this.status,
      department: department,
      departmentId: departmentId,
      items: items ?? this.items,
      technicians: technicians ?? this.technicians,
      amountBeforeDiscount: amountBeforeDiscount,
      amountAfterDiscount: amountAfterDiscount,
      amountAfterPromo: amountAfterPromo,
      totalAmount: totalAmount,
      vatAmount: vatAmount,
      vatPercent: vatPercent,
      promoCodeId: promoCodeId,
      promoCodeName: promoCodeName,
      promoDiscountType: promoDiscountType,
      promoDiscountValue: promoDiscountValue,
      promoDiscountAmount: promoDiscountAmount,
      totalDiscountType: totalDiscountType,
      totalDiscountValue: totalDiscountValue,
    );
  }
}

class JobTechnician {
  /// Assignment row id when present; may differ from [employeeId].
  final String id;
  /// Employee id for cashier catalog / POST `employeeIds` (from assign or orders payload).
  final String? employeeId;
  final String name;
  final double commissionPercent;
  final double commissionAmount;
  final String? status;
  /// From assignment row; used to pick latest row when API returns history.
  final String? assignedAt;

  JobTechnician({
    required this.id,
    this.employeeId,
    required this.name,
    required this.commissionPercent,
    required this.commissionAmount,
    this.status,
    this.assignedAt,
  });

  /// Id used to match [PosTechnician.id] in the assign-technician picker.
  String get pickerEmployeeId {
    final e = employeeId?.trim();
    if (e != null && e.isNotEmpty) return e;
    return id.trim();
  }

  /// `false` when API keeps a row after unassign (e.g. [status] `cancelled`).
  bool get isActiveAssignment {
    final s = (status ?? '').trim().toLowerCase();
    if (s.isEmpty) return true;
    if (s == 'cancelled' || s == 'canceled') return false;
    if (s == 'removed' || s == 'rejected') return false;
    return true;
  }

  static String? _employeeIdFromJson(Map<String, dynamic> json) {
    for (final k in ['employeeId', 'employee_id']) {
      final v = json[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    for (final nestedKey in ['employee', 'user', 'technician']) {
      final o = json[nestedKey];
      if (o is Map) {
        final m = Map<String, dynamic>.from(o);
        for (final idKey in ['id', 'employeeId', 'userId']) {
          final v = m[idKey]?.toString().trim();
          if (v != null && v.isNotEmpty) return v;
        }
      }
    }
    return null;
  }

  factory JobTechnician.fromJson(Map<String, dynamic> json) {
    return JobTechnician(
      id: json['id']?.toString() ?? '',
      employeeId: _employeeIdFromJson(json),
      name: json['name']?.toString() ??
          json['employeeName']?.toString() ??
          '',
      commissionPercent:
          double.tryParse(
            json['commissionPercent']?.toString() ??
                json['commission_percent']?.toString() ??
                json['commissionPct']?.toString() ??
                '0',
          ) ??
          0.0,
      commissionAmount:
          double.tryParse(
            json['commissionAmount']?.toString() ??
                json['commission_amount']?.toString() ??
                json['commission']?.toString() ??
                '0',
          ) ??
          0.0,
      status: json['status']?.toString() ?? json['assignmentStatus']?.toString() ?? '',
      assignedAt: json['assignedAt']?.toString() ?? json['assigned_at']?.toString(),
    );
  }
}

/// Stable job roster order (name, then employee id).
int compareJobTechniciansStable(JobTechnician a, JobTechnician b) {
  final nameCmp = a.name.toLowerCase().trim().compareTo(b.name.toLowerCase().trim());
  if (nameCmp != 0) return nameCmp;
  return a.pickerEmployeeId.compareTo(b.pickerEmployeeId);
}

void sortJobTechniciansList(List<JobTechnician> list) {
  if (list.length < 2) return;
  list.sort(compareJobTechniciansStable);
}

class PosOrderJobItem {
  final String id;
  final String itemType;
  final String productId;
  final String productName;
  final String productNameArabic;
  final String departmentId;
  final String departmentName;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final double unitPriceExcludingVat;
  final double lineTotalExcludingVat;
  final double lineVatAmount;
  final String? jobId;
  final String? discountType;
  final double? discountValue;

  PosOrderJobItem({
    required this.id,
    required this.itemType,
    required this.productId,
    required this.productName,
    this.productNameArabic = '',
    required this.departmentId,
    required this.departmentName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.unitPriceExcludingVat = 0.0,
    this.lineTotalExcludingVat = 0.0,
    this.lineVatAmount = 0.0,
    this.jobId,
    this.discountType,
    this.discountValue = 0.0,
  });

  factory PosOrderJobItem.fromJson(Map<String, dynamic> json) {
    final rawDept = json['department'];
    final deptObj = rawDept is Map ? Map<String, dynamic>.from(rawDept) : null;
    final typeRaw = (json['itemType'] ?? '').toString().trim().toLowerCase();
    final serviceId = _firstNonEmptyString([
      json['serviceId'],
      json['service_id'],
    ]) ??
        '';
    final productIdOnly = _firstNonEmptyString([
      json['productId'],
      json['product_id'],
    ]) ??
        '';
    final isServiceLine =
        typeRaw == 'service' || (serviceId.isNotEmpty && productIdOnly.isEmpty);
    final catalogLineId = isServiceLine
        ? (serviceId.isNotEmpty ? serviceId : productIdOnly)
        : (productIdOnly.isNotEmpty ? productIdOnly : serviceId);
    return PosOrderJobItem(
      id: json['id']?.toString() ?? '',
      itemType: json['itemType'] ?? (isServiceLine ? 'service' : 'product'),
      productId: catalogLineId,
      productName: json['productName']?.toString() ?? '',
      productNameArabic: _firstNonEmptyString([
        json['productNameArabic'],
        json['product_name_arabic'],
        json['nameArabic'],
        json['name_arabic'],
        json['arabicName'],
        json['arabic_name'],
        (json['product'] is Map) ? (json['product'] as Map)['nameArabic'] : null,
        (json['product'] is Map) ? (json['product'] as Map)['productNameArabic'] : null,
      ]) ?? '',
      departmentId:
          json['departmentId']?.toString() ??
          json['department_id']?.toString() ??
          deptObj?['id']?.toString() ??
          '',
      departmentName:
          json['departmentName']?.toString() ??
          deptObj?['name']?.toString() ??
          '',
      qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0.0,
      lineTotal: double.tryParse(json['lineTotal']?.toString() ?? '0') ?? 0.0,
      unitPriceExcludingVat:
          double.tryParse(json['unitPriceExcludingVat']?.toString() ?? '0') ?? 0.0,
      lineTotalExcludingVat:
          double.tryParse(json['lineTotalExcludingVat']?.toString() ?? '0') ?? 0.0,
      lineVatAmount: double.tryParse(json['lineVatAmount']?.toString() ?? '0') ?? 0.0,
      jobId: json['jobId']?.toString() ?? json['job_id']?.toString(),
      discountType: json['discountType']?.toString(),
      discountValue: double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

List<PosPaymentDraftRow>? _parsePosPaymentsList(Map<String, dynamic> json) {
  final raw = json['posPayments'] ?? json['pos_payments'];
  if (raw is! List || raw.isEmpty) return null;
  final out = <PosPaymentDraftRow>[];
  for (final e in raw) {
    out.add(PosPaymentDraftRow.fromJson(e));
  }
  return out.isEmpty ? null : out;
}

class PosOrder {
  final String id;
  final String status;
  final String source;
  final int odometerReading;
  final String createdAt;
  final String submittedAt;
  final String orderDateTime;
  final String orderDate;
  final String orderTime;
  final OrderCustomer? customer;
  final OrderVehicle? vehicle;
  final int jobsCount;
  final String assignedTo;
  final List<PosOrderJob> jobs;
  final List<dynamic> items;
  /// false on slim GET /cashier/orders rows — hydrate via GET /cashier/order/:id.
  final bool linesIncluded;

  final String? totalDiscountType;
  final double? totalDiscountValue;
  final String? invoiceNo;
  final String? promoCodeId;
  final String? promoCodeName;
  final double? promoDiscountAmount;
  final String? promoDiscountType;
  final double? promoDiscountValue;

  /// Marketing referral code stamped on the sales order (customer benefit).
  final String? referralCode;
  final String? marketingReferrerId;
  final String? referralReferrerName;
  /// Preview / computed VAT-inclusive customer benefit discount.
  final double referralDiscountAmount;
  
  // Aggregate fields from backend
  final double totalAmount;
  final double subtotal;

  final String? corporateAccountId;
  final String? corporateCompanyName;
  final String? corporateApprovalRejectionReason;
  final String? corporateOrderId;
  final String? paymentMethod;
  /// Backend may set when this cashier order was created from Corporate Bookings (not walk-in corporate).
  final bool fromCorporateBooking;
  final List<dynamic> pendingDepartments;
  final List<dynamic> proposalDepartments;

  /// Draft from `PATCH /cashier/order/:id/payment-method` (GET order / orders).
  final String? posCustomerKind;
  final List<PosPaymentDraftRow>? posPayments;
  /// After Request Payment — locked until invoice.
  final double? posPrepaidAmount;
  final String? posPrepaidAt;
  final List<PosPaymentDraftRow>? posPrepaidPayments;
  final String? posPrepaidIntentId;
  /// From GET order(s) `{ "maintenanceChecklist": { "checks": [...] } }`.
  final List<bool>? maintenanceChecks;

  bool get isPosPrepaid =>
      posPrepaidAmount != null && (posPrepaidAmount ?? 0) > 0.001;

  /// Prepaid via Orders Hub SoftPOS app-bar widget (may differ from order total).
  bool get isSoftPosAppBarPrepaid {
    if (!isPosPrepaid) return false;
    final rows = posPrepaidPayments ?? posPayments;
    if (rows == null || rows.isEmpty) return false;
    return rows.any((r) => r.isSoftPosAppBar);
  }

  bool prepaidAmountMatchesTotal(double currentTotal) {
    if (!isPosPrepaid) return true;
    return (currentTotal - posPrepaidAmount!).abs() <= 0.05;
  }

  /// SoftPOS app-bar: invoice allowed even when totals differ.
  bool canInvoiceWithPrepaidMismatch(double currentTotal) {
    if (!isPosPrepaid) return true;
    if (prepaidAmountMatchesTotal(currentTotal)) return true;
    return isSoftPosAppBarPrepaid;
  }

  String get prepaidPaymentMethodLabel {
    final rows = posPrepaidPayments ?? posPayments;
    if (rows == null || rows.isEmpty) return '';
    if (rows.length == 1) return rows.first.method;
    return rows.map((r) => '${r.method} ${r.amount.toStringAsFixed(2)}').join(' + ');
  }

  PosOrder({
    required this.id,
    required this.status,
    required this.source,
    required this.odometerReading,
    required this.createdAt,
    this.submittedAt = '',
    this.orderDateTime = '',
    this.orderDate = '',
    this.orderTime = '',
    this.customer,
    this.vehicle,
    required this.jobsCount,
    this.assignedTo = '',
    this.jobs = const [],
    this.items = const [],
    this.linesIncluded = true,
    this.totalDiscountType,
    this.totalDiscountValue,
    this.invoiceNo,
    this.promoCodeId,
    this.promoCodeName,
    this.promoDiscountAmount,
    this.promoDiscountType,
    this.promoDiscountValue,
    this.referralCode,
    this.marketingReferrerId,
    this.referralReferrerName,
    this.referralDiscountAmount = 0.0,
    this.totalAmount = 0.0,
    this.subtotal = 0.0,
    this.corporateAccountId,
    this.corporateCompanyName,
    this.corporateApprovalRejectionReason,
    this.corporateOrderId,
    this.paymentMethod,
    this.fromCorporateBooking = false,
    this.pendingDepartments = const [],
    this.proposalDepartments = const [],
    this.posCustomerKind,
    this.posPayments,
    this.posPrepaidAmount,
    this.posPrepaidAt,
    this.posPrepaidPayments,
    this.posPrepaidIntentId,
    this.maintenanceChecks,
  });

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    final corporate = _asMap(json['corporate']);
    final corporateOrder = _asMap(json['corporateOrder']);
    final corporateOrderVehicle = _asMap(corporateOrder['vehicle']);
    final vehicleMap = _asMap(json['vehicle']);
    final effectiveVehicle = vehicleMap.isNotEmpty ? vehicleMap : corporateOrderVehicle;
    final salesOrder = _asMap(json['salesOrder']);

    final parsedJobs =
        (json['jobs'] as List?)?.map((j) => PosOrderJob.fromJson(j)).toList() ??
        [];
    final originHints = [
      json['origin'],
      json['orderType'],
      json['orderSource'],
      corporate['origin'],
      corporateOrder['origin'],
    ];
    var fromBooking = _asBool(json['fromCorporateBooking']) ||
        _asBool(json['isCorporateBooking']) ||
        _asBool(json['corporateBooking']) ||
        _asBool(corporateOrder['fromCorporateBooking']) ||
        _asBool(corporate['fromCorporateBooking']);
    if (!fromBooking) {
      for (final h in originHints) {
        if (h == null) continue;
        final t = h.toString().toLowerCase();
        if (t.contains('corporate_booking') ||
            t.contains('corp_booking') ||
            t.contains('corporate_app') ||
            (t.contains('booking') && t.contains('corporate'))) {
          fromBooking = true;
          break;
        }
      }
    }
    if (!fromBooking) {
      final w = json['walkIn'] ?? json['isWalkIn'] ?? json['isWalkInOrder'];
      if (w == false &&
          (corporateOrder.isNotEmpty ||
              (json['corporateAccountId']?.toString().trim().isNotEmpty ?? false) ||
              (corporate['accountId']?.toString().trim().isNotEmpty ?? false))) {
        fromBooking = true;
      }
    }
    final resolvedCorporateOrderId = _firstNonEmptyString([
      corporateOrder['id'],
      corporateOrder['_id'],
      corporateOrder['orderId'],
      json['corporateOrderId'],
      json['corporate_order_id'],
      salesOrder['corporateOrderId'],
      salesOrder['corporate_order_id'],
    ]);
    return PosOrder(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      source: json['source'] ?? '',
      odometerReading: _firstNonZeroInt([
        json['odometerReading'],
        json['odometer'],
        salesOrder['odometerReading'],
        salesOrder['odometer'],
        effectiveVehicle['odometerReading'],
        effectiveVehicle['odometer'],
        corporateOrder['odometerReading'],
        corporateOrder['odometer'],
      ]),
      createdAt: json['createdAt'] ?? '',
      submittedAt: _firstNonEmptyString([
            json['submittedAt'],
            corporateOrder['submittedAt'],
          ]) ??
          '',
      orderDateTime: json['orderDateTime']?.toString() ?? '',
      orderDate: json['orderDate']?.toString() ?? '',
      orderTime: json['orderTime']?.toString() ?? '',
      customer: json['customer'] != null
          ? OrderCustomer.fromJson(json['customer'])
          : () {
              final name = _firstNonEmptyString([
                json['customerName'],
                json['customer_name'],
              ]);
              final mobile = _firstNonEmptyString([
                json['customerPhone'],
                json['customer_phone'],
                json['phone'],
              ]);
              if (name == null && mobile == null) return null;
              return OrderCustomer.fromJson({
                'id': json['customerId'] ?? json['customer_id'] ?? '',
                'name': name ?? '',
                'mobile': mobile ?? '',
                'taxId': json['customerTaxId'] ?? json['taxId'],
              });
            }(),
      vehicle: effectiveVehicle.isNotEmpty
          ? OrderVehicle.fromJson(effectiveVehicle)
          : null,
      jobsCount:
          (json['jobsCount'] as num?)?.toInt() ??
          parsedJobs.length,
      assignedTo: json['assignedTo']?.toString() ?? '',
      jobs: parsedJobs,
      items: _resolveOrderItemsList(json, parsedJobs),
      linesIncluded: json['linesIncluded'] != false &&
          json['lines_included'] != false,
      totalDiscountType: json['totalDiscountType']?.toString(),
      totalDiscountValue: double.tryParse(json['totalDiscountValue']?.toString() ?? '0') ?? 0.0,
      invoiceNo: json['invoiceNo']?.toString() ?? json['invoice_no']?.toString() ?? json['invoiceId']?.toString() ?? json['invoice_id']?.toString(),
      promoCodeId: json['promoCodeId']?.toString(),
      promoCodeName: json['promoCodeName']?.toString(),
      promoDiscountAmount: double.tryParse(json['promoDiscountAmount']?.toString() ?? '0') ?? 0.0,
      promoDiscountType: json['promoDiscountType']?.toString(),
      promoDiscountValue: double.tryParse(json['promoDiscountValue']?.toString() ?? '0') ?? 0.0,
      referralCode: json['referralCode']?.toString() ??
          json['referral_code']?.toString(),
      marketingReferrerId: json['marketingReferrerId']?.toString() ??
          json['marketing_referrer_id']?.toString(),
      referralReferrerName: json['referralReferrerName']?.toString() ??
          json['referral_referrer_name']?.toString(),
      referralDiscountAmount:
          double.tryParse(json['referralDiscountAmount']?.toString() ??
                  json['referral_discount_amount']?.toString() ??
                  '0') ??
              0.0,
      totalAmount: _parseFirstDouble(json, [
        'totalAmount',
        'total_amount',
        'grandTotal',
        'grand_total',
        'finalTotal',
        'final_total',
      ]),
      subtotal: _parseFirstDouble(json, [
        'subtotal',
        'sub_total',
        'amountAfterPromo',
        'amount_after_promo',
        'amountAfterDiscount',
        'amount_after_discount',
      ]),
      corporateAccountId: _firstNonEmptyString([
        json['corporateAccountId'],
        json['corporate_account_id'],
        corporate['accountId'],
      ]),
      corporateCompanyName: _firstNonEmptyString([
        json['corporateCompanyName'],
        json['corporate_company_name'],
        corporate['companyName'],
      ]),
      corporateApprovalRejectionReason: json['corporateApprovalRejectionReason']?.toString(),
      corporateOrderId: resolvedCorporateOrderId,
      paymentMethod: _firstNonEmptyString([
        json['paymentMethod'],
        json['payment_method'],
        json['preferredPaymentMethod'],
        json['bookingPaymentMethod'],
        corporateOrder['paymentMethod'],
        corporateOrder['payment_method'],
        corporateOrder['preferredPaymentMethod'],
        corporate['paymentMethod'],
        corporate['preferredPaymentMethod'],
      ]),
      fromCorporateBooking: fromBooking,
      pendingDepartments: json['pendingDepartments'] is List
          ? List<dynamic>.from(json['pendingDepartments'] as List)
          : const [],
      proposalDepartments: json['proposalDepartments'] is List
          ? List<dynamic>.from(json['proposalDepartments'] as List)
          : const [],
      posCustomerKind: () {
        final s = _firstNonEmptyString([
          json['posCustomerKind'],
          json['pos_customer_kind'],
        ])?.trim();
        return s?.isNotEmpty == true ? s : null;
      }(),
      posPayments: _parsePosPaymentsList(json),
      posPrepaidAmount: double.tryParse(
        json['posPrepaidAmount']?.toString() ??
            json['pos_prepaid_amount']?.toString() ??
            '',
      ),
      posPrepaidAt: _firstNonEmptyString([
        json['posPrepaidAt'],
        json['pos_prepaid_at'],
      ]),
      posPrepaidPayments: _parsePosPaymentsList({
        'posPayments':
            json['posPrepaidPayments'] ?? json['pos_prepaid_payments'],
      }),
      posPrepaidIntentId: _firstNonEmptyString([
        json['posPrepaidIntentId'],
        json['pos_prepaid_intent_id'],
      ]),
      maintenanceChecks:
          _parseMaintenanceChecks(json['maintenanceChecklist']) ??
              _parseMaintenanceChecks(json['maintenance_checklist']),
    );
  }

  PosOrder copyWith({
    String? id,
    String? status,
    String? source,
    int? odometerReading,
    String? createdAt,
    String? submittedAt,
    String? orderDateTime,
    String? orderDate,
    String? orderTime,
    OrderCustomer? customer,
    OrderVehicle? vehicle,
    int? jobsCount,
    String? assignedTo,
    List<PosOrderJob>? jobs,
    List<dynamic>? items,
    bool? linesIncluded,
    String? totalDiscountType,
    double? totalDiscountValue,
    String? invoiceNo,
    String? promoCodeId,
    String? promoCodeName,
    double? promoDiscountAmount,
    String? promoDiscountType,
    double? promoDiscountValue,
    String? referralCode,
    String? marketingReferrerId,
    String? referralReferrerName,
    double? referralDiscountAmount,
    double? totalAmount,
    double? subtotal,
    String? corporateAccountId,
    String? corporateCompanyName,
    String? corporateApprovalRejectionReason,
    String? corporateOrderId,
    String? paymentMethod,
    bool? fromCorporateBooking,
    List<dynamic>? pendingDepartments,
    List<dynamic>? proposalDepartments,
    String? posCustomerKind,
    List<PosPaymentDraftRow>? posPayments,
    double? posPrepaidAmount,
    String? posPrepaidAt,
    List<PosPaymentDraftRow>? posPrepaidPayments,
    String? posPrepaidIntentId,
    List<bool>? maintenanceChecks,
  }) {
    return PosOrder(
      id: id ?? this.id,
      status: status ?? this.status,
      source: source ?? this.source,
      odometerReading: odometerReading ?? this.odometerReading,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      orderDateTime: orderDateTime ?? this.orderDateTime,
      orderDate: orderDate ?? this.orderDate,
      orderTime: orderTime ?? this.orderTime,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      jobsCount: jobsCount ?? this.jobsCount,
      assignedTo: assignedTo ?? this.assignedTo,
      jobs: jobs ?? this.jobs,
      items: items ?? this.items,
      linesIncluded: linesIncluded ?? this.linesIncluded,
      totalDiscountType: totalDiscountType ?? this.totalDiscountType,
      totalDiscountValue: totalDiscountValue ?? this.totalDiscountValue,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      promoCodeName: promoCodeName ?? this.promoCodeName,
      promoDiscountAmount: promoDiscountAmount ?? this.promoDiscountAmount,
      promoDiscountType: promoDiscountType ?? this.promoDiscountType,
      promoDiscountValue: promoDiscountValue ?? this.promoDiscountValue,
      referralCode: referralCode ?? this.referralCode,
      marketingReferrerId: marketingReferrerId ?? this.marketingReferrerId,
      referralReferrerName: referralReferrerName ?? this.referralReferrerName,
      referralDiscountAmount:
          referralDiscountAmount ?? this.referralDiscountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      corporateAccountId: corporateAccountId ?? this.corporateAccountId,
      corporateCompanyName: corporateCompanyName ?? this.corporateCompanyName,
      corporateApprovalRejectionReason:
          corporateApprovalRejectionReason ?? this.corporateApprovalRejectionReason,
      corporateOrderId: corporateOrderId ?? this.corporateOrderId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fromCorporateBooking: fromCorporateBooking ?? this.fromCorporateBooking,
      pendingDepartments: pendingDepartments ?? this.pendingDepartments,
      proposalDepartments: proposalDepartments ?? this.proposalDepartments,
      posCustomerKind: posCustomerKind ?? this.posCustomerKind,
      posPayments: posPayments ?? this.posPayments,
      posPrepaidAmount: posPrepaidAmount ?? this.posPrepaidAmount,
      posPrepaidAt: posPrepaidAt ?? this.posPrepaidAt,
      posPrepaidPayments: posPrepaidPayments ?? this.posPrepaidPayments,
      posPrepaidIntentId: posPrepaidIntentId ?? this.posPrepaidIntentId,
      maintenanceChecks: maintenanceChecks ?? this.maintenanceChecks,
    );
  }

  bool get isCorporateWalkIn =>
      source.toLowerCase().contains('corporate') ||
      (corporateAccountId != null && corporateAccountId!.isNotEmpty) ||
      (corporateOrderId != null && corporateOrderId!.isNotEmpty) ||
      (corporateCompanyName != null && corporateCompanyName!.trim().isNotEmpty);

  /// Corporate **booking** (Corporate Bookings → cashier). When true, skip walk-in billing PATCH.
  /// Not the same as cashier-initiated corporate walk-in (`unapproved` / `waiting…` quote flow).
  bool get isCorporateBookingOrder {
    if (fromCorporateBooking) return true;

    final s =
        source.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_').trim();
    if (s.isEmpty) return false;

    if (s.contains('corporate_booking') || s.contains('corp_booking')) return true;
    if (s.contains('booking') && s.contains('corporate')) return true;
    if (s.contains('booking') && (corporateAccountId ?? '').trim().isNotEmpty) {
      return true;
    }

    // Cashier corporate walk-in quote — keep billing API.
    if (isCorporateUnapproved || isWaitingCorporateApproval || isRejectedByCorporate) {
      return false;
    }
    // After corporate approval, walk-in-shaped orders use billing PATCH again.
    if (isCorporateApproved) return false;

    // `walk_in_corporate` / similar: execution pipeline from booking, not the quote states above.
    if ((s.contains('walk_in') || s.contains('walkin')) && s.contains('corporate')) {
      return true;
    }

    // Booking fulfillment: corporate payload but `source` is not a cashier walk-in string
    // (backend rejects PATCH /billing for these orders).
    final walkInLike = s == 'walk_in' ||
        s == 'walkin' ||
        (s.contains('walk_in') && s.isNotEmpty);
    if (!walkInLike) {
      if (isCorporateUnapproved ||
          isWaitingCorporateApproval ||
          isRejectedByCorporate ||
          isCorporateApproved) {
        return false;
      }
      if ((corporateAccountId ?? '').trim().isNotEmpty ||
          (corporateCompanyName ?? '').trim().isNotEmpty ||
          (corporateOrderId ?? '').trim().isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  String get normalizedOrderStatus => status.trim().toLowerCase();

  /// Cashier order queue hides invoiced sales orders (API + local list).
  bool get isVisibleInCashierOrderQueue {
    if (normalizedOrderStatus == 'invoiced') return false;
    if (normalizedJobStatus == 'invoiced') return false;
    return true;
  }

  bool get isCorporateUnapproved => normalizedOrderStatus == 'unapproved';
  bool get isWaitingCorporateApproval =>
      normalizedOrderStatus == 'waiting for corporate approval';
  bool get isCorporateApproved => normalizedOrderStatus == 'corporate approved';
  bool get isRejectedByCorporate =>
      normalizedOrderStatus == 'rejected by corporate';

  List<String> get selectedDepartmentNames {
    final fromJobs = jobs
        .map((j) => j.department.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    if (fromJobs.isNotEmpty) return fromJobs;

    final out = <String>{};
    for (final raw in [...pendingDepartments, ...proposalDepartments]) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final name = _firstNonEmptyString([
        m['name'],
        m['departmentName'],
        m['department_name'],
      ]);
      if (name != null && name.trim().isNotEmpty) {
        out.add(name.trim());
      }
    }
    return out.toList();
  }

  List<Map<String, String>> get selectedDepartmentEntries {
    final entries = <Map<String, String>>[];
    final seen = <String>{};
    for (final raw in [...pendingDepartments, ...proposalDepartments]) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final name = _firstNonEmptyString([
        m['name'],
        m['departmentName'],
        m['department_name'],
      ]);
      if (name == null || name.trim().isEmpty) continue;
      final id = _firstNonEmptyString([
        m['departmentId'],
        m['department_id'],
        m['id'],
      ]);
      final key = '${id ?? ''}|${name.trim().toLowerCase()}';
      if (!seen.add(key)) continue;
      entries.add({
        'id': (id ?? '').trim(),
        'name': name.trim(),
      });
    }
    if (entries.isNotEmpty) return entries;
    for (final n in selectedDepartmentNames) {
      entries.add({'id': '', 'name': n});
    }
    return entries;
  }

  /// Sum of order-level line items (corporate booking / unassigned lines) incl. VAT.
  double get orderLevelLinesPayableTotal {
    if (items.isEmpty) return 0.0;
    var sum = 0.0;
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = PosOrderJobItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.lineTotal > 0.0001) {
        sum += item.lineTotal;
      } else {
        sum += item.lineTotalExcludingVat + item.lineVatAmount;
      }
    }
    return sum;
  }

  /// Payable total aligned with backend `computeCashierOrderEffectiveTotal`:
  /// Σ job totals + unassigned line VAT totals (GET `totalAmount`).
  double get draftPosOrderTotalDisplay {
    final jobsTotal = jobs.fold<double>(0, (s, j) => s + j.totalAmount);
    if (jobsTotal <= 0.0001) {
      if (totalAmount > 0.0001) return totalAmount;
      final lines = orderLevelLinesPayableTotal;
      return lines > 0.0001 ? lines : 0.0;
    }
    if (totalAmount <= 0.0001) return jobsTotal;
    // API total includes unassigned lines when it exceeds jobs sum.
    if (totalAmount >= jobsTotal - 0.01) return totalAmount;
    // Legacy: order.totalAmount may be a single-department rollup — prefer jobs sum.
    return jobsTotal;
  }

  /// Invoice / SoftPOS payable after a stamped referral (benefit is applied at invoice).
  double get draftPosOrderPayableDisplay {
    final base = draftPosOrderTotalDisplay;
    if ((referralCode ?? '').trim().isEmpty) return base;
    return (base - referralDiscountAmount.clamp(0.0, double.infinity))
        .clamp(0.0, double.infinity);
  }

  /// Labels the API uses when no customer was captured at order create (not a real name).
  static bool isPlaceholderCustomerName(String? value) {
    final n = (value ?? '').trim().toLowerCase();
    if (n.isEmpty) return true;
    return n == 'unknown' ||
        n == 'walk-in' ||
        n == 'walk-in customer' ||
        n == 'walk in' ||
        n == 'walk in customer';
  }

  String get customerName {
    final raw = (customer?.name ?? '').trim();
    if (isPlaceholderCustomerName(raw)) return '';
    return raw;
  }
  String get carModel => '${vehicle?.make ?? ""} ${vehicle?.model ?? ""}'.trim();
  String get plateNumber => vehicle?.displayPlate ?? '';
  /// Creation instant used to order the Orders Hub list.
  ///
  /// Creation is preferred over submission so the sort matches the date/time
  /// printed on the hub tile ([date] / [time] both come from `orderDate` /
  /// `orderTime`, which the backend derives from the order's creation instant).
  /// Null when the order carries no usable timestamp at all.
  DateTime? get hubSortInstant {
    for (final raw in [createdAt, orderDateTime]) {
      final iso = raw.trim();
      if (iso.isEmpty) continue;
      final dt = DateTime.tryParse(iso);
      if (dt != null) return dt.toUtc();
    }
    final day = orderDate.trim();
    if (day.isNotEmpty) {
      var clock = orderTime.trim();
      if (clock.isEmpty) clock = '00:00:00';
      if (clock.length == 5) clock = '$clock:00';
      final dt = DateTime.tryParse('${day}T$clock');
      if (dt != null) return dt.toUtc();
    }
    return DateTime.tryParse(submittedAt.trim())?.toUtc();
  }

  /// Best-available date string (YYYY-MM-DD), device-local parse from ISO timestamp
  String get date {
    if (orderDate.isNotEmpty) return orderDate;
    final iso = submittedAt.isNotEmpty ? submittedAt
        : orderDateTime.isNotEmpty ? orderDateTime
        : createdAt;
    if (iso.isEmpty) return '';
    try {
      return DateTime.parse(iso).toLocal().toIso8601String().split('T')[0];
    } catch (_) {
      return iso.split('T')[0];
    }
  }

  /// Best-available time string (HH:mm), device-local
  String get time {
    if (orderTime.isNotEmpty) {
      return orderTime.length >= 5 ? orderTime.substring(0, 5) : orderTime;
    }
    final iso = submittedAt.isNotEmpty ? submittedAt
        : orderDateTime.isNotEmpty ? orderDateTime
        : createdAt;
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  List<String> get services => []; // API doesn't provide services in this list

  String get activeDepartmentName {
    if (jobs.isEmpty) return '';
    try {
      final activeJob = jobs.firstWhere(
        (j) => j.status == 'in_progress' || j.status == 'accepted',
        orElse: () => latestJob!,
      );
      return activeJob.department;
    } catch (_) {
      return '';
    }
  }

  PosOrderJob? get latestJob {
    if (jobs.isEmpty) return null;
    return jobs.reduce((a, b) {
      int idA = int.tryParse(a.id) ?? 0;
      int idB = int.tryParse(b.id) ?? 0;
      return idA > idB ? a : b;
    });
  }

  String get _latestJobStatus {
    return latestJob?.status ?? status;
  }

  String get displayJobStatus {
    if (isCorporateWalkIn && isRejectedByCorporate) {
      return status;
    }
    return _latestJobStatus;
  }

  /// Takeaway kiosk: no workshop maintenance checklist on server.
  bool get isTakeawaySource =>
      source.toLowerCase().contains('takeaway');

  /// All departments done (completed / invoiced) → COMPLETED; any other job state → PENDING; no jobs → DRAFT.
  String get jobsAggregateBadgeLabel {
    if (jobs.isEmpty) return 'DRAFT';
    final active = jobs.where((j) => !j.isCancelledJob).toList();
    if (active.isEmpty) return 'PENDING';
    final allDone = active.every((j) {
      final s = j.status.toLowerCase();
      return s == 'completed' || s == 'invoiced' || s == 'edited';
    });
    return allDone ? 'COMPLETED' : 'PENDING';
  }

  /// Each non-cancelled job must have line items and an assigned technician before invoicing.
  bool get meetsCashierInvoicePrerequisites {
    final active = jobs.where((j) => !j.isCancelledJob).toList();
    if (active.isEmpty) return false;
    for (final job in active) {
      if (job.items.isEmpty) return false;
      if (job.distinctActiveTechnicians.isEmpty) return false;
    }
    return true;
  }

  String get normalizedJobStatus {
    return _normalizeStatus(_latestJobStatus);
  }

  String get assignedTechnicianNames {
    final techs = latestJob?.distinctActiveTechnicians ?? const <JobTechnician>[];
    final names = techs
        .map((t) => t.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '';
    return names.join(', ');
  }

  Color get statusColor {
    String currentStatus = normalizedJobStatus;
    switch (currentStatus.toLowerCase()) {
      case 'invoiced':
      case 'completed':
        return const Color(0xFF27AE60);
      case 'edited':
        return const Color(0xFF3949AB);
      case 'draft':
      case 'pending':
      case 'waiting_for_technician_acception':
      case 'waiting for technician acception':
      case 'waiting for technician acceptance':
        return const Color(0xFFF2994A);
      case 'in_progress':
      case 'ready_for_invoice':
      case 'accepted_by_technician':
        return const Color(0xFF2D9CDB); // Professional blue
      case 'cancelled':
      case 'rejected_by_technician':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    final job = latestJob;
    if (job != null && job.distinctActiveTechnicians.length > 1) {
      final completedCount = job.distinctActiveTechnicians
          .where((t) => t.status?.toLowerCase() == 'completed')
          .length;
      // If at least one has completed, but not all of them
      if (completedCount > 0 &&
          completedCount < job.distinctActiveTechnicians.length) {
        return 'COMPLETED BY $completedCount TECHNICIAN${completedCount > 1 ? 'S' : ''} STILL PENDING';
      }
    }

    String currentStatus = normalizedJobStatus;

    if (currentStatus.isEmpty) return 'Unknown';

    // Replace underscores with spaces and uppercase the string
    return currentStatus.replaceAll('_', ' ').toUpperCase();
  }

  String _normalizeStatus(String raw) {
    final status = raw.trim().toLowerCase();
    if (status == 'waiting for technician acception' ||
        status == 'waiting_for_technician_acception') {
      return 'waiting for technician';
    }
    if (status == 'waiting for technician acceptance' ||
        status == 'waiting_for_technician_acceptance') {
      return 'waiting for technician';
    }
    if (status == 'edited' || status == 'job_edited') {
      return 'edited';
    }
    return raw;
  }
}

class OrderCustomer {
  final String id;
  final String name;
  final String mobile;
  final String vatNumber;
  /// From order API when billing marks customer as branch employee.
  final bool isCustomerEmployee;
  final String? branchEmployeeId;
  final String? employeeType;

  OrderCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    this.vatNumber = '',
    this.isCustomerEmployee = false,
    this.branchEmployeeId,
    this.employeeType,
  });

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    final ie = json['isCustomerEmployee'];
    final employeeFlag = ie == true ||
        ie == 1 ||
        '${ie ?? ''}'.toLowerCase().trim() == 'true';
    final bidRaw = json['branchEmployeeId']?.toString().trim();
    final etRaw = json['employeeType']?.toString().trim();
    return OrderCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      vatNumber:
          json['vatNumber']?.toString() ??
          json['taxId']?.toString() ??
          json['vat']?.toString() ??
          json['vatNo']?.toString() ??
          '',
      isCustomerEmployee: employeeFlag,
      branchEmployeeId: bidRaw != null && bidRaw.isNotEmpty ? bidRaw : null,
      employeeType: etRaw != null && etRaw.isNotEmpty ? etRaw : null,
    );
  }
}

class OrderVehicle {
  final String id;
  final String plateNo;
  /// API display plate; may be null on hot-reload of older instances.
  final String? plateDisplay;
  /// GCC country code stored on the vehicle (`SA`/`AE`/`KW`/`BH`/`QA`/`OM`).
  /// Surfaced by the cashier orders-list endpoint so the "Edit customer
  /// details" popup can pre-fill its country selector for orders created
  /// from a non-Saudi Add-New-Order flow.
  final String? plateCountryCode;
  /// UAE emirate (e.g. `Dubai`), only meaningful when [plateCountryCode] is `AE`.
  final String? plateEmirate;
  final String make;
  final String model;
  final String? year;
  final String? color;
  final String? vin;

  OrderVehicle({
    required this.id,
    required this.plateNo,
    this.plateDisplay,
    this.plateCountryCode,
    this.plateEmirate,
    required this.make,
    required this.model,
    this.year,
    this.color,
    this.vin,
  });

  /// User-facing plate (letters - digits).
  String get displayPlate {
    final d = (plateDisplay ?? '').trim();
    if (d.isNotEmpty) return d;
    final legacy = plateNo.trim();
    if (legacy.isEmpty) return '';
    return formatVehiclePlateLettersFirst(legacy);
  }

  factory OrderVehicle.fromJson(Map<String, dynamic> json) {
    final plateNo = json['plateNo']?.toString() ?? '';
    final fromApi = (json['plateDisplay']?.toString() ??
            json['plateNumber']?.toString() ??
            '')
        .trim();
    final display = fromApi.isNotEmpty
        ? fromApi
        : (plateNo.isNotEmpty ? formatVehiclePlateLettersFirst(plateNo) : null);
    final country = _orderVehicleJsonString(json['plateCountryCode']);
    final emirate = _orderVehicleJsonString(json['plateEmirate']);
    return OrderVehicle(
      id: json['id']?.toString() ?? '',
      plateNo: plateNo,
      plateDisplay: display,
      plateCountryCode:
          country == null || country.trim().isEmpty ? null : country.trim().toUpperCase(),
      plateEmirate: emirate == null || emirate.trim().isEmpty ? null : emirate.trim(),
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: _orderVehicleJsonString(json['year']),
      color: _orderVehicleJsonString(json['color']),
      vin: _orderVehicleJsonString(json['vin']) ??
          _orderVehicleJsonString(json['carNo']),
    );
  }
}

// ── Cashier job line display / cart hydration ─────────────────────────────────

/// API may return duplicate **service** rows for the same [PosOrderJobItem.productId].
/// POS only allows one cart line per service; pick the best row for UI and pre-selection.
PosOrderJobItem pickBestDuplicateServiceJobLine(List<PosOrderJobItem> lines) {
  PosOrderJobItem? withDisc;
  for (final c in lines) {
    if ((c.discountValue ?? 0) > 0.0001) withDisc = c;
  }
  if (withDisc != null) return withDisc;
  return lines.reduce((a, b) {
    final at = a.lineTotalExcludingVat > 0.0001
        ? a.lineTotalExcludingVat
        : a.lineTotal;
    final bt = b.lineTotalExcludingVat > 0.0001
        ? b.lineTotalExcludingVat
        : b.lineTotal;
    return at >= bt ? a : b;
  });
}

/// One row per service [productId] (non-service lines unchanged; original order preserved).
List<PosOrderJobItem> dedupeCashierServiceLinesForPosDisplay(
  List<PosOrderJobItem> items,
) {
  final groups = <String, List<PosOrderJobItem>>{};
  for (final it in items) {
    final isSvc = it.itemType.toLowerCase().trim() == 'service';
    if (!isSvc) continue;
    final k = it.productId.trim();
    if (k.isEmpty) continue;
    groups.putIfAbsent(k, () => []).add(it);
  }
  final picked = <String, PosOrderJobItem>{};
  for (final e in groups.entries) {
    picked[e.key] = e.value.length == 1
        ? e.value.first
        : pickBestDuplicateServiceJobLine(e.value);
  }
  final emitted = <String>{};
  final out = <PosOrderJobItem>[];
  for (final it in items) {
    final isSvc = it.itemType.toLowerCase().trim() == 'service';
    if (!isSvc) {
      out.add(it);
      continue;
    }
    final k = it.productId.trim();
    if (k.isEmpty) {
      out.add(it);
      continue;
    }
    if (emitted.contains(k)) continue;
    emitted.add(k);
    out.add(picked[k]!);
  }
  return out;
}

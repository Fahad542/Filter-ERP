import 'package:flutter/material.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

double? _toNullableDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

String _todayDdMmYyyy() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';
}

class AffiliatedSupplier {
  // `id` is the affiliation/link row id — used for the active/inactive toggle
  // endpoint: PATCH /workshop-suppliers/affiliated/{id}
  final String id;
  // `supplierId` is the underlying supplier id — used for the ledger
  // endpoint: GET /workshop-suppliers/affiliated/{supplierId}/ledger
  final String supplierId;
  final String name;
  final String branch;
  final double openingBalance;
  double finalBalance;
  bool isActive;

  AffiliatedSupplier({
    required this.id,
    this.supplierId = '',
    required this.name,
    required this.branch,
    required this.openingBalance,
    required this.finalBalance,
    this.isActive = true,
  });

  // GET /workshop-suppliers/affiliated → suppliers[]
  factory AffiliatedSupplier.fromJson(Map<String, dynamic> json) {
    return AffiliatedSupplier(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      name: json['supplierName']?.toString() ?? '',
      branch: (json['branchName'] as String?) ?? '—',
      openingBalance: _toDouble(json['openingBalance']),
      finalBalance: _toDouble(json['finalBalance']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

// GET /workshop-suppliers/affiliated → full response
class AffiliatedSuppliersResponse {
  final bool success;
  final int total;
  final List<AffiliatedSupplier> suppliers;

  const AffiliatedSuppliersResponse({
    required this.success,
    required this.total,
    required this.suppliers,
  });

  factory AffiliatedSuppliersResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['suppliers'] as List?) ?? const [];
    return AffiliatedSuppliersResponse(
      success: json['success'] as bool? ?? false,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      suppliers: list
          .whereType<Map>()
          .map((e) => AffiliatedSupplier.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

// PATCH /workshop-suppliers/affiliated/{id} → { isActive }
class ToggleAffiliatedSupplierActiveResponse {
  final bool success;
  final String id;
  final bool isActive;
  final String? branchId;

  const ToggleAffiliatedSupplierActiveResponse({
    required this.success,
    required this.id,
    required this.isActive,
    this.branchId,
  });

  factory ToggleAffiliatedSupplierActiveResponse.fromJson(
      Map<String, dynamic> json) {
    return ToggleAffiliatedSupplierActiveResponse(
      success: json['success'] as bool? ?? false,
      id: json['id']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? false,
      branchId: json['branchId']?.toString(),
    );
  }
}

class RegisteredAffiliatedSupplier {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String contactPerson;
  final String vatId;
  final String cr;
  final String branch;
  final bool isLinked;
  final TextEditingController openingCtrl;
  final TextEditingController dateCtrl;

  RegisteredAffiliatedSupplier({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    this.contactPerson = '—',
    required this.vatId,
    required this.cr,
    required this.branch,
    this.isLinked = false,
    String openingBalance = '0',
    String asOfDate = '10/06/2026',
  })  : openingCtrl = TextEditingController(text: openingBalance),
        dateCtrl = TextEditingController(text: asOfDate);

  double get openingBalance => double.tryParse(openingCtrl.text.trim()) ?? 0.0;

  // dateCtrl is edited/displayed as dd/MM/yyyy — the create API expects
  // yyyy-MM-dd, so convert here rather than scattering parsing in the UI.
  String get openingBalanceDateApi {
    final parts = dateCtrl.text.trim().split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return '${y.toString().padLeft(4, '0')}-'
            '${m.toString().padLeft(2, '0')}-'
            '${d.toString().padLeft(2, '0')}';
      }
    }
    // Fallback so a malformed/empty date never blocks submission.
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    openingCtrl.dispose();
    dateCtrl.dispose();
  }

  // GET /workshop-suppliers/affiliated/available → suppliers[]
  factory RegisteredAffiliatedSupplier.fromJson(Map<String, dynamic> json) {
    return RegisteredAffiliatedSupplier(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '—',
      email: json['email']?.toString() ?? '—',
      contactPerson: (json['contactPerson'] as String?)?.trim().isNotEmpty == true
          ? json['contactPerson'] as String
          : '—',
      vatId: json['vatId']?.toString() ?? '—',
      cr: json['crNumber']?.toString() ?? '—',
      branch: '—',
      isLinked: json['isLinkedToWorkshop'] as bool? ?? false,
      asOfDate: _todayDdMmYyyy(),
    );
  }
}

// GET /workshop-suppliers/affiliated/available?limit=...&offset=...
// Returns: { success, total, limit, offset, suppliers: [ { id, name, mobile,
//   email, vatId, crNumber, contactPerson, registrationType, isActive,
//   isLinkedToWorkshop } ] }
class AvailableAffiliatedSuppliersResponse {
  final bool success;
  final int total;
  final List<RegisteredAffiliatedSupplier> suppliers;

  const AvailableAffiliatedSuppliersResponse({
    required this.success,
    required this.total,
    required this.suppliers,
  });

  factory AvailableAffiliatedSuppliersResponse.fromJson(
      Map<String, dynamic> json) {
    final list = (json['suppliers'] as List?) ?? const [];
    return AvailableAffiliatedSuppliersResponse(
      success: json['success'] as bool? ?? false,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      suppliers: list
          .whereType<Map>()
          .map((e) =>
              RegisteredAffiliatedSupplier.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

// One entry from the `linked` array returned by the create-affiliated-
// suppliers endpoint below.
class LinkedAffiliatedSupplierItem {
  final String workshopSupplierId;
  final String supplierId;
  final String supplierName;
  final bool isActive;
  final double finalBalance;
  final double openingBalance;

  const LinkedAffiliatedSupplierItem({
    required this.workshopSupplierId,
    required this.supplierId,
    required this.supplierName,
    required this.isActive,
    required this.finalBalance,
    required this.openingBalance,
  });

  factory LinkedAffiliatedSupplierItem.fromJson(Map<String, dynamic> json) {
    return LinkedAffiliatedSupplierItem(
      workshopSupplierId: json['workshopSupplierId']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
      finalBalance: _toDouble(json['finalBalance']),
      openingBalance: _toDouble(json['openingBalance']),
    );
  }
}

// POST /workshop-suppliers/affiliated
// Body: { branchId, items: [ { supplierId, openingBalance, openingBalanceDate } ] }
// Returns: { success, message, linkedCount, linked: [...] }
class CreateAffiliatedSuppliersResponse {
  final bool success;
  final String message;
  final int linkedCount;
  final List<LinkedAffiliatedSupplierItem> linked;

  const CreateAffiliatedSuppliersResponse({
    required this.success,
    required this.message,
    required this.linkedCount,
    required this.linked,
  });

  factory CreateAffiliatedSuppliersResponse.fromJson(
      Map<String, dynamic> json) {
    final list = (json['linked'] as List?) ?? const [];
    return CreateAffiliatedSuppliersResponse(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      linkedCount: (json['linkedCount'] as num?)?.toInt() ?? list.length,
      linked: list
          .whereType<Map>()
          .map((e) =>
              LinkedAffiliatedSupplierItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class LedgerEntry {
  final String date;
  final String description;
  final double? debit;
  final double? credit;
  final double balance;
  final bool isOpening;
  final bool isTotal;

  const LedgerEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    this.isOpening = false,
    this.isTotal = false,
  });

  const LedgerEntry.opening()
      : date = '',
        description = 'Opening balance',
        debit = null,
        credit = null,
        balance = 0,
        isOpening = true,
        isTotal = false;

  const LedgerEntry.totals({
    required double debit,
    required double credit,
    required double balance,
  })  : date = '',
        description = 'TOTALS',
        debit = debit,
        credit = credit,
        balance = balance,
        isOpening = false,
        isTotal = true;

  // A single row from GET /workshop-suppliers/affiliated/{id}/ledger → rows[]
  // NOTE: the sample response had an empty rows[] array, so exact field names
  // for individual rows weren't confirmed. This factory tries a few common
  // fallback keys (description/narration/details, debit/credit, balance) —
  // adjust the keys below once a populated response is available.
  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      date: (json['date'] ?? json['transactionDate'] ?? '').toString(),
      description: (json['description'] ??
          json['narration'] ??
          json['details'] ??
          json['reference'] ??
          '')
          .toString(),
      debit: _toNullableDouble(json['debit']),
      credit: _toNullableDouble(json['credit']),
      balance: _toDouble(json['balance'] ?? json['runningBalance']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ledger API models
// GET /workshop-suppliers/affiliated/{supplierId}/ledger?from=...&to=...
// ─────────────────────────────────────────────────────────────────────────────

class AffiliatedLedgerHeader {
  final String supplierId;
  final String supplierName;
  final String? branchId;
  final String? branchName;
  final double openingBalanceSeed;
  final String? openingBalanceDateSeed;
  final String type;
  final String from;
  final String to;
  final String workshopName;
  final String workshopAddress;
  final String currencyCode;

  const AffiliatedLedgerHeader({
    required this.supplierId,
    required this.supplierName,
    this.branchId,
    this.branchName,
    required this.openingBalanceSeed,
    this.openingBalanceDateSeed,
    required this.type,
    required this.from,
    required this.to,
    required this.workshopName,
    required this.workshopAddress,
    required this.currencyCode,
  });

  factory AffiliatedLedgerHeader.fromJson(Map<String, dynamic> json) {
    return AffiliatedLedgerHeader(
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      openingBalanceSeed: _toDouble(json['openingBalanceSeed']),
      openingBalanceDateSeed: json['openingBalanceDateSeed']?.toString(),
      type: json['type']?.toString() ?? 'affiliated',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      workshopName: json['workshopName']?.toString() ?? '',
      workshopAddress: json['workshopAddress']?.toString() ?? '',
      currencyCode: json['currencyCode']?.toString() ?? 'SAR',
    );
  }
}

class AffiliatedLedgerTotals {
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;

  const AffiliatedLedgerTotals({
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
  });

  factory AffiliatedLedgerTotals.fromJson(Map<String, dynamic> json) {
    return AffiliatedLedgerTotals(
      totalDebit: _toDouble(json['totalDebit']),
      totalCredit: _toDouble(json['totalCredit']),
      closingBalance: _toDouble(json['closingBalance']),
    );
  }
}

class AffiliatedLedgerResponse {
  final bool success;
  final AffiliatedLedgerHeader header;
  final double openingBalance;
  final List<LedgerEntry> rows;
  final AffiliatedLedgerTotals totals;

  const AffiliatedLedgerResponse({
    required this.success,
    required this.header,
    required this.openingBalance,
    required this.rows,
    required this.totals,
  });

  factory AffiliatedLedgerResponse.fromJson(Map<String, dynamic> json) {
    final rowsList = (json['rows'] as List?) ?? const [];
    return AffiliatedLedgerResponse(
      success: json['success'] as bool? ?? false,
      header: AffiliatedLedgerHeader.fromJson(
          (json['header'] as Map?)?.cast<String, dynamic>() ?? const {}),
      openingBalance: _toDouble(json['openingBalance']),
      rows: rowsList
          .whereType<Map>()
          .map((e) => LedgerEntry.fromJson(e.cast<String, dynamic>()))
          .toList(),
      totals: AffiliatedLedgerTotals.fromJson(
          (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  // Builds the card list the ledger UI expects: opening row + actual rows +
  // a totals row, mirroring the shape of the old hardcoded `_allEntries`.
  List<LedgerEntry> toDisplayEntries() {
    return [
      LedgerEntry(
        date: '',
        description: 'Opening balance',
        debit: null,
        credit: null,
        balance: openingBalance,
        isOpening: true,
      ),
      ...rows,
      LedgerEntry.totals(
        debit: totals.totalDebit,
        credit: totals.totalCredit,
        balance: totals.closingBalance,
      ),
    ];
  }
}
import 'package:flutter/material.dart';

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _asString(dynamic v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

class NonAffiliatedSupplier {
  final String id;
  final String name;
  final String branch;
  final String branchId;
  final String mobile;
  final String email;
  final String contactPerson;
  final String vatId;
  final String cr;
  final String address;
  final double openingBalance;
  final String? openingBalanceDate;
  double finalBalance;
  bool isActive;

  NonAffiliatedSupplier({
    required this.id,
    required this.name,
    required this.branch,
    this.branchId = '',
    this.mobile = '',
    this.email = '',
    this.contactPerson = '—',
    this.vatId = '—',
    this.cr = '—',
    this.address = '',
    required this.openingBalance,
    this.openingBalanceDate,
    required this.finalBalance,
    this.isActive = true,
  });

  /// Parses a single entry from `GET /workshop-suppliers/local` →
  /// `{ serial, id, name, phone, email, address, vatId, crNumber,
  ///   contactPerson, branchId, branchName, openingBalance,
  ///   openingBalanceDate, isActive, finalBalance, createdAt }`
  factory NonAffiliatedSupplier.fromJson(Map<String, dynamic> j) {
    return NonAffiliatedSupplier(
      id: _asString(j['id']),
      name: _asString(j['name']),
      branch: _asString(j['branchName'], '—'),
      branchId: _asString(j['branchId']),
      mobile: _asString(j['phone'] ?? j['mobile']),
      email: _asString(j['email']),
      contactPerson:
          j['contactPerson'] == null || j['contactPerson'].toString().isEmpty
              ? '—'
              : j['contactPerson'].toString(),
      vatId: j['vatId'] == null || j['vatId'].toString().isEmpty
          ? '—'
          : j['vatId'].toString(),
      cr: j['crNumber'] == null || j['crNumber'].toString().isEmpty
          ? '—'
          : j['crNumber'].toString(),
      address: _asString(j['address']),
      openingBalance: _asDouble(j['openingBalance']),
      openingBalanceDate: j['openingBalanceDate']?.toString(),
      finalBalance: _asDouble(j['finalBalance']),
      isActive: j['isActive'] as bool? ?? true,
    );
  }
}

/// `GET /workshop-suppliers/local` response wrapper.
class NonAffiliatedSuppliersResponse {
  final bool success;
  final int total;
  final List<NonAffiliatedSupplier> suppliers;

  const NonAffiliatedSuppliersResponse({
    required this.success,
    required this.total,
    required this.suppliers,
  });

  factory NonAffiliatedSuppliersResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['suppliers'] as List?) ?? const [];
    return NonAffiliatedSuppliersResponse(
      success: j['success'] as bool? ?? false,
      total: (j['total'] as num?)?.toInt() ?? list.length,
      suppliers: list
          .map((e) => NonAffiliatedSupplier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// `POST /workshop-suppliers/local` response — created supplier is a
/// slimmer shape than the list entry (no phone/email/etc echoed back).
class CreateNonAffiliatedSupplierResponse {
  final bool success;
  final NonAffiliatedSupplier? supplier;

  const CreateNonAffiliatedSupplierResponse({
    required this.success,
    this.supplier,
  });

  factory CreateNonAffiliatedSupplierResponse.fromJson(
      Map<String, dynamic> j) {
    final s = j['supplier'] as Map<String, dynamic>?;
    return CreateNonAffiliatedSupplierResponse(
      success: j['success'] as bool? ?? false,
      supplier: s == null ? null : NonAffiliatedSupplier.fromJson(s),
    );
  }
}

/// `PATCH /workshop-suppliers/local/{id}` response — used both for editing
/// supplier info and for toggling `isActive`.
/// `{ success, id, isActive, branchId, ... }`
class UpdateNonAffiliatedSupplierResponse {
  final bool success;
  final String id;
  final bool? isActive;
  final String? branchId;

  const UpdateNonAffiliatedSupplierResponse({
    required this.success,
    required this.id,
    this.isActive,
    this.branchId,
  });

  factory UpdateNonAffiliatedSupplierResponse.fromJson(
      Map<String, dynamic> j) {
    return UpdateNonAffiliatedSupplierResponse(
      success: j['success'] as bool? ?? false,
      id: _asString(j['id']),
      isActive: j['isActive'] as bool?,
      branchId: j['branchId']?.toString(),
    );
  }
}

/// `GET /workshop-suppliers/local/{id}/ledger` response.
class NonAffiliatedLedgerHeader {
  final String supplierId;
  final String supplierName;
  final String branchId;
  final String branchName;
  final double openingBalanceSeed;
  final String? openingBalanceDateSeed;
  final String from;
  final String to;
  final String workshopName;
  final String workshopAddress;
  final String currencyCode;

  const NonAffiliatedLedgerHeader({
    required this.supplierId,
    required this.supplierName,
    required this.branchId,
    required this.branchName,
    required this.openingBalanceSeed,
    this.openingBalanceDateSeed,
    required this.from,
    required this.to,
    required this.workshopName,
    required this.workshopAddress,
    required this.currencyCode,
  });

  factory NonAffiliatedLedgerHeader.fromJson(Map<String, dynamic> j) {
    return NonAffiliatedLedgerHeader(
      supplierId: _asString(j['supplierId']),
      supplierName: _asString(j['supplierName']),
      branchId: _asString(j['branchId']),
      branchName: _asString(j['branchName'], '—'),
      openingBalanceSeed: _asDouble(j['openingBalanceSeed']),
      openingBalanceDateSeed: j['openingBalanceDateSeed']?.toString(),
      from: _asString(j['from']),
      to: _asString(j['to']),
      workshopName: _asString(j['workshopName']),
      workshopAddress: _asString(j['workshopAddress']),
      currencyCode: _asString(j['currencyCode'], 'SAR'),
    );
  }
}

class NonAffiliatedLedgerTotals {
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;

  const NonAffiliatedLedgerTotals({
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
  });

  factory NonAffiliatedLedgerTotals.fromJson(Map<String, dynamic> j) {
    return NonAffiliatedLedgerTotals(
      totalDebit: _asDouble(j['totalDebit']),
      totalCredit: _asDouble(j['totalCredit']),
      closingBalance: _asDouble(j['closingBalance']),
    );
  }
}

class NonAffiliatedLedgerResponse {
  final bool success;
  final NonAffiliatedLedgerHeader header;
  final double openingBalance;
  final List<NonAffiliatedLedgerEntry> rows;
  final NonAffiliatedLedgerTotals totals;

  const NonAffiliatedLedgerResponse({
    required this.success,
    required this.header,
    required this.openingBalance,
    required this.rows,
    required this.totals,
  });

  factory NonAffiliatedLedgerResponse.fromJson(Map<String, dynamic> j) {
    final rowsRaw = (j['rows'] as List?) ?? const [];
    return NonAffiliatedLedgerResponse(
      success: j['success'] as bool? ?? false,
      header: NonAffiliatedLedgerHeader.fromJson(
          (j['header'] as Map<String, dynamic>?) ?? const {}),
      openingBalance: _asDouble(j['openingBalance']),
      rows: rowsRaw
          .map((e) => NonAffiliatedLedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: NonAffiliatedLedgerTotals.fromJson(
          (j['totals'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  /// Builds the full card list (opening row + movement rows + totals row)
  /// the ledger UI renders, mirroring the previous dummy-data shape.
  List<NonAffiliatedLedgerEntry> toDisplayEntries() {
    return [
      NonAffiliatedLedgerEntry(
        date: header.openingBalanceDateSeed ?? '',
        description: 'Opening balance — ${header.supplierName}',
        debit: null,
        credit: openingBalance,
        balance: openingBalance,
        isOpening: true,
      ),
      ...rows,
      NonAffiliatedLedgerEntry.totals(
        debit: totals.totalDebit,
        credit: totals.totalCredit,
        balance: totals.closingBalance,
      ),
    ];
  }
}

class NonAffiliatedLedgerEntry {
  final String date;
  final String description;
  final double? debit;
  final double? credit;
  final double balance;
  final bool isOpening;
  final bool isTotal;

  const NonAffiliatedLedgerEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    this.isOpening = false,
    this.isTotal = false,
  });

  const NonAffiliatedLedgerEntry.opening()
      : date = '',
        description = 'Opening balance',
        debit = null,
        credit = null,
        balance = 0,
        isOpening = true,
        isTotal = false;

  const NonAffiliatedLedgerEntry.totals({
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

  /// Parses a single row from the ledger `rows` array.
  factory NonAffiliatedLedgerEntry.fromJson(Map<String, dynamic> j) {
    return NonAffiliatedLedgerEntry(
      date: _asString(j['date']),
      description: _asString(j['description']),
      debit: j['debit'] == null ? null : _asDouble(j['debit']),
      credit: j['credit'] == null ? null : _asDouble(j['credit']),
      balance: _asDouble(j['balance']),
    );
  }
}

/// Form model used in the Add dialog
class AddNonAffiliatedSupplierForm {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController contactCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController vatCtrl = TextEditingController();
  final TextEditingController crCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController openingCtrl =
  TextEditingController(text: '0.00');
  final TextEditingController dateCtrl;

  String selectedBranch = '— None (workshop-wide) —';

  AddNonAffiliatedSupplierForm()
      : dateCtrl = TextEditingController(
    text:
    '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );

  void dispose() {
    nameCtrl.dispose();
    contactCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    vatCtrl.dispose();
    crCtrl.dispose();
    addressCtrl.dispose();
    openingCtrl.dispose();
    dateCtrl.dispose();
  }
}
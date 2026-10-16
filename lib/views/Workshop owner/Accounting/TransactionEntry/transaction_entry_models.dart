import 'package:flutter/material.dart';
import '../CashandBank/cash_bank_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Entry — shared models & dummy data
//
// Mirrors the web "Transaction Entry" screen (Payments / Receipts /
// Journal Entry tabs), redesigned as mobile cards in the existing
// Workshop-Owner visual language (see CashAndBank).
// ─────────────────────────────────────────────────────────────────────────────

/// Simple (id, label) pair used to drive every dropdown on this screen so
/// the UI only needs a single reusable dropdown widget.
class IdLabel {
  final String id;
  final String label;

  const IdLabel(this.id, this.label);

  static List<IdLabel> fromStrings(List<String> values) =>
      values.map((v) => IdLabel(v, v)).toList();
}

/// Lightweight chart-of-accounts entry used by Payments / Receipts / Journal.
class ChartAccount {
  final String id;
  final String code;
  final String name;

  const ChartAccount({
    required this.id,
    required this.code,
    required this.name,
  });

  String get label => '$code · $name';
}

extension ChartAccountListX on List<ChartAccount> {
  List<IdLabel> toOptions() =>
      map((a) => IdLabel(a.id, a.label)).toList();
}

/// Party type for a Payment voucher row.
enum PaymentPartyType { supplier, employee }

extension PaymentPartyTypeX on PaymentPartyType {
  String get label =>
      this == PaymentPartyType.supplier ? 'Supplier' : 'Employee';
}

/// Party type for a Receipt voucher row.
enum ReceiptPartyType { customer, other }

extension ReceiptPartyTypeX on ReceiptPartyType {
  String get label =>
      this == ReceiptPartyType.customer ? 'Customer' : 'Other';
}

/// A single entry shown in the "Recent ..." lists at the bottom of each tab.
class RecentTxEntry {
  final String id;
  final String dateLabel;
  final String description;
  final double amount;
  final String status;

  const RecentTxEntry({
    required this.id,
    required this.dateLabel,
    required this.description,
    required this.amount,
    this.status = 'POSTED',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Editable row models
// ─────────────────────────────────────────────────────────────────────────────

class PaymentRow {
  final String voucherNo;
  DateTime date;
  PaymentPartyType type;
  String? payeeId;
  String? accountId;

  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController referenceCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  PaymentRow({
    required this.voucherNo,
    DateTime? date,
    this.type = PaymentPartyType.supplier,
  }) : date = date ?? DateTime.now();

  double get amount => double.tryParse(amountCtrl.text.trim()) ?? 0;

  bool get isValid => payeeId != null && accountId != null && amount > 0;

  void dispose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
  }
}

class ReceiptRow {
  final String voucherNo;
  DateTime date;
  ReceiptPartyType type;
  String? receivedFromId;
  String? accountId;

  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController referenceCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  ReceiptRow({
    required this.voucherNo,
    DateTime? date,
    this.type = ReceiptPartyType.customer,
  }) : date = date ?? DateTime.now();

  double get amount => double.tryParse(amountCtrl.text.trim()) ?? 0;

  bool get isValid =>
      receivedFromId != null && accountId != null && amount > 0;

  void dispose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
  }
}

class JournalLineRow {
  String? accountId;

  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController debitCtrl = TextEditingController();
  final TextEditingController creditCtrl = TextEditingController();

  double get debit => double.tryParse(debitCtrl.text.trim()) ?? 0;
  double get credit => double.tryParse(creditCtrl.text.trim()) ?? 0;

  void dispose() {
    descriptionCtrl.dispose();
    debitCtrl.dispose();
    creditCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date helper — dd/mm/yyyy, matches the web screens
// ─────────────────────────────────────────────────────────────────────────────

String formatTxDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Dummy data
// ─────────────────────────────────────────────────────────────────────────────

class TxEntryDummyData {
  TxEntryDummyData._();

  static const List<String> suppliers = [
    'Al-Futtaim Logistics',
    'Fahad Non Affiliated',
    'WPI Supplies Co.',
    'National Auto Parts',
  ];

  static const List<String> employees = [
    'Sultan Al-Qahtani',
    'Ahmed Hassan',
    'Yousef Al-Mutairi',
  ];

  static const List<String> customers = [
    'Mohammed Al-Rashid',
    'Sara Abdullah',
    'Walk-in Customer',
    'Khalid Trading Est.',
  ];

  static const List<ChartAccount> payableExpenseAccounts = [
    ChartAccount(id: 'ap-1', code: '2001', name: 'Accounts Payable — Trade'),
    ChartAccount(id: 'exp-1', code: '5001', name: 'Workshop Supplies Expense'),
    ChartAccount(id: 'exp-2', code: '5002', name: 'Rent Expense'),
    ChartAccount(id: 'exp-3', code: '5003', name: 'Utilities Expense'),
    ChartAccount(id: 'exp-4', code: '5004', name: 'Vehicle Maintenance Expense'),
  ];

  static const List<ChartAccount> receivableRevenueAccounts = [
    ChartAccount(id: 'ar-1', code: '1101', name: 'Accounts Receivable — Trade'),
    ChartAccount(id: 'rev-1', code: '4001', name: 'Service Revenue'),
    ChartAccount(id: 'rev-2', code: '4002', name: 'Parts Sales Revenue'),
    ChartAccount(id: 'rev-3', code: '4003', name: 'Labor Revenue'),
  ];

  static const List<ChartAccount> journalAccounts = [
    ChartAccount(id: 'cash-1', code: '1001', name: 'Cash On Hand'),
    ChartAccount(id: 'bank-1', code: '1002', name: 'Bank — Al Rajhi Current'),
    ChartAccount(id: 'ar-1', code: '1101', name: 'Accounts Receivable — Trade'),
    ChartAccount(id: 'ap-1', code: '2001', name: 'Accounts Payable — Trade'),
    ChartAccount(id: 'comm-pay-1', code: '2101', name: 'Commission Payable'),
    ChartAccount(id: 'rev-1', code: '4001', name: 'Service Revenue'),
    ChartAccount(id: 'rev-2', code: '4002', name: 'Parts Sales Revenue'),
    ChartAccount(id: 'exp-1', code: '5001', name: 'Workshop Supplies Expense'),
    ChartAccount(id: 'comm-1', code: '5101', name: 'Commission Expense'),
  ];

  /// Branches list with "All Branches" prepended, matching the web header.
  static List<String> get branches => [
        'All Branches',
        ...CashBankDummyData.branches,
      ];

  // Recent lists are mutable so the view model can prepend newly-saved
  // entries — exactly like the "Recent Journal Entry / Payments / Receipts"
  // panels on the web screen.

  static final List<RecentTxEntry> recentPayments = [
    const RecentTxEntry(
      id: 'PE0001',
      dateLabel: '03/06/2026',
      description: 'Al-Futtaim Logistics',
      amount: 50.00,
    ),
  ];

  static final List<RecentTxEntry> recentReceipts = <RecentTxEntry>[];

  static final List<RecentTxEntry> recentJournalEntries = [
    const RecentTxEntry(
      id: 'JE0008',
      dateLabel: '11/06/2026',
      description: 'POS closing #148 · session 189 · Sultan',
      amount: 18.00,
    ),
    const RecentTxEntry(
      id: 'JE0007',
      dateLabel: '10/06/2026',
      description: 'Sales — INV-01703',
      amount: 30.92,
    ),
    const RecentTxEntry(
      id: 'JE0006',
      dateLabel: '10/06/2026',
      description: 'Commission accrual — Job#2128',
      amount: 0.66,
    ),
    const RecentTxEntry(
      id: 'JE0005',
      dateLabel: '03/06/2026',
      description: 'Supplier invoice approved WPI-SI-47 — Al-Futtaim Logistics',
      amount: 235.75,
    ),
    const RecentTxEntry(
      id: 'JE0004',
      dateLabel: '03/06/2026',
      description: 'Supplier invoice approved WPI-SI-46 — Al-Futtaim Logistics',
      amount: 202.56,
    ),
    const RecentTxEntry(
      id: 'JE0003',
      dateLabel: '03/06/2026',
      description: 'Local supplier PI WLPI-12 — Fahad Non Affiliated',
      amount: 624.75,
    ),
    const RecentTxEntry(
      id: 'JE0001',
      dateLabel: '03/06/2026',
      description: 'ok',
      amount: 50.00,
    ),
    const RecentTxEntry(
      id: 'JE-mpybfusf-0mkjq',
      dateLabel: '03/06/2026',
      description: 'Supplier invoice approved WPI-SI-45 — Al-Futtaim Logistics',
      amount: 345.00,
    ),
  ];
}

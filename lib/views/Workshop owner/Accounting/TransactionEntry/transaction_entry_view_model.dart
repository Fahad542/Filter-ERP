import 'package:flutter/material.dart';
import '../CashandBank/cash_bank_models.dart';
import 'transaction_entry_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionEntryViewModel
//
// Backs the mobile "Transaction Entry" screen — Payments, Receipts and
// Journal Entry tabs. Uses the same dummy-data approach as
// CashBankViewModel so it can be wired to a real repository later without
// changing the view.
// ─────────────────────────────────────────────────────────────────────────────

class TransactionEntryViewModel extends ChangeNotifier {
  TransactionEntryViewModel() {
    addPaymentRow();
    addPaymentRow();
    addReceiptRow();
    addReceiptRow();
    addJournalLine();
    addJournalLine();
  }

  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ── Header / shared fields ────────────────────────────────────────────────

  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;

  void setActiveTab(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    _notify();
  }

  DateTime _entryDate = DateTime.now();
  DateTime get entryDate => _entryDate;

  void setEntryDate(DateTime date) {
    _entryDate = date;
    _notify();
  }

  String _branch = TxEntryDummyData.branches.first;
  String get branch => _branch;

  void setBranch(String? branch) {
    if (branch == null) return;
    _branch = branch;
    _notify();
  }

  final TextEditingController generalNoteCtrl = TextEditingController();

  String? _cashBankAccountId;
  String? get cashBankAccountId => _cashBankAccountId;

  void setCashBankAccount(String? accountId) {
    _cashBankAccountId = accountId;
    _notify();
  }

  List<CashBankAccount> get cashBankAccounts => CashBankDummyData.accounts;
  List<String> get branches => TxEntryDummyData.branches;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // ── Payments ─────────────────────────────────────────────────────────────

  final List<PaymentRow> paymentRows = [];
  int _paymentSeq = 2; // PE0001 already posted; form starts at PE0002

  void addPaymentRow() {
    final row = PaymentRow(
      voucherNo: 'PE${_paymentSeq.toString().padLeft(4, '0')}',
    );
    _paymentSeq++;
    row.amountCtrl.addListener(_notify);
    paymentRows.add(row);
    _notify();
  }

  void removePaymentRow(PaymentRow row) {
    if (paymentRows.length <= 1) return;
    paymentRows.remove(row);
    row.amountCtrl.removeListener(_notify);
    row.dispose();
    _notify();
  }

  void setPaymentDate(PaymentRow row, DateTime date) {
    row.date = date;
    _notify();
  }

  void setPaymentType(PaymentRow row, PaymentPartyType type) {
    if (row.type == type) return;
    row.type = type;
    row.payeeId = null;
    _notify();
  }

  void setPaymentPayee(PaymentRow row, String? payeeId) {
    row.payeeId = payeeId;
    _notify();
  }

  void setPaymentAccount(PaymentRow row, String? accountId) {
    row.accountId = accountId;
    _notify();
  }

  int get validPaymentRowsCount =>
      paymentRows.where((r) => r.isValid).length;

  double get paymentsTotal => paymentRows
      .where((r) => r.isValid)
      .fold(0.0, (sum, r) => sum + r.amount);

  List<RecentTxEntry> get recentPayments => TxEntryDummyData.recentPayments;

  Future<void> saveAllPayments() async {
    if (validPaymentRowsCount == 0 || _isSaving) return;
    _isSaving = true;
    _notify();

    await Future.delayed(const Duration(milliseconds: 700));

    final saved = paymentRows.where((r) => r.isValid).toList();
    for (final row in saved) {
      TxEntryDummyData.recentPayments.insert(
        0,
        RecentTxEntry(
          id: row.voucherNo,
          dateLabel: formatTxDate(row.date),
          description: row.payeeId ?? '',
          amount: row.amount,
        ),
      );
    }

    for (final row in saved) {
      paymentRows.remove(row);
      row.amountCtrl.removeListener(_notify);
      row.dispose();
    }
    if (paymentRows.isEmpty) addPaymentRow();

    _isSaving = false;
    _notify();
  }

  // ── Receipts ─────────────────────────────────────────────────────────────

  final List<ReceiptRow> receiptRows = [];
  int _receiptSeq = 1;

  void addReceiptRow() {
    final row = ReceiptRow(
      voucherNo: 'RV${_receiptSeq.toString().padLeft(4, '0')}',
    );
    _receiptSeq++;
    row.amountCtrl.addListener(_notify);
    receiptRows.add(row);
    _notify();
  }

  void removeReceiptRow(ReceiptRow row) {
    if (receiptRows.length <= 1) return;
    receiptRows.remove(row);
    row.amountCtrl.removeListener(_notify);
    row.dispose();
    _notify();
  }

  void setReceiptDate(ReceiptRow row, DateTime date) {
    row.date = date;
    _notify();
  }

  void setReceiptType(ReceiptRow row, ReceiptPartyType type) {
    if (row.type == type) return;
    row.type = type;
    row.receivedFromId = null;
    _notify();
  }

  void setReceiptReceivedFrom(ReceiptRow row, String? id) {
    row.receivedFromId = id;
    _notify();
  }

  void setReceiptAccount(ReceiptRow row, String? accountId) {
    row.accountId = accountId;
    _notify();
  }

  int get validReceiptRowsCount =>
      receiptRows.where((r) => r.isValid).length;

  double get receiptsTotal => receiptRows
      .where((r) => r.isValid)
      .fold(0.0, (sum, r) => sum + r.amount);

  List<RecentTxEntry> get recentReceipts => TxEntryDummyData.recentReceipts;

  Future<void> saveAllReceipts() async {
    if (validReceiptRowsCount == 0 || _isSaving) return;
    _isSaving = true;
    _notify();

    await Future.delayed(const Duration(milliseconds: 700));

    final saved = receiptRows.where((r) => r.isValid).toList();
    for (final row in saved) {
      TxEntryDummyData.recentReceipts.insert(
        0,
        RecentTxEntry(
          id: row.voucherNo,
          dateLabel: formatTxDate(row.date),
          description: row.receivedFromId ?? '',
          amount: row.amount,
        ),
      );
    }

    for (final row in saved) {
      receiptRows.remove(row);
      row.amountCtrl.removeListener(_notify);
      row.dispose();
    }
    if (receiptRows.isEmpty) addReceiptRow();

    _isSaving = false;
    _notify();
  }

  // ── Journal Entry ────────────────────────────────────────────────────────

  final TextEditingController journalMemoCtrl = TextEditingController();
  final List<JournalLineRow> journalLines = [];
  int _journalSeq = 9; // last posted was JE0008

  void addJournalLine() {
    final line = JournalLineRow();
    line.debitCtrl.addListener(_notify);
    line.creditCtrl.addListener(_notify);
    journalLines.add(line);
    _notify();
  }

  void removeJournalLine(JournalLineRow line) {
    if (journalLines.length <= 2) return;
    journalLines.remove(line);
    line.debitCtrl.removeListener(_notify);
    line.creditCtrl.removeListener(_notify);
    line.dispose();
    _notify();
  }

  void setJournalAccount(JournalLineRow line, String? accountId) {
    line.accountId = accountId;
    _notify();
  }

  /// A line is either a debit or a credit — typing in one clears the other,
  /// matching standard double-entry behaviour.
  void onJournalDebitChanged(JournalLineRow line, String value) {
    final v = double.tryParse(value.trim()) ?? 0;
    if (v > 0 && line.creditCtrl.text.isNotEmpty) {
      line.creditCtrl.clear();
    }
  }

  void onJournalCreditChanged(JournalLineRow line, String value) {
    final v = double.tryParse(value.trim()) ?? 0;
    if (v > 0 && line.debitCtrl.text.isNotEmpty) {
      line.debitCtrl.clear();
    }
  }

  double get journalDebitTotal =>
      journalLines.fold(0.0, (sum, l) => sum + l.debit);

  double get journalCreditTotal =>
      journalLines.fold(0.0, (sum, l) => sum + l.credit);

  double get journalDiff => journalDebitTotal - journalCreditTotal;

  bool get journalIsBalanced =>
      journalDebitTotal > 0 && journalDiff.abs() < 0.005;

  List<RecentTxEntry> get recentJournalEntries =>
      TxEntryDummyData.recentJournalEntries;

  Future<void> postJournalEntry() async {
    if (!journalIsBalanced || _isSaving) return;
    _isSaving = true;
    _notify();

    await Future.delayed(const Duration(milliseconds: 700));

    final memo = journalMemoCtrl.text.trim();
    final lineDescriptions = journalLines
        .map((l) => l.descriptionCtrl.text.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    final description = memo.isNotEmpty
        ? memo
        : (lineDescriptions.isNotEmpty
            ? lineDescriptions.first
            : 'Journal entry');

    TxEntryDummyData.recentJournalEntries.insert(
      0,
      RecentTxEntry(
        id: 'JE${_journalSeq.toString().padLeft(4, '0')}',
        dateLabel: formatTxDate(_entryDate),
        description: description,
        amount: journalDebitTotal,
      ),
    );
    _journalSeq++;

    // Reset the form back to two empty lines.
    for (final line in List.of(journalLines)) {
      line.debitCtrl.removeListener(_notify);
      line.creditCtrl.removeListener(_notify);
      line.dispose();
    }
    journalLines.clear();
    journalMemoCtrl.clear();
    addJournalLine();
    addJournalLine();

    _isSaving = false;
    _notify();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    generalNoteCtrl.dispose();
    journalMemoCtrl.dispose();
    for (final r in paymentRows) {
      r.dispose();
    }
    for (final r in receiptRows) {
      r.dispose();
    }
    for (final l in journalLines) {
      l.dispose();
    }
    super.dispose();
  }
}

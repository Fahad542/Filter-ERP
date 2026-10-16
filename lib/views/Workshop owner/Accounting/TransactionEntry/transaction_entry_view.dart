import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_colors.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/owner_shell.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import 'transaction_entry_models.dart';
import 'transaction_entry_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionEntryView — Payments · Receipts · Journal Entry
//
// Mobile redesign of the web "Transaction Entry" screen, built with the same
// card / tab / field language as CashBankView so it feels native to the
// Workshop Owner app.
// ─────────────────────────────────────────────────────────────────────────────

class TransactionEntryView extends StatefulWidget {
  const TransactionEntryView({super.key});

  @override
  State<TransactionEntryView> createState() => _TransactionEntryViewState();
}

class _TransactionEntryViewState extends State<TransactionEntryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = ['Payments', 'Receipts', 'Journal Entry'];
  static const _tabIcons = [
    Icons.payments_rounded,
    Icons.receipt_long_rounded,
    Icons.sync_alt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      context.read<TransactionEntryViewModel>().setActiveTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionEntryViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: const OwnerDashboardTitle(subtitle: 'Transaction Entry'),
            showDrawer: true,
            showNotification: true,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
          ),
          body: Column(
            children: [
              // ── Shared header: Date · Branch · Note · Account ─────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: _HeaderCard(vm: vm),
              ),

              // ── Tab bar ─────────────────────────────────────────────────
              Container(
                color: OwnerUi.scaffoldBackground,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.secondaryLight,
                  unselectedLabelColor: Colors.grey.shade500,
                  labelStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  indicator: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  tabs: List.generate(_tabLabels.length, (i) {
                    return Tab(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tabIcons[i], size: 16),
                          const SizedBox(width: 6),
                          Text(_tabLabels[i]),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // ── Tab content ────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PaymentsTabBody(vm: vm),
                    _ReceiptsTabBody(vm: vm),
                    _JournalTabBody(vm: vm),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeaderCard — Date · Branch · General Note · Paid-From / Received-Into
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final TransactionEntryViewModel vm;
  const _HeaderCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isReceipts = vm.activeTabIndex == 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Date *',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await _pickDate(context, vm.entryDate);
                      if (picked != null) vm.setEntryDate(picked);
                    },
                    child: _DateTile(date: vm.entryDate),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Branch',
                  child: _IdDropdownTile(
                    value: vm.branch,
                    options: IdLabel.fromStrings(vm.branches),
                    hint: 'Select branch',
                    onChanged: vm.setBranch,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _LabeledField(
            label: 'General Note',
            child: TextField(
              controller: vm.generalNoteCtrl,
              style: _fieldTextStyle,
              decoration: _fieldDecoration(hint: 'Optional note for all entries'),
            ),
          ),
          const SizedBox(height: 10),
          _LabeledField(
            label: isReceipts ? 'Received Into Account' : 'Paid From Account',
            child: _IdDropdownTile(
              value: vm.cashBankAccountId,
              options:
                  vm.cashBankAccounts.map((a) => IdLabel(a.id, a.name)).toList(),
              hint: isReceipts
                  ? 'Select Cash/Bank to deposit into'
                  : 'Select Cash / Bank / Petty Cash',
              onChanged: vm.setCashBankAccount,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENTS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentsTabBody extends StatelessWidget {
  final TransactionEntryViewModel vm;
  const _PaymentsTabBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        const _SectionInfoBanner(
          icon: Icons.payments_rounded,
          title: 'Payments',
          subtitle: 'Dr: Payable / Expense   ·   Cr: Cash / Bank',
        ),
        const SizedBox(height: 12),
        ...List.generate(vm.paymentRows.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PaymentRowCard(
              row: vm.paymentRows[i],
              index: i,
              vm: vm,
            ),
          );
        }),
        _AddRowButton(label: 'Add row', onTap: vm.addPaymentRow),
        const SizedBox(height: 14),
        _SummaryAndSaveBar(
          summaryIcon: Icons.fact_check_outlined,
          summaryLabel:
              '${vm.validPaymentRowsCount} valid row${vm.validPaymentRowsCount == 1 ? '' : 's'}   ·   Total SAR ${vm.paymentsTotal.toStringAsFixed(2)}',
          summaryColor: Colors.grey.shade600,
          buttonLabel: 'Save All Payments',
          buttonIcon: Icons.shield_outlined,
          isLoading: vm.isSaving,
          onPressed:
              vm.validPaymentRowsCount > 0 ? vm.saveAllPayments : null,
        ),
        const SizedBox(height: 24),
        const _RecentSectionHeader(title: 'Recent Payments'),
        const SizedBox(height: 10),
        if (vm.recentPayments.isEmpty)
          const _EmptyStateCard(message: 'No recent payments yet.')
        else
          ...vm.recentPayments.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentEntryTile(entry: e),
              )),
      ],
    );
  }
}

class _PaymentRowCard extends StatelessWidget {
  final PaymentRow row;
  final int index;
  final TransactionEntryViewModel vm;

  const _PaymentRowCard({
    required this.row,
    required this.index,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final payeeOptions = row.type == PaymentPartyType.supplier
        ? TxEntryDummyData.suppliers
        : TxEntryDummyData.employees;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Voucher # + delete ────────────────────────────────────────
          Row(
            children: [
              _VoucherChip(label: row.voucherNo),
              const Spacer(),
              _DeleteButton(
                onTap: vm.paymentRows.length > 1
                    ? () => vm.removePaymentRow(row)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Date + Type ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Date',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await _pickDate(context, row.date);
                      if (picked != null) vm.setPaymentDate(row, picked);
                    },
                    child: _DateTile(date: row.date),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Type',
                  child: _SegmentedToggle(
                    value: row.type.name,
                    options: const [
                      IdLabel('supplier', 'Supplier'),
                      IdLabel('employee', 'Employee'),
                    ],
                    onChanged: (v) => vm.setPaymentType(
                      row,
                      PaymentPartyType.values.byName(v),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Payee ──────────────────────────────────────────────────────
          _LabeledField(
            label: 'Payee (To)',
            child: _IdDropdownTile(
              value: row.payeeId,
              options: IdLabel.fromStrings(payeeOptions),
              hint: row.type == PaymentPartyType.supplier
                  ? 'Select supplier'
                  : 'Select employee',
              onChanged: (v) => vm.setPaymentPayee(row, v),
            ),
          ),
          const SizedBox(height: 10),

          // ── Account Dr ─────────────────────────────────────────────────
          _LabeledField(
            label: 'Account Dr — Payable / Expense',
            child: _IdDropdownTile(
              value: row.accountId,
              options: TxEntryDummyData.payableExpenseAccounts.toOptions(),
              hint: 'Select account...',
              onChanged: (v) => vm.setPaymentAccount(row, v),
            ),
          ),
          const SizedBox(height: 10),

          // ── Amount + Reference ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Amount (SAR)',
                  child: TextField(
                    controller: row.amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(hint: '0.00'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Reference',
                  child: TextField(
                    controller: row.referenceCtrl,
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(hint: 'Ref #'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Notes ──────────────────────────────────────────────────────
          _LabeledField(
            label: 'Notes',
            child: TextField(
              controller: row.notesCtrl,
              style: _fieldTextStyle,
              decoration: _fieldDecoration(hint: 'Notes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECEIPTS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptsTabBody extends StatelessWidget {
  final TransactionEntryViewModel vm;
  const _ReceiptsTabBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        const _SectionInfoBanner(
          icon: Icons.receipt_long_rounded,
          title: 'Receipts',
          subtitle: 'Dr: Cash / Bank   ·   Cr: Receivable / Revenue',
        ),
        const SizedBox(height: 12),
        ...List.generate(vm.receiptRows.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReceiptRowCard(
              row: vm.receiptRows[i],
              index: i,
              vm: vm,
            ),
          );
        }),
        _AddRowButton(label: 'Add row', onTap: vm.addReceiptRow),
        const SizedBox(height: 14),
        _SummaryAndSaveBar(
          summaryIcon: Icons.fact_check_outlined,
          summaryLabel:
              '${vm.validReceiptRowsCount} valid row${vm.validReceiptRowsCount == 1 ? '' : 's'}   ·   Total SAR ${vm.receiptsTotal.toStringAsFixed(2)}',
          summaryColor: Colors.grey.shade600,
          buttonLabel: 'Save All Receipts',
          buttonIcon: Icons.shield_outlined,
          isLoading: vm.isSaving,
          onPressed:
              vm.validReceiptRowsCount > 0 ? vm.saveAllReceipts : null,
        ),
        const SizedBox(height: 24),
        const _RecentSectionHeader(title: 'Recent Receipts'),
        const SizedBox(height: 10),
        if (vm.recentReceipts.isEmpty)
          const _EmptyStateCard(message: 'No recent receipts yet.')
        else
          ...vm.recentReceipts.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentEntryTile(entry: e),
              )),
      ],
    );
  }
}

class _ReceiptRowCard extends StatelessWidget {
  final ReceiptRow row;
  final int index;
  final TransactionEntryViewModel vm;

  const _ReceiptRowCard({
    required this.row,
    required this.index,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Voucher # + delete ────────────────────────────────────────
          Row(
            children: [
              _VoucherChip(label: row.voucherNo),
              const Spacer(),
              _DeleteButton(
                onTap: vm.receiptRows.length > 1
                    ? () => vm.removeReceiptRow(row)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Date + Type ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Date',
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await _pickDate(context, row.date);
                      if (picked != null) vm.setReceiptDate(row, picked);
                    },
                    child: _DateTile(date: row.date),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Type',
                  child: _SegmentedToggle(
                    value: row.type.name,
                    options: const [
                      IdLabel('customer', 'Customer'),
                      IdLabel('other', 'Other'),
                    ],
                    onChanged: (v) => vm.setReceiptType(
                      row,
                      ReceiptPartyType.values.byName(v),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Received From ─────────────────────────────────────────────
          _LabeledField(
            label: 'Received From',
            child: _IdDropdownTile(
              value: row.receivedFromId,
              options: IdLabel.fromStrings(TxEntryDummyData.customers),
              hint: 'Select customer',
              onChanged: (v) => vm.setReceiptReceivedFrom(row, v),
            ),
          ),
          const SizedBox(height: 10),

          // ── Account Cr ─────────────────────────────────────────────────
          _LabeledField(
            label: 'Account Cr — Receivable / Revenue',
            child: _IdDropdownTile(
              value: row.accountId,
              options: TxEntryDummyData.receivableRevenueAccounts.toOptions(),
              hint: 'Select account...',
              onChanged: (v) => vm.setReceiptAccount(row, v),
            ),
          ),
          const SizedBox(height: 10),

          // ── Amount + Reference ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Amount (SAR)',
                  child: TextField(
                    controller: row.amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(hint: '0.00'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Reference',
                  child: TextField(
                    controller: row.referenceCtrl,
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(hint: 'Ref #'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Notes ──────────────────────────────────────────────────────
          _LabeledField(
            label: 'Notes',
            child: TextField(
              controller: row.notesCtrl,
              style: _fieldTextStyle,
              decoration: _fieldDecoration(hint: 'Notes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOURNAL ENTRY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _JournalTabBody extends StatelessWidget {
  final TransactionEntryViewModel vm;
  const _JournalTabBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isBalanced = vm.journalIsBalanced;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        const _SectionInfoBanner(
          icon: Icons.sync_alt_rounded,
          title: 'Journal Entry',
          subtitle: 'Manual double entry — total debits must equal total credits',
        ),
        const SizedBox(height: 12),

        // ── Memo + live diff ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledField(
                label: 'Journal Entry Description / Memo',
                child: TextField(
                  controller: vm.journalMemoCtrl,
                  maxLines: 2,
                  minLines: 1,
                  style: _fieldTextStyle,
                  decoration:
                      _fieldDecoration(hint: 'Journal entry description / memo'),
                ),
              ),
              const SizedBox(height: 10),
              _DiffPill(diff: vm.journalDiff, hasAmount: vm.journalDebitTotal > 0 || vm.journalCreditTotal > 0),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Journal lines ─────────────────────────────────────────────────
        ...List.generate(vm.journalLines.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _JournalLineCard(
              line: vm.journalLines[i],
              index: i,
              vm: vm,
            ),
          );
        }),
        _AddRowButton(label: 'Add row', onTap: vm.addJournalLine),
        const SizedBox(height: 12),

        // ── Totals ───────────────────────────────────────────────────────
        _JournalTotalsCard(vm: vm),
        const SizedBox(height: 14),

        // ── Post ─────────────────────────────────────────────────────────
        _SummaryAndSaveBar(
          summaryIcon: isBalanced
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          summaryLabel: isBalanced
              ? 'Balanced — ready to post'
              : 'Unbalanced — Dr ${vm.journalDebitTotal.toStringAsFixed(2)} / Cr ${vm.journalCreditTotal.toStringAsFixed(2)}',
          summaryColor: isBalanced
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
          buttonLabel: 'Post Journal Entry',
          buttonIcon: Icons.menu_book_rounded,
          isLoading: vm.isSaving,
          onPressed: isBalanced ? vm.postJournalEntry : null,
        ),
        const SizedBox(height: 24),
        const _RecentSectionHeader(title: 'Recent Journal Entry'),
        const SizedBox(height: 10),
        if (vm.recentJournalEntries.isEmpty)
          const _EmptyStateCard(message: 'No recent journal entries yet.')
        else
          ...vm.recentJournalEntries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecentEntryTile(entry: e),
              )),
      ],
    );
  }
}

class _JournalLineCard extends StatelessWidget {
  final JournalLineRow line;
  final int index;
  final TransactionEntryViewModel vm;

  const _JournalLineCard({
    required this.line,
    required this.index,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _VoucherChip(label: 'Line ${index + 1}'),
              const Spacer(),
              _DeleteButton(
                onTap: vm.journalLines.length > 2
                    ? () => vm.removeJournalLine(line)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Account',
            child: _IdDropdownTile(
              value: line.accountId,
              options: TxEntryDummyData.journalAccounts.toOptions(),
              hint: 'Select account...',
              onChanged: (v) => vm.setJournalAccount(line, v),
            ),
          ),
          const SizedBox(height: 10),
          _LabeledField(
            label: 'Line Description',
            child: TextField(
              controller: line.descriptionCtrl,
              style: _fieldTextStyle,
              decoration: _fieldDecoration(hint: 'Line description'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Debit (SAR)',
                  child: TextField(
                    controller: line.debitCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(hint: '0.00'),
                    onChanged: (v) => vm.onJournalDebitChanged(line, v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Credit (SAR)',
                  child: TextField(
                    controller: line.creditCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: _fieldTextStyle,
                    decoration: _fieldDecoration(hint: '0.00'),
                    onChanged: (v) => vm.onJournalCreditChanged(line, v),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JournalTotalsCard extends StatelessWidget {
  final TransactionEntryViewModel vm;
  const _JournalTotalsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _TotalPill(
              label: 'Total Debit',
              amount: vm.journalDebitTotal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TotalPill(
              label: 'Total Credit',
              amount: vm.journalCreditTotal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffPill extends StatelessWidget {
  final double diff;
  final bool hasAmount;
  const _DiffPill({required this.diff, required this.hasAmount});

  @override
  Widget build(BuildContext context) {
    final balanced = diff.abs() < 0.005;
    final color = !hasAmount
        ? Colors.grey.shade500
        : (balanced ? const Color(0xFF059669) : const Color(0xFFDC2626));
    final bg = !hasAmount
        ? Colors.grey.shade50
        : (balanced ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2));

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              !hasAmount
                  ? Icons.info_outline_rounded
                  : (balanced
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              'Diff SAR ${diff.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalPill extends StatelessWidget {
  final String label;
  final double amount;
  const _TotalPill({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'SAR ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryLight,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets / styles
// ─────────────────────────────────────────────────────────────────────────────

Future<DateTime?> _pickDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.secondaryLight,
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
      ),
      child: child!,
    ),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );

const TextStyle _fieldTextStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w700,
  color: Color(0xFF1E293B),
);

InputDecoration _fieldDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: Colors.grey.shade400,
      fontWeight: FontWeight.w400,
      fontSize: 12.5,
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

/// Read-only "date" looking field — tap target is provided by the caller via
/// [GestureDetector] so it can open [showDatePicker].
class _DateTile extends StatelessWidget {
  final DateTime date;
  const _DateTile({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.secondaryLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              formatTxDate(date),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single reusable dropdown — driven by [IdLabel] so every picker on this
/// screen (branch, account, supplier, customer, employee…) shares one widget.
class _IdDropdownTile extends StatelessWidget {
  final String? value;
  final List<IdLabel> options;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _IdDropdownTile({
    required this.value,
    required this.options,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a value that no longer exists in `options`
    // (e.g. type toggled and the previous payee list no longer applies).
    final hasValue = value != null && options.any((o) => o.id == value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hasValue ? value : null,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey.shade500),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          items: options
              .map((o) => DropdownMenuItem<String>(
                    value: o.id,
                    child: Text(o.label, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Two-option pill toggle — used for the Payment "Supplier / Employee" and
/// Receipt "Customer / Other" Type fields.
class _SegmentedToggle extends StatelessWidget {
  final String value;
  final List<IdLabel> options;
  final ValueChanged<String> onChanged;

  const _SegmentedToggle({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: options.map((o) {
          final selected = o.id == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.primaryLight : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VoucherChip extends StatelessWidget {
  final String label;
  const _VoucherChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppColors.secondaryLight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _DeleteButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFEF2F2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 16,
          color: enabled ? const Color(0xFFEF4444) : Colors.grey.shade400,
        ),
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddRowButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Summary line (valid rows / total, or balance status) + primary action
/// button — used for "Save All Payments", "Save All Receipts" and
/// "Post Journal Entry".
class _SummaryAndSaveBar extends StatelessWidget {
  final IconData summaryIcon;
  final String summaryLabel;
  final Color summaryColor;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SummaryAndSaveBar({
    required this.summaryIcon,
    required this.summaryLabel,
    required this.summaryColor,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(summaryIcon, size: 15, color: summaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  summaryLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: summaryColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(buttonIcon, size: 17),
              label: Text(buttonLabel, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.secondaryLight.withOpacity(0.35),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionInfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.secondaryLight),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSectionHeader extends StatelessWidget {
  final String title;
  const _RecentSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontSize: 14,
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;
  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 30, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _RecentEntryTile extends StatelessWidget {
  final RecentTxEntry entry;
  const _RecentEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.dateLabel} • ${entry.description}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SAR ${entry.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _StatusChip(
                label: entry.status,
                color: const Color(0xFF059669),
                bg: const Color(0xFFECFDF5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

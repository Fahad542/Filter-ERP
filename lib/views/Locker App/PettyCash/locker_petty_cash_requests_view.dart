import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;

String _money(double v) => NumberFormat('#,##0.00').format(v);

/// One petty-cash request row — same shape as web `MOCK_PETTY_CASH`.
class PettyCashRequestItem {
  final int id;
  final String branch;
  final String requested;
  final double amount;
  final String purpose;
  final String status;

  const PettyCashRequestItem({
    required this.id,
    required this.branch,
    required this.requested,
    required this.amount,
    required this.purpose,
    required this.status,
  });

  String get requestNumber => 'PC-$id';
}

class LockerPettyCashRequestsViewModel extends ChangeNotifier {
  /// Seeded with the same sample row as web locker Petty Cash.
  final List<PettyCashRequestItem> _requests = [
    const PettyCashRequestItem(
      id: 1,
      branch: 'Main — Riyadh',
      requested: '2026-03-10',
      amount: 500,
      purpose: 'Office supplies',
      status: 'pending',
    ),
  ];

  List<PettyCashRequestItem> get requests => List.unmodifiable(_requests);

  void addRequest({
    required String branch,
    required DateTime date,
    required double amount,
    required String purpose,
  }) {
    final nextId = _requests.isEmpty
        ? 1
        : _requests.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    _requests.insert(
      0,
      PettyCashRequestItem(
        id: nextId,
        branch: branch.trim().isEmpty ? '—' : branch.trim(),
        requested: dateStr,
        amount: amount,
        purpose: purpose.trim().isEmpty ? '—' : purpose.trim(),
        status: 'pending',
      ),
    );
    notifyListeners();
  }
}

class LockerPettyCashRequestsView extends StatelessWidget {
  final bool isSupervisor;

  const LockerPettyCashRequestsView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerPettyCashRequestsViewModel(),
      child: _Body(isSupervisor: isSupervisor),
    );
  }
}

class _Body extends StatelessWidget {
  final bool isSupervisor;

  const _Body({required this.isSupervisor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<LockerPettyCashRequestsViewModel>();

    return LockerShell(
      isSupervisor: isSupervisor,
      currentItem: LockerSidebarItem.dashboard,
      title: l10n.lockerPettyCashTitle,
      backgroundColor: OwnerUi.scaffoldBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewRequestSheet(context),
        backgroundColor: AppColors.secondaryLight,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.lockerNewRequest,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          const _PageHeader(),
          const SizedBox(height: 14),
          if (vm.requests.isEmpty)
            const _EmptyState()
          else
            ...vm.requests.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RequestCard(item: r),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openNewRequestSheet(BuildContext context) async {
    final vm = context.read<LockerPettyCashRequestsViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _NewRequestSheet(onSubmit: vm.addRequest),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lockerPettyCashTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PettyCashRequestItem item;

  const _RequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OwnerListIconBox(icon: Icons.account_balance_wallet_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.requestNumber, style: OwnerListStyle.titleStyle),
                      const SizedBox(height: 3),
                      Text(
                        item.branch == 'Main — Riyadh'
                            ? l10n.lockerSampleBranchMainRiyadh
                            : item.branch,
                        style: OwnerListStyle.subtitleStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${l10n.lockerSarCurrency} ${_money(item.amount)}',
                      style: OwnerListStyle.titleStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: item.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: OwnerListStyle.cardBorder),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event_rounded,
                    size: 12, color: Colors.black.withValues(alpha: 0.35)),
                const SizedBox(width: 4),
                Text(
                  item.requested,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.notes_rounded,
                    size: 12, color: Colors.black.withValues(alpha: 0.35)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.purpose == 'Office supplies'
                        ? l10n.lockerSampleOfficeSupplies
                        : item.purpose,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = status.toLowerCase();
    late Color bg;
    late String label;
    if (s == 'approved' || s == 'paid' || s == 'disbursed') {
      bg = Colors.green.shade700;
      label = l10n.lockerStatusApproved;
    } else if (s == 'rejected') {
      bg = Colors.red.shade700;
      label = l10n.lockerStatusRejected;
    } else {
      // pending — dark solid badge (locker status style)
      bg = const Color(0xFF92400E);
      label = l10n.lockerStatusPending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          l10n.lockerNoPettyRequestsYet,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _NewRequestSheet extends StatefulWidget {
  final void Function({
    required String branch,
    required DateTime date,
    required double amount,
    required String purpose,
  }) onSubmit;

  const _NewRequestSheet({required this.onSubmit});

  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  final _branchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _branchCtrl.dispose();
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lockerEnterValidAmount)),
      );
      return;
    }
    widget.onSubmit(
      branch: _branchCtrl.text,
      date: _date,
      amount: amount,
      purpose: _purposeCtrl.text,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.lockerNewRequest,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _branchCtrl,
            decoration: InputDecoration(
              labelText: l10n.lockerFilterBranch,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: l10n.lockerAmountLabel(l10n.lockerSarCurrency),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeCtrl,
            decoration: InputDecoration(
              labelText: l10n.lockerPurpose,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.lockerDate, style: const TextStyle(fontSize: 13)),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              onPressed: _pickDate,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.lockerSubmitRequest,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

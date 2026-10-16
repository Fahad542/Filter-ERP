import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_list_style.dart';
import 'approvals_view_model.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../owner_shell.dart';

// ---------------------------------------------------------------------------
// ApprovalsView
//
// Queue filter keys (raw — never translated):
//   'all'               All Queue
//   'fund'              Top-ups (+ admin wallet fund)
//   'expense'           Expenses (+ admin wallet expense)
//   'supplier'          Supplier Invoices
//   'purchase_returns'  Purchase Returns
//   'returns'           Sales Returns
//   'wallet'            Admin Wallet
//
// Status filter keys: 'all' | 'pending' | 'approved' | 'rejected'
// ---------------------------------------------------------------------------

class ApprovalsView extends StatefulWidget {
  const ApprovalsView({super.key});

  @override
  State<ApprovalsView> createState() => _ApprovalsViewState();
}

class _ApprovalsViewState extends State<ApprovalsView> {
  static const List<String> _queueKeys = [
    'all',
    'fund',
    'expense',
    'supplier',
    'purchase_returns',
    'returns',
    'wallet',
  ];

  static const List<String> _statusKeys = [
    'all',
    'pending',
    'approved',
    'rejected',
  ];

  ApprovalsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= context.read<ApprovalsViewModel>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _vm?.bindRealtime();
        _vm?.fetchRequests();
      }
    });
  }

  @override
  void dispose() {
    _vm?.unbindRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm   = context.watch<ApprovalsViewModel>();
    final rows  = vm.rows;

    final queueOptions = [
      MapEntry(_queueKeys[0], l10n.approvalsQueueAll),
      MapEntry(_queueKeys[1], l10n.approvalsQueueTopUps),
      MapEntry(_queueKeys[2], l10n.approvalsQueueExpenses),
      MapEntry(_queueKeys[3], l10n.approvalsQueueSupplierInvoices),
      MapEntry(_queueKeys[4], 'Purchase Returns'),
      MapEntry(_queueKeys[5], 'Sales Returns'),
      MapEntry(_queueKeys[6], 'Wallet'),
    ];

    final statusOptions = [
      MapEntry(_statusKeys[0], l10n.approvalsStatusAll),
      MapEntry(_statusKeys[1], l10n.approvalsStatusPending),
      MapEntry(_statusKeys[2], l10n.approvalsStatusApproved),
      MapEntry(_statusKeys[3], l10n.approvalsStatusRejected),
    ];

    final showBack = OwnerShell.openedWithBack(context);
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: l10n.approvalsTitle,
        showGlobalLeft: false,
        showNotification: false,
        showBackButton: showBack,
        showDrawer: !showBack,
        onMenuPressed: () => OwnerShell.openDrawer(context),
      ),
      body: Column(
        children: [
          // ── Filters ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSegmentLabel(l10n.approvalsQueueLabel),
                const SizedBox(height: 6),
                _buildSegmentedRow(
                  options: queueOptions,
                  selectedKey: vm.queueFilter,
                  onSelect: vm.setQueueFilter,
                  activeColor: AppColors.secondaryLight,
                  activeTextColor: Colors.white,
                  scrollable: true,
                ),
                const SizedBox(height: 10),
                _buildSegmentLabel(l10n.approvalsStatusLabel),
                const SizedBox(height: 6),
                _buildSegmentedRow(
                  options: statusOptions,
                  selectedKey: vm.statusFilter,
                  onSelect: vm.setStatusFilter,
                ),
              ],
            ),
          ),

          // ── Error banner ─────────────────────────────────────────────────
          if (vm.error != null && vm.error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Text(
                  vm.error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: vm.isLoading
                ? const OwnerListPageShimmer(showSearch: true)
                : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => vm.fetchRequests(),
                  child: rows.isEmpty
                      ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 600)],
                  )
                      : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final isLast = index == rows.length - 1;
                      return _ApprovalCard(
                        row: row,
                        currency: vm.currency,
                        isLast: isLast,
                        hasActionInFlight: vm.hasApprovalActionInFlight,
                        isApproving: vm.isApprovingRequest(row.id),
                        isRejecting: vm.isRejectingRequest(row.id),
                        onApprove: () => _handleApprove(context, vm, row),
                        onReject: (reason) => _handleReject(vm, row, reason),
                      );
                    },
                  ),
                ),
                if (rows.isEmpty) _buildEmptyState(vm, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _handleApprove(
    BuildContext context,
    ApprovalsViewModel vm,
    ApprovalRow row,
  ) async {
    if (row.isAdminWallet) {
      _showAdminWalletApproveSheet(context, vm, row);
      return;
    }
    await _showApprovalConfirmDialog(
      context,
      title: AppLocalizations.of(context)!.ownerCommonApprove,
      message: AppLocalizations.of(context)!.approvalsApproveConfirm,
      confirmLabel: AppLocalizations.of(context)!.invConfirm,
      onConfirm: () async {
        switch (row.type) {
          case ApprovalRowType.salesReturn:
            await vm.approveSalesReturn(row.id);
            break;
          case ApprovalRowType.purchaseReturn:
            await vm.approvePurchaseReturn(row.id);
            break;
          case ApprovalRowType.supplierInvoice:
            await vm.approveSupplierInvoice(row.id);
            break;
          default:
            await vm.approveRequest(row.id);
        }
      },
    );
  }

  Future<void> _handleReject(
    ApprovalsViewModel vm,
    ApprovalRow row,
    String reason,
  ) {
    final trimmed = reason.trim();
    if (row.isAdminWallet) {
      return vm.rejectAdminWallet(
        row.id,
        row.adminWalletKind!,
        trimmed.isEmpty ? 'Rejected' : trimmed,
      );
    }
    switch (row.type) {
      case ApprovalRowType.salesReturn:
        return vm.rejectSalesReturn(row.id, trimmed);
      case ApprovalRowType.supplierInvoice:
        return vm.rejectSupplierInvoice(
          row.id,
          trimmed.isEmpty ? 'Rejected' : trimmed,
        );
      default:
        return vm.rejectRequest(row.id, trimmed);
    }
  }

  void _showAdminWalletApproveSheet(
    BuildContext context,
    ApprovalsViewModel vm,
    ApprovalRow row,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminWalletApproveSheet(vm: vm, row: row),
    );
  }

  Widget _buildSegmentLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: Color(0xFF9CA3AF),
      letterSpacing: 0.4,
    ),
  );

  // Scrollable / fixed segmented control (Status style).
  Widget _buildSegmentedRow({
    required List<MapEntry<String, String>> options,
    required String selectedKey,
    required void Function(String) onSelect,
    Color activeColor = AppColors.primaryLight,
    Color activeTextColor = AppColors.secondaryLight,
    bool scrollable = false,
  }) {
    final pillRadius = BorderRadius.circular(11);

    Widget tab(MapEntry<String, String> e, {bool expand = false}) {
      final selected = selectedKey == e.key;
      final child = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(e.key),
          borderRadius: pillRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              vertical: 9,
              horizontal: scrollable ? 12 : 2,
            ),
            decoration: BoxDecoration(
              color: selected ? activeColor : Colors.transparent,
              borderRadius: pillRadius,
            ),
            child: Text(
              e.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: selected ? 11.5 : 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? activeTextColor : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      );
      return expand ? Expanded(child: child) : child;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((e) => tab(e)).toList(),
              ),
            )
          : Row(
              children: options.map((e) => tab(e, expand: true)).toList(),
            ),
    );
  }

  Widget _buildEmptyState(ApprovalsViewModel vm, AppLocalizations l10n) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 68, color: Colors.green.withOpacity(0.2)),
              const SizedBox(height: 14),
              Text(
                vm.queueFilter == 'expense'
                    ? l10n.approvalsEmptyExpenses
                    : vm.queueFilter == 'supplier'
                    ? l10n.approvalsQueueSupplierInvoices
                    : vm.queueFilter == 'purchase_returns'
                    ? 'No Purchase Returns'
                    : vm.queueFilter == 'returns'
                    ? 'No Sales Returns'
                    : vm.queueFilter == 'wallet'
                    ? 'No Wallet Approvals'
                    : l10n.approvalsEmptyPettyCash,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.approvalsEmptySubtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// _ApprovalCard
//
// Card layout:
//   ┌─────────────────────────────────────────────┐
//   │ [TypeChip]                    [StatusBadge]  │
//   │ SAR 200.00  (bold, large)                    │
//   │ ─────────────────────────────────────────── │
//   │ 👤 Requested by       [value]                │
//   │ 📁 Category           [value]                │
//   │ 🏢 Branch             [value]                │
//   │ 💬 Reason             [value]                │
//   │ 🕐 Requested at       [value]                │
//   │ ─────────────────────────────────────────── │
//   │ [✗ Reject]           [✓ Approve]            │
//   │    OR                                        │
//   │ [🔴 rejection reason banner]                 │
//   └─────────────────────────────────────────────┘
// ---------------------------------------------------------------------------
class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.row,
    required this.currency,
    required this.isLast,
    required this.hasActionInFlight,
    required this.isApproving,
    required this.isRejecting,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRow row;
  final String currency;
  final bool isLast;
  final bool hasActionInFlight;
  final bool isApproving;
  final bool isRejecting;
  final VoidCallback onApprove;
  final Future<void> Function(String reason) onReject;

  IconData get _typeIcon {
    switch (row.type) {
      case ApprovalRowType.expense:
        return Icons.receipt_outlined;
      case ApprovalRowType.topUp:
        return Icons.arrow_circle_up_outlined;
      case ApprovalRowType.supplierInvoice:
        return Icons.description_outlined;
      case ApprovalRowType.salesReturn:
        return Icons.assignment_return_outlined;
      case ApprovalRowType.purchaseReturn:
        return Icons.undo_outlined;
      case ApprovalRowType.adminWallet:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _typeLabel(AppLocalizations l10n) {
    if (row.isAdminWallet) {
      return row.adminWalletKind == 'admin_wallet_expense'
          ? l10n.ownerExpenseTitle
          : l10n.approvalsQueueTopUps;
    }
    switch (row.type) {
      case ApprovalRowType.expense:
        return l10n.ownerExpenseTitle;
      case ApprovalRowType.topUp:
        return l10n.approvalsQueueTopUps;
      case ApprovalRowType.supplierInvoice:
        return l10n.ownerPurchaseInvoicesInvoice;
      case ApprovalRowType.salesReturn:
        return l10n.ownerSalesReturnsTitle;
      case ApprovalRowType.purchaseReturn:
        return l10n.ownerPurchaseInvoicesTitle;
      case ApprovalRowType.adminWallet:
        return l10n.paymentMethodWallet;
    }
  }

  bool get _isPending {
    final s = row.status.toLowerCase();
    return s != 'approved' && s != 'completed' && s != 'rejected';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DecoratedBox(
                          decoration: OwnerListStyle.iconBoxDecoration,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              _typeIcon,
                              color: AppColors.primaryLight,
                              size: 18,
                            ),
                          ),
                        ),
                        if (_isPending)
                          Positioned(
                            right: -1,
                            bottom: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF43A047),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _typeLabel(l10n),
                                style: OwnerListStyle.titleStyle.copyWith(
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(
                              status: row.status,
                              translatedLabel: row.translatedStatusLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ownerFormatMoney(context, row.amount, currency: currency),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (row.requestedBy.isNotEmpty)
                          _MetaLine(
                            icon: Icons.person_outline_rounded,
                            label: l10n.ownerApprovalsRequestedBy,
                            value: row.requestedBy,
                            localizeValue: true,
                          ),
                        if (row.categoryLabel != null &&
                            row.categoryLabel!.isNotEmpty)
                          _MetaLine(
                            icon: Icons.tag_rounded,
                            label: l10n.ownerApprovalsReference,
                            value: row.categoryLabel!,
                            localizeValue: true,
                          ),
                        if (row.branchName != null &&
                            row.branchName!.isNotEmpty)
                          _MetaLine(
                            icon: Icons.store_outlined,
                            label: l10n.ownerApprovalsBranch,
                            value: row.branchName!,
                            localizeValue: true,
                          ),
                        if (row.reason != null && row.reason!.isNotEmpty)
                          _MetaLine(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: l10n.ownerApprovalsDetails,
                            value: row.reason!,
                            localizeValue: true,
                          ),
                        _MetaLine(
                          icon: Icons.schedule_rounded,
                          label: l10n.ownerApprovalsRequestedAt,
                          value: _formatDateTime(context, row.requestedAt),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (row.rejectionReason != null &&
                  row.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x14F44336),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x4DF44336)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel_outlined,
                          size: 13, color: Colors.red),
                      const SizedBox(width: 5),
                      Expanded(
                        child: LocalizedApiText(
                          row.rejectionReason!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (row.canApproveReject) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (row.type != ApprovalRowType.purchaseReturn) ...[
                      Expanded(
                        child: _ActionButton(
                          label: l10n.ownerCommonReject,
                          color: Colors.white,
                          bg: AppColors.secondaryLight,
                          loading: isRejecting,
                          disabled: hasActionInFlight,
                          onTap: () => _showRejectDialog(context, onReject),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _ActionButton(
                        label: l10n.ownerCommonApprove,
                        color: AppColors.secondaryLight,
                        bg: AppColors.primaryLight,
                        loading: isApproving,
                        disabled: hasActionInFlight,
                        onTap: onApprove,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    final formatted = DateFormat(
      'd MMM yyyy  HH:mm',
      Localizations.localeOf(context).toString(),
    ).format(dt);
    return ownerLocalizeDigits(context, formatted);
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
    this.localizeValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool localizeValue;

  @override
  Widget build(BuildContext context) {
    final valueStyle = OwnerListStyle.metaStyle.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF4B5563),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: OwnerListStyle.mutedText),
          const SizedBox(width: 4),
          Text(
            label,
            style: OwnerListStyle.metaStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: localizeValue
                ? LocalizedApiText(
                    value,
                    style: valueStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  )
                : Text(
                    value,
                    style: valueStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.translatedLabel});
  final String status;
  final String? translatedLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final normalised = status.toLowerCase();
    final fallback = switch (normalised) {
      'approved' => l10n.approvalsStatusApproved,
      'completed' => l10n.ownerPurchaseInvoicesStatusCompleted,
      'rejected' => l10n.approvalsStatusRejected,
      'pending' => l10n.approvalsStatusPending,
      _ => status.isEmpty
          ? l10n.ownerCommonPending
          : status[0].toUpperCase() + status.substring(1),
    };
    final label = (translatedLabel != null && translatedLabel!.isNotEmpty)
        ? translatedLabel!
        : fallback;

    late final Color bg;
    late final Color fg;

    switch (normalised) {
      case 'approved':
      case 'completed':
        bg = OwnerListStyle.actionBg;
        fg = AppColors.secondaryLight;
        break;
      case 'rejected':
        bg = const Color(0x14F44336);
        fg = Colors.red;
        break;
      default:
        bg = const Color(0x38FCC247); // primary ~22%
        fg = AppColors.secondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.bg,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color bg;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? SizedBox(
                height: 18,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: disabled ? Colors.grey.shade400 : color,
                  ),
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared confirm dialog — logout-style UI, loader inside Confirm.
// ---------------------------------------------------------------------------
Future<void> _showApprovalConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (ctx) => _ApprovalConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
    ),
  );
}

class _ApprovalConfirmDialog extends StatefulWidget {
  const _ApprovalConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Future<void> Function() onConfirm;

  @override
  State<_ApprovalConfirmDialog> createState() => _ApprovalConfirmDialogState();
}

class _ApprovalConfirmDialogState extends State<_ApprovalConfirmDialog> {
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      disabledBackgroundColor:
                          AppColors.secondaryLight.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.approvalsCancel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      disabledBackgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.secondaryLight,
                      disabledForegroundColor: AppColors.secondaryLight,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.secondaryLight,
                            ),
                          )
                        : Text(
                            widget.confirmLabel,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                            ),
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

// ---------------------------------------------------------------------------
// Reject dialog — logout-style UI + reason field + Confirm loader
// ---------------------------------------------------------------------------
void _showRejectDialog(
  BuildContext context,
  Future<void> Function(String reason) onReject,
) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (ctx) => _RejectConfirmDialog(onReject: onReject),
  );
}

class _RejectConfirmDialog extends StatefulWidget {
  const _RejectConfirmDialog({required this.onReject});

  final Future<void> Function(String reason) onReject;

  @override
  State<_RejectConfirmDialog> createState() => _RejectConfirmDialogState();
}

class _RejectConfirmDialogState extends State<_RejectConfirmDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onReject(_controller.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.ownerApprovalsRejectTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.approvalsRejectHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: l10n.approvalsRejectHint,
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primaryLight,
                    width: 1.5,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      disabledBackgroundColor:
                          AppColors.secondaryLight.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.approvalsCancel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      disabledBackgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.secondaryLight,
                      disabledForegroundColor: AppColors.secondaryLight,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.secondaryLight,
                            ),
                          )
                        : Text(
                            l10n.invConfirm,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                            ),
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

// ---------------------------------------------------------------------------
// Admin wallet approve — needs cash/budget account (web parity).
// ---------------------------------------------------------------------------
class _AdminWalletApproveSheet extends StatefulWidget {
  const _AdminWalletApproveSheet({required this.vm, required this.row});

  final ApprovalsViewModel vm;
  final ApprovalRow row;

  @override
  State<_AdminWalletApproveSheet> createState() =>
      _AdminWalletApproveSheetState();
}

class _AdminWalletApproveSheetState extends State<_AdminWalletApproveSheet> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _cashAccounts = [];
  List<Map<String, dynamic>> _budgetAccounts = [];
  String? _sourceAccountId;
  String? _budgetAccountId;
  final _remarksCtrl = TextEditingController();

  bool get _isExpense =>
      widget.row.adminWalletKind == 'admin_wallet_expense';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final branchId = widget.row.branchId;
      if (_isExpense) {
        final budgets = await widget.vm.loadBudgetAccounts(branchId: branchId);
        final cash = await widget.vm.loadCashBankAccounts(branchId: branchId);
        if (!mounted) return;
        setState(() {
          _budgetAccounts = budgets;
          _cashAccounts = cash;
          _budgetAccountId =
              budgets.isNotEmpty ? budgets.first['id']?.toString() : null;
          _sourceAccountId =
              cash.isNotEmpty ? cash.first['id']?.toString() : null;
          _loading = false;
        });
      } else {
        final cash = await widget.vm.loadCashBankAccounts(branchId: branchId);
        if (!mounted) return;
        setState(() {
          _cashAccounts = cash;
          _sourceAccountId =
              cash.isNotEmpty ? cash.first['id']?.toString() : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _accountLabel(BuildContext context, Map<String, dynamic> a) {
    final name = a['name']?.toString() ?? 'Account';
    final type = a['type']?.toString() ?? a['kind']?.toString() ?? '';
    final bal = a['currentBalance'] ?? a['balance'];
    final balStr = bal == null
        ? ''
        : ' — ${ownerFormatMoney(context, double.tryParse(bal.toString()) ?? 0)}';
    return type.isEmpty ? '$name$balStr' : '$name ($type)$balStr';
  }

  Map<String, dynamic>? _findById(
      List<Map<String, dynamic>> list, String? id) {
    if (id == null) return null;
    for (final a in list) {
      if (a['id']?.toString() == id) return a;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final kind = widget.row.adminWalletKind;
    if (kind == null) return;

    if (_isExpense &&
        (_budgetAccountId == null || _budgetAccountId!.isEmpty)) {
      setState(() => _error = 'Select a budget account to continue.');
      return;
    }
    if (!_isExpense &&
        (_sourceAccountId == null || _sourceAccountId!.isEmpty)) {
      setState(() => _error = 'Select a cash/bank account to continue.');
      return;
    }

    final body = <String, dynamic>{};
    final remarks = _remarksCtrl.text.trim();
    if (remarks.isNotEmpty) body['remarks'] = remarks;

    if (_isExpense) {
      final budget = _findById(_budgetAccounts, _budgetAccountId);
      body['budgetAccountId'] = _budgetAccountId;
      if (budget?['name'] != null) {
        body['budgetAccountName'] = budget!['name'].toString();
      }
      if (_sourceAccountId != null && _sourceAccountId!.isNotEmpty) {
        final src = _findById(_cashAccounts, _sourceAccountId);
        body['sourceAccountId'] = _sourceAccountId;
        if (src?['name'] != null) {
          body['sourceAccountName'] = src!['name'].toString();
        }
      }
    } else {
      final src = _findById(_cashAccounts, _sourceAccountId);
      body['sourceAccountId'] = _sourceAccountId;
      if (src?['name'] != null) {
        body['sourceAccountName'] = src!['name'].toString();
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.vm.approveAdminWallet(widget.row.id, kind, body: body);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: OwnerUi.sheetFormInitialSize,
        minChildSize: OwnerUi.sheetMinSize,
        maxChildSize: OwnerUi.sheetFormMaxSize,
        expand: false,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isExpense
                      ? l10n.ownerApprovalsApproveWalletExpense
                      : l10n.ownerApprovalsApproveWalletTopUp,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LocalizedApiText(
                      widget.row.requestedBy,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' · ${ownerFormatMoney(context, widget.row.amount)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.row.branchName != null &&
                        widget.row.branchName!.isNotEmpty) ...[
                      Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      LocalizedApiText(
                        widget.row.branchName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (_error != null && _error!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_isExpense) ...[
                    const Text(
                      'Budget account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OwnerStyledDropdown<String>(
                      value: _budgetAccountId,
                      hint: 'Select account',
                      height: 48,
                      enabled: !_submitting,
                      options: _budgetAccounts
                          .map(
                            (a) => OwnerDropdownOption(
                              value: a['id']?.toString() ?? '',
                              label: a['name']?.toString() ?? 'Account',
                            ),
                          )
                          .where((o) => o.value.isNotEmpty)
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _budgetAccountId = v),
                      triggerStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pay-from account (optional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OwnerStyledDropdown<String>(
                      value: _sourceAccountId ?? '',
                      hint: 'None',
                      height: 48,
                      enabled: !_submitting,
                      options: [
                        const OwnerDropdownOption(value: '', label: 'None'),
                        ..._cashAccounts
                            .map(
                              (a) => OwnerDropdownOption(
                                value: a['id']?.toString() ?? '',
                                label: _accountLabel(context, a),
                              ),
                            )
                            .where((o) => o.value.isNotEmpty),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() =>
                              _sourceAccountId =
                                  (v == null || v.isEmpty) ? null : v),
                      triggerStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Pay-from account',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    OwnerStyledDropdown<String>(
                      value: _sourceAccountId,
                      hint: 'Select account',
                      height: 48,
                      enabled: !_submitting,
                      options: _cashAccounts
                          .map(
                            (a) => OwnerDropdownOption(
                              value: a['id']?.toString() ?? '',
                              label: _accountLabel(context, a),
                            ),
                          )
                          .where((o) => o.value.isNotEmpty)
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _sourceAccountId = v),
                      triggerStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Remarks (optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _remarksCtrl,
                    maxLines: 3,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      hintText: 'e.g. Approved for branch float',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isExpense
                                  ? l10n.ownerApprovalsApproveExpense
                                  : l10n.ownerApprovalsApproveTopUp,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

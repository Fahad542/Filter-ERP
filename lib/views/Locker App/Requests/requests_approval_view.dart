import 'package:filter_service_providers/views/Locker%20App/Requests/requests_approval_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_segmented_tabs.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerVarianceApprovalsView extends StatelessWidget {
  const LockerVarianceApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerVarianceApprovalsViewModel(),
      child: const _VarianceApprovalsBody(),
    );
  }
}

// ── Inner StatefulWidget ──────────────────────────────────────────────────────

class _VarianceApprovalsBody extends StatefulWidget {
  const _VarianceApprovalsBody();

  @override
  State<_VarianceApprovalsBody> createState() => _VarianceApprovalsBodyState();
}

class _VarianceApprovalsBodyState extends State<_VarianceApprovalsBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.read<LockerVarianceApprovalsViewModel>().init(l10n);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LockerVarianceApprovalsViewModel>(
      builder: (context, vm, _) {
        final l10n = AppLocalizations.of(context)!;
        return LockerShell(
          isSupervisor: true,
          currentItem: LockerSidebarItem.varianceApprovals,
          title: l10n.lockerNavApprovals,
          backgroundColor: OwnerUi.scaffoldBackground,
          body: _buildBody(context, vm),
        );
      },
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, LockerVarianceApprovalsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;

    if (vm.isLoading) {
      return const OwnerListPageShimmer(itemCount: 5);
    }

    if (vm.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(Icons.wifi_off_rounded,
                    size: 40, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.lockerFailedLoadVariance,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage ?? l10n.lockerUnexpectedError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: vm.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.lockerRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        OwnerSegmentedTabs(
          controller: _tabController,
          tabs: [l10n.lockerTabVariance, l10n.lockerTabPettyCashFunds],
          layout: PosSegmentedTabLayout.expanded,
          counts: [
            null,
            vm.pendingFundCount > 0 ? vm.pendingFundCount : null,
          ],
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVarianceTab(context, vm),
              _buildFundRequestsTab(context, vm),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 0: Variance ───────────────────────────────────────────────────────

  Widget _buildVarianceTab(
      BuildContext context, LockerVarianceApprovalsViewModel vm) {
    final l10n = AppLocalizations.of(context)!;

    if (vm.approvals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 48, color: Colors.green),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.lockerAllClear,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.lockerNoPendingVariance,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.4), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (vm.actionState == VarianceActionState.error &&
            vm.actionError != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade400, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vm.actionError!,
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.red.shade400, size: 16),
                  onPressed: vm.resetActionState,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: vm.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.approvals.length,
              itemBuilder: (context, index) {
                final item = vm.approvals[index];
                return _VarianceCard(
                  approval: item,
                  isProcessing: vm.processingId == item.id,
                  isDisabled: vm.isProcessing,
                  onApprove: () => _handleApprove(context, vm, item),
                  onReject: () => _handleReject(context, vm, item),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Petty Cash Funds ───────────────────────────────────────────────

  Widget _buildFundRequestsTab(
      BuildContext context, LockerVarianceApprovalsViewModel vm) {
    if (vm.fundRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_outlined,
                    size: 48, color: Colors.black.withOpacity(0.35)),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.lockerNoPendingFundRequests,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (vm.actionState == VarianceActionState.error &&
            vm.actionError != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade400, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vm.actionError!,
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.red.shade400, size: 16),
                  onPressed: vm.resetActionState,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryLight,
            onRefresh: vm.refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.fundRequests.length,
              itemBuilder: (context, index) {
                final request = vm.fundRequests[index];
                return _FundRequestCard(
                  request: request,
                  isProcessing: vm.processingId == request.id,
                  isDisabled: vm.isProcessing,
                  onApprove: () => _handleFundApprove(context, vm, request),
                  onReject: () => _handleFundReject(context, vm, request),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Action handlers ───────────────────────────────────────────────────────

  Future<void> _handleApprove(
      BuildContext context,
      LockerVarianceApprovalsViewModel vm,
      LockerVarianceApproval item,
      ) async {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel =
    item.isShort ? l10n.lockerShortLabel : l10n.lockerOverLabel;

    final confirmed = await _showConfirmDialog(
      context,
      title: l10n.lockerApproveVarianceTitle,
      message: l10n.lockerApproveVarianceConfirm(
        typeLabel,
        item.difference.abs().toStringAsFixed(2),
        item.branchName,
      ),
      confirmLabel: l10n.lockerApprove,
      confirmColor: Colors.green,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await vm.approve(item.id);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lockerApproveSuccess),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleReject(
      BuildContext context,
      LockerVarianceApprovalsViewModel vm,
      LockerVarianceApproval item,
      ) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await _showRejectDialog(context, item);
    if (reason == null || !context.mounted) return;

    final ok = await vm.reject(item.id, reason: reason);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lockerRejectSuccess),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleFundApprove(
      BuildContext context,
      LockerVarianceApprovalsViewModel vm,
      LockerFundRequest request,
      ) async {
    final ok = await vm.approveFundRequest(request.id);
    if (ok && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lockerFundApproved),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleFundReject(
      BuildContext context,
      LockerVarianceApprovalsViewModel vm,
      LockerFundRequest request,
      ) async {
    final reason = await _showFundRejectDialog(context);
    if (reason == null || !context.mounted) return;

    final ok = await vm.rejectFundRequest(request.id, reason: reason);
    if (ok && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lockerFundRejected),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmLabel,
        required Color confirmColor,
      }) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight)),
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.lockerCancel,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<String?> _showRejectDialog(
      BuildContext context, LockerVarianceApproval item) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.lockerRejectVarianceDialogTitle,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lockerRejectingFor(item.branchName),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.lockerRejectionReasonOptional,
                hintStyle:
                const TextStyle(color: Colors.black38, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.lockerCancel,
                style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.lockerReject,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showFundRejectDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              l10n.lockerRejectFundRequest,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lockerProvideRejectionReason,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.lockerRejectionReason,
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 12),
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.black.withOpacity(0.1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(l10n.lockerCancel,
                    style: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                onPressed: () {
                  final reason = reasonCtrl.text.trim();
                  if (reason.isEmpty) {
                    setLocal(() => errorText = l10n.lockerReasonRequired);
                    return;
                  }
                  Navigator.pop(ctx, reason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.lockerReject,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Variance card ─────────────────────────────────────────────────────────────

class _VarianceCard extends StatelessWidget {
  final LockerVarianceApproval approval;
  final bool isProcessing;
  final bool isDisabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VarianceCard({
    required this.approval,
    required this.isProcessing,
    required this.isDisabled,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isShort = approval.isShort;
    final varianceColor = isShort ? Colors.red : Colors.orange;
    final varianceLabel =
    isShort ? l10n.lockerShortVariance : l10n.lockerOverVariance;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: OwnerListStyle.cardDecoration.copyWith(
        border: Border.all(color: varianceColor.withOpacity(0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OwnerListIconBox(
                  icon: isShort
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval.branchName,
                        style: OwnerListStyle.titleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                          Localizations.localeOf(context).toString(),
                        ).format(approval.date.toLocal()),
                        style: OwnerListStyle.metaStyle,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isShort
                        ? Colors.red.shade800
                        : Colors.orange.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    varianceLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // People row
            Row(
              children: [
                _PersonChip(
                  icon: Icons.person_outline_rounded,
                  label: approval.cashierName,
                  sublabel: l10n.lockerCashierLabel,
                ),
                const SizedBox(width: 10),
                _PersonChip(
                  icon: Icons.badge_outlined,
                  label: approval.officerName,
                  sublabel: l10n.lockerOfficerLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amounts row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _AmountStat(
                    label: l10n.lockerExpected,
                    value:
                    '${l10n.lockerSarCurrency} ${approval.expectedAmount.toStringAsFixed(2)}',
                    color: Colors.blue,
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.black.withOpacity(0.06),
                      margin:
                      const EdgeInsets.symmetric(horizontal: 12)),
                  _AmountStat(
                    label: l10n.lockerReceivedLabel,
                    value:
                    '${l10n.lockerSarCurrency} ${approval.receivedAmount.toStringAsFixed(2)}',
                    color: Colors.teal,
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.black.withOpacity(0.06),
                      margin:
                      const EdgeInsets.symmetric(horizontal: 12)),
                  _AmountStat(
                    label: l10n.lockerDiffLabel,
                    value:
                    '${l10n.lockerSarCurrency} ${approval.difference.abs().toStringAsFixed(2)}',
                    color: varianceColor,
                  ),
                ],
              ),
            ),
            // Notes
            if (approval.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded,
                        size: 13,
                        color: Colors.black.withOpacity(0.3)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        approval.notes,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.45),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Action buttons — loader inside Approve when processing
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isDisabled || isProcessing ? null : onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.secondaryLight.withOpacity(0.4),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.lockerReject,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isDisabled || isProcessing ? null : onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        disabledBackgroundColor: AppColors.primaryLight,
                        disabledForegroundColor: AppColors.secondaryLight,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.secondaryLight,
                              ),
                            )
                          : Text(
                              l10n.lockerApprove,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: AppColors.secondaryLight,
                              ),
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

// ── Fund request card ─────────────────────────────────────────────────────────

class _FundRequestCard extends StatelessWidget {
  final LockerFundRequest request;
  final bool isProcessing;
  final bool isDisabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _FundRequestCard({
    required this.request,
    required this.isProcessing,
    required this.isDisabled,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = (request.description ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OwnerListIconBox(
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.cashierName.isNotEmpty
                            ? request.cashierName
                            : l10n.lockerFallbackCashier,
                        style: OwnerListStyle.titleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.branchName,
                        style: OwnerListStyle.subtitleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                          Localizations.localeOf(context).toString(),
                        ).format(request.createdAt.toLocal()),
                        style: OwnerListStyle.metaStyle,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${l10n.lockerSarCurrency} ${request.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isDisabled || isProcessing ? null : onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.secondaryLight.withOpacity(0.4),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.lockerReject,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isDisabled || isProcessing ? null : onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        disabledBackgroundColor: AppColors.primaryLight,
                        disabledForegroundColor: AppColors.secondaryLight,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.secondaryLight,
                              ),
                            )
                          : Text(
                              l10n.lockerApprove,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: AppColors.secondaryLight,
                              ),
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

// ── Small reusable widgets ────────────────────────────────────────────────────

class _PersonChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _PersonChip(
      {required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.secondaryLight.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.secondaryLight.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color: AppColors.secondaryLight.withOpacity(0.4)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.25),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withOpacity(0.3),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

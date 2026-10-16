import 'package:filter_service_providers/views/Locker%20App/PettyCash/locker_petty_cash_view.dart';
import 'package:filter_service_providers/views/Locker%20App/PettyCash/locker_petty_cash_issue_log_view.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../CashDeposit/locker_deposit_view.dart';
import '../Collection/record_collection_view.dart';
import '../CollectionHistory/locker_collection_history_view.dart';
import '../DifferencesReport/locker_differences_report_view.dart';
import '../Expenses/locker_expenses_view.dart';
import '../Requests/locker_requests_list_view.dart';
import '../Requests/requests_approval_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LockerSidebarItem
//
// Identifies which sidebar entry corresponds to the screen currently on
// screen, so LockerSidebar can highlight the right row instead of always
// highlighting "Dashboard". Pass the matching value in from each screen
// (via LockerShell's `currentItem` param); leave it null (or use
// `.dashboard`) for the dashboard itself or any screen with no sidebar
// entry of its own.
// ─────────────────────────────────────────────────────────────────────────────

enum LockerSidebarItem {
  dashboard,
  pendingRequests,    // supervisor: "Pending Requests"
  recordCollection,   // both roles
  varianceApprovals,  // supervisor: "Approvals"
  collectionHistory,
  differencesReport,
  assignedRequests,   // collector: "Assigned Requests"
  depositToBank,
  issuePettyCash,     // supervisor: "Issue Petty Cash"
  pettyCashIssueLog,  // supervisor: "Petty Cash Issue Log"
  expenses,           // both roles: "Expenses"
}

// ─────────────────────────────────────────────────────────────────────────────
// LockerSidebar
//
// Shared Drawer for both locker dashboards. Same visual language as
// OwnerShell's drawer (dark background, avatar header, rounded highlighted
// item, expandable-free flat list, logout confirm dialog).
//
// Supervisor gets the full item set; collector gets a trimmed-down one
// (`isSupervisor: false`) — pass the flag in from whichever dashboard
// mounts this.
// ─────────────────────────────────────────────────────────────────────────────

class LockerSidebar extends StatelessWidget {
  final String? userName;
  final String? roleLabel;
  final bool isSupervisor;

  /// Which entry represents the screen this drawer was opened from.
  /// Defaults to [LockerSidebarItem.dashboard] so existing call sites that
  /// don't pass it (yet) keep today's behaviour.
  final LockerSidebarItem currentItem;

  /// Called when the person taps "Log Out" — the dashboard owns the actual
  /// session-clearing + confirm dialog (each role has its own ViewModel),
  /// the sidebar just delegates to it.
  final VoidCallback onLogoutTap;

  const LockerSidebar({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.isSupervisor,
    required this.onLogoutTap,
    this.currentItem = LockerSidebarItem.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      width: 280,
      backgroundColor: AppColors.secondaryLight,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _drawerItem(
                  context,
                  title: l10n.lockerNavDashboard,
                  icon: Icons.dashboard_rounded,
                  selected: currentItem == LockerSidebarItem.dashboard,
                  onTap: () => _goToDashboard(context),
                ),
                const SizedBox(height: 4),

                if (isSupervisor) ...[
                  // 1. Pending Requests
                  _drawerItem(
                    context,
                    title: l10n.lockerNavPendingRequests,
                    icon: Icons.view_list_rounded,
                    selected: currentItem == LockerSidebarItem.pendingRequests,
                    onTap: () => _push(
                      context,
                      const LockerRequestsListView(initialView: 'supervisor'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 2. Record Collection
                  _drawerItem(
                    context,
                    title: l10n.lockerNavRecordCollection,
                    icon: Icons.assignment_turned_in_rounded,
                    selected: currentItem == LockerSidebarItem.recordCollection,
                    onTap: () => _push(
                      context,
                      const RecordCollectionView(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 3. Approvals
                  _drawerItem(
                    context,
                    title: l10n.lockerNavApprovals,
                    icon: Icons.compare_arrows_rounded,
                    selected: currentItem == LockerSidebarItem.varianceApprovals,
                    onTap: () => _push(
                      context,
                      const LockerVarianceApprovalsView(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 4. Deposit to Bank
                  _drawerItem(
                    context,
                    title: l10n.lockerNavDepositToBank,
                    icon: Icons.send_rounded,
                    selected: currentItem == LockerSidebarItem.depositToBank,
                    onTap: () => _push(
                      context,
                      LockerDepositView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 5. Issue Petty Cash
                  _drawerItem(
                    context,
                    title: l10n.lockerNavIssuePettyCash,
                    icon: Icons.currency_exchange_rounded,
                    selected: currentItem == LockerSidebarItem.issuePettyCash,
                    onTap: () => _push(
                      context,
                      LockerPettyCashView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 6. Petty Cash Issue Log
                  _drawerItem(
                    context,
                    title: l10n.lockerNavPettyCashIssueLog,
                    icon: Icons.playlist_add_check_rounded,
                    selected: currentItem == LockerSidebarItem.pettyCashIssueLog,
                    onTap: () => _push(
                      context,
                      LockerPettyCashIssueLogView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 7. Expenses
                  _drawerItem(
                    context,
                    title: l10n.lockerNavExpenses,
                    icon: Icons.receipt_long_rounded,
                    selected: currentItem == LockerSidebarItem.expenses,
                    onTap: () => _push(
                      context,
                      LockerExpensesView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 8. Collections History
                  _drawerItem(
                    context,
                    title: l10n.lockerNavCollectionsHistory,
                    icon: Icons.history_rounded,
                    selected: currentItem == LockerSidebarItem.collectionHistory,
                    onTap: () => _push(
                      context,
                      LockerCollectionHistoryView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 9. Differences Report
                  _drawerItem(
                    context,
                    title: l10n.lockerNavDifferencesReport,
                    icon: Icons.trending_down_rounded,
                    selected: currentItem == LockerSidebarItem.differencesReport,
                    onTap: () => _push(
                      context,
                      LockerDifferencesReportView(isSupervisor: isSupervisor),
                    ),
                  ),
                ] else ...[
                  _drawerItem(
                    context,
                    title: l10n.lockerNavAssignedRequests,
                    icon: Icons.assignment_ind_rounded,
                    selected: currentItem == LockerSidebarItem.assignedRequests,
                    onTap: () => _push(
                      context,
                      const LockerRequestsListView(
                        filterMode: LockerListFilterMode.myPending,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _drawerItem(
                    context,
                    title: l10n.lockerNavRecordCollection,
                    icon: Icons.assignment_turned_in_rounded,
                    selected: currentItem == LockerSidebarItem.recordCollection,
                    onTap: () => _push(
                      context,
                      const RecordCollectionView(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _drawerItem(
                    context,
                    title: l10n.lockerNavExpenses,
                    icon: Icons.receipt_long_rounded,
                    selected: currentItem == LockerSidebarItem.expenses,
                    onTap: () => _push(
                      context,
                      LockerExpensesView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _drawerItem(
                    context,
                    title: l10n.lockerNavCollectionHistory,
                    icon: Icons.history_rounded,
                    selected: currentItem == LockerSidebarItem.collectionHistory,
                    onTap: () => _push(
                      context,
                      LockerCollectionHistoryView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _drawerItem(
                    context,
                    title: l10n.lockerNavDifferencesHistory,
                    icon: Icons.trending_down_rounded,
                    selected: currentItem == LockerSidebarItem.differencesReport,
                    onTap: () => _push(
                      context,
                      LockerDifferencesReportView(isSupervisor: isSupervisor),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                _drawerItem(
                  context,
                  title: l10n.lockerLogOut,
                  icon: Icons.logout_rounded,
                  isLogout: true,
                  onTap: () {
                    Navigator.pop(context);
                    onLogoutTap();
                  },
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context); // close the drawer first
    // Plain push → LockerShell shows hamburger (not back). Dashboard
    // Quick Actions / View All use LockerShell.pushWithBack instead.
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// "Dashboard" item — close the drawer AND pop every screen pushed on
  /// top of it, back down to the dashboard (the first/root route on this
  /// Navigator).
  ///
  /// Navigator.pop(context) alone only closes the drawer (the drawer is
  /// itself a route on the same Navigator) — it does NOT remove any
  /// LockerShell screens that were reached via Navigator.push(). So tapping
  /// "Dashboard" from e.g. Petty Cash or Collection History just closed the
  /// drawer and left that screen showing underneath, with no visible
  /// change. popUntil(isFirst) walks back through the entire stack —
  /// closing the drawer along with it — until only the dashboard is left.
  void _goToDashboard(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName =
    (userName != null && userName!.isNotEmpty) ? userName! : l10n.lockerDefaultUser;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=FCC247&color=23262D',
                width: 48,
                height: 48,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.person, color: AppColors.secondaryLight),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (roleLabel != null && roleLabel!.isNotEmpty)
                  Text(
                    roleLabel!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white24, size: 16),
          const SizedBox(width: 8),
          Text(
            l10n.lockerFooterPortal,
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Item row ─────────────────────────────────────────────────────────────

  Widget _drawerItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
        bool selected = false,
        bool isLogout = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.black : Colors.white70),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
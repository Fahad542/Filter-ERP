import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/technician_commission_history_model.dart';
import '../../../utils/app_colors.dart';
import '../technician_view_model.dart';
import '../widgets/tech_dashboard_filter_bar.dart';
import '../widgets/tech_list_shimmer.dart';
import '../../../widgets/global_locale_toolbar_icon.dart';
import '../../../widgets/notification_toolbar_icon.dart';
import '../Notifications/notifications_view.dart';

class CommissionHistoryView extends StatefulWidget {
  const CommissionHistoryView({super.key});

  @override
  State<CommissionHistoryView> createState() => _CommissionHistoryViewState();
}

class _CommissionHistoryViewState extends State<CommissionHistoryView> {
  DateFormat _entryDateFormat(BuildContext context) =>
      DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString());
  DateFormat _entryTimeFormat(BuildContext context) =>
      DateFormat('hh:mm a', Localizations.localeOf(context).toString());
  DateFormat _rangeDateFormat(BuildContext context) =>
      DateFormat('dd MMM yyyy · hh:mm a', Localizations.localeOf(context).toString());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechAppViewModel>().fetchCommissionHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommissionEntry> _filteredEntries(List<CommissionEntry> entries) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return entries;

    return entries.where((e) {
      final orderId = e.orderId.toLowerCase();
      final inv = e.invoiceId != null
          ? 'inv-${e.invoiceId}'.toLowerCase()
          : '';
      return orderId.contains(q) || inv.contains(q);
    }).toList();
  }

  double _totalCommission(List<CommissionEntry> entries) =>
      entries.fold(0.0, (sum, e) => sum + e.commission);

  /// Job completion instant — same field as Assigned Orders (`completedAt`).
  DateTime? _entryDateTime(CommissionEntry entry) {
    return DateTime.tryParse(entry.date)?.toLocal();
  }

  String _entryDateTimeLabel(BuildContext context, CommissionEntry entry) {
    final dt = _entryDateTime(entry);
    if (dt == null) return '—';
    return '${_entryDateFormat(context).format(dt)} · ${_entryTimeFormat(context).format(dt)}';
  }

  String _invoiceLabel(CommissionEntry entry) {
    if (entry.invoiceId == null || entry.invoiceId!.trim().isEmpty) {
      return '';
    }
    return 'INV-${entry.invoiceId}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FD),
      child: Consumer<TechAppViewModel>(
        builder: (context, vm, child) {
          final loading = vm.isLoadingCommission;
          final filtered = _filteredEntries(vm.commissionHistory);
          final isSearching = _searchController.text.trim().isNotEmpty;
          final showTotalBar = !loading &&
              (vm.commissionHistoryTotalCommission > 0 ||
                  vm.commissionHistory.isNotEmpty);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, vm),
              _buildSearchBar(),
              Expanded(
                child: loading
                    ? const TechListCardShimmer()
                    : RefreshIndicator(
                        color: AppColors.secondaryLight,
                        backgroundColor: Colors.white,
                        onRefresh: vm.fetchCommissionHistory,
                        child: vm.commissionHistory.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height * 0.28,
                                    child: _buildEmptyState(isSearching: false),
                                  ),
                                ],
                              )
                            : filtered.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                                0.28,
                                        child: _buildEmptyState(
                                          isSearching: true,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                      20,
                                      4,
                                      20,
                                      showTotalBar ? 8 : 20,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _buildCommissionItem(filtered[index]);
                                    },
                                  ),
                      ),
              ),
              if (showTotalBar)
                _buildTotalCommissionBar(
                  vm,
                  filtered,
                  isSearching: isSearching,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
          controller: _searchController,
          style: const TextStyle(
            color: AppColors.secondaryLight,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: l10n.techCommSearchHint,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.black.withOpacity(0.35),
              size: 22,
            ),
            suffixIcon: _searchController.text.trim().isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.black.withOpacity(0.35),
                      size: 20,
                    ),
                    onPressed: _searchController.clear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isSearching}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.payments_outlined,
            size: 48,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? l10n.techCommNoSearchMatch
                : l10n.techCommNoneFound,
            style: TextStyle(
              color: Colors.black.withOpacity(0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? l10n.techCommSearchEmptyHint
                : l10n.techCommEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCommissionBar(
    TechAppViewModel vm,
    List<CommissionEntry> visibleEntries, {
    required bool isSearching,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final commission = isSearching
        ? _totalCommission(visibleEntries)
        : vm.commissionHistoryTotalCommission;
    final count =
        isSearching ? visibleEntries.length : vm.reportPeriodJobCount;
    final amount = commission.toStringAsFixed(2);
    final countStr = count.toString();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_rangeDateFormat(context).format(vm.commissionHistoryFrom)} – ${_rangeDateFormat(context).format(vm.commissionHistoryTo)}',
                      style: const TextStyle(
                        color: AppColors.onSecondaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      isSearching
                          ? l10n.techOrdersShowingMatches(
                              countStr,
                              l10n.ownerCurrencySar,
                              amount,
                            )
                          : l10n.techOrdersTotalCommission(
                              countStr,
                              l10n.ownerCurrencySar,
                              amount,
                            ),
                      style: TextStyle(
                        color: AppColors.onSecondaryLight.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TechAppViewModel vm) {
    const filterOverlap = 46.0;
    const headerBodyHeight = 112.0;
    final topPad = MediaQuery.paddingOf(context).top;
    final isRtl = Directionality.of(context).name == 'rtl';
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: topPad + headerBodyHeight + filterOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + headerBodyHeight,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 32),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Center(
                      child: Text(
                        l10n.techCommTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment:
                        isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: _menuButton(context),
                  ),
                  Align(
                    alignment:
                        isRtl ? Alignment.centerLeft : Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GlobalLocaleToolbarIcon(inCluster: true),
                        const SizedBox(width: 6),
                        NotificationToolbarIcon(
                          inCluster: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationsView(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: TechDashboardOverlapFilters(
              startDate: vm.commissionHistoryFrom,
              endDate: vm.commissionHistoryTo,
              onStartDateChanged: vm.applyCommissionHistoryStartDate,
              onEndDateChanged: vm.applyCommissionHistoryEndDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryLight.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildCommissionItem(CommissionEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = entry.isPaid;
    final statusColor = isPaid ? Colors.green : Colors.orange;
    final dateTimeLabel = _entryDateTimeLabel(context, entry);
    final invoiceLabel = _invoiceLabel(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPaid
              ? Colors.green.withOpacity(0.15)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateTimeLabel,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.orderId,
                  style: const TextStyle(
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                if (invoiceLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    invoiceLabel,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  entry.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.techMoneyAmount(
                  l10n.ownerCurrencySar,
                  entry.commission.toStringAsFixed(2),
                ),
                style: const TextStyle(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (isPaid)
                Text(
                  l10n.techCommCreditedWallet,
                  style: TextStyle(
                    color: Colors.green.shade400,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

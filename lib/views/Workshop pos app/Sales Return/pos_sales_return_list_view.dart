import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../widgets/pos_segmented_list_tabs.dart';
import 'sales_return_list_view_model.dart';
import '../../../models/sales_return_list_model.dart';

String _salesReturnLang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _salesReturnDigits(BuildContext context, Object? value) {
  return AppTranslationService.localizeDigitsForLanguage(
    value?.toString() ?? '',
    _salesReturnLang(context),
  );
}

String _salesReturnRef(BuildContext context, String value) =>
    _salesReturnDigits(context, value);

String _salesReturnMoney(BuildContext context, num amount) {
  final raw = amount.toStringAsFixed(2);
  if (_salesReturnLang(context) == 'ar') {
    return '${_salesReturnDigits(context, raw)} ر.س';
  }
  return AppLocalizations.of(context)!.posSalesReturnSarAmount(raw);
}

String _salesReturnDate(BuildContext context, DateTime date) {
  final lang = _salesReturnLang(context);
  final formatted = DateFormat(
    'MMM dd, yyyy • hh:mm a',
    lang == 'ar' ? 'ar' : 'en',
  ).format(date);
  return _salesReturnDigits(context, formatted);
}

class _SalesReturnStatusColors {
  final Color background;
  final Color foreground;
  const _SalesReturnStatusColors({
    required this.background,
    required this.foreground,
  });
}

String _statusLabel(AppLocalizations l10n, String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return l10n.posSalesReturnStatusPending;
    case 'completed':
      return l10n.posSalesReturnStatusCompleted;
    case 'rejected':
      return l10n.posSalesReturnStatusRejected;
    default:
      return status;
  }
}

_SalesReturnStatusColors _statusColors(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const _SalesReturnStatusColors(
        background: Color(0xFFEA580C),
        foreground: Colors.white,
      );
    case 'completed':
      return const _SalesReturnStatusColors(
        background: Color(0xFF15803D),
        foreground: Colors.white,
      );
    case 'rejected':
      return const _SalesReturnStatusColors(
        background: Color(0xFFB42318),
        foreground: Colors.white,
      );
    default:
      return _SalesReturnStatusColors(
        background: Colors.grey.shade700,
        foreground: Colors.white,
      );
  }
}

class PosSalesReturnListView extends StatefulWidget {
  const PosSalesReturnListView({super.key});

  @override
  State<PosSalesReturnListView> createState() => _PosSalesReturnListViewState();
}

class _PosSalesReturnListViewState extends State<PosSalesReturnListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusTab = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesReturnListViewModel>().fetchReturns(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final vm = context.read<SalesReturnListViewModel>();
      if (!vm.isLoading && vm.hasMore) {
        vm.fetchReturns();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final vm = context.watch<SalesReturnListViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PosScreenAppBar(
        title: AppLocalizations.of(context)!.posSalesReturnListTitle,
        showBackButton: false,
        showHamburger: true,
        onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
      ),
      body: wrapPosShellRailBody(
        context,
        RefreshIndicator(
          onRefresh: () => vm.fetchReturns(refresh: true),
          color: AppColors.primaryLight,
          child: _buildBody(vm, isTablet),
        ),
      ),
    );
  }

  Widget _buildBody(SalesReturnListViewModel vm, bool isTablet) {
    if (vm.isLoading && vm.returns.isEmpty) {
      return _SalesReturnListShimmer(isTablet: isTablet);
    }

    if (vm.error != null && vm.returns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.posSalesReturnListFailedLoad,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => vm.fetchReturns(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.black,
              ),
              child: Text(AppLocalizations.of(context)!.posCommonRetry),
            ),
          ],
        ),
      );
    }

    if (vm.returns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.posSalesReturnListNoReturns,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    final statusFiltered = _filterByStatusTab(vm.returns);
    final filteredReturns = query.isEmpty
        ? statusFiltered
        : statusFiltered
              .where((item) => _matchesReturnSearch(item, query))
              .toList();
    return Column(
      children: [
        _buildSearchBar(isTablet),
        _buildStatusTabs(isTablet, vm),
        Expanded(
          child: filteredReturns.isEmpty
              ? (query.isNotEmpty
                    ? _buildNoSearchResults()
                    : _buildNoTabResults())
              : _buildNaturalReturnGrid(
                  returns: filteredReturns,
                  isTablet: isTablet,
                  showLoadMore: query.isEmpty &&
                      _selectedStatusTab == 'all' &&
                      vm.hasMore,
                ),
        ),
      ],
    );
  }

  List<SalesReturnInfo> _filterByStatusTab(List<SalesReturnInfo> items) {
    switch (_selectedStatusTab) {
      case 'pending':
        return items
            .where((item) => item.status.toLowerCase() == 'pending')
            .toList();
      case 'approved':
        return items
            .where((item) => item.status.toLowerCase() == 'completed')
            .toList();
      case 'rejected':
        return items
            .where((item) => item.status.toLowerCase() == 'rejected')
            .toList();
      default:
        return items;
    }
  }

  bool _matchesReturnSearch(SalesReturnInfo item, String query) {
    final haystack = [
      item.returnNo,
      item.invoiceNo,
      item.orderId,
      item.customerName,
      item.customerId,
      item.reason ?? '',
      item.status,
      item.totalAmount.toStringAsFixed(2),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  Widget _buildSearchBar(bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 20 : 24,
        10,
        isTablet ? 20 : 24,
        4,
      ),
      child: PosWorkshopSearchBar(
        controller: _searchController,
        hintText: AppLocalizations.of(context)!.posSalesReturnSearchHint,
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildStatusTabs(bool isTablet, SalesReturnListViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final pendingCount = vm.returns
        .where((item) => item.status.toLowerCase() == 'pending')
        .length;
    final approvedCount = vm.returns
        .where((item) => item.status.toLowerCase() == 'completed')
        .length;
    final rejectedCount = vm.returns
        .where((item) => item.status.toLowerCase() == 'rejected')
        .length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 20 : 12,
        0,
        isTablet ? 20 : 12,
        8,
      ),
      child: PosSegmentedListTabs(
        layout: PosSegmentedTabLayout.expanded,
        containerColor: Colors.white,
        unselectedTabColor: Colors.white,
        tabVerticalPadding: isTablet ? 9 : 8,
        tabs: [
          PosSegmentedTab(
            id: 'all',
            label: l10n.posCommonAll,
            count: vm.returns.length,
          ),
          PosSegmentedTab(
            id: 'pending',
            label: l10n.posSalesReturnStatusPending,
            count: pendingCount,
          ),
          PosSegmentedTab(
            id: 'approved',
            label: l10n.posSalesReturnStatusCompleted,
            count: approvedCount,
          ),
          PosSegmentedTab(
            id: 'rejected',
            label: l10n.posSalesReturnStatusRejected,
            count: rejectedCount,
          ),
        ],
        selectedId: _selectedStatusTab,
        onSelected: (id) => setState(() => _selectedStatusTab = id),
      ),
    );
  }

  Widget _buildNaturalReturnGrid({
    required List<SalesReturnInfo> returns,
    required bool isTablet,
    required bool showLoadMore,
  }) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final columns = isTablet ? (isLandscape ? 3 : 2) : 1;
    final cardExtent = isTablet ? (isLandscape ? 110.0 : 114.0) : 102.0;

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 14 : 10,
        6,
        isTablet ? 14 : 10,
        isTablet ? 12 : 10,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: cardExtent,
      ),
      itemCount: returns.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (showLoadMore && index == returns.length) {
          return const Center(
            child: PosShimmer(
              child: PosShimmerBox(width: 42, height: 14, radius: 7),
            ),
          );
        }
        return _buildReturnCard(returns[index], isTablet);
      },
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.posSalesReturnNoInvoicesFound(
          _salesReturnRef(context, _searchQuery),
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoTabResults() {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (_selectedStatusTab) {
      'pending' => l10n.posSalesReturnStatusPending,
      'approved' => l10n.posSalesReturnStatusCompleted,
      'rejected' => l10n.posSalesReturnStatusRejected,
      _ => l10n.posSalesReturnListNoReturns,
    };
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReturnCard(SalesReturnInfo returnInfo, bool isTablet) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final l10n = AppLocalizations.of(context)!;

    final date = DateTime.tryParse(returnInfo.returnDate) ?? DateTime.now();
    final formattedDate = _salesReturnDate(context, date);
    final statusLabel = _statusLabel(l10n, returnInfo.status);
    final statusColors = _statusColors(returnInfo.status);
    final hasReason =
        returnInfo.reason != null && returnInfo.reason!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onDoubleTap: () {}, // Prevent accidental taps
              onTap: () => _showReturnDetails(returnInfo, isTablet),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _salesReturnRef(context, returnInfo.returnNo),
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColors.foreground,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: AppColors.primaryLight.withOpacity(0.55),
                              ),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.secondaryLight,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.posSalesReturnListInvoiceLabel(
                                    _salesReturnRef(
                                      context,
                                      returnInfo.invoiceNo,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isLandscape ? 12 : 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2D3139),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formattedDate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isLandscape ? 10 : 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.posSalesReturnRefundAmount,
                                style: TextStyle(
                                  fontSize: isLandscape ? 8.5 : 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _salesReturnMoney(
                                  context,
                                  returnInfo.totalAmount,
                                ),
                                style: TextStyle(
                                  fontSize: isLandscape ? 13 : 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondaryLight,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: isLandscape ? 16 : 18,
                      child: hasReason
                          ? Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: LocalizedApiText(
                                    returnInfo.reason!.trim(),
                                    style: TextStyle(
                                      fontSize: isLandscape ? 9.5 : 10.5,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  void _showReturnDetails(SalesReturnInfo returnInfo, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 100 : 16,
          vertical: 28,
        ),
        child: _ReturnDetailsDialog(returnInfo: returnInfo, isTablet: isTablet),
      ),
    );
  }
}

class _ReturnDetailsDialog extends StatelessWidget {
  final SalesReturnInfo returnInfo;
  final bool isTablet;

  const _ReturnDetailsDialog({
    required this.returnInfo,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 16, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.posSalesReturnDetailsTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E2124),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.posSalesReturnDetailsSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Grid
                  _buildDetailedGrid(context, isTablet),

                  const SizedBox(height: 22),

                  // Section Title
                  Row(
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
                        AppLocalizations.of(
                          context,
                        )!.posSalesReturnItemsReturned,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2124),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Product List
                  ...returnInfo.items.map(
                    (item) => _buildItemRow(context, item),
                  ),
                ],
              ),
            ),
          ),

          // Footer Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.posSalesReturnCloseDetails,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedGrid(BuildContext context, bool isTablet) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      children: [
        _buildDetailItem(
          AppLocalizations.of(context)!.posSalesReturnNoLabel,
          _salesReturnRef(context, returnInfo.returnNo),
          Icons.tag_rounded,
        ),
        if ((returnInfo.creditNoteNo ?? '').isNotEmpty)
          _buildDetailItem(
            AppLocalizations.of(context)!.posSalesReturnCreditNoteLabel,
            _salesReturnRef(context, returnInfo.creditNoteNo!),
            Icons.note_alt_outlined,
          ),
        _buildDetailItem(
          AppLocalizations.of(context)!.posSalesReturnStatusLabel,
          _statusLabel(AppLocalizations.of(context)!, returnInfo.status),
          Icons.info_outline_rounded,
        ),
        _buildDetailItem(
          AppLocalizations.of(context)!.posSalesReturnInvoiceNoLabel,
          _salesReturnRef(context, returnInfo.invoiceNo),
          Icons.receipt_rounded,
        ),
        _buildDetailItem(
          AppLocalizations.of(context)!.posSalesReturnOrderIdLabel,
          _salesReturnRef(context, returnInfo.orderId),
          Icons.shopping_bag_rounded,
        ),
        _buildDetailItem(
          AppLocalizations.of(context)!.posSalesReturnCustomerLabel,
          returnInfo.customerName.isNotEmpty
              ? returnInfo.customerName
              : returnInfo.customerId,
          Icons.person_rounded,
        ),
        _buildDetailItem(
          AppLocalizations.of(context)!.posSalesReturnTotalRefund,
          _salesReturnMoney(context, returnInfo.totalAmount),
          Icons.payments_rounded,
          isAmount: true,
        ),
        if (returnInfo.reason != null)
          _buildDetailItem(
            AppLocalizations.of(context)!.posSalesReturnReasonLabel,
            returnInfo.reason!,
            Icons.comment_rounded,
            isFullWidth: true,
          ),
        if ((returnInfo.rejectionReason ?? '').trim().isNotEmpty)
          _buildDetailItem(
            AppLocalizations.of(context)!.posSalesReturnRejectionReasonLabel,
            returnInfo.rejectionReason!.trim(),
            Icons.block_rounded,
            isFullWidth: true,
          ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    bool isAmount = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : (isTablet ? 210 : 120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                LocalizedApiText(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isAmount ? FontWeight.w900 : FontWeight.w700,
                    color: isAmount
                        ? const Color(0xFF109D59)
                        : const Color(0xFF2D3139),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, SalesReturnItemInfo item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 18,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.posSalesReturnItemId(
                    _salesReturnRef(context, item.salesOrderItemId),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF2D3139),
                  ),
                ),
                if (item.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: LocalizedApiText(
                      item.reason!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.posSalesReturnItemQty(_salesReturnDigits(context, item.qty)),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _salesReturnMoney(context, item.lineTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.secondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesReturnListShimmer extends StatelessWidget {
  const _SalesReturnListShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isTablet ? 14 : 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? (isLandscape ? 3 : 2) : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: isTablet ? (isLandscape ? 110.0 : 114.0) : 102.0,
      ),
      itemCount: isTablet ? 6 : 4,
      itemBuilder: (_, __) => Container(
        padding: EdgeInsets.all(isTablet ? 7 : 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const PosShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PosShimmerBox(width: 72, height: 18, radius: 8),
                  Spacer(),
                  PosShimmerBox(width: 56, height: 18, radius: 8),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  PosShimmerBox(width: 30, height: 30, radius: 9),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PosShimmerLine(width: double.infinity, height: 12),
                        SizedBox(height: 5),
                        PosShimmerLine(width: 108, height: 9),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              PosShimmerLine(width: 112, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

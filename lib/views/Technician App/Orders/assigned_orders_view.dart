import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/technician_models.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/global_locale_toolbar_icon.dart';
import '../../../widgets/notification_toolbar_icon.dart';
import '../Notifications/notifications_view.dart';
import '../technician_view_model.dart';
import '../widgets/tech_dashboard_filter_bar.dart';
import '../widgets/tech_list_shimmer.dart';
import 'order_details_view.dart';

class AssignedOrdersView extends StatefulWidget {
  final bool isFromDashboard;
  const AssignedOrdersView({super.key, this.isFromDashboard = false});

  @override
  State<AssignedOrdersView> createState() => _AssignedOrdersViewState();
}

class _AssignedOrdersViewState extends State<AssignedOrdersView> {
  final Set<String> _expandedIds = {};
  final TextEditingController _searchController = TextEditingController();

  DateFormat _orderDateFormat(BuildContext context) =>
      DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString());
  DateFormat _orderTimeFormat(BuildContext context) =>
      DateFormat('hh:mm a', Localizations.localeOf(context).toString());
  DateFormat _rangeDateFormat(BuildContext context) =>
      DateFormat('dd MMM yyyy · hh:mm a', Localizations.localeOf(context).toString());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechAppViewModel>().fetchAssignedOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TechOrder> _filteredOrders(List<TechOrder> orders) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return orders;

    final qCompact = q.replaceAll(RegExp(r'[\s\-]+'), '');
    return orders.where((o) {
      final id = o.id.toLowerCase();
      final plate = o.plateNumber.toLowerCase();
      final plateCompact =
          plate.replaceAll(RegExp(r'[\s\-]+'), '');
      final customer = o.customerName.toLowerCase();
      return id.contains(q) ||
          plate.contains(q) ||
          plateCompact.contains(qCompact) ||
          customer.contains(q);
    }).toList();
  }

  double _totalCommission(List<TechOrder> orders) =>
      orders.fold(0.0, (sum, o) => sum + o.commission);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FD),
      child: Consumer<TechAppViewModel>(
        builder: (context, vm, _) {
          final ordersLoading = vm.isAssignedOrdersRequestInFlight;
          final filteredOrders = _filteredOrders(vm.assignedOrders);
          final isSearching = _searchController.text.trim().isNotEmpty;
          final showTotalBar = !ordersLoading &&
              (vm.assignedOrdersTotalCommission > 0 ||
                  vm.assignedOrders.isNotEmpty);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, vm),
              _buildSearchBar(),
              Expanded(
                child: ordersLoading
                    ? const TechListCardShimmer()
                    : RefreshIndicator(
                        color: AppColors.secondaryLight,
                        backgroundColor: Colors.white,
                        onRefresh: vm.fetchAssignedOrders,
                        child: vm.assignedOrders.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.sizeOf(context).height *
                                        0.28,
                                    child: _buildEmptyState(isSearching: false),
                                  ),
                                ],
                              )
                            : filteredOrders.isEmpty
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
                                      showTotalBar ? 16 : 24,
                                    ),
                                    itemCount: filteredOrders.length,
                                    itemBuilder: (context, index) {
                                      return _buildOrderCard(
                                        context,
                                        filteredOrders[index],
                                        vm,
                                      );
                                    },
                                  ),
                      ),
              ),
              if (showTotalBar)
                _buildTotalBar(
                  vm,
                  filteredOrders,
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
            hintText: l10n.techOrdersSearchHint,
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
                    onPressed: () {
                      _searchController.clear();
                    },
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
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Center(
                      child: Text(
                        l10n.techOrdersTitle,
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
                    child: widget.isFromDashboard
                        ? _backButton(context)
                        : _menuButton(context),
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
              startDate: vm.assignedOrdersFrom,
              endDate: vm.assignedOrdersTo,
              onStartDateChanged: vm.applyAssignedOrdersStartDate,
              onEndDateChanged: vm.applyAssignedOrdersEndDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: AppColors.secondaryLight,
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

  Widget _buildTotalBar(
    TechAppViewModel vm,
    List<TechOrder> visibleOrders, {
    required bool isSearching,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final commission = isSearching
        ? _totalCommission(visibleOrders)
        : vm.dashboardCommissionEarned;
    final count =
        isSearching ? visibleOrders.length : vm.reportPeriodJobCount;
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
                  Icons.assignment_turned_in_rounded,
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
                      '${_rangeDateFormat(context).format(vm.assignedOrdersFrom)} – ${_rangeDateFormat(context).format(vm.assignedOrdersTo)}',
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

  Widget _buildEmptyState({required bool isSearching}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off_rounded : Icons.assignment_outlined,
            size: 48,
            color: Colors.black.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? l10n.techOrdersNoSearchMatch
                : l10n.techOrdersNoJobsInRange,
            style: TextStyle(
              color: Colors.black.withOpacity(0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? l10n.techOrdersSearchHintEmpty
                : l10n.techOrdersEmptyHint,
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

  Widget _buildOrderCard(
    BuildContext context,
    TechOrder order,
    TechAppViewModel vm,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final expanded = _expandedIds.contains(order.jobId);
    final completedLabel = order.timestamp != null
        ? '${_orderDateFormat(context).format(order.timestamp!)} · ${_orderTimeFormat(context).format(order.timestamp!)}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              if (expanded) {
                _expandedIds.remove(order.jobId);
              } else {
                _expandedIds.add(order.jobId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completedLabel,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.id,
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.plateNumber.trim().isNotEmpty
                                ? order.plateNumber.toUpperCase()
                                : '—',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
                            order.commission.toStringAsFixed(2),
                          ),
                          style: const TextStyle(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          l10n.techOrdersCommission,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.45),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.black38,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _detailRow(
                    l10n.techOrdersCustomer,
                    order.customerName.trim().isNotEmpty
                        ? order.customerName
                        : '—',
                  ),
                  if (order.vehicleModel.trim().isNotEmpty)
                    _detailRow(l10n.techOrdersVehicle, order.vehicleModel),
                  _detailRow(
                    l10n.techOrdersDepartment,
                    order.department.isEmpty
                        ? l10n.techOrdersGeneral
                        : order.department,
                  ),
                  _detailRow(
                    l10n.techOrdersOrderValue,
                    l10n.techMoneyAmount(
                      l10n.ownerCurrencySar,
                      order.totalValue.toStringAsFixed(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openDetails(context, order, vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.techOrdersViewDetails,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(
    BuildContext context,
    TechOrder order,
    TechAppViewModel vm,
  ) {
    vm.fetchOrderDetails(order.jobId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailsView(order: order)),
    );
  }
}

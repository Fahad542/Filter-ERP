import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/cashier_ai_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../widgets/pos_filter_tab_dropdown.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import 'ai_orders_view_model.dart';
import 'pos_ai_order_detail_view.dart';

class PosAiOrdersView extends StatefulWidget {
  const PosAiOrdersView({super.key});

  @override
  State<PosAiOrdersView> createState() => _PosAiOrdersViewState();
}

class _PosAiOrdersViewState extends State<PosAiOrdersView> {
  final _searchController = TextEditingController();

  static const _statuses = <String?>[
    null,
    'VEHICLE_ENTERED',
    'CONFIRMED',
    'MATCHED',
    'UNMATCHED',
    'EXPIRED',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<AiOrdersViewModel>();
      vm.bootstrap();
      vm.fetchList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _statusLabel(String? s) {
    if (s == null || s.isEmpty) return 'All';
    switch (s) {
      case 'VEHICLE_ENTERED':
        return 'Entered';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'MATCHED':
        return 'Matched';
      case 'UNMATCHED':
        return 'Unmatched';
      case 'EXPIRED':
        return 'Expired';
      default:
        return s;
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'VEHICLE_ENTERED':
        return const Color(0xFF475569);
      case 'CONFIRMED':
        return const Color(0xFFB48A14);
      case 'MATCHED':
        return const Color(0xFF15803D);
      case 'UNMATCHED':
        return const Color(0xFFB91C1C);
      case 'EXPIRED':
        return const Color(0xFF64748B);
      default:
        return AppColors.secondaryLight;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'VEHICLE_ENTERED':
        return const Color(0xFFF1F5F9);
      case 'CONFIRMED':
        return const Color(0xFFFFF9EC);
      case 'MATCHED':
        return const Color(0xFFECFDF5);
      case 'UNMATCHED':
        return const Color(0xFFFFF5F5);
      case 'EXPIRED':
        return const Color(0xFFF8FAFC);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  String _scopeId(AiOrdersViewModel vm) {
    if (vm.unbilledOnly) return 'unbilled';
    if (vm.companyVehiclesOnly) return 'company';
    return 'all';
  }

  void _setScope(AiOrdersViewModel vm, String id) {
    final wantUnbilled = id == 'unbilled';
    final wantCompany = id == 'company';
    if (vm.unbilledOnly != wantUnbilled) {
      vm.setUnbilledOnly(wantUnbilled);
    }
    if (vm.companyVehiclesOnly != wantCompany) {
      vm.setCompanyVehiclesOnly(wantCompany);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: PosScreenAppBar(
        title: 'AI Orders',
        showBackButton: false,
        showHamburger: true,
        onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
      ),
      body: wrapPosShellRailBody(
        context,
        Consumer<AiOrdersViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 20 : 12,
                    12,
                    isTablet ? 20 : 12,
                    8,
                  ),
                  child: _buildFilters(vm, isTablet: isTablet),
                ),
                Expanded(child: _buildBody(vm, isTablet: isTablet)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(AiOrdersViewModel vm, {required bool isTablet}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PosWorkshopSearchBar(
                controller: _searchController,
                hintText: 'Search plate / capture…',
                onChanged: (v) {
                  // Debounce-free live filter on submit only would lag —
                  // mirror Closing History: update as user types.
                  vm.setSearchQuery(v);
                },
                onSubmitted: vm.setSearchQuery,
                onClear: () {
                  _searchController.clear();
                  vm.setSearchQuery('');
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    vm.fetchList();
                    vm.fetchUnbilledCount(silent: true);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.secondaryLight,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PosFilterTabDropdown(
                expand: true,
                title: 'Status',
                selectedId: vm.statusFilter ?? 'all',
                options: [
                  for (final s in _statuses)
                    PosFilterTabOption(
                      id: s ?? 'all',
                      label: _statusLabel(s),
                    ),
                ],
                onSelected: (id) {
                  vm.setStatusFilter(id == 'all' ? null : id);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PosFilterTabDropdown(
                expand: true,
                title: 'View',
                selectedId: _scopeId(vm),
                options: [
                  const PosFilterTabOption(id: 'all', label: 'All'),
                  PosFilterTabOption(
                    id: 'unbilled',
                    label: 'Unbilled',
                    count: vm.unbilledCount > 0 ? vm.unbilledCount : null,
                  ),
                  const PosFilterTabOption(id: 'company', label: 'Company'),
                ],
                onSelected: (id) => _setScope(vm, id),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(AiOrdersViewModel vm, {required bool isTablet}) {
    if (vm.isLoading && vm.orders.isEmpty) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 20 : 12,
          4,
          isTablet ? 20 : 12,
          24,
        ),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const _AiOrderShimmerCard(),
      );
    }
    if (vm.errorMessage != null && vm.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 160,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => vm.fetchList(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.onPrimaryLight,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (vm.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy_outlined,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                'No AI orders for today',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () async {
        await vm.fetchList(silent: true);
        await vm.fetchUnbilledCount(silent: true);
      },
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 20 : 12,
          4,
          isTablet ? 20 : 12,
          24,
        ),
        itemCount: vm.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = vm.orders[index];
          return _AiOrderRow(
            order: order,
            statusLabel: _statusLabel(order.status),
            statusFg: _statusFg(order.status),
            statusBg: _statusBg(order.status),
            entranceLabel: _fmt(order.entranceDetectedAt),
            bayLabel: order.lastBayName ?? '—',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PosAiOrderDetailView(aiOrderId: order.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AiOrderShimmerCard extends StatelessWidget {
  const _AiOrderShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const PosShimmer(
        child: Row(
          children: [
            PosShimmerBox(width: 36, height: 36, radius: 10),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(width: 110, height: 12, radius: 6),
                  SizedBox(height: 8),
                  PosShimmerBox(width: 160, height: 10, radius: 5),
                ],
              ),
            ),
            PosShimmerBox(width: 56, height: 22, radius: 999),
          ],
        ),
      ),
    );
  }
}

class _AiOrderRow extends StatelessWidget {
  const _AiOrderRow({
    required this.order,
    required this.statusLabel,
    required this.statusFg,
    required this.statusBg,
    required this.entranceLabel,
    required this.bayLabel,
    required this.onTap,
  });

  final AiOrderCashier order;
  final String statusLabel;
  final Color statusFg;
  final Color statusBg;
  final String entranceLabel;
  final String bayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alert = order.isUnbilledAlert;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alert
                  ? const Color(0xFFFECACA)
                  : order.isCompanyVehicle
                      ? const Color(0xFFC7D2FE)
                      : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.secondaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.displayPlate,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF1E2124),
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.isCompanyVehicle) ...[
                          const SizedBox(width: 6),
                          _miniBadge(
                            'Company',
                            bg: const Color(0xFFEEF2FF),
                            fg: const Color(0xFF4338CA),
                          ),
                        ],
                        if (alert) ...[
                          const SizedBox(width: 6),
                          _miniBadge(
                            'Unbilled',
                            bg: const Color(0xFFFEF2F2),
                            fg: const Color(0xFFB91C1C),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.captureNo}  ·  Entrance $entranceLabel  ·  Bay $bayLabel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: statusFg,
                      ),
                    ),
                  ),
                  if (order.hasOpenPosOrder || order.cashierOrderId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
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

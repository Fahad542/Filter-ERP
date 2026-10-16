import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/cashier_ai_order_model.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'VEHICLE_ENTERED':
        return Colors.blueGrey;
      case 'CONFIRMED':
        return Colors.orange.shade800;
      case 'MATCHED':
        return Colors.green.shade700;
      case 'UNMATCHED':
        return Colors.red.shade700;
      case 'EXPIRED':
        return Colors.grey.shade600;
      default:
        return Colors.black54;
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: const PosScreenAppBar(
        title: 'AI Orders',
        showBackButton: false,
        showHamburger: false,
      ),
      body: wrapPosShellRailBody(
        context,
        Consumer<AiOrdersViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilters(vm),
                Expanded(child: _buildBody(vm)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(AiOrdersViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search plate / capture…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (v) => vm.setSearchQuery(v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () {
                  vm.fetchList();
                  vm.fetchUnbilledCount(silent: true);
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in _statuses) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: FilterChip(
                      label: Text(_statusLabel(s)),
                      selected: vm.statusFilter == s,
                      onSelected: (_) => vm.setStatusFilter(s),
                      selectedColor: AppColors.primaryLight.withValues(alpha: 0.35),
                    ),
                  ),
                ],
                FilterChip(
                  label: Text(
                    vm.unbilledCount > 0
                        ? 'Unbilled (${vm.unbilledCount})'
                        : 'Unbilled',
                  ),
                  selected: vm.unbilledOnly,
                  onSelected: (v) => vm.setUnbilledOnly(v),
                  selectedColor: Colors.red.shade100,
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Company'),
                  selected: vm.companyVehiclesOnly,
                  onSelected: (v) => vm.setCompanyVehiclesOnly(v),
                  selectedColor: Colors.indigo.shade100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AiOrdersViewModel vm) {
    if (vm.isLoading && vm.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => vm.fetchList(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (vm.orders.isEmpty) {
      return const Center(
        child: Text(
          'No AI orders for today',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await vm.fetchList(silent: true);
        await vm.fetchUnbilledCount(silent: true);
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: vm.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = vm.orders[index];
          return _AiOrderRow(
            order: order,
            statusLabel: _statusLabel(order.status),
            statusColor: _statusColor(order.status),
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

class _AiOrderRow extends StatelessWidget {
  const _AiOrderRow({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.entranceLabel,
    required this.bayLabel,
    required this.onTap,
  });

  final AiOrderCashier order;
  final String statusLabel;
  final Color statusColor;
  final String entranceLabel;
  final String bayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alert = order.isUnbilledAlert;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: alert
                  ? Colors.red.shade300
                  : order.isCompanyVehicle
                      ? Colors.indigo.shade200
                      : Colors.grey.shade200,
              width: alert ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.displayPlate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (order.isCompanyVehicle) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Company',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ),
                        ],
                        if (alert) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Unbilled',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.captureNo}  ·  Entrance $entranceLabel  ·  Bay $bayLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: statusColor,
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
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

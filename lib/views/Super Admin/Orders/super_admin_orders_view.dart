import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'super_admin_orders_view_model.dart';

class SuperAdminOrdersView extends StatelessWidget {
  const SuperAdminOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SuperAdminOrdersContent();
  }
}

class _SuperAdminOrdersContent extends StatefulWidget {
  const _SuperAdminOrdersContent();

  @override
  State<_SuperAdminOrdersContent> createState() => _SuperAdminOrdersContentState();
}

class _SuperAdminOrdersContentState extends State<_SuperAdminOrdersContent> {
  late SuperAdminOrdersViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminOrdersViewModel();
    _vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<SuperAdminOrdersViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => vm.exportData(),
              backgroundColor: AppColors.primaryLight,
              elevation: 4,
              icon: const Icon(Icons.download_rounded, color: AppColors.secondaryLight, size: 24),
              label: const Text('Export CSV', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
            ),
            body: vm.isLoading && vm.filteredOrders.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabs(context, vm),
                        const SizedBox(height: 16),
                        _buildFilters(context, vm, isDesktop),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildOrdersTable(context, vm),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTabs(BuildContext context, SuperAdminOrdersViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabItem('All', vm),
          _buildTabItem('Completed', vm),
          _buildTabItem('Pending', vm),
          _buildTabItem('Cancelled', vm),
          _buildTabItem('Refunded', vm),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, SuperAdminOrdersViewModel vm) {
    final isSelected = vm.filterStatus.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            vm.setFilterStatus(label);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.primaryLight : Colors.grey.shade200),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryLight.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
            ),
            child: Text(
              label == 'All' ? 'All Orders' : label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, SuperAdminOrdersViewModel vm, bool isDesktop) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: vm.setSearchQuery,
              style: const TextStyle(fontSize: 14, color: AppColors.secondaryLight),
              decoration: const InputDecoration(
                hintText: 'Search by Order ID, Customer, or Branch...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(BuildContext context, SuperAdminOrdersViewModel vm) {
    return ListView.separated(
      key: ValueKey('${vm.filterStatus}_${vm.searchQuery}'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: vm.filteredOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = vm.filteredOrders[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight)),
                      const SizedBox(height: 2),
                      Text(order['date'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  _buildStatusBadge(order['status']),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CUSTOMER', style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(order['customer'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.secondaryLight)),
                      const SizedBox(height: 2),
                      Text(order['branch'], style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TOTAL AMOUNT', style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('SAR ${order['amount']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF10B981))),
                      const SizedBox(height: 8),
                      _buildPaymentBadge(order['payment']),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildOrderAction(Icons.receipt_long_rounded, 'Items'),
                  const SizedBox(width: 8),
                  _buildOrderAction(Icons.print_rounded, 'Print'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String type) {
    final isPaid = type == 'Cash' || type == 'Paid'; // Assuming green for success types
    final color = isPaid ? const Color(0xFF10B981) : AppColors.secondaryLight;
    IconData icon = Icons.payment_rounded;

    if (type == 'Credit Card') icon = Icons.credit_card_rounded;
    else if (type == 'Cash') icon = Icons.money_rounded;
    else if (type == 'Apple Pay') icon = Icons.apple_rounded;
    else if (type == 'Corporate') icon = Icons.business_center_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            type.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isCompleted = status == 'Completed' || status == 'Delivered';
    final color = isCompleted ? const Color(0xFF10B981) : AppColors.secondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}

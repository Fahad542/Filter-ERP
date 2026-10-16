import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'super_admin_finance_view_model.dart';

class SuperAdminFinanceView extends StatelessWidget {
  const SuperAdminFinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SuperAdminFinanceContent();
  }
}

class _SuperAdminFinanceContent extends StatefulWidget {
  const _SuperAdminFinanceContent();

  @override
  State<_SuperAdminFinanceContent> createState() => _SuperAdminFinanceContentState();
}

class _SuperAdminFinanceContentState extends State<_SuperAdminFinanceContent> {
  late SuperAdminFinanceViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminFinanceViewModel();
    _vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<SuperAdminFinanceViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: vm.isLoading && vm.filteredTransactions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFinancialCards(vm, isDesktop),
                        const SizedBox(height: 32),
                        const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
                        const SizedBox(height: 16),
                        _buildTabs(context, vm),
                        const SizedBox(height: 16),
                        _buildFilters(context, vm, isDesktop),
                        const SizedBox(height: 16),
                        _buildTransactionsTable(context, vm),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Finance & Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
        const SizedBox(height: 4),
        Text('Manage enterprise revenues, operational expenses, and profit margins.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildFinancialCards(SuperAdminFinanceViewModel vm, bool isDesktop) {
    final cards = [
      _buildFinCard('Total Revenue', vm.totalRevenue, Icons.account_balance_wallet_rounded),
      _buildFinCard('Total Expenses', vm.totalExpenses, Icons.receipt_long_rounded),
      _buildFinCard('Net Profit', vm.netProfit, Icons.trending_up_rounded),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList(),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: cards.map((c) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(width: 210, child: c),
          )).toList(),
        ),
      );
    }
  }

  Widget _buildFinCard(String title, double amount, IconData icon) {
    return Container(
      height: 130, // Even more compact
      padding: const EdgeInsets.all(16), // Tighter padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryLight, size: 20),
          ),
          const Spacer(),
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text('SAR ${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, SuperAdminFinanceViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabItem('All Types', vm),
          _buildTabItem('Revenue', vm),
          _buildTabItem('Expense', vm),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, SuperAdminFinanceViewModel vm) {
    final isSelected = vm.typeFilter.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            vm.setTypeFilter(label);
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
              label == 'All Types' ? 'All Transactions' : label,
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

  Widget _buildFilters(BuildContext context, SuperAdminFinanceViewModel vm, bool isDesktop) {
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
                hintText: 'Search by ID or description...',
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

  Widget _buildTransactionsTable(BuildContext context, SuperAdminFinanceViewModel vm) {
    return ListView.separated(
      key: ValueKey('${vm.typeFilter}_${vm.searchQuery}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.filteredTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trx = vm.filteredTransactions[index];
        final isRevenue = trx['amount'] > 0;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isRevenue ? const Color(0xFF10B981) : AppColors.secondaryLight).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isRevenue ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isRevenue ? const Color(0xFF10B981) : AppColors.secondaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trx['description'] ?? 'Transaction',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trx['date']} • ${trx['category'].toUpperCase()}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isRevenue ? '+' : ''}${trx['amount']} SAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isRevenue ? const Color(0xFF10B981) : AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTypeBadge(trx['type']),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeBadge(String type) {
    final isRevenue = type == 'Revenue' || type == 'Income';
    final color = isRevenue ? const Color(0xFF10B981) : AppColors.secondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }
}

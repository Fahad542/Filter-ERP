import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'super_admin_branches_view_model.dart';

class SuperAdminBranchesView extends StatelessWidget {
  const SuperAdminBranchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SuperAdminBranchesContent();
  }
}

class _SuperAdminBranchesContent extends StatefulWidget {
  const _SuperAdminBranchesContent();

  @override
  State<_SuperAdminBranchesContent> createState() => _SuperAdminBranchesContentState();
}

class _SuperAdminBranchesContentState extends State<_SuperAdminBranchesContent> {
  late SuperAdminBranchesViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminBranchesViewModel();
    _vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<SuperAdminBranchesViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddBranchDialog(context),
              backgroundColor: AppColors.primaryLight,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: AppColors.secondaryLight, size: 24),
              label: const Text('Add Branch', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
            ),
            body: vm.isLoading && vm.filteredBranches.isEmpty
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
                          child: _buildBranchesTable(context, vm),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }



  Widget _buildTabs(BuildContext context, SuperAdminBranchesViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabItem('All', vm),
          _buildTabItem('Active', vm),
          _buildTabItem('Maintenance', vm),
          _buildTabItem('Closed', vm),
        ],
      ),
    );
  }

  Color _getStatusDotColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981); // Green
      case 'Maintenance':
        return Colors.orange;
      case 'Closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDecoratedAction({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildTabItem(String label, SuperAdminBranchesViewModel vm) {
    final isSelected = vm.statusFilter.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            vm.setStatusFilter(label);
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
              label,
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

  Widget _buildFilters(BuildContext context, SuperAdminBranchesViewModel vm, bool isDesktop) {
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
                hintText: 'Search branches...',
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

  Widget _buildBranchesTable(BuildContext context, SuperAdminBranchesViewModel vm) {
    return ListView.separated(
      key: ValueKey('${vm.statusFilter}_${vm.searchQuery}'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: vm.filteredBranches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final branch = vm.filteredBranches[index];
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
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.store_rounded, color: AppColors.primaryLight, size: 28),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusDotColor(branch.status),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight)),
                            const Spacer(),
                            _buildDecoratedAction(
                              icon: Icons.edit_rounded,
                              onTap: () => _showAddBranchDialog(context),
                            ),
                            const SizedBox(width: 8),
                            _buildDecoratedAction(
                              icon: Icons.delete_rounded,
                              onTap: () => vm.deleteBranch(branch.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(branch.address.isNotEmpty ? branch.address : 'No address provided', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Removed status badge as per request
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BRANCH MANAGER', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(branch.contactPerson?.isNotEmpty == true ? branch.contactPerson! : 'N/A', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondaryLight)),
                      const SizedBox(height: 2),
                      Text('0 employees', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('TOTAL REVENUE', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('SAR 0', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _getStatusDotColor(branch.status))),
                      const SizedBox(height: 4),
                      Text('ID: ${branch.id}', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }



  void _showAddBranchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.store_rounded, color: AppColors.primaryLight),
                  SizedBox(width: 12),
                  Text('Add New Branch', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Branch Name',
                  labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Location / Address',
                  labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Manager Name',
                  labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Branch', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

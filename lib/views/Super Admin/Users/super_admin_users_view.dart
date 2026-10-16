import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';

import 'super_admin_users_view_model.dart';

class SuperAdminUsersView extends StatelessWidget {
  const SuperAdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SuperAdminUsersContent();
  }
}

class _SuperAdminUsersContent extends StatefulWidget {
  const _SuperAdminUsersContent();

  @override
  State<_SuperAdminUsersContent> createState() => _SuperAdminUsersContentState();
}

class _SuperAdminUsersContentState extends State<_SuperAdminUsersContent> {
  late SuperAdminUsersViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminUsersViewModel();
    _vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<SuperAdminUsersViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddUserDialog(context),
              backgroundColor: AppColors.primaryLight,
              elevation: 4,
              icon: const Icon(Icons.person_add_rounded, color: AppColors.secondaryLight, size: 24),
              label: const Text('Add User', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
            ),
            body: vm.isLoading && vm.filteredUsers.isEmpty
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
                          child: _buildUsersTable(context, vm),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTabs(BuildContext context, SuperAdminUsersViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabItem('All', vm),
          _buildTabItem('Manager', vm),
          _buildTabItem('Technician', vm),
          _buildTabItem('Cashier', vm),
          _buildTabItem('Support', vm),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, SuperAdminUsersViewModel vm) {
    final isSelected = vm.roleFilter.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            vm.setRoleFilter(label);
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
              label == 'All' ? 'All Roles' : label,
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

  Widget _buildFilters(BuildContext context, SuperAdminUsersViewModel vm, bool isDesktop) {
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
                hintText: 'Search by name or email...',
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

  Widget _buildUsersTable(BuildContext context, SuperAdminUsersViewModel vm) {
    return ListView.separated(
      key: ValueKey('${vm.roleFilter}_${vm.searchQuery}'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: vm.filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = vm.filteredUsers[index];
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
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w900, fontSize: 20),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: user.isActive ? const Color(0xFF10B981) : Colors.grey,
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
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight)),
                            const Spacer(),
                            _buildUserAction(Icons.edit_rounded, () => _showAddUserDialog(context)),
                            const SizedBox(width: 8),
                            _buildUserAction(Icons.delete_rounded, () => vm.deleteUser(user.id)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ROLE & BRANCH', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleBadge(user.userType),
                          const SizedBox(width: 8),
                          Text(user.branchId ?? 'All', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.secondaryLight)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('JOINED DATE', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(user.createdAt.split('T').first, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.secondaryLight)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserAction(IconData icon, VoidCallback onTap) {
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

  Widget _buildRoleBadge(String role) {
    const color = AppColors.secondaryLight;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AppColors.primaryLight),
                  SizedBox(width: 12),
                  Text('Add New User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.secondaryLight)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
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
                  labelText: 'Email Address',
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
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: ['Manager', 'Technician', 'Cashier', 'Support'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) {},
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Branch Assignment',
                  labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FD),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: ['Riyadh Main', 'Jeddah Central', 'Dammam East', 'HQ'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) {},
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
                    child: const Text('Save User', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
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

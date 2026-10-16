import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import 'super_admin_departments_view_model.dart';

class SuperAdminDepartmentsView extends StatelessWidget {
  const SuperAdminDepartmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return _SuperAdminDepartmentsContent();
  }
}

class _SuperAdminDepartmentsContent extends StatefulWidget {
  const _SuperAdminDepartmentsContent();

  @override
  State<_SuperAdminDepartmentsContent> createState() => _SuperAdminDepartmentsContentState();
}

class _SuperAdminDepartmentsContentState extends State<_SuperAdminDepartmentsContent> {
  late SuperAdminDepartmentsViewModel _vm;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminDepartmentsViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<SuperAdminDepartmentsViewModel>(
        builder: (context, vm, child) {
          final filteredDepartments = vm.departments.where((dept) {
            return dept.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                   dept.workshopName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                // Future expansion: Create Department
              },
              backgroundColor: AppColors.primaryLight,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: AppColors.secondaryLight, size: 24),
              label: const Text('Add Department', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
            ),
            body: vm.isLoading && vm.departments.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: vm.departments.isEmpty && !vm.isLoading
                              ? const Center(
                                  child: Text('No departments found.',
                                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 100),
                                  itemCount: filteredDepartments.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final department = filteredDepartments[index];
                                    return _buildDepartmentCard(department);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 14, color: AppColors.secondaryLight),
              decoration: const InputDecoration(
                hintText: 'Search departments...',
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

  Widget _buildDepartmentCard(dynamic department) {
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
                      child: Icon(Icons.business_rounded, color: AppColors.primaryLight, size: 28),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: department.isActive ? const Color(0xFF10B981) : Colors.red,
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
                        Expanded(
                          child: Text(
                            department.name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondaryLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildDecoratedAction(
                          icon: Icons.edit_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.store_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            department.workshopName,
                            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Dept ID', '#${department.id}', Icons.tag_rounded),
              Container(width: 1, height: 24, color: Colors.grey.shade200),
              _buildStatItem('Status', department.isActive ? 'Active' : 'Inactive', Icons.toggle_on_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.secondaryLight)),
          ],
        ),
      ],
    );
  }
}

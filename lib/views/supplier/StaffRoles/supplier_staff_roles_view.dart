import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/widgets.dart';
import 'supplier_staff_roles_view_model.dart';

class SupplierStaffRolesView extends StatelessWidget {
  final VoidCallback? onBack;

  const SupplierStaffRolesView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChangeNotifierProvider(
      create: (_) => SupplierStaffRolesViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Consumer<SupplierStaffRolesViewModel>(
          builder: (context, vm, _) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: PosScreenAppBar(
                title: 'Staff & Roles',
                showHamburger: true,
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
                showBackButton: false,
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoleCards(context, vm, isTablet),
                    const SizedBox(height: 24),
                    _buildEmployeeList(context, vm, isTablet),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _showAddEmployeeDialog(context, vm),
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Employee/ Role'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleCards(
    BuildContext context,
    SupplierStaffRolesViewModel vm,
    bool isTablet,
  ) {
    final roleCounts = vm.roleCounts;
    final summaries = SupplierStaffRolesViewModel.roleSummaries;
    final firstFour = summaries.take(4).toList();
    final supervisor = summaries.length > 4 ? summaries[4] : null;
    const spacing = 8.0;
    const crossAxisCount = 2;
    final aspectRatio = isTablet ? 2.0 : 1.85;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / crossAxisCount;
        final tileHeight = tileWidth / aspectRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
              children: [
                for (final role in firstFour)
                  _RoleCard(
                    label: role.label,
                    count: roleCounts[role.label] ?? 0,
                    icon: role.icon,
                    cardColor: Colors.black,
                    textColor: Colors.white,
                    isTablet: isTablet,
                  ),
              ],
            ),
            const SizedBox(height: spacing),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (supervisor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: spacing),
                      child: SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _RoleCard(
                          label: supervisor.label,
                          count: roleCounts[supervisor.label] ?? 0,
                          icon: supervisor.icon,
                          cardColor: Colors.black,
                          textColor: Colors.white,
                          isTablet: isTablet,
                        ),
                      ),
                    ),
                  for (final label in vm.customRoles)
                    Padding(
                      padding: const EdgeInsets.only(right: spacing),
                      child: SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _RoleCard(
                          label: label,
                          count: roleCounts[label] ?? 0,
                          icon: Icons.badge_outlined,
                          cardColor: Colors.black,
                          textColor: Colors.white,
                          isTablet: isTablet,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: spacing),
            SizedBox(
              width: tileWidth,
              height: tileHeight,
              child: Material(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _showAddRoleDialog(context, vm),
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 28,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Role',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddRoleDialog(
    BuildContext context,
    SupplierStaffRolesViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AddRoleDialog(
        onSave: (roleName) {
          vm.addCustomRole(roleName);
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Role added')));
        },
      ),
    );
  }

  void _showAddEmployeeDialog(
    BuildContext context,
    SupplierStaffRolesViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AddEmployeeDialog(
        roleLabels: vm.allRoleLabels,
        onSave: (name, role, phone) {
          vm.addEmployee(
            StaffRoleItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              role: role,
              mobile: phone,
              vehiclePlate: '',
              availability: 'Available',
              status: 'Active',
            ),
          );
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Widget _buildEmployeeList(
    BuildContext context,
    SupplierStaffRolesViewModel vm,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: vm.employees.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 24,
                ),
                child: Center(
                  child: Text(
                    'No employees added yet',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: vm.employees
                      .map((e) => _EmployeeCard(employee: e))
                      .toList(),
                ),
              ),
      ),
    );
  }
}

class _AddEmployeeDialog extends StatefulWidget {
  final List<String> roleLabels;
  final void Function(String name, String role, String phone) onSave;

  const _AddEmployeeDialog({required this.roleLabels, required this.onSave});

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = SupplierStaffRolesViewModel.roleSummaries.first.label;

  @override
  void initState() {
    super.initState();
    if (widget.roleLabels.isNotEmpty &&
        !widget.roleLabels.contains(_selectedRole)) {
      _selectedRole = widget.roleLabels.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = widget.roleLabels.isEmpty
        ? SupplierStaffRolesViewModel.roleSummaries.map((r) => r.label).toList()
        : widget.roleLabels;
    return AlertDialog(
      title: const Text('Add Employee'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: 'Name',
              controller: _nameController,
              showBorder: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              showBorder: true,
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final phone = _phoneController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter name')),
                      );
                      return;
                    }
                    widget.onSave(name, _selectedRole, phone);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Employee added')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddRoleDialog extends StatefulWidget {
  final void Function(String roleName) onSave;

  const _AddRoleDialog({required this.onSave});

  @override
  State<_AddRoleDialog> createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends State<_AddRoleDialog> {
  final _roleNameController = TextEditingController();

  @override
  void dispose() {
    _roleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Role'),
      content: CustomTextField(
        label: 'Role name',
        controller: _roleNameController,
        showBorder: true,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final name = _roleNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter role name')),
                      );
                      return;
                    }
                    widget.onSave(name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color cardColor;
  final Color textColor;
  final bool isTablet;

  const _RoleCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.cardColor,
    required this.textColor,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 28 : 24, color: textColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: isTablet ? 13 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w800,
              fontSize: isTablet ? 26 : 22,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final StaffRoleItem employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.name,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                e.role,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.phone_android_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                e.mobile,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.secondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

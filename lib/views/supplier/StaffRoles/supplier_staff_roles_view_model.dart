import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class StaffRoleItem {
  final String id;
  final String name;
  final String role;
  final String mobile;
  final String vehiclePlate;
  final String availability;
  final String status;

  StaffRoleItem({
    required this.id,
    required this.name,
    required this.role,
    required this.mobile,
    required this.vehiclePlate,
    required this.availability,
    required this.status,
  });
}

class RoleSummary {
  final String label;
  final int count;
  final IconData icon;
  final Color cardColor;
  final Color textColor;

  const RoleSummary({
    required this.label,
    required this.count,
    required this.icon,
    required this.cardColor,
    required this.textColor,
  });
}

class SupplierStaffRolesViewModel extends ChangeNotifier {
  List<StaffRoleItem> _employees = [];
  List<String> _customRoles = [];

  List<StaffRoleItem> get employees => _employees;
  List<String> get customRoles => List.unmodifiable(_customRoles);

  List<String> get allRoleLabels => [
    ...SupplierStaffRolesViewModel.roleSummaries.map((r) => r.label),
    ..._customRoles,
  ];

  static List<RoleSummary> get roleSummaries => [
    RoleSummary(
      label: 'Warehouse Incharge',
      count: 0,
      icon: Icons.people_outline,
      cardColor: AppColors.primaryLight.withOpacity(0.25),
      textColor: AppColors.secondaryLight,
    ),
    RoleSummary(
      label: 'Order Processor',
      count: 0,
      icon: Icons.inventory_2_outlined,
      cardColor: AppColors.primaryLight.withOpacity(0.2),
      textColor: AppColors.secondaryLight,
    ),
    RoleSummary(
      label: 'Driver',
      count: 0,
      icon: Icons.local_shipping_outlined,
      cardColor: AppColors.primaryLight.withOpacity(0.3),
      textColor: AppColors.secondaryLight,
    ),
    RoleSummary(
      label: 'Accountant',
      count: 0,
      icon: Icons.account_balance_wallet_outlined,
      cardColor: AppColors.primaryLight.withOpacity(0.22),
      textColor: AppColors.secondaryLight,
    ),
    RoleSummary(
      label: 'Supervisor',
      count: 0,
      icon: Icons.supervisor_account_outlined,
      cardColor: AppColors.backgroundLight,
      textColor: AppColors.secondaryLight,
    ),
  ];

  int get totalEmployees => _employees.length;

  void addEmployee(StaffRoleItem item) {
    _employees.add(item);
    notifyListeners();
  }

  void removeEmployee(String id) {
    _employees.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Map<String, int> get roleCounts {
    final counts = <String, int>{};
    for (final label in allRoleLabels) {
      counts[label] = _employees.where((e) => e.role == label).length;
    }
    return counts;
  }

  void addCustomRole(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _customRoles.add(trimmed);
    notifyListeners();
  }
}

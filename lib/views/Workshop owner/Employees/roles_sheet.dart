import 'package:flutter/material.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/owner_perm_l10n.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../widgets/owner_shimmer.dart';
import '../widgets/owner_sheet_actions.dart';
import '../widgets/owner_styled_dropdown.dart';
import 'employee_management_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// roles_sheet.dart
//
// Contains everything related to "Roles & Permissions":
//   • RolesPermissionsSheet  — list sheet (shows role cards + Create Role btn)
//   • CreateRoleSheet  — full permission-builder sheet
//   • Supporting private widgets, data, helpers
//
// WorkshopRole model lives in workshop_owner_models.dart
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point  ─  Roles tab body (also usable inside a sheet)
// ─────────────────────────────────────────────────────────────────────────────

class RolesTabContent extends StatelessWidget {
  const RolesTabContent({super.key});

  void _editRole(BuildContext context, EmployeeManagementViewModel vm, WorkshopRole role) {
    showModalBottomSheet<WorkshopRole?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: CreateRoleSheet(existingRole: role),
      ),
    ).then((updated) {
      if (updated != null) {
        vm.updateRole(context, role.id, updated);
      }
    });
  }

  void _deleteRole(BuildContext context, EmployeeManagementViewModel vm, WorkshopRole role) {
    showDialog<bool>(
      context: context,
      builder: (_) => _DeleteRoleDialog(roleName: role.name),
    ).then((confirmed) {
      if (confirmed == true) {
        vm.deleteRole(context, role.id);
      }
    });
  }

  /// Opens the create-role sheet (used by the Roles-tab FAB).
  static void openCreateRole(BuildContext context, EmployeeManagementViewModel vm) {
    showModalBottomSheet<WorkshopRole?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const CreateRoleSheet(existingRole: null),
      ),
    ).then((role) {
      if (role != null) {
        vm.createRole(context, role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeManagementViewModel>(
      builder: (context, vm, _) {
        final roles = vm.roles;
        final isLoading = vm.isRolesLoading;

        if (isLoading) {
          return const OwnerFormPageShimmer(fieldCount: 5);
        }

        return RefreshIndicator(
          color: AppColors.primaryLight,
          onRefresh: () => vm.fetchRoles(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (roles.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondaryLight.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.ownerRolesEmpty,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  AppLocalizations.of(context)!.ownerRolesWorkshopRoles,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                ...roles.map(
                  (role) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RoleCard(
                      role: role,
                      onEdit: () => _editRole(context, vm, role),
                      onDelete: () => _deleteRole(context, vm, role),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Legacy bottom sheet wrapper — prefer [RolesTabContent] + tabs.
class RolesPermissionsSheet extends StatelessWidget {
  const RolesPermissionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _SheetHeader(
              title: AppLocalizations.of(context)!.ownerRolesAndPermissions,
              onClose: () => Navigator.pop(ctx),
            ),
            const Expanded(child: RolesTabContent()),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card  —  matches the web panel screenshot exactly
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final WorkshopRole role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoleCard({
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  // Derive a short portal badge label from the portal string
  String _portalBadge(AppLocalizations l10n) {
    final p = role.portal.toLowerCase();
    if (p.contains('cashier')) return l10n.ownerRolesPortalCashier;
    if (p.contains('technician')) return l10n.ownerRolesPortalTechnician;
    return l10n.ownerRolesPortalWorkshop;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = _portalBadge(l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: name + portal badge ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ownerLocalizeRoleName(l10n, role.name),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F9EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22863A),
                  ),
                ),
              ),
            ],
          ),

          // ── Description ─────────────────────────────────────────────
          if (role.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              role.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 5),

          // ── Meta row ────────────────────────────────────────────────
          Text(
            l10n.ownerRolesPermissionsCount(
              ownerLocalizeDigits(context, '${role.permissionCount}'),
            ),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // ── Action buttons ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: l10n.ownerCommonEdit,
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF4A90D9),
                  bg: const Color(0xFFEBF4FF),
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  label: l10n.ownerCommonDelete,
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade500,
                  bg: Colors.red.shade50,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete role confirmation dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteRoleDialog extends StatelessWidget {
  final String roleName;
  const _DeleteRoleDialog({required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade400, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.ownerRolesDeleteTitle,
              style: AppTextStyles.h2
                  .copyWith(fontSize: 17, color: AppColors.secondaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.ownerRolesDeleteConfirm(roleName),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(AppLocalizations.of(context)!.ownerCommonCancel,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryLight)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(AppLocalizations.of(context)!.ownerCommonDelete,
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit Role sheet
// ─────────────────────────────────────────────────────────────────────────────

// ── Permission data models ────────────────────────────────────────────────────

class _PermNode {
  final String key;
  final String label;
  final bool isChild;
  final List<String> actions;

  const _PermNode({
    required this.key,
    required this.label,
    this.isChild = false,
    required this.actions,
  });
}

class _PermSection {
  final String title;
  final List<_PermNode> nodes;
  bool expanded;

  _PermSection({
    required this.title,
    required this.nodes,
    this.expanded = true,
  });

  int get total => nodes.fold(0, (s, n) => s + n.actions.length);
}

// ── Static permission tree ────────────────────────────────────────────────────

List<_PermSection> _buildPermSections() => [
  _PermSection(title: 'CONTROL', nodes: [
    _PermNode(key: 'dashboard', label: 'Dashboard', actions: ['view']),
    _PermNode(
        key: 'approvals_page',
        label: 'Approvals Queue (Page Access)',
        actions: ['view', 'approve', 'reject']),
    _PermNode(
        key: 'topup',
        label: 'Top-up requests',
        isChild: true,
        actions: ['view', 'approve', 'reject']),
    _PermNode(
        key: 'expense_req',
        label: 'Expense requests',
        isChild: true,
        actions: ['view', 'approve', 'reject']),
    _PermNode(
        key: 'supplier_inv',
        label: 'Supplier invoices',
        isChild: true,
        actions: ['view', 'approve', 'reject']),
    _PermNode(
        key: 'sales_ret_q',
        label: 'Sales returns',
        isChild: true,
        actions: ['view', 'approve', 'reject']),
    _PermNode(
        key: 'sales_returns',
        label: 'Sales Returns',
        actions: ['view']),
    _PermNode(
        key: 'employees',
        label: 'Employees',
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'branches_page',
        label: 'Branches & Access (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'branch_portals',
        label: 'Branch Portals',
        isChild: true,
        actions: ['view']),
    _PermNode(
        key: 'access_perms',
        label: 'Access Permissions',
        isChild: true,
        actions: ['view', 'edit']),
    _PermNode(
        key: 'roles_perms',
        label: 'Roles & Permissions',
        actions: ['view', 'create', 'edit', 'delete']),
  ]),
  _PermSection(title: 'INVENTORY & CATALOG', nodes: [
    _PermNode(
        key: 'inv_page',
        label: 'View Inventory & Departments (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'dept_tab',
        label: 'Departments tab',
        isChild: true,
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'products_tab',
        label: 'Products tab',
        isChild: true,
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'services_tab',
        label: 'Services tab',
        isChild: true,
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'cats_tab',
        label: 'Categories tab',
        isChild: true,
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'catalog_page',
        label: 'Master Catalog (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'cat_depts',
        label: 'Departments',
        isChild: true,
        actions: ['view', 'add']),
    _PermNode(
        key: 'cat_cats',
        label: 'Categories',
        isChild: true,
        actions: ['view', 'add']),
    _PermNode(
        key: 'cat_products',
        label: 'Products',
        isChild: true,
        actions: ['view', 'add']),
    _PermNode(
        key: 'cat_services',
        label: 'Services',
        isChild: true,
        actions: ['view', 'add']),
    _PermNode(
        key: 'manage_inv',
        label: 'Manage Inventory',
        actions: ['view', 'create', 'edit', 'delete']),
  ]),
  _PermSection(title: 'OPERATIONS', nodes: [
    _PermNode(
        key: 'pi_page',
        label: 'Purchase Invoices (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'invoices',
        label: 'Invoices',
        isChild: true,
        actions: ['view', 'create', 'edit']),
    _PermNode(
        key: 'price_rpt',
        label: 'Price Report',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'sp_page',
        label: 'Suppliers & Purchases (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'suppliers',
        label: 'Suppliers list',
        isChild: true,
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'purch_hist',
        label: 'Purchase history',
        isChild: true,
        actions: ['view']),
    _PermNode(
        key: 'filter_sup',
        label: 'Filter Affiliated Suppliers',
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'non_aff',
        label: 'Non-Affiliated Suppliers',
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'reports_page',
        label: 'Reports & Analytics (Page Access)',
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_orders',
        label: 'Orders',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_daily',
        label: 'Daily Sales',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_tech',
        label: 'By Technician',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_cust',
        label: 'By Customer',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_prod',
        label: 'By Product',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_dept',
        label: 'By Department',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_branch',
        label: 'By Branch',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'rpt_cashier',
        label: 'By Cashier',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'pos_mon',
        label: 'POS Monitoring',
        actions: ['view']),
    _PermNode(
        key: 'locker_mgmt',
        label: 'Locker Management',
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'petty_cash',
        label: 'My Petty Cash',
        actions: ['view', 'issue']),
  ]),
  _PermSection(title: 'MARKETING & CORPORATE', nodes: [
    _PermNode(
        key: 'promo',
        label: 'Promo Codes',
        actions: ['view', 'create', 'edit', 'delete']),
    _PermNode(
        key: 'corp_mgmt',
        label: 'Corporate Management',
        actions: ['view', 'create', 'edit', 'delete', 'approve']),
    _PermNode(
        key: 'comm_page',
        label: 'Commissions (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'comm_ledger',
        label: 'Ledger',
        isChild: true,
        actions: ['view']),
    _PermNode(
        key: 'comm_rules',
        label: 'Rules',
        isChild: true,
        actions: ['view', 'create', 'edit', 'delete']),
  ]),
  _PermSection(title: 'ACCOUNTING', nodes: [
    _PermNode(
        key: 'coa_page',
        label: 'Chart of Accounts (Page Access)',
        actions: ['view']),
    _PermNode(
        key: 'coa',
        label: 'Chart of Accounts',
        isChild: true,
        actions: ['view', 'create', 'edit']),
    _PermNode(
        key: 'trial_bal',
        label: 'Trial Balance',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'pnl', label: 'P&L', isChild: true, actions: ['view', 'export']),
    _PermNode(
        key: 'bal_sheet',
        label: 'Balance Sheet',
        isChild: true,
        actions: ['view', 'export']),
    _PermNode(
        key: 'cash_bank',
        label: 'Cash & Bank',
        actions: ['view', 'create', 'edit']),
    _PermNode(
        key: 'transactions',
        label: 'Transactions',
        actions: ['view']),
    _PermNode(
        key: 'journal',
        label: 'Journal Entries',
        actions: ['view', 'create']),
    _PermNode(
        key: 'purchases',
        label: 'Purchases',
        actions: ['view', 'create', 'edit', 'approve']),
    _PermNode(
        key: 'expenses',
        label: 'Expenses',
        actions: ['view', 'create', 'edit', 'approve']),
    _PermNode(
        key: 'receipts',
        label: 'Receipts',
        actions: ['view', 'create']),
    _PermNode(
        key: 'payments',
        label: 'Payments',
        actions: ['view', 'create', 'approve']),
    _PermNode(
        key: 'advances',
        label: 'Advances',
        actions: ['view', 'create', 'approve']),
    _PermNode(
        key: 'payroll',
        label: 'Payroll Run',
        actions: ['view', 'create', 'approve', 'export']),
    _PermNode(
        key: 'approval_lim',
        label: 'Approval Limits',
        actions: ['view', 'edit']),
    _PermNode(
        key: 'ledger', label: 'Ledger', actions: ['view', 'export']),
  ]),
];

const _kRoleNames = [
  'Cashier',
  'Technician',
  'Supervisor',
  'Manager',
  'Team Leader',
  'Locker Supervisor',
  'Locker Collector',
  'Custom name…',
];

const _kPortals = [
  'Workshop Admin Portal',
  'Cashier (POS) Portal',
  'Technician Portal',
];

// ── CreateRoleSheet ───────────────────────────────────────────────────────────

class CreateRoleSheet extends StatefulWidget {
  /// Pass an existing role to edit it; null to create a new one.
  final WorkshopRole? existingRole;

  const CreateRoleSheet({super.key, required this.existingRole});

  @override
  State<CreateRoleSheet> createState() => _CreateRoleSheetState();
}

class _CreateRoleSheetState extends State<CreateRoleSheet> {
  final _customNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedRoleName;
  String _selectedPortal = _kPortals.first;
  String _branchAccess = 'All Branches (no restriction)';
  final Set<String> _selectedBranches = {};
  final Map<String, bool> _perms = {};
  late final List<_PermSection> _sections;
  bool _isLoading = false;

  bool get _isEditing => widget.existingRole != null;

  @override
  void initState() {
    super.initState();
    _sections = _buildPermSections();

    // Pre-fill when editing
    final r = widget.existingRole;
    if (r != null) {
      _selectedRoleName = _kRoleNames.contains(r.name) ? r.name : 'Custom name…';
      if (_selectedRoleName == 'Custom name…') _customNameCtrl.text = r.name;
      _descCtrl.text = r.description;
      _selectedPortal = _kPortals.contains(r.portal) ? r.portal : _kPortals.first;
      // Convert flat "section.node.action" permission strings into the
      // internal "node:action" checkbox map used by the permission tree.
      for (final p in r.permissions) {
        final parts = p.split('.');
        if (parts.length >= 2) {
          final action = parts.last;
          final nodeKey = parts.sublist(0, parts.length - 1).join('.');
          _perms[_permKey(nodeKey, action)] = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Permission helpers ──────────────────────────────────────────────────────

  String _permKey(String nodeKey, String action) => '$nodeKey:$action';

  bool _isNodeChecked(_PermNode node) =>
      node.actions.every((a) => _perms[_permKey(node.key, a)] == true);

  bool _isNodePartial(_PermNode node) {
    final any = node.actions.any((a) => _perms[_permKey(node.key, a)] == true);
    return any && !_isNodeChecked(node);
  }

  void _toggleNode(_PermNode node, bool on) {
    setState(() {
      for (final a in node.actions) {
        _perms[_permKey(node.key, a)] = on;
      }
    });
  }

  void _toggleAction(String nodeKey, String action, bool on) {
    setState(() => _perms[_permKey(nodeKey, action)] = on);
  }

  bool _isSectionChecked(_PermSection sec) =>
      sec.nodes.every((n) => _isNodeChecked(n));

  bool _isSectionPartial(_PermSection sec) {
    final any = sec.nodes.any((n) => _isNodeChecked(n) || _isNodePartial(n));
    return any && !_isSectionChecked(sec);
  }

  void _toggleSection(_PermSection sec, bool on) {
    setState(() {
      for (final n in sec.nodes) {
        for (final a in n.actions) {
          _perms[_permKey(n.key, a)] = on;
        }
      }
    });
  }

  int get _totalSelected => _perms.values.where((v) => v).length;
  int get _totalPossible =>
      _sections.fold(0, (s, sec) => s + sec.total);

  void _selectAll(bool on) {
    setState(() {
      for (final sec in _sections) {
        for (final n in sec.nodes) {
          for (final a in n.actions) {
            _perms[_permKey(n.key, a)] = on;
          }
        }
      }
    });
  }

  int _sectionSelected(_PermSection sec) => sec.nodes
      .expand((n) => n.actions.map((a) => _perms[_permKey(n.key, a)] == true))
      .where((v) => v)
      .length;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: OwnerUi.sheetInitialSize,
      minChildSize: 0.6,
      maxChildSize: OwnerUi.sheetMaxSize,
      expand: false,
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _SheetHeader(
              title: _isEditing
                  ? AppLocalizations.of(context)!.ownerRolesEditTitle
                  : AppLocalizations.of(context)!.ownerRolesCreateTitle,
              onClose: () => Navigator.pop(ctx),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottomPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRoleNameField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPortalField()),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_selectedRoleName == 'Custom name…') ...[
                      TextField(
                        controller: _customNameCtrl,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLight),
                        decoration: _inputDeco(
                            AppLocalizations.of(context)!.ownerRolesTypeCustomName),
                      ),
                      const SizedBox(height: 10),
                    ],

                    _FieldLabel(AppLocalizations.of(context)!.ownerRolesFieldDescription),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descCtrl,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLight),
                      decoration: _inputDeco(''),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 14),

                    _buildBranchAccess(),
                    const SizedBox(height: 18),

                    _buildPermHeader(),
                    const SizedBox(height: 10),

                    ..._sections.map((sec) => _buildSection(sec)),
                    const SizedBox(height: 28),

                    OwnerSheetActions(
                      onCancel: () => Navigator.pop(ctx),
                      onPrimary: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      primaryLabel:
                          _isEditing
                              ? AppLocalizations.of(context)!.ownerRolesSaveChanges
                              : AppLocalizations.of(context)!.ownerEmployeesCreateRole,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Role name dropdown ──────────────────────────────────────────────────────

  Widget _buildRoleNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(AppLocalizations.of(context)!.ownerRolesFieldRoleName, required: true),
        const SizedBox(height: 6),
        OwnerStyledDropdown<String>(
          value: _selectedRoleName,
          hint: AppLocalizations.of(context)!.ownerRolesPickRoleName,
          height: 48,
          localizeLabels: false,
          displayLabel: _selectedRoleName == null
              ? null
              : (_selectedRoleName == 'Custom name…'
                  ? AppLocalizations.of(context)!.ownerRolesCustomName
                  : ownerLocalizeRoleName(
                      AppLocalizations.of(context)!, _selectedRoleName!)),
          options: _kRoleNames
              .map((r) => OwnerDropdownOption(
                    value: r,
                    label: r == 'Custom name…'
                        ? AppLocalizations.of(context)!.ownerRolesCustomName
                        : ownerLocalizeRoleName(AppLocalizations.of(context)!, r),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedRoleName = v),
          triggerStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }

  // ── Portal dropdown ─────────────────────────────────────────────────────────

  Widget _buildPortalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(AppLocalizations.of(context)!.ownerRolesFieldPortal),
        const SizedBox(height: 6),
        OwnerStyledDropdown<String>(
          value: _selectedPortal,
          hint: AppLocalizations.of(context)!.ownerRolesSelectPortal,
          height: 48,
          options: _kPortals
              .map((p) => OwnerDropdownOption(value: p, label: p))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedPortal = v);
          },
          triggerStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryLight,
          ),
        ),
      ],
    );
  }

  // ── Branch access block ─────────────────────────────────────────────────────

  Widget _buildBranchAccess() {
    final l10n = AppLocalizations.of(context)!;
    final isSpecific = _branchAccess == 'Specific Branches...';
    final allBranchesLabel = l10n.ownerRolesAllBranchesNoRestriction;
    final specificBranchesLabel = l10n.ownerRolesSpecificBranches;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(l10n.ownerRolesFieldBranchAccess),
          const SizedBox(height: 8),
          OwnerStyledDropdown<String>(
            value: _branchAccess,
            hint: l10n.ownerRolesSelectBranchAccess,
            height: 48,
            backgroundColor: isSpecific ? Colors.white : Colors.grey.shade50,
            borderColor: isSpecific
                ? const Color(0xFF4A90D9)
                : Colors.grey.shade200,
            localizeLabels: false,
            displayLabel:
                isSpecific ? specificBranchesLabel : allBranchesLabel,
            options: [
              OwnerDropdownOption(
                value: 'All Branches (no restriction)',
                label: allBranchesLabel,
              ),
              OwnerDropdownOption(
                value: 'Specific Branches...',
                label: specificBranchesLabel,
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _branchAccess = v);
            },
            triggerStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight,
            ),
          ),
          if (isSpecific) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Main Branch', 'Branch 2', 'Branch 3'].map((b) {
                final selected = _selectedBranches.contains(b);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedBranches.remove(b);
                    } else {
                      _selectedBranches.add(b);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.secondaryLight
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Permission header ───────────────────────────────────────────────────────

  Widget _buildPermHeader() {
    final allChecked = _totalSelected == _totalPossible;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.secondaryLight.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: allChecked,
              activeColor: AppColors.primaryLight,
              checkColor: AppColors.secondaryLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => _selectAll(v == true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.ownerRolesPermissionsTitle,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight),
            ),
          ),
          Text(
            AppLocalizations.of(context)!.ownerRolesSelectedCount(
              ownerLocalizeDigits(context, '$_totalSelected'),
              ownerLocalizeDigits(context, '$_totalPossible'),
            ),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Section block ───────────────────────────────────────────────────────────

  Widget _buildSection(_PermSection sec) {
    final selected = _sectionSelected(sec);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => sec.expanded = !sec.expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _isSectionChecked(sec)
                          ? true
                          : _isSectionPartial(sec)
                          ? null
                          : false,
                      tristate: true,
                      activeColor: AppColors.primaryLight,
                      checkColor: AppColors.secondaryLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => _toggleSection(
                          sec, !(v == true && _isSectionChecked(sec))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ownerLocalizePermLabel(
                          AppLocalizations.of(context)!, sec.title),
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryLight,
                          letterSpacing: 0.3),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.ownerRolesSectionCount(
                      ownerLocalizeDigits(context, '$selected'),
                      ownerLocalizeDigits(context, '${sec.total}'),
                    ),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    sec.expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (sec.expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            ...sec.nodes.asMap().entries.map((e) {
              final idx = e.key;
              final node = e.value;
              return Column(
                children: [
                  _buildPermRow(node),
                  if (idx < sec.nodes.length - 1)
                    Divider(height: 1, color: Colors.grey.shade100),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Single permission row ───────────────────────────────────────────────────

  Widget _buildPermRow(_PermNode node) {
    final checked = _isNodeChecked(node);
    final partial = _isNodePartial(node);

    return Padding(
      padding: EdgeInsets.fromLTRB(node.isChild ? 14 : 4, 10, 12, 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: checked ? true : partial ? null : false,
              tristate: true,
              activeColor: AppColors.primaryLight,
              checkColor: AppColors.secondaryLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => _toggleNode(node, !checked),
            ),
          ),
          const SizedBox(width: 8),
          if (node.isChild) ...[
            Text('↳ ',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w700)),
          ],
          Expanded(
            child: Text(
              ownerLocalizePermLabel(
                  AppLocalizations.of(context)!, node.label),
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                  node.isChild ? FontWeight.w600 : FontWeight.w700,
                  color: AppColors.secondaryLight),
            ),
          ),
          Wrap(
            spacing: 5,
            children: node.actions.map((action) {
              final key = _permKey(node.key, action);
              final active = _perms[key] == true;
              return GestureDetector(
                onTap: () => _toggleAction(node.key, action, !active),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryLight.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? AppColors.primaryLight
                          : Colors.grey.shade300,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    ownerLocalizePermAction(
                        AppLocalizations.of(context)!, action),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppColors.secondaryLight
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final roleName = _selectedRoleName == 'Custom name…'
        ? _customNameCtrl.text.trim()
        : _selectedRoleName;
    if (roleName == null || roleName.isEmpty) return;

    setState(() => _isLoading = true);

    // Convert internal "node:action" checkbox map into flat
    // "node.action" permission strings expected by the API.
    final selectedPermissions = _perms.entries
        .where((e) => e.value)
        .map((e) => e.key.replaceFirst(':', '.'))
        .toList();

    final role = WorkshopRole(
      id: widget.existingRole?.id ?? '',
      name: roleName,
      description: _descCtrl.text.trim(),
      portal: _selectedPortal,
      permissions: selectedPermissions,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context, role);
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
        color: Colors.grey.shade400, fontWeight: FontWeight.w400),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets  (used inside this file only)
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.grey.shade600,
        ),
        children: [
          if (required)
            const TextSpan(
                text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
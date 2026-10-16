import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../models/workshop_owner_models.dart';
import 'branch_management_view_model.dart';
import 'branch_portals_tab.dart';
import 'access_permissions_tab.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_sheet_actions.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../owner_shell.dart';

class BranchManagementView extends StatefulWidget {
  const BranchManagementView({super.key});

  @override
  State<BranchManagementView> createState() => _BranchManagementViewState();
}

class _BranchManagementViewState extends State<BranchManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<BranchManagementViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: OwnerDashboardTitle(subtitle: l10n.ownerShellBranches),
            showBackButton: false,
            showNotification: true,
            onNotificationPressed: () => OwnerShell.goToNotifications(context),
            onMenuPressed: () => OwnerShell.openDrawer(context),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              vm.clearForm();
              _showBranchSheet(context, l10n, vm);
            },
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.secondaryLight,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.branchAddButton,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Column(
            children: [
              // ── Tab selector ───────────────────────────────────────────
              _TabSelector(tabController: _tabController, l10n: l10n),

              // ── Grant Access button ────────────────────────────────────
              _GrantAccessHeader(
                onPressed: () => _showSetAccessSheet(context, l10n, vm, null),
              ),

              // ── Tab content ────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    BranchPortalsTab(
                      vm: vm,
                      l10n: l10n,
                      onAddBranch: () {
                        vm.clearForm();
                        _showBranchSheet(context, l10n, vm);
                      },
                      onEditBranch: (branch) {
                        vm.setEditBranch(branch);
                        _showBranchSheet(context, l10n, vm);
                      },
                      onSetAccess: (branch) =>
                          _showSetAccessSheet(context, l10n, vm, branch),
                    ),
                    AccessPermissionsTab(
                      vm: vm,
                      l10n: l10n,
                      onGrantAccess: () =>
                          _showSetAccessSheet(context, l10n, vm, null),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Show branch form sheet ─────────────────────────────────────────────────

  void _showBranchSheet(
      BuildContext context,
      AppLocalizations l10n,
      BranchManagementViewModel vm,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BranchFormSheet(vm: vm, l10n: l10n),
    );
  }

  // ── Show set access sheet ──────────────────────────────────────────────────

  void _showSetAccessSheet(
      BuildContext context,
      AppLocalizations l10n,
      BranchManagementViewModel vm,
      Branch? branch,
      ) {
    vm.clearAccessForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SetAccessSheet(vm: vm, l10n: l10n, preselectedBranch: branch),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab selector widget
// ─────────────────────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  final TabController tabController;
  final AppLocalizations l10n;

  const _TabSelector({
    required this.tabController,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: TabBar(
          controller: tabController,
          dividerColor: Colors.transparent,
          labelColor: AppColors.secondaryLight,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          tabs: const [
            Tab(height: 38, text: 'Branch Portals'),
            Tab(height: 38, text: 'Access Permissions'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grant Access header button
// ─────────────────────────────────────────────────────────────────────────────

class _GrantAccessHeader extends StatelessWidget {
  final VoidCallback onPressed;
  const _GrantAccessHeader({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF0FF),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: const Color(0xFFBFCFFF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 18,
                      color: Color(0xFF3D5AFE),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Grant portal access to a branch admin',
                        style: TextStyle(
                          color: Color(0xFF3D5AFE),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFF3D5AFE),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branch form bottom sheet (New Branch / Edit Branch)
// ─────────────────────────────────────────────────────────────────────────────

class _BranchFormSheet extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;

  const _BranchFormSheet({required this.vm, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: OwnerUi.sheetMaxSize,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 0),
                child: Row(
                  children: [
                    Text(
                      vm.isEditing
                          ? l10n.branchFormTitleEdit
                          : l10n.branchFormTitleAdd,
                      style: AppTextStyles.h2.copyWith(fontSize: 20),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
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
              ),

              // Form content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    // ── Info banner ───────────────────────────────────────
                    _InfoBanner(),
                    const SizedBox(height: 20),

                    // ── Branch Name ───────────────────────────────────────
                    _label('${l10n.branchFormNameLabel} *'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: vm.branchNameController,
                      hint: l10n.branchFormNameHint,
                    ),
                    const SizedBox(height: 16),

                    // ── Branch Code | Status ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Branch Code'),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.branchCodeController,
                                hint: 'e.g. RYD-001',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(l10n.branchFormStatusLabel),
                              const SizedBox(height: 8),
                              Consumer<BranchManagementViewModel>(
                                builder: (_, vm2, __) =>
                                    _StatusDropdown(vm: vm2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Phone | Email ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Phone'),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.phoneController,
                                hint: '+966...',
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Email'),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.emailController,
                                hint: 'branch@example.com',
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── GPS Lat | GPS Lng ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(l10n.branchFormLatLabel),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.gpsLatController,
                                hint: '24.7136',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(l10n.branchFormLngLabel),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.gpsLngController,
                                hint: '46.6753',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── VAT ID | CR Number ────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('VAT ID'),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.vatIdController,
                                hint: '',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('CR Number'),
                              const SizedBox(height: 8),
                              _textField(
                                controller: vm.crNumberController,
                                hint: '',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── EGS Serial ───────────────────────────────────────
                    _label('EGS Serial'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: vm.egsSerialController,
                      hint: '1-Filter|2-EGS|3-device-id',
                    ),
                    const SizedBox(height: 16),

                    // ── Contact Person ────────────────────────────────────
                    _label('Contact Person'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: vm.contactPersonController,
                      hint: '',
                    ),
                    const SizedBox(height: 16),

                    // ── Address with autocomplete ─────────────────────────
                    _label(l10n.branchFormAddressLabel),
                    const SizedBox(height: 8),
                    _AddressField(vm: vm, l10n: l10n),
                    const SizedBox(height: 32),

                    // ── Action buttons ────────────────────────────────────
                    Consumer<BranchManagementViewModel>(
                      builder: (_, vm2, __) => OwnerSheetActions(
                        onCancel: () => Navigator.pop(context),
                        onPrimary: vm2.isActionLoading
                            ? null
                            : () => vm2.submitBranchForm(context),
                        isLoading: vm2.isActionLoading,
                        primaryLabel: vm2.isEditing
                            ? l10n.branchFormUpdateButton
                            : l10n.branchFormSaveButton,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Set Access bottom sheet  –  matches "Grant Branch Admin Access" dialog design
// ─────────────────────────────────────────────────────────────────────────────

class _SetAccessSheet extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;
  final Branch? preselectedBranch;

  const _SetAccessSheet({
    required this.vm,
    required this.l10n,
    this.preselectedBranch,
  });

  static const _sections = [
    {'key': 'pos',         'label': 'POS / Sales',          'icon': Icons.point_of_sale_rounded},
    {'key': 'employees',   'label': 'Employee Management',   'icon': Icons.people_alt_rounded},
    {'key': 'departments', 'label': 'Dept & Products',       'icon': Icons.category_rounded},
    {'key': 'approvals',   'label': 'Approvals Queue',       'icon': Icons.check_circle_outline_rounded},
    {'key': 'suppliers',   'label': 'Suppliers & Purchases', 'icon': Icons.local_shipping_outlined},
    {'key': 'reports',     'label': 'Reports & Analytics',   'icon': Icons.bar_chart_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    if (preselectedBranch != null &&
        vm.selectedAccessBranch?.id != preselectedBranch!.id) {
      Future.microtask(() => vm.setSelectedAccessBranch(preselectedBranch));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: OwnerUi.sheetMaxSize,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Grant Branch Admin Access',
                      style: AppTextStyles.h2.copyWith(fontSize: 20),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
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
              ),

              // Form
              Expanded(
                child: Consumer<BranchManagementViewModel>(
                  builder: (_, vm2, __) => ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    children: [
                      // ── Branch selector ───────────────────────────────
                      _accessLabel('Branch *'),
                      const SizedBox(height: 8),
                      _AccessBranchDropdown(
                        vm: vm2,
                        preselectedBranch: preselectedBranch,
                      ),
                      const SizedBox(height: 20),

                      // ── Admin Name | Admin Email ───────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _accessLabel('Admin Name'),
                                const SizedBox(height: 8),
                                _textFieldStatic(
                                  controller: vm2.accessAdminNameController,
                                  hint: 'Full name',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _accessLabel('Admin Email'),
                                const SizedBox(height: 8),
                                _textFieldStatic(
                                  controller: vm2.accessAdminEmailController,
                                  hint: 'admin@branch.com',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Permitted Sections ─────────────────────────────
                      Text(
                        'PERMITTED SECTIONS',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2-column section grid with icons + checkboxes
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.6,
                        children: _sections.map((s) {
                          final key        = s['key']   as String;
                          final label      = s['label']  as String;
                          final icon       = s['icon']   as IconData;
                          final isSelected = vm2.selectedSections.contains(key);
                          return GestureDetector(
                            onTap: () => vm2.toggleSection(key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondaryLight.withOpacity(0.07)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondaryLight
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.secondaryLight
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.secondaryLight
                                            : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded,
                                        size: 12, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 7),
                                  Icon(icon,
                                      size: 15,
                                      color: isSelected
                                          ? AppColors.secondaryLight
                                          : Colors.grey.shade500),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.secondaryLight
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // ── Action buttons ────────────────────────────────
                      OwnerSheetActions(
                        onCancel: () => Navigator.pop(context),
                        onPrimary: vm2.isActionLoading
                            ? null
                            : () => vm2.submitAccessForm(
                                  context,
                                  branchId: preselectedBranch?.id ??
                                      vm2.selectedAccessBranch?.id ??
                                      '',
                                ),
                        isLoading: vm2.isActionLoading,
                        primaryLabel: 'Grant Access',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ── Branch dropdown for Grant Access sheet ────────────────────────────────────

class _AccessBranchDropdown extends StatelessWidget {
  final BranchManagementViewModel vm;
  final Branch? preselectedBranch;

  const _AccessBranchDropdown({
    required this.vm,
    this.preselectedBranch,
  });

  @override
  Widget build(BuildContext context) {
    final locked     = preselectedBranch != null;
    final branches   = vm.branches;
    final currentVal = locked ? preselectedBranch : vm.selectedAccessBranch;
    final validValue = branches.any((b) => b.id == currentVal?.id)
        ? currentVal
        : null;

    return OwnerStyledDropdown<String>(
      value: validValue?.id,
      hint: 'Select branch',
      height: 48,
      enabled: !locked,
      backgroundColor: locked ? Colors.grey.shade100 : Colors.white,
      borderColor: Colors.blue.shade300,
      options: branches
          .map((b) => OwnerDropdownOption(
                value: b.id,
                label: b.translatedName ?? b.name,
              ))
          .toList(),
      onChanged: locked
          ? null
          : (id) {
              if (id == null) return;
              final branch = branches.firstWhere((b) => b.id == id);
              vm.setSelectedAccessBranch(branch);
            },
      triggerStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Info Banner
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB3D1FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFF1A6ECC)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A6ECC),
                    height: 1.5),
                children: [
                  TextSpan(text: 'Each branch gets its own '),
                  TextSpan(
                    text: 'Branch Portal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'POS',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                    '. The Workshop Owner Admin can grant Branch Admins access to permitted sections only.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final BranchManagementViewModel vm;
  const _StatusDropdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    return OwnerStyledDropdown<bool>(
      value: vm.isActive,
      hint: 'Select status',
      height: 48,
      options: const [
        OwnerDropdownOption(value: true, label: 'Active'),
        OwnerDropdownOption(value: false, label: 'Inactive'),
      ],
      onChanged: (val) => vm.toggleStatus(val ?? true),
      triggerStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _label(String text) => Text(
  text,
  style: const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 13,
    color: AppColors.secondaryLight,
  ),
);

Widget _accessLabel(String text) => Text(
  text,
  style: const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 13,
    color: AppColors.secondaryLight,
  ),
);

Widget _textField({
  required TextEditingController controller,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
}) =>
    TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: OwnerUi.scaffoldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

Widget _textFieldStatic({
  required TextEditingController controller,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
}) =>
    TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: OwnerUi.scaffoldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Address autocomplete field (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────

class _AddressField extends StatefulWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;
  const _AddressField({required this.vm, required this.l10n});

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.vm.addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: widget.l10n.branchFormAddressHint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: OwnerUi.scaffoldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _loading
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
                : null,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (val) async {
            if (val.length < 3) {
              setState(() => _suggestions = []);
              return;
            }
            setState(() => _loading = true);
            final s = await widget.vm.getAddressSuggestions(val);
            setState(() {
              _suggestions = s;
              _loading = false;
            });
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: Colors.grey, size: 18),
                  title: Text(s['description'] as String,
                      style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    widget.vm.setSelectedAddress(
                      s['description'] as String,
                      s['placeId'] as String,
                    );
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
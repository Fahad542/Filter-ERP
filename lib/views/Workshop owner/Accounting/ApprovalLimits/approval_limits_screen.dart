import 'package:flutter/material.dart';
import '../../widgets/owner_ui_constants.dart';
import 'package:flutter/services.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
// NOTE: adjust this import to wherever CustomButton actually lives in your project.
import '../../../../widgets/custom_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ApprovalLimitsScreen
//
// Allows the workshop owner to configure per-request and daily approval limits
// for each role, and designate a primary and fallback approver.
// ─────────────────────────────────────────────────────────────────────────────

class ApprovalLimitsScreen extends StatefulWidget {
  const ApprovalLimitsScreen({super.key});

  @override
  State<ApprovalLimitsScreen> createState() => _ApprovalLimitsScreenState();
}

class _ApprovalLimitsScreenState extends State<ApprovalLimitsScreen> {
  bool _isSaving = false;

  // Sample approvers list (would come from API)
  final List<String?> _approvers = [
    null, // null = "Use role fallback"
    'Sultan (workshop_owner)',
    'Khalid (manager)',
    'Ahmed (accounting)',
  ];

  // Sample roles list (would come from API/model)
  final List<RoleLimitConfig> _roles = [
    RoleLimitConfig(
      displayName: 'Manager',
      roleKey: 'manager',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '4'),
      selectedApprover: 'Sultan (workshop_owner)',
      fallbackRole: null,
    ),
    RoleLimitConfig(
      displayName: 'Supervisor',
      roleKey: 'supervisor',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '0'),
      selectedApprover: null,
      fallbackRole: null,
    ),
    RoleLimitConfig(
      displayName: 'Team Leader',
      roleKey: 'team_leader',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '0'),
      selectedApprover: null,
      fallbackRole: 'accounting',
    ),
    RoleLimitConfig(
      displayName: 'Cashier',
      roleKey: 'cashier',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '0'),
      selectedApprover: 'Sultan (workshop_owner)',
      fallbackRole: null,
    ),
    RoleLimitConfig(
      displayName: 'Technician',
      roleKey: 'technician',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '0'),
      selectedApprover: null,
      fallbackRole: 'workshop_admin',
    ),
    RoleLimitConfig(
      displayName: 'Accounting',
      roleKey: 'accounting',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '0'),
      selectedApprover: null,
      fallbackRole: null,
    ),
    RoleLimitConfig(
      displayName: 'Staff (other)',
      roleKey: 'staff',
      perRequestLimit: TextEditingController(text: '0'),
      dailyLimit: TextEditingController(text: '0'),
      selectedApprover: null,
      fallbackRole: null,
    ),
  ];

  int get _configuredCount =>
      _roles.where((r) => r.selectedApprover != null || r.fallbackRole != null).length;

  Future<void> _saveMatrix() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval matrix saved', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.secondaryLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    // TODO: reload roles / approvers from API and call setState with fresh data.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final r in _roles) {
      r.perRequestLimit.dispose();
      r.dailyLimit.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: 'Approval Limits'),
        showDrawer: true,
        showNotification: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        backgroundColor: Colors.white,
        onRefresh: _refresh,
        child: Column(
          children: [
            // ── Top info bar ─────────────────────────────────────────────
            _buildTopBar(),

            // ── Role cards (pull down anywhere here to refresh) ─────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                itemCount: _roles.length,
                itemBuilder: (context, index) => _buildRoleCard(_roles[index]),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom note ──────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNote(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: OwnerUi.scaffoldBackground,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set per-request and daily approval limits per role, and designate the default approver. '
                'Workshop owner and accounting can always approve in parallel.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryLight.withOpacity(0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Save button — shared CustomButton style
              CustomButton(
                text: 'Save Matrix',
                onPressed: _saveMatrix,
                isLoading: _isSaving,
                backgroundColor: AppColors.primaryLight,
                textColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),

              const Spacer(),

              // Configured count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_configuredCount/${_roles.length} configured',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _fieldLabelStyle() => AppTextStyles.bodySmall.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: AppColors.secondaryLight.withOpacity(0.45),
  );

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(text, style: _fieldLabelStyle()),
    );
  }

  Widget _buildRoleCard(RoleLimitConfig role) {
    final bool isConfigured = role.selectedApprover != null || role.fallbackRole != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConfigured ? AppColors.primaryLight.withOpacity(0.55) : Colors.grey.shade100,
          width: isConfigured ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role header: avatar + name + key + configured badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  role.displayName.isNotEmpty ? role.displayName[0] : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.roleKey,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryLight.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConfigured)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: AppColors.secondaryLight),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Per-request + daily limit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('PER-REQUEST (SAR)'),
                    _buildNumberField(role.perRequestLimit),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('DAILY LIMIT (SAR)'),
                    _buildNumberField(role.dailyLimit),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Designated approver
          _buildFieldLabel('DESIGNATED APPROVER'),
          _buildApproverDropdown(
            value: role.selectedApprover,
            onChanged: (val) => setState(() => role.selectedApprover = val),
            hint: '— Use role fallback —',
          ),

          const SizedBox(height: 14),

          // Fallback approver role
          _buildFieldLabel('FALLBACK APPROVER ROLE'),
          _buildFallbackDropdown(
            value: role.fallbackRole,
            onChanged: (val) => setState(() => role.fallbackRole = val),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        bool isFocused = false;
        return Focus(
          onFocusChange: (f) => setLocal(() => isFocused = f),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryLight,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              filled: true,
              fillColor: AppColors.backgroundLight,
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
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildApproverDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    final bool hasValue = value != null;

    return Container(
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue ? AppColors.primaryLight : Colors.grey.shade200,
          width: hasValue ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          focusColor: AppColors.secondaryLight.withOpacity(0.5),
          hint: Text(
            hint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryLight.withOpacity(0.4),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: _approvers.map((item) {
            return DropdownMenuItem<String?>(
              value: item,
              child: Text(
                item ?? '— Use role fallback —',
                style: AppTextStyles.bodySmall.copyWith(
                  color: item == null
                      ? AppColors.secondaryLight.withOpacity(0.4)
                      : AppColors.secondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFallbackDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final roles = [
      null,
      'manager',
      'supervisor',
      'team_leader',
      'accounting',
      'workshop_admin',
    ];

    return Container(
      decoration: BoxDecoration(
        color: OwnerUi.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          focusColor: AppColors.secondaryLight.withOpacity(0.5),
          hint: Text(
            '— None —',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryLight.withOpacity(0.4),
            ),
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.secondaryLight,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: roles.map((r) {
            return DropdownMenuItem<String?>(
              value: r,
              child: Text(
                r ?? '— None —',
                style: AppTextStyles.bodySmall.copyWith(
                  color: r == null
                      ? AppColors.secondaryLight.withOpacity(0.4)
                      : AppColors.secondaryLight,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomNote() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondaryLight.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'If a request is within the limits, the designated approver (or fallback role) handles it. '
                  'Otherwise it escalates to the workshop admin. Accounting users may always approve in parallel.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryLight.withOpacity(0.55),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RoleLimitConfig — data model for one role row
// ─────────────────────────────────────────────────────────────────────────────

class RoleLimitConfig {
  final String displayName;
  final String roleKey;
  final TextEditingController perRequestLimit;
  final TextEditingController dailyLimit;
  String? selectedApprover;
  String? fallbackRole;

  RoleLimitConfig({
    required this.displayName,
    required this.roleKey,
    required this.perRequestLimit,
    required this.dailyLimit,
    this.selectedApprover,
    this.fallbackRole,
  });
}
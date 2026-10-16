import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_shimmer.dart';
import 'branch_management_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AccessPermissionsTab
//
// Mobile-optimized view of branch access permissions.
// Desktop equivalent (Image 3): table with Branch | Permitted Sections | Desc.
// Mobile: card-per-entry layout with section chips and admin info.
//
// TODO: Wire up fetchAccessPermissions() in BranchManagementViewModel to a
//       real API endpoint so this tab populates with live data.
// ─────────────────────────────────────────────────────────────────────────────

class AccessPermissionsTab extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;
  final VoidCallback onGrantAccess;

  const AccessPermissionsTab({
    super.key,
    required this.vm,
    required this.l10n,
    required this.onGrantAccess,
  });

  @override
  Widget build(BuildContext context) {
    return vm.isAccessLoading
        ? const OwnerListPageShimmer(itemCount: 5)
        : vm.accessPermissions.isEmpty
        ? _EmptyPermissions(onGrantAccess: onGrantAccess)
        : _PermissionsList(vm: vm, l10n: l10n);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPermissions extends StatelessWidget {
  final VoidCallback onGrantAccess;
  const _EmptyPermissions({required this.onGrantAccess});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vpn_key_outlined,
                size: 52,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No access permissions yet',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grant a branch admin access to specific sections of the portal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onGrantAccess,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Grant Access'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permissions list ──────────────────────────────────────────────────────────

class _PermissionsList extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;

  const _PermissionsList({required this.vm, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: vm.accessPermissions.length,
      itemBuilder: (context, index) {
        final perm = vm.accessPermissions[index];
        return _PermissionCard(permission: perm, l10n: l10n);
      },
    );
  }
}

// ── Permission card ───────────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  final BranchAccessPermission permission;
  final AppLocalizations l10n;

  const _PermissionCard({required this.permission, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final hasAdmin =
        permission.adminName != null && permission.adminEmail != null;

    final description = hasAdmin
        ? 'Branch Admin: ${permission.adminName} (${permission.adminEmail}) — ${permission.branchName} — ${permission.city}'
        : '${permission.branchName} — ${permission.city}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Branch code badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    permission.branchCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.branchName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      if (permission.city.isNotEmpty)
                        Text(
                          permission.city,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Permitted sections label ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'PERMITTED SECTIONS',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // ── Section chips ───────────────────────────────────────────────
          if (permission.permittedSections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: permission.permittedSections
                    .map((section) => _SectionChip(label: section))
                    .toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No sections permitted',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
            ),

          // ── Divider ─────────────────────────────────────────────────────
          Divider(color: Colors.grey.shade100, height: 1),

          // ── Admin info ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasAdmin
                        ? Colors.green.withOpacity(0.08)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: hasAdmin ? Colors.green.shade600 : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: hasAdmin
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.adminName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      Text(
                        permission.adminEmail!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    'No admin assigned',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // Admin status badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasAdmin
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasAdmin ? 'Admin' : 'No admin',
                    style: TextStyle(
                      color: hasAdmin
                          ? Colors.green.shade700
                          : const Color(0xFF856404),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Description (matches table view) ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  const _SectionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2D5BE3),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
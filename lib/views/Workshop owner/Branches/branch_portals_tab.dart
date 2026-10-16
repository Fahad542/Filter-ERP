import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../models/workshop_owner_models.dart';
import '../Reports/reports_search_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/owner_shimmer.dart';
import 'branch_management_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BranchPortalsTab
// ─────────────────────────────────────────────────────────────────────────────

class BranchPortalsTab extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;
  final VoidCallback onAddBranch;
  final void Function(Branch branch) onEditBranch;
  final void Function(Branch branch) onSetAccess;

  const BranchPortalsTab({
    super.key,
    required this.vm,
    required this.l10n,
    required this.onAddBranch,
    required this.onEditBranch,
    required this.onSetAccess,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(vm: vm, l10n: l10n),
        Expanded(
          child: vm.isLoading
              ? const OwnerListPageShimmer(showSearch: true)
              : vm.branches.isEmpty
              ? _EmptyState(l10n: l10n)
              : _BranchList(
            vm: vm,
            l10n: l10n,
            onEditBranch: onEditBranch,
            onSetAccess: onSetAccess,
          ),
        ),
      ],
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;

  const _SearchBar({required this.vm, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ReportsSearchBar(
        hint: l10n.branchSearchHint,
        onChanged: vm.updateSearchQuery,
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              Icons.store_outlined,
              size: 52,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.branchNoBranches,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to create your first branch',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Branch list ───────────────────────────────────────────────────────────────

class _BranchList extends StatelessWidget {
  final BranchManagementViewModel vm;
  final AppLocalizations l10n;
  final void Function(Branch) onEditBranch;
  final void Function(Branch) onSetAccess;

  const _BranchList({
    required this.vm,
    required this.l10n,
    required this.onEditBranch,
    required this.onSetAccess,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: vm.branches.length,
      itemBuilder: (context, index) {
        final branch = vm.branches[index];
        return BranchCard(
          branch: branch,
          l10n: l10n,
          vm: vm,
          onEdit: () => onEditBranch(branch),
          onSetAccess: () => onSetAccess(branch),
          onDelete: () => _confirmDelete(context, branch.id),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String branchId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade400, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.branchDeleteConfirmTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.branchDeleteConfirmBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        l10n.branchDeleteConfirmCancel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<BranchManagementViewModel>(
                      builder: (_, vmInner, __) => ElevatedButton(
                        onPressed: vmInner.isActionLoading
                            ? null
                            : () async {
                          Navigator.pop(ctx);
                          await vmInner.deleteBranch(context, branchId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: vmInner.isActionLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : Text(
                          l10n.branchDeleteConfirmDelete,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
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

// ── Branch card ───────────────────────────────────────────────────────────────

class BranchCard extends StatelessWidget {
  final Branch branch;
  final AppLocalizations l10n;
  final BranchManagementViewModel vm;
  final VoidCallback onEdit;
  final VoidCallback onSetAccess;
  final VoidCallback onDelete;

  const BranchCard({
    super.key,
    required this.branch,
    required this.l10n,
    required this.vm,
    required this.onEdit,
    required this.onSetAccess,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayName     = branch.translatedName ?? branch.name;
    final displayLocation = branch.translatedLocation ?? branch.location;
    final isActive        = branch.status.toLowerCase() == 'active';

    // New fields — add to Branch model (see ViewModel comments)
    final phone         = branch.phone ?? '';
    final email         = branch.email ?? '';
    final employeeCount = branch.employeeCount ?? 0;
    final adminName     = branch.adminName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: OwnerListStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch icon — theme secondary + primary
                OwnerListIconBox(
                  icon: Icons.store_rounded,
                  showActiveDot: isActive,
                ),
                const SizedBox(width: 12),

                // Branch name
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.secondaryLight,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                // More options (delete)
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'delete') onDelete();
                  },
                  icon: Icon(Icons.more_vert_rounded,
                      color: Colors.grey.shade400, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: Colors.red.shade400, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.branchDeleteButton,
                            style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Info rows ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                if (displayLocation.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    text: displayLocation,
                  ),
                if (phone.isNotEmpty)
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    text: phone,
                  ),
                if (email.isNotEmpty)
                  _InfoRow(
                    icon: Icons.email_outlined,
                    text: email,
                  ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Divider(color: Colors.grey.shade100, height: 1),

          // ── Employee + Status row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Employee count
                const Icon(Icons.people_rounded, size: 17, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '$employeeCount employees',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // Admin badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: adminName != null
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    adminName ?? 'No admin',
                    style: TextStyle(
                      color: adminName != null
                          ? Colors.green.shade700
                          : const Color(0xFF856404),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // INACTIVE / toggle / ACTIVE
                Row(
                  children: [
                    Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isActive,
                        onChanged: (_) {
                          // TODO: toggle branch active status via API
                        },
                        activeColor: AppColors.primaryLight,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Edit button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(l10n.branchEditButton),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: AppColors.secondaryLight,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Set Access button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSetAccess,
                    icon: const Icon(Icons.vpn_key_rounded, size: 15),
                    label: const Text('Set Access'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.secondaryLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row helper ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
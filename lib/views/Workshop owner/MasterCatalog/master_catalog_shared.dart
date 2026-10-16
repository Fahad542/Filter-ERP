// ─── master_catalog_shared.dart ──────────────────────────────────────────────
// Shared models, dummy data, and reusable widgets for the Master Catalog screen.
// Mirrors the style/color conventions of the Branch Catalog.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_styled_dropdown.dart';

// ─── Misc shared style constants ─────────────────────────────────────────────

class MCDivider {
  static const Color color = Color(0xFFF0F0F0);
  static const Color selectedFill = Color(0x1AFCC247); // primaryLight @ 10%
}

// ─── Master Catalog Models ────────────────────────────────────────────────────

class MasterBranch {
  final String id;
  final String name;
  const MasterBranch({required this.id, required this.name});
}

class MasterDepartment {
  final String id;
  final String name;
  final String parentLabel; // e.g. "Master Department"
  final bool isAddedToCurrentBranch; // gold outline = already added to at least one branch
  final bool isActive; // from API — whether the dept is currently active
  const MasterDepartment({
    required this.id,
    required this.name,
    this.parentLabel = 'Master Department',
    this.isAddedToCurrentBranch = false,
    this.isActive = true, // default true so all existing const entries compile unchanged
  });
}

class MasterCategory {
  final String id;
  final String name;
  final String type; // 'product' | 'service'
  final String departmentId; // used for client-side filtering by dept dropdown
  final String departmentName;
  final bool isAddedToCurrentBranch;
  const MasterCategory({
    required this.id,
    required this.name,
    required this.type,
    this.departmentId = '', // optional: defaults to '' for legacy const data
    required this.departmentName,
    this.isAddedToCurrentBranch = false,
  });
}

class MasterProduct {
  final String id;
  final String name;
  final String sku;
  final String brandName;
  final String departmentId;
  final String departmentName;
  final String categoryName;
  final String unit;
  final double salePrice;
  final double purchasePrice;
  final int openingQty;
  final int criticalStockPoint;
  final bool isActive;
  final bool isAddedToCurrentBranch;
  const MasterProduct({
    required this.id,
    required this.name,
    required this.sku,
    this.brandName = '',
    this.departmentId = '',
    this.departmentName = '',
    required this.categoryName,
    required this.unit,
    required this.salePrice,
    this.purchasePrice = 0,
    this.openingQty = 0,
    this.criticalStockPoint = 0,
    this.isActive = true,
    this.isAddedToCurrentBranch = false,
  });
}
class MasterService {
  final String id;
  final String name;
  final String departmentId;
  final String departmentName;
  final String categoryName;
  final double? salePrice;
  final bool isActive;
  final bool isAddedToCurrentBranch;
  const MasterService({
    required this.id,
    required this.name,
    this.departmentId = '',
    required this.departmentName,
    required this.categoryName,
    this.salePrice,
    this.isActive = true,
    this.isAddedToCurrentBranch = false,
  });
}
// ─── Add-to-branches result ───────────────────────────────────────────────────

class AddToBranchResult {
  final int added;
  final int skipped;
  final List<String> details; // e.g. "MAIN BRANCH: 2 departments (…)"
  const AddToBranchResult({
    required this.added,
    required this.skipped,
    required this.details,
  });
}

// ─── Dummy Data ───────────────────────────────────────────────────────────────

const List<MasterBranch> kMasterBranches = [
  MasterBranch(id: 'b1', name: 'MAIN BRANCH'),
  MasterBranch(id: 'b2', name: 'NORTH BRANCH'),
];

const List<MasterDepartment> kMasterDepartments = [
  MasterDepartment(id: 'd1', name: 'Clearance Offers Section', isAddedToCurrentBranch: true),
  MasterDepartment(id: 'd2', name: 'LIQUIDATION SERVICES DEPARTMENT'),
  MasterDepartment(id: 'd3', name: 'Oil Change Department', isAddedToCurrentBranch: true),
  MasterDepartment(id: 'd4', name: 'Polishing Department'),
  MasterDepartment(id: 'd5', name: 'Tea & Refreshment Department'),
  MasterDepartment(id: 'd6', name: 'TIRES Department'),
  MasterDepartment(id: 'd7', name: 'Upholstery Department'),
  MasterDepartment(id: 'd8', name: 'Washing Department'),
];

const List<MasterCategory> kMasterCategories = [
  MasterCategory(id: 'c1', name: 'AC Filters فلاتر المكيف', type: 'product', departmentName: 'Oil Change Department', isAddedToCurrentBranch: true),
  MasterCategory(id: 'c2', name: 'add-on services', type: 'service', departmentName: 'Washing Department'),
  MasterCategory(id: 'c3', name: 'add-on services', type: 'service', departmentName: 'Oil Change Department', isAddedToCurrentBranch: true),
  MasterCategory(id: 'c4', name: 'Air Filters', type: 'product', departmentName: 'Oil Change Department'),
  MasterCategory(id: 'c5', name: 'Benzol Oil', type: 'product', departmentName: 'Oil Change Department'),
  MasterCategory(id: 'c6', name: 'Car Wash VIP', type: 'service', departmentName: 'Washing Department'),
  MasterCategory(id: 'c7', name: 'Engine Oils', type: 'product', departmentName: 'Oil Change Department'),
  MasterCategory(id: 'c8', name: 'Gear Oil', type: 'product', departmentName: 'Oil Change Department'),
  MasterCategory(id: 'c9', name: 'Liquidation Services', type: 'service', departmentName: 'LIQUIDATION SERVICES DEPARTMENT'),
];


// ─── Shared Utility Widgets ───────────────────────────────────────────────────

/// Green shield check — shown on cards that are already added to a branch.
Widget buildAddedBadge() {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: const Color(0xFF2ECC71),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
  );
}

/// Blue "+" button — shown on cards not yet added.
Widget buildAddButton(VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
      ),
      child: const Icon(Icons.add_rounded, color: AppColors.secondaryLight, size: 20),
    ),
  );
}

/// Empty state widget
Widget buildMCEmptyState(String message) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inbox_rounded, size: 36, color: Colors.grey.shade300),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

/// Small status badge (active/inactive)
Widget buildMCStatusBadge(bool isActive) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: isActive ? const Color(0xFFE8F5E9) : Colors.orange.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isActive ? 'Active' : 'Inactive',
      style: TextStyle(
        color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Type badge (product / service)
Widget buildTypeBadge(String type) {
  final isProduct = type == 'product';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: isProduct
          ? AppColors.primaryLight.withOpacity(0.12)
          : Colors.purple.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      type.toUpperCase(),
      style: TextStyle(
        color: isProduct ? const Color(0xFF92620A) : Colors.purple.shade700,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    ),
  );
}

/// Selection bar shown when items are selected.
/// [onSelectAll] is optional — pass null to hide the "Select all" button.
class MCSelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onAddToBranches;
  final VoidCallback? onSelectAll; // optional

  const MCSelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onAddToBranches,
    this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            l10n.ownerCatalogSelected,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.secondaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (onSelectAll != null) ...[
            _MCBarBtn(label: l10n.ownerCatalogSelectAll, onTap: onSelectAll!),
            const SizedBox(width: 6),
          ],
          if (count > 0) ...[
            _MCBarBtn(label: l10n.ownerCatalogClear, onTap: onClear),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddToBranches,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.secondaryLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                l10n.ownerCatalogAddToBranches,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryLight),
              ),
            ),
          ] else ...[
            _MCBarBtn(label: l10n.ownerCatalogClear, onTap: onClear),
          ],
        ],
      ),
    );
  }
}

class _MCBarBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MCBarBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Result banner shown after a successful add-to-branch action
class MCResultBanner extends StatelessWidget {
  final AddToBranchResult result;
  const MCResultBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Added: ${result.added} · Skipped: ${result.skipped} (already in branch)',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (result.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...result.details.map((d) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: Color(0xFF2E7D32), fontSize: 11)),
                  Expanded(
                    child: Text(
                      d,
                      style: const TextStyle(
                          color: Color(0xFF2E7D32), fontSize: 11),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

/// Shared search bar
class MCSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const MCSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 13, color: AppColors.secondaryLight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey.shade400, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.grey.shade400, size: 18),
            onPressed: onClear,
          )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Department filter dropdown — compact inventory-style (narrow, single line).
class MCDeptDropdown extends StatelessWidget {
  final List<MasterDepartment> departments;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const MCDeptDropdown({
    super.key,
    required this.departments,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = selectedId ?? 'all';
    final l10n = AppLocalizations.of(context)!;
    var display = l10n.ownerCommonAllDepts;
    if (selectedId != null) {
      for (final d in departments) {
        if (d.id == selectedId) {
          display = d.name;
          break;
        }
      }
    }

    return OwnerStyledDropdown<String>(
      value: value,
      displayLabel: display,
      hint: l10n.ownerCommonAllDepts,
      height: 36,
      backgroundColor: Colors.white,
      borderColor: Colors.grey.shade200,
      options: [
        OwnerDropdownOption(value: 'all', label: l10n.ownerCommonAllDepartments),
        ...departments.map(
          (d) => OwnerDropdownOption(value: d.id, label: d.name),
        ),
      ],
      onChanged: (v) => onChanged(v == 'all' ? null : v),
    );
  }
}

/// Selection checkbox matching Manage Inventory list cards.
class MCListSelectCheck extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const MCListSelectCheck({
    super.key,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.secondaryLight,
              )
            : null,
      ),
    );
  }
}

/// Meta row with icon — Manage Inventory style.
class MCListMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const MCListMetaLine({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final c = color ?? const Color(0xFF9E9E9E);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Expanded(
            child: LocalizedApiText(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: c,
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

/// Primary action chip for list cards (Add / etc.).
class MCListActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const MCListActionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primaryLight
              : const Color(0x1423262D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primary
                ? AppColors.secondaryLight
                : AppColors.secondaryLight,
          ),
        ),
      ),
    );
  }
}

/// Compact branch filter dropdown — designed to sit inline next to
/// added/not-added pills in a single row.
class MCBranchFilter extends StatelessWidget {
  final List<MasterBranch> branches;
  final String? selectedBranchId;
  final ValueChanged<String?> onChanged;

  const MCBranchFilter({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = selectedBranchId != null;
    final seen = <String>{};
    final uniqueBranches = branches
        .where((b) => b.id.isNotEmpty && seen.add(b.id))
        .toList();
    final label = hasFilter
        ? uniqueBranches
            .firstWhere(
              (b) => b.id == selectedBranchId,
              orElse: () => const MasterBranch(id: '', name: 'Branch'),
            )
            .name
        : 'All branches';

    return PopupMenuButton<String>(
      initialValue: selectedBranchId ?? 'all',
      onSelected: (v) => onChanged(v == 'all' ? null : v),
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'all', child: Text('All branches')),
        ...uniqueBranches.map(
          (b) => PopupMenuItem(
            value: b.id,
            child: Text(b.name),
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.secondaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFilter ? AppColors.secondaryLight : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 70),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasFilter ? FontWeight.w700 : FontWeight.w500,
                  color: hasFilter ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: hasFilter ? Colors.white : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

/// Shared "Not added / Added" toggle pill pair.
class MCAddedToggle extends StatelessWidget {
  final bool showAdded;
  final int notAddedCount;
  final int addedCount;
  final ValueChanged<bool> onToggle;

  const MCAddedToggle({
    super.key,
    required this.showAdded,
    required this.notAddedCount,
    required this.addedCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: MCPill(
              label: l10n.ownerCatalogNotAdded(notAddedCount),
              active: !showAdded,
              onTap: () => onToggle(false),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: MCPill(
              label: l10n.ownerCatalogAdded(addedCount),
              active: showAdded,
              onTap: () => onToggle(true),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single toggle pill used by [MCAddedToggle].
class MCPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const MCPill(
      {super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.secondaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.secondaryLight : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade600,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
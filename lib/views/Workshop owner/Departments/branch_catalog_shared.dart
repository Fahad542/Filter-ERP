import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';

// ─── Shared const color tokens ────────────────────────────────────────────────
// PERF: withOpacity() creates a new Color object every call. Replaced with
// compile-time const hex values — zero runtime cost.

const _kActiveGreenBg    = Color(0xFFE8F5E9);
const _kInactiveOrangeBg = Color(0x1EFB8C00); // orange ~12%
const _kRedBg            = Color(0x12F44336); // red ~7%
const _kRedBorder        = Color(0x4DF44336); // red ~30%

// ─── Shared const text styles ─────────────────────────────────────────────────
const _kActiveTextStyle = TextStyle(
  color: Color(0xFF388E3C),
  fontSize: 11,
  fontWeight: FontWeight.w700,
);
const _kInactiveTextStyle = TextStyle(
  color: Color(0xFFF57C00),
  fontSize: 11,
  fontWeight: FontWeight.w700,
);

// ─── Shared const border radii ────────────────────────────────────────────────
const _kRadius8  = BorderRadius.all(Radius.circular(8));
const _kRadius20 = BorderRadius.all(Radius.circular(20));

// ─── Status Badge ─────────────────────────────────────────────────────────────

/// Small green dot for active catalog rows — bottom-right of icon decoration.
class CatalogActiveDot extends StatelessWidget {
  final bool isActive;
  const CatalogActiveDot({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF43A047),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Compact recessed toggle — primary when active (departments catalog).
class CatalogPrimaryToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CatalogPrimaryToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const double _width = 40;
  static const double _height = 22;
  static const double _thumb = 17;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return SizedBox(
      width: _width,
      height: _height,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_height / 2),
            color: value ? AppColors.primaryLight : const Color(0xFFE4E7EC),
            border: Border.all(
              color: value ? const Color(0xFFE0A820) : const Color(0xFFD0D5DD),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumb,
              height: _thumb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 2.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CatalogStatusBadge extends StatelessWidget {
  final bool isActive;
  const CatalogStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive ? _kActiveGreenBg : _kInactiveOrangeBg,
        borderRadius: _kRadius20,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          isActive ? 'active' : 'inactive',
          style: isActive ? _kActiveTextStyle : _kInactiveTextStyle,
        ),
      ),
    );
  }
}

// Function wrapper for backward compat
Widget buildCatalogStatusBadge(bool isActive) =>
    CatalogStatusBadge(isActive: isActive);

// ─── Remove Button ────────────────────────────────────────────────────────────

const _kRemoveDecoration = BoxDecoration(
  color: _kRedBg,
  borderRadius: _kRadius8,
  border: Border.fromBorderSide(BorderSide(color: _kRedBorder)),
);
const _kRemoveTextStyle = TextStyle(
  color: Colors.red,
  fontSize: 11,
  fontWeight: FontWeight.w700,
);

Widget buildCatalogRemoveButton(String label, VoidCallback? onTap) {
  return GestureDetector(
    onTap: onTap,
    child: DecoratedBox(
      decoration: _kRemoveDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(label, style: _kRemoveTextStyle),
      ),
    ),
  );
}

Widget buildCatalogDeleteIconButton(VoidCallback? onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.delete_outline_rounded,
        size: 18,
        color: Colors.white,
      ),
    ),
  );
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class CatalogEmptyState extends StatelessWidget {
  final String message;
  const CatalogEmptyState({super.key, required this.message});

  static const _iconDecoration = BoxDecoration(
    color: OwnerUi.scaffoldBackground,
    shape: BoxShape.circle,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DecoratedBox(
            decoration: _iconDecoration,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(Icons.inbox_rounded, size: 36, color: Color(0xFFE0E0E0)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Function wrapper for backward compat
Widget buildCatalogEmptyState(String message) =>
    CatalogEmptyState(message: message);

// ─── Dept filter dropdown (inventory-style compact) ───────────────────────────

class CatalogDeptFilterDropdown extends StatelessWidget {
  final List<CatalogDepartmentModel> departments;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const CatalogDeptFilterDropdown({
    super.key,
    required this.departments,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = selectedId ?? 'all';
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/gcc_plate.dart';

/// Country + optional UAE emirate selectors — same [MenuAnchor] pattern as Year dropdown.
class GccPlateCountrySelector extends StatelessWidget {
  const GccPlateCountrySelector({
    super.key,
    required this.countryCode,
    required this.onCountryChanged,
    this.emirate,
    this.onEmirateChanged,
    this.isTablet = false,
    this.enabled = true,
  });

  final String countryCode;
  final ValueChanged<String> onCountryChanged;
  final String? emirate;
  final ValueChanged<String?>? onEmirateChanged;
  final bool isTablet;
  final bool enabled;

  static const Color _hintColor = Color(0xFF9E9E9E);

  double _menuMaxHeight(BuildContext context) {
    return math.min(
      280.0,
      math.max(
        140.0,
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom) *
            0.42,
      ),
    );
  }

  Widget _menuDropdown({
    required BuildContext context,
    required String label,
    required String displayText,
    required IconData prefixIcon,
    required List<MenuItemButton> menuChildren,
    required bool readOnly,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final menuMaxH = _menuMaxHeight(context);
    final radius = isTablet ? 14.0 : 12.0;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      crossAxisUnconstrained: false,
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        maximumSize: WidgetStatePropertyAll(Size.fromHeight(menuMaxH)),
      ),
      menuChildren: menuChildren,
      builder: (context, controller, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: !enabled || readOnly
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          child: InputDecorator(
            isFocused: controller.isOpen,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(
                prefixIcon,
                size: isTablet ? 20 : 18,
                color: Colors.grey.shade400,
              ),
              suffixIcon: !enabled || readOnly
                  ? Icon(
                      Icons.lock_outline,
                      size: isTablet ? 16 : 15,
                      color: Colors.grey.shade400,
                    )
                  : Icon(
                      controller.isOpen
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: Colors.grey.shade500,
                    ),
              filled: true,
              fillColor: !enabled || readOnly
                  ? Colors.grey.shade50
                  : Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(
                isTablet ? 10 : 8,
                isTablet ? 12 : 10,
                isTablet ? 10 : 8,
                isTablet ? 12 : 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey,
                fontSize: isTablet ? 13 : 12,
              ),
            ),
            child: Text(
              displayText,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: AppTextStyles.bodyMedium.copyWith(
                color: displayText.isEmpty
                    ? _hintColor
                    : AppColors.secondaryLight,
                fontSize: isTablet ? 13 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cc = GccPlateCountry.parseOrDefault(countryCode).code;
    final country = GccPlateCountry.parseOrDefault(cc);
    final countryLabel = isAr ? country.nameAr : country.nameEn;

    final countryMenuChildren = <MenuItemButton>[
      for (final c in GccPlateCountry.all)
        _menuItem(
          context: context,
          label: isAr ? c.nameAr : c.nameEn,
          selected: cc == c.code,
          onPressed: enabled
              ? () {
                  onCountryChanged(c.code);
                  if (c.code != 'AE') {
                    onEmirateChanged?.call(null);
                  } else {
                    onEmirateChanged?.call(
                      emirate ?? UaeEmirate.all[1].key,
                    );
                  }
                }
              : null,
        ),
    ];

    final showEmirate = cc == 'AE' && onEmirateChanged != null;
    final em = UaeEmirate.parseOrDefault(emirate);
    final emLabel = isAr ? em.nameAr : em.nameEn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: showEmirate ? 4 : 1,
          child: _menuDropdown(
            context: context,
            label: l10n.posGccPlateCountryLabel,
            displayText: countryLabel,
            prefixIcon: Icons.public_outlined,
            menuChildren: countryMenuChildren,
            readOnly: false,
          ),
        ),
        if (showEmirate) ...[
          SizedBox(width: isTablet ? 10 : 8),
          Expanded(
            flex: 3,
            child: _menuDropdown(
              context: context,
              label: l10n.posGccPlateEmirateLabel,
              displayText: emLabel,
              prefixIcon: Icons.location_city_outlined,
              readOnly: false,
              menuChildren: [
                for (final e in UaeEmirate.all)
                  _menuItem(
                    context: context,
                    label: isAr ? e.nameAr : e.nameEn,
                    selected: em.key == e.key,
                    onPressed: enabled ? () => onEmirateChanged!(e.key) : null,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  MenuItemButton _menuItem({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    return MenuItemButton(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(isTablet ? 220 : 180, 36),
        ),
        backgroundColor: WidgetStatePropertyAll(
          selected
              ? AppColors.primaryLight.withValues(alpha: 0.18)
              : Colors.white,
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      onPressed: onPressed,
      child: Align(
        alignment: Localizations.localeOf(context).languageCode == 'ar'
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: isTablet ? 13 : 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.secondaryLight,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/locker_translation_mixin.dart';
import '../utils/app_colors.dart';

/// One tab in [PosSegmentedListTabs] (label + optional count).
class PosSegmentedTab {
  const PosSegmentedTab({
    required this.id,
    required this.label,
    this.count,
  });

  final String id;
  final String label;
  final int? count;

  String displayLabelFor(BuildContext context) {
    if (count == null) return label;
    final locale = Localizations.localeOf(context).languageCode;
    final countText =
        AppTranslationService.localizeDigitsForLanguage('$count', locale);
    return '$label ($countText)';
  }
}

enum PosSegmentedTabLayout {
  /// Horizontal scroll (orders, corporate, technician, takeaway depts).
  scrollable,

  /// Equal-width segments (products All / Products / Services).
  expanded,
}

/// Pill segmented control for POS list filter tabs.
class PosSegmentedListTabs extends StatelessWidget {
  const PosSegmentedListTabs({
    super.key,
    required this.tabs,
    required this.selectedId,
    required this.onSelected,
    this.layout = PosSegmentedTabLayout.scrollable,
    this.padding,
    this.outerRadius = 12,
    this.innerRadius = 8,
    this.tabGap = 4,
    this.containerColor = Colors.white,
    this.unselectedTabColor = Colors.white,
    this.selectedTabColor = AppColors.primaryLight,
    this.selectedLabelColor = AppColors.onPrimaryLight,
    this.tabVerticalPadding,
    this.tabHorizontalPadding,
    this.fontSize,
    this.containerInnerPadding,
  });

  static const Color unselectedLabel = Color(0xFF5B6B7C);
  static const Color outerBorder = Color(0xFFE8ECF3);

  final List<PosSegmentedTab> tabs;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final PosSegmentedTabLayout layout;
  final EdgeInsetsGeometry? padding;
  final double outerRadius;
  final double innerRadius;
  final double tabGap;
  /// Bordered wrapper background.
  final Color containerColor;
  /// Background for tabs that are not selected (inside the bordered container).
  final Color unselectedTabColor;
  /// Background for the selected tab.
  final Color selectedTabColor;
  /// Text color on the selected tab.
  final Color selectedLabelColor;
  /// Optional override for vertical padding inside each tab tile.
  final double? tabVerticalPadding;
  /// Optional override for horizontal padding inside each tab tile.
  final double? tabHorizontalPadding;
  /// Optional override for tab label font size.
  final double? fontSize;
  /// Padding between the outer border and tab row (default 4).
  final double? containerInnerPadding;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final hPad = tabHorizontalPadding ?? (isTablet ? 12.0 : 10.0);
    final vPad = tabVerticalPadding ?? (isTablet ? 6.0 : 5.0);
    final labelSize = fontSize ?? (isTablet ? 12.5 : 11.5);
    final innerPad = containerInnerPadding ?? 4.0;

    final expandTiles = layout == PosSegmentedTabLayout.expanded;

    Widget tabTile(PosSegmentedTab tab) {
      final selected = tab.id == selectedId;
      return GestureDetector(
        onTap: selected ? null : () => onSelected(tab.id),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: expandTiles ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: selected ? selectedTabColor : unselectedTabColor,
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            tab.displayLabelFor(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? selectedLabelColor : unselectedLabel,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: labelSize,
              height: 1.1,
              letterSpacing: 0.05,
            ),
          ),
        ),
      );
    }

    final tabRow = layout == PosSegmentedTabLayout.expanded
        ? Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) SizedBox(width: tabGap),
                Expanded(child: tabTile(tabs[i])),
              ],
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) SizedBox(width: tabGap),
                tabTile(tabs[i]),
              ],
            ],
          );

    final bordered = Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: outerBorder, width: 1),
      ),
      padding: EdgeInsets.all(innerPad),
      clipBehavior: Clip.antiAlias,
      child: tabRow,
    );

    final sized = layout == PosSegmentedTabLayout.expanded
        ? SizedBox(width: double.infinity, child: bordered)
        : bordered;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: layout == PosSegmentedTabLayout.expanded
            ? sized
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: sized,
              ),
      ),
    );
  }
}

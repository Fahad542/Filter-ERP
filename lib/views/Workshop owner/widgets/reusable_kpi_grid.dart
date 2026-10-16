import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../../utils/pos_tablet_layout.dart';

/// Compact money label for KPI tiles: `SAR 493.51k`, `ر.س ٤٩٣.٥١k`, etc.
String formatKpiAmount(
  num value, {
  String currency = 'SAR',
  String? languageCode,
  BuildContext? context,
}) {
  final lang = languageCode ??
      (context != null
          ? Localizations.localeOf(context).languageCode
          : 'en');
  var cur = currency;
  if (lang == 'ar' && currency.trim().toUpperCase() == 'SAR') {
    cur = 'ر.س';
  }
  return ownerFormatMoneyForLanguage(
    value,
    languageCode: lang,
    currency: cur,
    compact: true,
  );
}

enum KpiGridLayout {
  grid,
  /// Fixed-width tiles in one horizontal row (scrollable when needed).
  singleRow,
}

class ReusableKpiMetric {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const ReusableKpiMetric({
    required this.title,
    required this.value,
    this.icon,
    this.accentColor,
    this.subtitle,
    this.onTap,
  });
}

class ReusableKpiGrid extends StatelessWidget {
  final List<ReusableKpiMetric> metrics;
  final bool showFeatured;
  final int crossAxisCount;
  final KpiGridLayout layout;
  /// Width of each tile when [layout] is [KpiGridLayout.singleRow].
  final double? singleRowCardWidth;
  /// Legacy sizing — prefer [mainAxisExtent] for compact KPI rows.
  final double? childAspectRatio;
  final double? mainAxisExtent;
  final EdgeInsetsGeometry? padding;
  /// Kept for callers; card layout is always label / value / icon (web style).
  final bool iconOnTop;
  /// When true, icon sits on the leading (left) side of the KPI tile.
  final bool iconOnLeft;
  /// Tighter card sizing for 3-column owner rows.
  final bool dense;

  const ReusableKpiGrid({
    super.key,
    required this.metrics,
    this.showFeatured = true,
    this.crossAxisCount = 2,
    this.layout = KpiGridLayout.grid,
    this.singleRowCardWidth,
    this.childAspectRatio,
    this.mainAxisExtent,
    this.padding,
    this.iconOnTop = false,
    this.iconOnLeft = false,
    this.dense = false,
  });

  /// Owner portal standard — up to 3 KPIs per row, web-style KPI tiles.
  factory ReusableKpiGrid.owner({
    required List<ReusableKpiMetric> metrics,
    EdgeInsetsGeometry? padding,
    int crossAxisCount = 3,
    bool iconOnLeft = false,
    bool iconOnTop = false,
  }) {
    final hasSubtitle =
        metrics.any((m) => m.subtitle != null && m.subtitle!.trim().isNotEmpty);
    return ReusableKpiGrid(
      metrics: metrics,
      showFeatured: false,
      crossAxisCount: crossAxisCount,
      dense: crossAxisCount >= 3,
      iconOnLeft: iconOnLeft,
      iconOnTop: iconOnTop,
      mainAxisExtent: iconOnTop
          ? (hasSubtitle ? 112 : 104)
          : (hasSubtitle ? 96 : 86),
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 4),
    );
  }

  double _resolveGridHeight(List<ReusableKpiMetric> items) {
    if (mainAxisExtent != null) return mainAxisExtent!;
    final hasSubtitle =
        items.any((m) => m.subtitle != null && m.subtitle!.trim().isNotEmpty);
    if (dense || crossAxisCount >= 3) {
      return hasSubtitle ? 96 : 86;
    }
    return hasSubtitle ? 100 : 90;
  }

  Widget _buildMetricTile(ReusableKpiMetric metric, {bool compact = false}) {
    return ReusableMetricCard(
      title: metric.title,
      value: metric.value,
      icon: metric.icon,
      color: metric.accentColor ?? AppColors.primaryLight,
      subtitle: metric.subtitle,
      compact: compact,
      dense: dense,
      iconOnTop: iconOnTop,
      iconOnLeft: iconOnLeft,
      isFeatured: false,
      onTap: metric.onTap,
    );
  }

  Widget _buildSingleRow(BuildContext context, List<ReusableKpiMetric> items) {
    const gap = 10.0;
    final tablet = PosTabletLayout.isTablet(context);
    final cardWidth = singleRowCardWidth ?? (tablet ? 168.0 : 150.0);
    final baseHeight = mainAxisExtent ??
        (_resolveGridHeight(items) + (tablet ? 12.0 : 8.0));
    // Icon-on-top needs a bit more vertical room than side-icon tiles.
    final rowHeight = iconOnTop ? baseHeight.clamp(100.0, 140.0) : baseHeight;

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: gap),
        itemBuilder: (context, index) {
          return SizedBox(
            width: cardWidth,
            child: _buildMetricTile(items[index], compact: true),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    final featured = metrics.first;
    final gridMetrics = showFeatured ? metrics.skip(1).toList() : metrics;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showFeatured) ...[
            ReusableMetricCard(
              title: featured.title,
              value: featured.value,
              icon: featured.icon,
              color: featured.accentColor ?? AppColors.primaryLight,
              subtitle: featured.subtitle,
              isFeatured: true,
              iconOnLeft: iconOnLeft,
              onTap: featured.onTap,
            ),
            if (gridMetrics.isNotEmpty) const SizedBox(height: 8),
          ],
          if (gridMetrics.isNotEmpty)
            layout == KpiGridLayout.singleRow
                ? _buildSingleRow(context, gridMetrics)
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gridMetrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: dense ? 8 : 10,
                      mainAxisSpacing: dense ? 8 : 10,
                      mainAxisExtent: childAspectRatio == null
                          ? _resolveGridHeight(gridMetrics)
                          : null,
                      childAspectRatio: childAspectRatio ?? 1,
                    ),
                    itemBuilder: (context, index) {
                      return _buildMetricTile(gridMetrics[index]);
                    },
                  ),
        ],
      ),
    );
  }
}

/// Web-style KPI tile: uppercase label, bold value, optional subtitle,
/// dark icon box with yellow glyph (right by default, left via [iconOnLeft]).
class ReusableMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color color;
  final String? subtitle;
  final bool isFeatured;
  final bool compact;
  final bool dense;
  final bool iconOnTop;
  final bool iconOnLeft;
  final VoidCallback? onTap;

  const ReusableMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    required this.color,
    this.subtitle,
    this.isFeatured = false,
    this.compact = false,
    this.dense = false,
    this.iconOnTop = false,
    this.iconOnLeft = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tablet = PosTabletLayout.isTablet(context);
    final double valueSize = compact
        ? (tablet ? 14.5 : 13.5)
        : dense
            ? (tablet ? 15.5 : 14.5)
            : (isFeatured ? (tablet ? 20.0 : 18.0) : (tablet ? 17.5 : 16.0));
    final double titleSize = compact
        ? 9.5
        : dense
            ? 9.5
            : (isFeatured ? 11.5 : 10.5);
    final double subtitleSize = compact ? 9.0 : (dense ? 9.0 : 10.0);
    final iconBoxSize = iconOnTop && compact
        ? 28.0
        : compact
            ? 32.0
            : dense
                ? 34.0
                : (isFeatured ? 44.0 : 40.0);
    final iconGlyphSize = iconOnTop && compact
        ? 14.0
        : compact
            ? 16.0
            : dense
                ? 17.0
                : (isFeatured ? 22.0 : 20.0);
    final hPad = compact
        ? (iconOnTop ? 8.0 : 12.0)
        : dense
            ? 12.0
            : (isFeatured ? 14.0 : 14.0);
    final vPad = compact
        ? (iconOnTop ? 8.0 : 10.0)
        : dense
            ? 10.0
            : (isFeatured ? 12.0 : 10.0);
    final radius = isFeatured ? 16.0 : 14.0;

    Widget iconBox() => Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(iconOnTop && compact ? 10 : 12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.primaryLight,
            size: iconGlyphSize,
          ),
        );

    final textColumn = Column(
      crossAxisAlignment: iconOnTop
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
          Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? title
              : title.toUpperCase(),
          maxLines: iconOnTop ? 2 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: iconOnTop ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: iconOnTop
                ? (dense || compact ? 10.5 : 11.5)
                : titleSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8A94A6),
            letterSpacing: iconOnTop ? 0.3 : 0.6,
            height: iconOnTop ? 1.15 : 1.25,
          ),
        ),
        SizedBox(height: iconOnTop && compact ? 2 : (compact || dense ? 4 : 5)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment:
              iconOnTop ? Alignment.center : AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            textAlign: iconOnTop ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: iconOnTop
                  ? (dense || compact ? 16.0 : 17.0)
                  : valueSize,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight,
              height: 1.1,
            ),
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: iconOnTop ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: iconOnTop
                  ? (dense || compact ? 10.0 : 10.5)
                  : subtitleSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9AA3B2),
              height: 1.2,
            ),
          ),
        ],
      ],
    );

    final Widget body;
    if (icon != null && iconOnTop) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconBox(),
          SizedBox(height: compact ? 9 : 12),
          textColumn,
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null && iconOnLeft) ...[
            iconBox(),
            const SizedBox(width: 10),
          ],
          Expanded(child: textColumn),
          if (icon != null && !iconOnLeft) ...[
            const SizedBox(width: 8),
            iconBox(),
          ],
        ],
      );
    }

    final card = Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: iconOnTop
          ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: body,
            )
          : body,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

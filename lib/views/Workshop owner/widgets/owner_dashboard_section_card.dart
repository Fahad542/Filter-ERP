import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

/// Generic section card used in the owner dashboard.
/// Wraps content in a white rounded card with an optional header row
/// containing a title, count badge, and "View all" action.
class OwnerDashboardSectionCard extends StatelessWidget {
  final String title;
  final String? badgeText;
  final Color? badgeColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool compact;

  const OwnerDashboardSectionCard({
    super.key,
    required this.title,
    this.badgeText,
    this.badgeColor,
    this.actionLabel,
    this.onAction,
    required this.child,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 16.0 : 20.0;
    final headerPad = compact
        ? const EdgeInsets.fromLTRB(16, 14, 14, 10)
        : const EdgeInsets.fromLTRB(20, 16, 16, 12);
    final titleSize = compact ? 13.0 : 15.0;
    final actionSize = compact ? 11.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: compact ? 8 : 12,
            offset: Offset(0, compact ? 3 : 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: headerPad,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.h2.copyWith(
                            fontSize: titleSize,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        SizedBox(width: compact ? 6 : 8),
                        _Badge(
                          text: badgeText!,
                          color: badgeColor ?? AppColors.primaryLight,
                          compact: compact,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 8,
                        vertical: compact ? 2 : 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: actionSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: padding ??
                (compact
                    ? const EdgeInsets.fromLTRB(16, 0, 16, 14)
                    : const EdgeInsets.fromLTRB(20, 0, 20, 16)),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool compact;

  const _Badge({
    required this.text,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

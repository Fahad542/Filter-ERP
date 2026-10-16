import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/owner_l10n_helpers.dart';

/// Low-stock product row — same card language as [OwnerBranchPerformanceTile].
class OwnerDashboardLowStockTile extends StatelessWidget {
  final DashboardLowStockItem item;
  final VoidCallback? onTap;
  final bool compact;

  const OwnerDashboardLowStockTile({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
  });

  Color get _levelColor {
    if (item.criticalLevel <= 0) return Colors.orange;
    final ratio = item.stockQty / item.criticalLevel;
    if (ratio <= 0.3) return Colors.red;
    if (ratio <= 0.6) return Colors.orange;
    return Colors.amber.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = compact ? 16.0 : 20.0;
    final iconSize = compact ? 40.0 : 48.0;
    final outerPad = compact ? 14.0 : 20.0;
    final bottomGap = compact ? 8.0 : 12.0;
    final unit = ownerLocalizedUnit(l10n, item.unit);
    final qtyStr = ownerLocalizeDigits(
      context,
      item.stockQty
          .toStringAsFixed(item.stockQty == item.stockQty.roundToDouble() ? 0 : 1),
    );
    final critStr = ownerLocalizeDigits(
      context,
      item.criticalLevel.toStringAsFixed(
          item.criticalLevel == item.criticalLevel.roundToDouble() ? 0 : 1),
    );
    final qtyLabel = l10n.ownerLowStockQty(qtyStr, unit);
    final critLabel = l10n.ownerLowStockCritical(critStr, unit);
    final branch = (item.branchName ?? '').trim();
    final subtitleStyle = TextStyle(
      color: Colors.grey,
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w500,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          margin: EdgeInsets.only(bottom: bottomGap),
          padding: EdgeInsets.all(outerPad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryLight.withValues(alpha: 0.03),
                blurRadius: compact ? 10 : 15,
                offset: Offset(0, compact ? 4 : 8),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.primaryLight,
                  size: compact ? 18 : 22,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedApiText(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: compact ? 13 : 15,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    if (branch.isEmpty)
                      Text(
                        critLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle,
                      )
                    else
                      Row(
                        children: [
                          Flexible(
                            child: LocalizedApiText(
                              branch,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subtitleStyle,
                            ),
                          ),
                          Text(
                            ' · $critLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    qtyLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _levelColor,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                  Text(
                    l10n.posProductInStock,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: compact ? 8 : 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(width: compact ? 8 : 12),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: compact ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

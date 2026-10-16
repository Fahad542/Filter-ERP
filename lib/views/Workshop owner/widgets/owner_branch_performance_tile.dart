import 'package:flutter/material.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/owner_l10n_helpers.dart';

/// Branch row used on dashboard Branch Performance and full list screen.
class OwnerBranchPerformanceTile extends StatelessWidget {
  final Branch branch;
  final VoidCallback? onTap;
  final bool compact;

  const OwnerBranchPerformanceTile({
    super.key,
    required this.branch,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = compact ? 16.0 : 18.0;
    final iconSize = compact ? 40.0 : 42.0;
    final outerPad = 14.0;
    final bottomGap = compact ? 8.0 : 10.0;
    final name = branch.name;
    final location = branch.location;

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
                blurRadius: compact ? 10 : 12,
                offset: Offset(0, compact ? 4 : 6),
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
                  borderRadius: BorderRadius.circular(compact ? 10 : 11),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppColors.primaryLight,
                  size: compact ? 18 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedApiText(
                      name,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: compact ? 13 : 14,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    LocalizedApiText(
                      location,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ownerFormatMoney(context, branch.salesMTD, decimals: 0),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryLight,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                  Text(
                    l10n.ownerMonthlySales,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: compact ? 8 : 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(width: compact ? 8 : 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

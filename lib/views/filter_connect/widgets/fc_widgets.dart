import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

/// Shared cards / pills — Filter ERP theme (yellow + charcoal).
class FcCard extends StatelessWidget {
  const FcCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: box,
      ),
    );
  }
}

class FcPill extends StatelessWidget {
  const FcPill({
    super.key,
    required this.label,
    this.danger = false,
    this.success = false,
    this.info = false,
  });

  final String label;
  final bool danger;
  final bool success;
  final bool info;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.primaryLight.withOpacity(0.25);
    Color fg = AppColors.secondaryLight;
    if (danger) {
      bg = AppColors.errorLight.withOpacity(0.12);
      fg = AppColors.errorLight;
    } else if (success) {
      bg = const Color(0xFF16A34A).withOpacity(0.12);
      fg = const Color(0xFF16A34A);
    } else if (info) {
      bg = const Color(0xFF0D9488).withOpacity(0.12);
      fg = const Color(0xFF0D9488);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
          fontSize: 11,
        ),
      ),
    );
  }
}

class FcKpi extends StatelessWidget {
  const FcKpi({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    this.hint,
  });

  final String label;
  final String value;
  final String delta;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return FcCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontSize: 18,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delta,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: delta.startsWith('+')
                  ? const Color(0xFF16A34A)
                  : Colors.grey.shade600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 1),
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FcSectionTitle extends StatelessWidget {
  const FcSectionTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontSize: 16,
            color: AppColors.secondaryLight,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
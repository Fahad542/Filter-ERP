import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/promo_application_requirements.dart';
import 'promo_view_model.dart';

List<String> _scopeItemNames({
  required String scope,
  required List<String> names,
  required String summary,
}) {
  final normalizedScope = scope.trim().toLowerCase();
  if (normalizedScope == 'all' || normalizedScope == 'none') return const [];
  if (names.isNotEmpty) return names;
  if (summary.trim().isEmpty ||
      summary == 'All Products' ||
      summary == 'All Services' ||
      summary == 'Does not apply') {
    return const [];
  }
  return summary
      .split(',')
      .map((part) => part.replaceAll(RegExp(r'\s*\+\d+\s*more\s*$'), '').trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String _scopeHeading({
  required String scope,
  required String allLabel,
  required String noneLabel,
}) {
  final normalizedScope = scope.trim().toLowerCase();
  if (normalizedScope == 'none') return noneLabel;
  if (normalizedScope == 'all') return allLabel;
  return '';
}

/// Opens a popup listing all products/services covered by [promo].
void showPromoDetailsDialog(
  BuildContext context,
  AvailablePromotion promo,
) {
  final l10n = AppLocalizations.of(context)!;
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final appliesTitle = isAr
      ? 'ينطبق رمز العرض على'
      : 'This promo applies to';
  final screenHeight = MediaQuery.sizeOf(context).height;
  final screenWidth = MediaQuery.sizeOf(context).width;

  final productItems = _scopeItemNames(
    scope: promo.productScope,
    names: promo.productNames,
    summary: promo.applicableProducts,
  );
  final serviceItems = _scopeItemNames(
    scope: promo.serviceScope,
    names: promo.serviceNames,
    summary: promo.applicableServices,
  );
  final requirementLines = buildPromoApplicationRequirements(
    selectedItemMatchMode: promo.selectedItemMatchMode,
    selectedServiceRequired: promo.selectedServiceRequired,
    productScope: promo.productScope,
    serviceScope: promo.serviceScope,
    productNames: productItems,
    serviceNames: serviceItems,
    applicableProducts: promo.applicableProducts,
    applicableServices: promo.applicableServices,
    isArabic: isAr,
  );
  final requirementsTitle = isAr
      ? 'متطلبات تطبيق العرض'
      : 'Requirements to apply this promo';

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? 28 : 10,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (screenWidth - 20).clamp(320.0, 560.0),
            maxHeight: screenHeight * 0.72,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_offer_outlined,
                        size: 20,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        promo.code,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E2124),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  requirementsTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                _PromoRequirementsSection(lines: requirementLines),
                const SizedBox(height: 14),
                Text(
                  appliesTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _PromoDetailsSection(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.posPromoProductsLabel,
                  scopeHeading: _scopeHeading(
                    scope: promo.productScope,
                    allLabel: 'All Products',
                    noneLabel: 'Does not apply',
                  ),
                  items: productItems,
                ),
                const SizedBox(height: 10),
                _PromoDetailsSection(
                  icon: Icons.build_circle_outlined,
                  label: l10n.posCommonServices,
                  scopeHeading: _scopeHeading(
                    scope: promo.serviceScope,
                    allLabel: 'All Services',
                    noneLabel: 'Does not apply',
                  ),
                  items: serviceItems,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PromoRequirementsSection extends StatelessWidget {
  const _PromoRequirementsSection({required this.lines});

  final List<PromoRequirementLine> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC145).withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            if (line.type == 'heading')
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line.text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E2124),
                    height: 1.3,
                  ),
                ),
              )
            else if (line.type == 'subheading')
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  line.text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              )
            else if (line.type == 'bullet')
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Expanded(
                      child: LocalizedApiText(
                        line.text,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2124),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (line.type == 'note')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  line.text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                    height: 1.35,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line.text,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PromoDetailsSection extends StatelessWidget {
  const _PromoDetailsSection({
    required this.icon,
    required this.label,
    required this.scopeHeading,
    required this.items,
  });

  final IconData icon;
  final String label;
  final String scopeHeading;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.secondaryLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (scopeHeading.isNotEmpty)
            LocalizedApiText(
              scopeHeading,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2124),
                height: 1.35,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    Expanded(
                      child: LocalizedApiText(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2124),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared promo card — same layout in [PosPromoView] and [PromoCodeDialog].
class PromoPromotionCard extends StatelessWidget {
  const PromoPromotionCard({
    super.key,
    required this.promo,
    this.onTap,
    this.isApplying = false,
  });

  final AvailablePromotion promo;
  final VoidCallback? onTap;
  final bool isApplying;

  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  bool _isAr(BuildContext context) => _lang(context) == 'ar';

  String _seeDetailsLabel(BuildContext context) =>
      _isAr(context) ? 'عرض التفاصيل' : 'See Details';

  String _digits(BuildContext context, Object? value) {
    return AppTranslationService.localizeDigitsForLanguage(
      value?.toString() ?? '',
      _lang(context),
    );
  }

  String _money(BuildContext context, num amount) {
    final lang = _lang(context);
    final v = _digits(
      context,
      amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2),
    );
    return lang == 'ar' ? '$v ر.س' : 'SAR $v';
  }

  String _discountText(BuildContext context, double discount, bool isPercent) {
    final amount = discount % 1 == 0
        ? discount.toStringAsFixed(0)
        : discount.toStringAsFixed(2);
    final d = _digits(context, amount);
    if (_isAr(context)) {
      return isPercent ? 'خصم $d٪' : 'خصم ${_money(context, discount)}';
    }
    return isPercent ? '$d% OFF' : '${_money(context, discount)} OFF';
  }

  String _applyPromoLabel(BuildContext context) =>
      _isAr(context) ? 'تطبيق العرض' : 'Apply Promo';

  Widget _buildBottomActionBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => showPromoDetailsDialog(context, promo),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              foregroundColor: AppColors.onSecondaryLight,
              padding: const EdgeInsets.symmetric(vertical: 5),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: Text(
              _seeDetailsLabel(context),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: isApplying ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.onPrimaryLight,
              disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.85),
              disabledForegroundColor: AppColors.onPrimaryLight,
              padding: const EdgeInsets.symmetric(vertical: 5),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: isApplying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimaryLight,
                    ),
                  )
                : Text(
                    _applyPromoLabel(context),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainHeaderBody(BuildContext context) {
    final subtitle = promo.description.trim().isNotEmpty
        ? promo.description
        : promo.title.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E2124),
                    letterSpacing: 0.4,
                    height: 1.1,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  LocalizedApiText(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      height: 1.15,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: LocalizedApiText(
                        _digits(context, promo.applicableStore),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: LocalizedApiText(
                        _digits(context, promo.validityPeriod),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2124),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _discountText(context, promo.discount, promo.isPercent),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;

    return SizedBox(
      height: promoPromotionCardExtent(isTablet: isTablet),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight.withOpacity(0.22),
              const Color(0xFFFFF7E6),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMainHeaderBody(context)),
                const SizedBox(height: 8),
                _buildBottomActionBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed card height for promo grids — must match [PromoPromotionCard] layout.
double promoPromotionCardExtent({required bool isTablet}) => isTablet ? 138 : 136;

import 'package:flutter/material.dart';
import '../../../models/customer_search_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';

/// Customer profile screen. Invoice list lives on POS Home search results.
class PosCustomerHistoryView extends StatelessWidget {
  final SearchedCustomer customer;
  final String? focusOrderId;

  const PosCustomerHistoryView({
    super.key,
    required this.customer,
    this.focusOrderId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: PosScreenAppBar(title: l10n.posCustomerHistoryTitle),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 24,
        ),
        child: _buildCustomerProfile(isTablet, customer),
      ),
    );
  }

  Widget _buildCustomerProfile(bool isTablet, SearchedCustomer customer) {
    final outerPad = isTablet ? 18.0 : 24.0;
    final avatarPad = isTablet ? 12.0 : 16.0;
    final avatarIcon = isTablet ? 28.0 : 36.0;
    final nameFs = isTablet ? 19.0 : 24.0;
    final metaFs = isTablet ? 14.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(outerPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(avatarPad),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primaryLight,
              size: avatarIcon,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: LocalizedApiText(
                        customer.name,
                        style: AppTextStyles.h2.copyWith(
                          fontSize: nameFs,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2124),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        customer.customerType.toUpperCase(),
                        style: TextStyle(
                          fontSize: isTablet ? 11 : 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 6 : 8),
                LocalizedApiText(
                  customer.mobile,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: metaFs,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if ((customer.taxId ?? '').trim().isNotEmpty) ...[
                  SizedBox(height: isTablet ? 4 : 6),
                  LocalizedApiText(
                    'VAT: ${customer.taxId}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: metaFs - 1,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

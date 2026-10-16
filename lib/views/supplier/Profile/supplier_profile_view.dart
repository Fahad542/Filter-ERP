import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/widgets.dart';
import 'supplier_profile_view_model.dart';

class SupplierProfileView extends StatelessWidget {
  final VoidCallback? onBack;
  const SupplierProfileView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ChangeNotifierProvider(
      create: (_) => SupplierProfileViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PosScreenAppBar(
            title: 'Profile',
            showHamburger: false,
            showBackButton: false,
            showGlobalLeft: true,
          ),
          body: Consumer<SupplierProfileViewModel>(
            builder: (context, vm, _) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: 24,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Supplier / Warehouse Profile',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.secondaryLight,
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                      _profileRow('Company Name', vm.companyName),
                      _profileRow('Trade License / CR No', vm.tradeLicenseNo),
                      _profileRow('VAT ID', vm.vatId),
                      _profileRow('Contact Person', vm.contactPerson),
                      _profileRow('Mobile Number', vm.mobile),
                      _profileRow('Email', vm.email),
                      _profileRow('Address', vm.address),
                      _profileRow('Bank IBAN', vm.bankIban),
                      _profileRow('Bank Name', vm.bankName),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Update Profile',
                              onPressed: () => _showComingSoon(context),
                              textColor: Colors.black,
                              textStyle: AppTextStyles.button.copyWith(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade600,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showComingSoon(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Change Password',
                                          maxLines: 1,
                                          style: AppTextStyles.button.copyWith(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/pos_widgets.dart';
import '../Login/supplier_login_view.dart';
import 'supplier_registration_view_model.dart';

class SupplierRegistrationView extends StatefulWidget {
  const SupplierRegistrationView({super.key});

  @override
  State<SupplierRegistrationView> createState() => _SupplierRegistrationViewState();
}

class _SupplierRegistrationViewState extends State<SupplierRegistrationView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final hPad = isTablet ? 32.0 : 24.0;
    final fieldGap = isTablet ? 18.0 : 14.0;

    return ChangeNotifierProvider(
      create: (_) => SupplierRegistrationViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: const Color(0xFFFBF9F6),
          appBar: const PosScreenAppBar(title: 'Supplier / Warehouse Registration'),
          body: Consumer<SupplierRegistrationViewModel>(
            builder: (context, vm, _) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Company & Contact Information'),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Company Name *',
                        controller: vm.companyNameController,
                        prefixIcon: const Icon(Icons.business_outlined),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Trade License / CR No *',
                        controller: vm.tradeLicenseController,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'VAT ID *',
                        controller: vm.vatIdController,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Contact Person Name *',
                        controller: vm.contactPersonController,
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Mobile Number * (OTP)',
                        controller: vm.mobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Email * (login ID)',
                        controller: vm.emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: isTablet ? 24 : 20),
                      _sectionTitle('Address (GPS + Manual)'),
                      SizedBox(height: fieldGap),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: vm.detectGps,
                          icon: const Icon(Icons.my_location, size: 20),
                          label: const Text('Detect GPS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Street',
                        controller: vm.streetController,
                        prefixIcon: const Icon(Icons.streetview_outlined),
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'City / District',
                        controller: vm.cityDistrictController,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      SizedBox(height: isTablet ? 24 : 20),
                      _sectionTitle('Bank Details'),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'IBAN',
                        controller: vm.ibanController,
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                      ),
                      SizedBox(height: fieldGap),
                      CustomTextField(
                        label: 'Bank Name',
                        controller: vm.bankNameController,
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                      ),
                      SizedBox(height: fieldGap),
                      _sectionTitle('Upload Documents'),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _showComingSoon(context),
                            child: const Text('Choose File'),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No file chosen',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Trade License / CR',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _showComingSoon(context),
                            child: const Text('Choose File'),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No file chosen',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'VAT Certificate',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _showComingSoon(context),
                            child: const Text('Choose File'),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No file chosen',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Company Logo',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 20),
                      Row(
                        children: [
                          Checkbox(
                            value: vm.isInternalWarehouse,
                            onChanged: (v) =>
                                vm.setInternalWarehouse(v ?? false),
                            activeColor: AppColors.primaryLight,
                          ),
                          Expanded(
                            child: Text(
                              'Is this your own Internal Warehouse? Yes',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Register',
                          isLoading: vm.isLoading,
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final success = await vm.register();
                            if (!context.mounted) return;
                            if (success) {
                              ToastService.showSuccess(
                                context,
                                'Registration submitted',
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SupplierLoginView(),
                                ),
                              );
                            } else {
                              ToastService.showError(
                                context,
                                vm.errorMessage ?? 'Registration failed',
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupplierLoginView(),
                            ),
                          ),
                          child: Text(
                            'Already have an account? Login',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.secondaryLight,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File upload coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

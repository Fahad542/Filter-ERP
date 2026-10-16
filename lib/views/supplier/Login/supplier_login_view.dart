import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/widgets.dart';
import '../../../widgets/pos_widgets.dart';
import '../Registration/supplier_registration_view.dart';
import '../supplier_shell.dart';
import 'supplier_login_view_model.dart';

class SupplierLoginView extends StatefulWidget {
  const SupplierLoginView({super.key});

  @override
  State<SupplierLoginView> createState() => _SupplierLoginViewState();
}

class _SupplierLoginViewState extends State<SupplierLoginView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.1 : 24.0;
    // Header extends to ~half of login box (box starts at 28%, so ~52% of screen ≈ midpoint of card)
    final headerHeight = screenHeight * (isTablet ? 0.48 : 0.52);

    return ChangeNotifierProvider(
      create: (_) => SupplierLoginViewModel(),
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(isTablet ? 0.9 : 0.85)),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomAuthHeader(
                      title: 'Supplier / Warehouse Login',
                      subtitle: 'Sign in to continue',
                      showBackButton: true,
                      height: headerHeight,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height *
                            (isTablet ? 0.26 : 0.28),
                        left: horizontalPadding,
                        right: horizontalPadding,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 48 : 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<SupplierLoginViewModel>(
                                builder: (context, vm, _) {
                                  return CustomTextField(
                                    label: 'Mobile / Email *',
                                    hint: 'Enter mobile or email',
                                    controller: vm.mobileEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                    validator: (value) {
                                      if (value == null ||
                                          value.toString().trim().isEmpty) {
                                        return 'Please enter mobile or email';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Consumer<SupplierLoginViewModel>(
                                builder: (context, vm, _) {
                                  return CustomTextField(
                                    label: 'Password *',
                                    hint: 'Enter your password',
                                    controller: vm.passwordController,
                                    obscureText: vm.obscurePassword,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        vm.obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: vm.togglePasswordVisibility,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter password';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Forgot Password? Coming soon',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.backgroundDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Consumer<SupplierLoginViewModel>(
                                builder: (context, vm, _) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      text: 'Login',
                                      backgroundColor: AppColors.primaryLight,
                                      textColor: Colors.black,
                                      isLoading: vm.isLoading,
                                      onPressed: () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        final success = await vm.login();
                                        if (!mounted) return;
                                        if (success) {
                                          ToastService.showSuccess(
                                            context,
                                            'Login successful',
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              settings: const RouteSettings(
                                                name: '/supplier',
                                              ),
                                              builder: (_) =>
                                                  const SupplierShell(),
                                            ),
                                          );
                                        } else {
                                          ToastService.showError(
                                            context,
                                            vm.errorMessage ?? 'Login failed',
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SupplierRegistrationView(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Don't have an account? Register",
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.backgroundDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

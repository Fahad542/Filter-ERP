import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/widgets.dart';
import '../super_admin_shell.dart';
import 'super_admin_login_view_model.dart';
import '../../../services/session_service.dart';

class SuperAdminLoginView extends StatefulWidget {
  const SuperAdminLoginView({super.key});

  @override
  State<SuperAdminLoginView> createState() => _SuperAdminLoginViewState();
}

class _SuperAdminLoginViewState extends State<SuperAdminLoginView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<SuperAdminLoginViewModel>();
      viewModel.clear();
      // Check if already logged in → redirect to shell
      final isLoggedIn = await viewModel.checkSession();
      if (isLoggedIn && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminShell()),
        );
      }
    });
  }

  Future<void> _handleLogin() async {
    final viewModel = context.read<SuperAdminLoginViewModel>();
    if (!viewModel.formKey.currentState!.validate()) return;
    final success = await viewModel.login();
    if (success) {
      if (mounted) {
        ToastService.showSuccess(context, 'Login successful');
        await context.read<SessionService>().saveLastPortal('super-admin');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminShell()),
        );
      }
    } else {
      if (mounted) {
        ToastService.showError(context, viewModel.errorMessage ?? 'Login failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.1 : 24.0;
    final viewModel = context.watch<SuperAdminLoginViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CustomAuthHeader(
                  title: 'Super Admin',
                  subtitle: 'Sign in to management portal',
                  showBackButton: true,
                  height: MediaQuery.of(context).size.height *
                      (isTablet ? 0.37 : 0.42),
                ),
                // Floating white card
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height *
                        (isTablet ? 0.26 : 0.27),
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 60 : 24),
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
                      key: viewModel.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: viewModel.emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: viewModel.passwordController,
                            obscureText: viewModel.obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewModel.obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: viewModel.togglePasswordVisibility,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Sign In',
                              isLoading: viewModel.isLoading,
                              onPressed: _handleLogin,
                            ),
                          ),
                          const SizedBox(height: 16),
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
    );
  }
}

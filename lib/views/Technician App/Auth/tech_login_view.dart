import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/widgets.dart';
import '../technician_shell.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';
import '../../../utils/toast_service.dart';

class TechLoginView extends StatefulWidget {
  const TechLoginView({super.key});

  @override
  State<TechLoginView> createState() => _TechLoginViewState();
}

class _TechLoginViewState extends State<TechLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repository = AuthRepository();
      final response = await repository.technicianLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response.success == false) {
        if (mounted) {
          ToastService.showError(
            context,
            response.message ?? l10n.techLoginInvalidCreds,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final userType = response.user?.userType?.trim().toLowerCase();
      final hasTechnician = response.user?.technician != null;
      if (userType != 'workshop_user' || !hasTechnician) {
        if (mounted) {
          ToastService.showError(
            context,
            l10n.techLoginNoPortalAccess,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Print token as requested
      final session = SessionService();
      await session.saveSession(response, role: 'tech');
      await session.saveLastPortal('tech');

      if (mounted) {
        ToastService.showSuccess(context, l10n.techLoginSuccess);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TechShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, l10n.techLoginInvalidCreds);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.1 : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Yellow header
                CustomAuthHeader(
                  title: l10n.techPortalTitle,
                  subtitle: l10n.techPortalSubtitle,
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
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: l10n.ownerRegisterEmail,
                            hint: l10n.ownerRegisterEmailHint,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.techLoginEmailRequired;
                              }
                              if (!value.contains('@')) {
                                return l10n.techLoginEmailInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: l10n.ownerRegisterPassword,
                            hint: l10n.ownerRegisterPasswordHint,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.techLoginPasswordRequired;
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
                                l10n.ownerLoginForgotPassword,
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
                              text: l10n.ownerLoginSignIn,
                              isLoading: _isLoading,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/cashier_realtime_session_guard.dart';
import '../../../services/session_service.dart';
import '../../../utils/app_navigation.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/custom_auth_header.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/locker_translation_mixin.dart';

import '../Navbar/pos_shell.dart';
import 'login_view_model.dart';
import '../Home Screen/pos_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    context.read<LoginViewModel>().togglePasswordVisibility();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final loginViewModel = context.read<LoginViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    final success = await loginViewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      if (mounted) {
        final autoClosed = loginViewModel.previousSessionAutoClosed;
        await context.read<SessionService>().saveLastPortal('cashier');
        final posVm = context.read<PosViewModel>();
        posVm.clearForcedLogoutPending();
        posVm.setShellSelectedIndex(0);
        await CashierRealtimeSessionGuard.instance.ensureConnected();
        await posVm.reconnectRealtime();
        final opened = await AppNavigation.toCashierShell(
          const PosShell(),
          context: context,
        );
        if (!opened) {
          await loginViewModel.rollbackFailedShellNavigation();
          if (mounted) {
            ToastService.showError(
              context,
              'Could not open the POS home screen. Please try signing in again.',
            );
          }
          return;
        }
        if (!mounted) return;
        ToastService.showSuccess(context, l10n.posLoginSuccess);
        if (autoClosed && mounted) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              ToastService.showInfo(
                context,
                l10n.posLoginPreviousShiftAutoClosed,
              );
            }
          });
        }
      }
    } else {
      if (mounted) {
        ToastService.showError(
          context,
          loginViewModel.errorMessage != null
              ? await AppTranslationService.localizedDynamicValueForLanguage(
                  loginViewModel.errorMessage!,
                  langCode,
                )
              : l10n.posLoginFailed,
        );
      }
    }
  }

  void _handleForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final l10n = AppLocalizations.of(context)!;
        return Padding(
          padding: EdgeInsets.only(
            left: isTablet ? MediaQuery.of(context).size.width * 0.1 : 24,
            right: isTablet ? MediaQuery.of(context).size.width * 0.1 : 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: isTablet ? 60 : 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.posLoginResetPasswordTitle,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.secondaryLight,
                  fontSize: isTablet ? 22 : 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.posLoginResetPasswordSubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                  fontSize: isTablet ? 14 : 13,
                ),
              ),
              const SizedBox(height: 28),
              CustomTextField(
                label: l10n.posLoginResetPasswordEmailLabel,
                hint: l10n.posLoginResetPasswordEmailHint,
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: l10n.posLoginResetPasswordSendButton,
                  onPressed: () {
                    Navigator.pop(context);
                    ToastService.showSuccess(
                      context,
                      l10n.posLoginResetPasswordSentSuccess,
                    );
                  },
                ),
              ),
              if (isTablet) const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginVm = context.watch<LoginViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;
    final horizontalPad = isTablet ? screenWidth * 0.1 : 24.0;
    final headerFraction = isTablet ? (isLandscape ? 0.32 : 0.37) : 0.42;
    final cardTopFraction = isTablet ? (isLandscape ? 0.22 : 0.26) : 0.27;
    final cardInnerPad = isTablet ? (isLandscape ? 32.0 : 48.0) : 24.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CustomAuthHeader(
                  title: l10n.menuWorkshopPosAppPlain,
                  subtitle: l10n.posLoginTitle,
                  showBackButton: true,
                  height: screenHeight * headerFraction,
                  subtitleBottomSpacing: isTablet ? 14 : 12,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * cardTopFraction,
                    left: horizontalPad,
                    right: horizontalPad,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(cardInnerPad),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
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
                            label: l10n.posLoginEmail,
                            hint: l10n.posLoginEmailHint,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            focusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_passwordFocus);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.posLoginEmailRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: l10n.posLoginPassword,
                            hint: l10n.posLoginPasswordHint,
                            controller: _passwordController,
                            obscureText: loginVm.obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                loginVm.obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.posLoginPasswordRequired;
                              }
                              return null;
                            },
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: Text(
                                l10n.posLoginForgotPassword,
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
                              text: l10n.posLoginSignIn,
                              isLoading: loginVm.isLoading,
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

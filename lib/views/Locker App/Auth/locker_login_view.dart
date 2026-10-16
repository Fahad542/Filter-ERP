import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Collector/locker_collector_dashboard_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/widgets.dart';
import '../Supervisor/locker_supervisor_dashboard_view.dart';
import 'locker_login_view_model.dart';

class LockerLoginView extends StatefulWidget {
  const LockerLoginView({super.key});

  @override
  State<LockerLoginView> createState() => _LockerLoginViewState();
}

class _LockerLoginViewState extends State<LockerLoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ViewModel is created once in State — NOT inside build() — so that
  // notifyListeners() rebuilds the Consumer without resetting the error.
  late final LockerLoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LockerLoginViewModel();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.1 : 24.0;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<LockerLoginViewModel>(
        builder: (context, viewModel, _) {
          return PopScope(
            // Block the system back gesture while a login request is in-flight
            // so the user can't accidentally navigate away and lose the error.
            canPop: !viewModel.isLoading,
            child: Scaffold(
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
                          title: l10n.lockerPortalTitle,
                          subtitle: l10n.lockerPortalSubtitle,
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
                                    label: l10n.lockerEmail,
                                    hint: l10n.lockerEmailHint,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.lockerEmailRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: l10n.lockerPassword,
                                    hint: l10n.lockerPasswordHint,
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.lockerPasswordRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  // Error message
                                  if (viewModel.errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Colors.red.shade600,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              viewModel.errorMessage!,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                  color:
                                                  Colors.red.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        l10n.lockerForgotPassword,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      text: l10n.lockerContinue,
                                      isLoading: viewModel.isLoading,
                                      onPressed: () =>
                                          _handleLogin(context, viewModel),
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
            ),  // Scaffold
          );  // PopScope
        },
      ),
    );
  }

  Future<void> _handleLogin(
      BuildContext context, LockerLoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    viewModel.clearError();

    final success = await viewModel.login(
      context,
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final isSupervisor = viewModel.resolvedView == 'supervisor';
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => isSupervisor
              ? const LockerSupervisorDashboardView()
              : const LockerCollectorDashboardView(),
        ),
        (route) => false,
      );
    }
  }
}
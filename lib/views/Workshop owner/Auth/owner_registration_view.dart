import 'package:flutter/material.dart';
import '../widgets/owner_ui_constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../../widgets/widgets.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/session_service.dart';
import 'owner_registration_view_model.dart';

// ---------------------------------------------------------------------------
// OwnerRegistrationView
//
// All user-visible strings are served via AppLocalizations (l10n.*).
// No hardcoded English strings remain in this file.
// Address suggestions come from Google Places and are in the user's locale
// as provided by the Places API — no additional translation needed.
// ---------------------------------------------------------------------------

class OwnerRegistrationView extends StatelessWidget {
  const OwnerRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OwnerRegistrationViewModel(
        authRepository: context.read<AuthRepository>(),
        sessionService: context.read<SessionService>(),
      )..clear(),
      child: const _OwnerRegistrationViewContent(),
    );
  }
}

class _OwnerRegistrationViewContent extends StatefulWidget {
  const _OwnerRegistrationViewContent();

  @override
  State<_OwnerRegistrationViewContent> createState() =>
      _OwnerRegistrationViewContentState();
}

class _OwnerRegistrationViewContentState
    extends State<_OwnerRegistrationViewContent> {
  Future<void> _handleRegistration() async {
    final l10n      = AppLocalizations.of(context)!;
    final viewModel = context.read<OwnerRegistrationViewModel>();
    if (!viewModel.formKey.currentState!.validate()) return;

    final success = await viewModel.register();
    if (success) {
      if (mounted) {
        ToastService.showSuccess(context, l10n.ownerRegisterSuccess);
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ToastService.showError(
          context,
          viewModel.errorMessage ?? l10n.ownerRegisterFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n              = AppLocalizations.of(context)!;
    final screenWidth       = MediaQuery.of(context).size.width;
    final isTablet          = screenWidth > 600;
    final horizontalPad     = isTablet ? screenWidth * 0.1 : 24.0;
    final viewModel         = context.watch<OwnerRegistrationViewModel>();

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Branded header.
                CustomAuthHeader(
                  title: l10n.ownerRegisterTitle,
                  subtitle: l10n.ownerRegisterSubtitle,
                  showBackButton: true,
                  height: MediaQuery.of(context).size.height *
                      (isTablet ? 0.32 : 0.35),
                ),
                // Floating white card.
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height *
                        (isTablet ? 0.25 : 0.26),
                    left: horizontalPad,
                    right: horizontalPad,
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
                      key: viewModel.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Workshop name ──────────────────────────────
                          CustomTextField(
                            label: l10n.ownerRegisterWorkshopName,
                            hint: l10n.ownerRegisterWorkshopNameHint,
                            controller: viewModel.workshopNameController,
                            prefixIcon: const Icon(Icons.store_rounded),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.ownerRegisterFieldRequired
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Owner name ─────────────────────────────────
                          CustomTextField(
                            label: l10n.ownerRegisterOwnerName,
                            hint: l10n.ownerRegisterOwnerNameHint,
                            controller: viewModel.ownerNameController,
                            prefixIcon: const Icon(Icons.person_rounded),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.ownerRegisterFieldRequired
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Email ──────────────────────────────────────
                          CustomTextField(
                            label: l10n.ownerRegisterEmail,
                            hint: l10n.ownerRegisterEmailHint,
                            controller: viewModel.emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_rounded),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.ownerRegisterFieldRequired
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Mobile ─────────────────────────────────────
                          CustomTextField(
                            label: l10n.ownerRegisterMobile,
                            hint: l10n.ownerRegisterMobileHint,
                            controller: viewModel.mobileController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_rounded),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.ownerRegisterFieldRequired
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Tax ID ─────────────────────────────────────
                          CustomTextField(
                            label: l10n.ownerRegisterTaxId,
                            hint: l10n.ownerRegisterTaxIdHint,
                            controller: viewModel.taxIdController,
                            prefixIcon: const Icon(Icons.assignment_rounded),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.ownerRegisterFieldRequired
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Address (typeahead) ────────────────────────
                          TypeAheadField<Map<String, dynamic>>(
                            controller: viewModel.addressController,
                            builder: (context, controller, focusNode) {
                              return CustomTextField(
                                label: l10n.ownerRegisterAddress,
                                hint: l10n.ownerRegisterAddressHint,
                                controller: controller,
                                focusNode: focusNode,
                                prefixIcon:
                                const Icon(Icons.location_on_rounded),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.ownerRegisterFieldRequired
                                    : null,
                              );
                            },
                            suggestionsCallback: (pattern) async {
                              if (pattern.length < 3) return [];
                              return await viewModel
                                  .getAddressSuggestions(pattern);
                            },
                            itemBuilder: (context, suggestion) {
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on_rounded,
                                  size: 20,
                                  color: AppColors.primaryLight,
                                ),
                                title: Text(
                                  suggestion['description'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            },
                            onSelected: (suggestion) {
                              viewModel.onAddressSelected(suggestion);
                            },
                            emptyBuilder: (context) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                l10n.approvalsNoAddressesFound,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            decorationBuilder: (context, child) {
                              return Material(
                                type: MaterialType.card,
                                elevation: 8,
                                borderRadius: BorderRadius.circular(16),
                                child: child,
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Password ───────────────────────────────────
                          CustomTextField(
                            label: l10n.ownerRegisterPassword,
                            hint: l10n.ownerRegisterPasswordHint,
                            controller: viewModel.passwordController,
                            obscureText: viewModel.obscurePassword,
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                viewModel.obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: viewModel.togglePasswordVisibility,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.ownerRegisterFieldRequired
                                : null,
                          ),
                          const SizedBox(height: 32),

                          // ── Register button ────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: l10n.ownerRegisterButton,
                              isLoading: viewModel.isLoading,
                              onPressed: _handleRegistration,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Already have account ───────────────────────
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                l10n.ownerRegisterHaveAccount,
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
    );
  }
}
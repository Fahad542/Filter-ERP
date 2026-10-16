import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_shimmer.dart';
import '../owner_shell.dart';
import '../../../services/session_service.dart';
import '../../Menu/menu_view.dart';
import '../../../utils/restart_widget.dart';
import 'owner_settings_view_model.dart';

class OwnerSettingsView extends StatelessWidget {
  const OwnerSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OwnerSettingsViewModel()..loadProfile(),
      child: const _OwnerSettingsContent(),
    );
  }
}

class _OwnerSettingsContent extends StatelessWidget {
  const _OwnerSettingsContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OwnerSettingsViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(
          subtitle: l10n.ownerSettingsTitle,
          showBranchPicker: false,
        ),
        showGlobalLeft: true,
        showNotification: true,
        showBackButton: false,
        showDrawer: false,
        onNotificationPressed: () => OwnerShell.goToNotifications(context),
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
      body: vm.state == OwnerSettingsState.loading
          ? const OwnerFormPageShimmer()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileCard(vm: vm),
            const SizedBox(height: 20),

            // Error banner
            if (vm.state == OwnerSettingsState.error && vm.errorMessage != null)
              _ErrorBanner(message: vm.errorMessage!, onDismiss: vm.clearError),

            if (vm.state == OwnerSettingsState.error && vm.errorMessage != null)
              const SizedBox(height: 16),

            // Workshop Info (read-only or edit)
            _WorkshopInfoSection(vm: vm),
            const SizedBox(height: 24),

            _buildLogoutButton(context),
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.ownerSettingsVersionFooter,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.secondaryLight, size: 20),
        title: Text(l10n.ownerSettingsLogout,
            style: const TextStyle(
                color: AppColors.secondaryLight,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
        trailing:
        const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryLight, size: 18),
        onTap: () => _showLogoutDialog(context),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.ownerSettingsLogoutDialogTitle,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryLight)),
              const SizedBox(height: 10),
              Text(
                l10n.ownerSettingsLogoutDialogBody,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(l10n.ownerSettingsCancel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final session = SessionService();
                        await session.clearSession(role: 'owner');
                        await session.saveLastPortal('');
                        if (context.mounted) {
                          RestartWidget.restartApp(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        disabledBackgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.secondaryLight,
                        disabledForegroundColor: AppColors.secondaryLight,
                        minimumSize: const Size.fromHeight(56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(l10n.ownerSettingsLogoutConfirm,
                          style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final OwnerSettingsViewModel vm;
  const _ProfileCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ownerName = vm.profile?.ownerName ?? l10n.ownerSettingsAdminFallback;
    final workshopName = vm.profile?.name ?? '';
    final statusRaw = vm.profile?.status ?? '';
    final statusLabel = statusRaw.isEmpty
        ? ''
        : ownerLocalizedWorkshopStatus(l10n, statusRaw);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(ownerName)}&background=FCC247&color=23262D',
                width: 56,
                height: 56,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedApiText(ownerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const SizedBox(height: 2),
                LocalizedApiText(workshopName,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                if (statusLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workshop info section ────────────────────────────────────────────────────

class _WorkshopInfoSection extends StatelessWidget {
  final OwnerSettingsViewModel vm;
  const _WorkshopInfoSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSaving = vm.state == OwnerSettingsState.saving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header row
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ownerSettingsWorkshopProfile,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (!vm.isEditing)
                GestureDetector(
                  onTap: vm.startEditing,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 13, color: AppColors.secondaryLight.withOpacity(0.7)),
                        const SizedBox(width: 5),
                        Text(
                          l10n.ownerSettingsEdit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryLight.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoField(
                label: l10n.ownerSettingsFieldWorkshopName,
                icon: Icons.business_rounded,
                controller: vm.workshopNameController,
                enabled: vm.isEditing,
              ),
              _divider(),
              _infoField(
                label: l10n.ownerSettingsFieldOwnerName,
                icon: Icons.person_rounded,
                controller: vm.ownerNameController,
                enabled: vm.isEditing,
              ),
              _divider(),
              _infoField(
                label: l10n.ownerSettingsFieldMobile,
                icon: Icons.phone_rounded,
                controller: vm.mobileController,
                enabled: vm.isEditing,
                keyboardType: TextInputType.phone,
              ),
              _divider(),
              _infoField(
                label: l10n.ownerSettingsFieldEmail,
                icon: Icons.email_rounded,
                controller: vm.emailController,
                enabled: vm.isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              _divider(),
              _infoField(
                label: l10n.ownerSettingsFieldAddress,
                icon: Icons.location_on_rounded,
                controller: vm.addressController,
                enabled: vm.isEditing,
              ),
              _divider(),
              // Read-only fields
              if (vm.profile != null) ...[
                _staticInfoRow(
                  label: l10n.ownerSettingsFieldCurrency,
                  icon: Icons.monetization_on_rounded,
                  value: ownerLocalizedCurrency(context, vm.profile!.currencyCode),
                  readOnlyLabel: l10n.ownerSettingsReadOnly,
                ),
                _divider(),
                _staticInfoRow(
                  label: l10n.ownerSettingsFieldVat,
                  icon: Icons.receipt_long_rounded,
                  value: '${vm.profile!.vatPercent.toStringAsFixed(0)}%'
                      '${vm.profile!.vatInclusiveDefault ? '  •  ${l10n.ownerSettingsInclusive}' : '  •  ${l10n.ownerSettingsExclusive}'}',
                  readOnlyLabel: l10n.ownerSettingsReadOnly,
                ),
              ],

              // Save / Cancel buttons
              if (vm.isEditing) ...[
                _divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving ? null : vm.cancelEditing,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text(l10n.ownerSettingsCancel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondaryLight,
                                  fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                            final ok = await vm.saveProfile();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.ownerSettingsProfileUpdated),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.secondaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.secondaryLight),
                          )
                              : Text(l10n.ownerSettingsSaveChanges,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: enabled
                ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.secondaryLight),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                const TextStyle(color: Colors.grey, fontSize: 11),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  controller.text.isEmpty ? '—' : controller.text,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.secondaryLight),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticInfoRow({
    required String label,
    required IconData icon,
    required String value,
    required String readOnlyLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondaryLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.secondaryLight),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(readOnlyLabel,
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.1));
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 18),
          ),
        ],
      ),
    );
  }
}
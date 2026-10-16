import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_petty_cash_view_model.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerPettyCashView extends StatelessWidget {
  /// Whether the signed-in user is a supervisor or collector — controls
  /// which sidebar item set [LockerShell] shows. Defaults to true since
  /// this screen is most commonly reached from the supervisor's quick
  /// actions / sidebar.
  final bool isSupervisor;

  const LockerPettyCashView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerPettyCashViewModel(),
      child: _PettyCashBody(isSupervisor: isSupervisor),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _PettyCashBody extends StatefulWidget {
  final bool isSupervisor;

  const _PettyCashBody({required this.isSupervisor});

  @override
  State<_PettyCashBody> createState() => _PettyCashBodyState();
}

class _PettyCashBodyState extends State<_PettyCashBody> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LockerPettyCashViewModel>().init(context);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LockerPettyCashViewModel>(
      builder: (context, vm, _) {
        return LockerShell(
          isSupervisor: widget.isSupervisor,
          currentItem: LockerSidebarItem.issuePettyCash,
          title: l10n.lockerPettyIssueTitle,
          backgroundColor: OwnerUi.scaffoldBackground,
          body: _buildBodyContent(context, vm, l10n),
        );
      },
    );
  }

  // ── Body dispatcher ───────────────────────────────────────────────────────

  Widget _buildBodyContent(
    BuildContext context,
    LockerPettyCashViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          OwnerKpiGridShimmer(showFeatured: true, count: 1, crossAxisCount: 1),
          SizedBox(height: 16),
          OwnerCardRowShimmer(),
          SizedBox(height: 10),
          OwnerCardRowShimmer(),
          SizedBox(height: 10),
          OwnerCardRowShimmer(),
          SizedBox(height: 10),
          OwnerCardRowShimmer(),
        ],
      );
    }
    if (vm.hasError) {
      return _buildError(context, vm, l10n);
    }
    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.refresh(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableKpiGrid.owner(
              crossAxisCount: 1,
              padding: EdgeInsets.zero,
              metrics: [
                ReusableKpiMetric(
                  title: l10n.lockerVaultBalance,
                  value:
                      '${l10n.lockerSarCurrency} ${NumberFormat('#,##0.00').format(vm.vaultBalance)}',
                  icon: Icons.lock_outline_rounded,
                  subtitle: l10n.lockerCashInTransit,
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: _IssueFormCard(
                formKey: _formKey,
                vm: vm,
                amountController: _amountController,
                referenceController: _referenceController,
                onSubmit: () => _handleSubmit(context, vm),
              ),
            ),
            const SizedBox(height: 6),
            _RecentFloatsSection(floats: vm.recentFloats),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(
    BuildContext context,
    LockerPettyCashViewModel vm,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.lockerFailedToLoad,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? l10n.lockerAnUnexpectedError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => vm.refresh(context),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.lockerRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit handler ────────────────────────────────────────────────────────

  Future<void> _handleSubmit(
      BuildContext context, LockerPettyCashViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!vm.canSubmit) return;

    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    final success = await vm.submit(context: context);

    if (!mounted) return;

    if (success) {
      _amountController.clear();
      _referenceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(l10n.lockerFloatIssuedSuccess,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      vm.resetSubmitState();
    } else if (vm.submitError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(vm.submitError!,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      vm.resetSubmitState();
    }
  }
}

// ── Issue Form Card ───────────────────────────────────────────────────────────

class _IssueFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final LockerPettyCashViewModel vm;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final VoidCallback onSubmit;

  const _IssueFormCard({
    required this.formKey,
    required this.vm,
    required this.amountController,
    required this.referenceController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = l10n.lockerSarCurrency;
    return Container(
      decoration: OwnerListStyle.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lockerIssueFloat,
              style: OwnerListStyle.titleStyle.copyWith(fontSize: 14.5),
            ),
            const SizedBox(height: 16),

            // Cashier dropdown
            _FieldLabel(label: l10n.lockerLabelCashier),
            const SizedBox(height: 6),
            _CashierDropdown(vm: vm),
            const SizedBox(height: 14),

            // Amount + Date row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: l10n.lockerAmountLabel(currency)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        onChanged: vm.setAmount,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.lockerRequired;
                          }
                          final parsed = double.tryParse(v);
                          if (parsed == null || parsed <= 0) {
                            return l10n.lockerInvalidAmount;
                          }
                          if (parsed > vm.vaultBalance) {
                            return l10n.lockerExceedsVault;
                          }
                          return null;
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryLight,
                        ),
                        decoration: _inputDecoration('0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: l10n.lockerIssueDate),
                      const SizedBox(height: 6),
                      _DatePickerField(vm: vm),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Reference optional
            _FieldLabel(label: l10n.lockerReferenceOptional),
            const SizedBox(height: 6),
            TextFormField(
              controller: referenceController,
              onChanged: vm.setReference,
              maxLength: 80,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryLight,
              ),
              decoration: _inputDecoration(l10n.lockerWeeklyFloatHint)
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: _SubmitButton(vm: vm, onSubmit: onSubmit),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
  }
}

// ── Cashier Dropdown ──────────────────────────────────────────────────────────

class _CashierDropdown extends StatelessWidget {
  final LockerPettyCashViewModel vm;

  const _CashierDropdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FormField<CashierOption>(
      initialValue: vm.selectedCashier,
      validator: (v) => (v ?? vm.selectedCashier) == null
          ? l10n.lockerPleaseSelectCashier
          : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OwnerStyledDropdown<CashierOption>(
              value: vm.selectedCashier,
              hint: l10n.lockerSelectCashier,
              height: 44,
              leadingIcon: Icons.person_outline_rounded,
              options: vm.cashiers
                  .map((c) => OwnerDropdownOption(value: c, label: c.name))
                  .toList(),
              onChanged: (c) {
                vm.selectCashier(c);
                state.didChange(c);
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Date Picker Field ─────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final LockerPettyCashViewModel vm;

  const _DatePickerField({required this.vm});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd/MM/yyyy').format(vm.issueDate);
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: vm.issueDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.secondaryLight,
                  onPrimary: AppColors.primaryLight,
                  surface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) vm.setIssueDate(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final LockerPettyCashViewModel vm;
  final VoidCallback onSubmit;

  const _SubmitButton({required this.vm, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: vm.canSubmit
            ? AppColors.secondaryLight
            : AppColors.secondaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: vm.canSubmit ? onSubmit : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryLight,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: vm.canSubmit
                              ? AppColors.primaryLight
                              : Colors.white60,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.lockerIssueAndPostGl,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: vm.canSubmit
                                ? AppColors.primaryLight
                                : Colors.white60,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Recent Floats Section ─────────────────────────────────────────────────────

class _RecentFloatsSection extends StatelessWidget {
  final List<PettyCashFloat> floats;

  const _RecentFloatsSection({required this.floats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.lockerRecentFloatsIssued,
              style: OwnerListStyle.titleStyle.copyWith(fontSize: 13.5),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: OwnerListStyle.actionBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${floats.length}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (floats.isEmpty)
          Container(
            width: double.infinity,
            decoration: OwnerListStyle.cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              l10n.lockerNoFloatsYet,
              textAlign: TextAlign.center,
              style: OwnerListStyle.subtitleStyle.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: floats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _FloatCard(float: floats[i]),
          ),
      ],
    );
  }
}

class _FloatCard extends StatelessWidget {
  final PettyCashFloat float;

  const _FloatCard({required this.float});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = float.currency == 'SAR' || float.currency.isEmpty
        ? l10n.lockerSarCurrency
        : float.currency;
    final formattedAmount =
        '$currency ${NumberFormat('#,##0.00').format(float.amount)}';
    final formattedDate = DateFormat('dd/MM/yy').format(float.issuedAt);
    final desc = float.description.isNotEmpty
        ? float.description
        : l10n.lockerNoDescription;

    return Container(
      decoration: OwnerListStyle.cardDecoration,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OwnerListIconBox(icon: Icons.payments_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  float.cashierName,
                  style: OwnerListStyle.titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formattedAmount,
                  style: OwnerListStyle.titleStyle.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate · $desc',
                  style: OwnerListStyle.metaStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field Label helper ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }
}

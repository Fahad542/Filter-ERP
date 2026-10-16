import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_deposit_view_model.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class LockerDepositView extends StatelessWidget {
  /// Whether the signed-in user is a supervisor or collector — controls
  /// which sidebar item set [LockerShell] shows. Defaults to true since
  /// this screen is most commonly reached from the supervisor's quick
  /// actions / sidebar.
  final bool isSupervisor;

  const LockerDepositView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerDepositViewModel(),
      child: _DepositBody(isSupervisor: isSupervisor),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DepositBody extends StatefulWidget {
  final bool isSupervisor;

  const _DepositBody({required this.isSupervisor});

  @override
  State<_DepositBody> createState() => _DepositBodyState();
}

class _DepositBodyState extends State<_DepositBody> {
  final _amountController    = TextEditingController();
  final _referenceController = TextEditingController();
  final _formKey             = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LockerDepositViewModel>().init(context);
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
    return Consumer<LockerDepositViewModel>(
      builder: (context, vm, _) {
        // Show success snackbar once
        if (vm.isSuccess && vm.successMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vm.successMessage!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 3),
              ),
            );
            // Reset to idle after showing
            vm.clearSuccess();
            // Clear form fields after success
            _amountController.clear();
            _referenceController.clear();
          });
        }

        // Show a SnackBar for submit-time errors (e.g. network/API failure).
        // Init-load failures are handled separately by the full-page error
        // view in _buildContent, so only fire this once data already exists.
        if (vm.hasError &&
            vm.errorMessage != null &&
            (vm.recentDeposits.isNotEmpty || vm.bankRegisters.isNotEmpty)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 4),
              ),
            );
            vm.clearError();
          });
        }

        return LockerShell(
          isSupervisor: widget.isSupervisor,
          currentItem: LockerSidebarItem.depositToBank,
          title: l10n.lockerDepositTitle,
          backgroundColor: OwnerUi.scaffoldBackground,
          body: _buildContent(context, vm, l10n),
        );
      },
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    LockerDepositViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.isLoading) return _buildLoader();
    if (vm.hasError && vm.recentDeposits.isEmpty && vm.bankRegisters.isEmpty) {
      return _buildError(context, vm, l10n);
    }
    return _buildScrollable(context, vm);
  }

  Widget _buildLoader() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        OwnerKpiGridShimmer(count: 3, crossAxisCount: 3),
        SizedBox(height: 14),
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

  Widget _buildError(
    BuildContext context,
    LockerDepositViewModel vm,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  size: 36, color: Colors.red.shade400),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.lockerFailedToLoadTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight),
            ),
            const SizedBox(height: 6),
            Text(
              vm.errorMessage ?? l10n.lockerAnUnexpectedError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => vm.refresh(context),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.lockerRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollable(BuildContext context, LockerDepositViewModel vm) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1 — Overview KPIs (reusable card, default colors)
            _OverviewKpiGrid(vm: vm),
            const SizedBox(height: 6),

            // 2 — Deposit form card
            _DepositFormCard(
              vm: vm,
              amountController: _amountController,
              referenceController: _referenceController,
              formKey: _formKey,
            ),
            const SizedBox(height: 14),

            // 3 — Recent deposits
            _RecentDepositsCard(vm: vm),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Overview KPI grid (uses the shared ReusableKpiGrid/ReusableMetricCard) ────

class _OverviewKpiGrid extends StatelessWidget {
  final LockerDepositViewModel vm;

  const _OverviewKpiGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // No accentColor passed → ReusableMetricCard falls back to its own
    // default colors (AppColors.primaryLight) for every card here.
    final metrics = <ReusableKpiMetric>[
      ReusableKpiMetric(
        title: l10n.lockerVaultBalance,
        value:
            '${l10n.lockerSarCurrency} ${vm.vaultBalance.toStringAsFixed(2)}',
        icon: Icons.account_balance_wallet_rounded,
        subtitle: l10n.lockerCashInTransit,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiBankRegisters,
        value: '${vm.bankRegisters.length}',
        icon: Icons.account_balance_rounded,
      ),
      ReusableKpiMetric(
        title: l10n.lockerKpiRecentDeposits,
        value: '${vm.recentDeposits.length}',
        icon: Icons.receipt_long_rounded,
      ),
    ];

    return ReusableKpiGrid(
      metrics: metrics,
      showFeatured: false,
      crossAxisCount: 3,
      dense: true,
      iconOnTop: true,
      mainAxisExtent: 104,
      padding: EdgeInsets.zero,
    );
  }
}

// ── Deposit form card ─────────────────────────────────────────────────────────

class _DepositFormCard extends StatelessWidget {
  final LockerDepositViewModel vm;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final GlobalKey<FormState> formKey;

  const _DepositFormCard({
    required this.vm,
    required this.amountController,
    required this.referenceController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: OwnerListStyle.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(l10n.lockerBankRegister),
          const SizedBox(height: 6),
          _RegisterDropdown(vm: vm),
          const SizedBox(height: 14),

          // Amount + Date in a row on wider screens
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 480;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _AmountField(vm: vm, controller: amountController)),
                  const SizedBox(width: 12),
                  Expanded(child: _DateField(vm: vm, context: context)),
                ],
              );
            }
            return Column(
              children: [
                _AmountField(vm: vm, controller: amountController),
                const SizedBox(height: 14),
                _DateField(vm: vm, context: context),
              ],
            );
          }),
          const SizedBox(height: 14),

          // Reference
          _FieldLabel(l10n.lockerReferenceOptional),
          const SizedBox(height: 6),
          TextFormField(
            controller: referenceController,
            onChanged: vm.setReference,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLight),
            decoration: _inputDecoration(
              hint: l10n.lockerBankSlipHint,
              icon: Icons.tag_rounded,
            ),
          ),
          const SizedBox(height: 18),

          // Submit button
          _SubmitButton(vm: vm),

          // Slow-connection hint — shown only while a request is genuinely
          // taking longer than expected, so the button doesn't look frozen.
          if (vm.isSubmitting && vm.isSlowNetwork) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: Colors.orange.shade400,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.lockerSlowConnection,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Register dropdown ─────────────────────────────────────────────────────────

class _RegisterDropdown extends StatelessWidget {
  final LockerDepositViewModel vm;

  const _RegisterDropdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (vm.bankRegisters.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: OwnerListStyle.cardBorder),
        ),
        child: Text(
          l10n.lockerNoBankRegisters,
          style: const TextStyle(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    return OwnerStyledDropdown<BankRegister>(
      value: vm.selectedRegister,
      hint: l10n.lockerSelectBankRegister,
      height: 44,
      leadingIcon: Icons.account_balance_rounded,
      options: vm.bankRegisters
          .map(
            (reg) => OwnerDropdownOption(
              value: reg,
              label: reg.accountNumber.isNotEmpty
                  ? '${reg.name} · ${reg.accountNumber}'
                  : reg.name,
            ),
          )
          .toList(),
      displayLabel: vm.selectedRegister?.name,
      onChanged: vm.selectRegister,
    );
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  final LockerDepositViewModel vm;
  final TextEditingController controller;

  const _AmountField({required this.vm, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.lockerAmountLabel(l10n.lockerSarCurrency)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          onChanged: vm.setAmount,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryLight),
          decoration: _inputDecoration(
            hint: '0.00',
            icon: Icons.payments_rounded,
            errorText: vm.amountErrorFor(l10n),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return l10n.lockerRequired;
            final parsed = double.tryParse(v);
            if (parsed == null || parsed <= 0) {
              return l10n.lockerEnterValidAmount;
            }
            if (parsed > vm.vaultBalance) return l10n.lockerExceedsVault;
            return null;
          },
        ),
      ],
    );
  }
}

// ── Date field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final LockerDepositViewModel vm;
  final BuildContext context;

  const _DateField({required this.vm, required this.context});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label =
        '${vm.depositDate.day.toString().padLeft(2, '0')}/'
        '${vm.depositDate.month.toString().padLeft(2, '0')}/'
        '${vm.depositDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.lockerDate),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: vm.depositDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
              builder: (ctx, child) {
                return Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.secondaryLight,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) vm.setDepositDate(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final LockerDepositViewModel vm;

  const _SubmitButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = vm.canSubmit;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isActive
            ? () {
          FocusScope.of(context).unfocus();
          vm.submitDeposit(context: context);
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryLight,
          disabledBackgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.grey.shade400,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: vm.isSubmitting
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, size: 16),
            const SizedBox(width: 8),
            Text(
              l10n.lockerDepositAndPostGl,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent deposits card ──────────────────────────────────────────────────────

class _RecentDepositsCard extends StatelessWidget {
  final LockerDepositViewModel vm;

  const _RecentDepositsCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.lockerRecentBankDeposits,
                style: OwnerListStyle.titleStyle.copyWith(fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: OwnerListStyle.actionBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${vm.recentDeposits.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (vm.recentDeposits.isEmpty)
          Container(
            decoration: OwnerListStyle.cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              l10n.lockerNoDepositsYet,
              textAlign: TextAlign.center,
              style: OwnerListStyle.subtitleStyle,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vm.recentDeposits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              return _DepositCard(record: vm.recentDeposits[i]);
            },
          ),
      ],
    );
  }
}

class _DepositCard extends StatelessWidget {
  final DepositRecord record;

  const _DepositCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel =
        '${record.depositedAt.day.toString().padLeft(2, '0')}/'
        '${record.depositedAt.month.toString().padLeft(2, '0')}/'
        '${record.depositedAt.year}';
    final currency = record.currency == 'SAR' || record.currency.isEmpty
        ? l10n.lockerSarCurrency
        : record.currency;

    return Container(
      decoration: OwnerListStyle.cardDecoration,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OwnerListIconBox(icon: Icons.account_balance_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.reference.isNotEmpty
                      ? record.reference
                      : l10n.lockerBankDeposit,
                  style: OwnerListStyle.titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency ${record.amount.toStringAsFixed(2)}',
                  style: OwnerListStyle.titleStyle.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.registerName} · $dateLabel',
                  style: OwnerListStyle.metaStyle,
                  maxLines: 1,
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

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: AppColors.primaryLight),
    errorText: errorText,
    errorStyle: const TextStyle(fontSize: 10),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      const BorderSide(color: AppColors.primaryLight, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/petty_cash_expense_categories.dart';
import '../../../data/repositories/locker_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_colors.dart';
import '../../Technician App/widgets/tech_dashboard_filter_bar.dart';
import '../../Workshop Owner/widgets/owner_list_style.dart';
import '../../Workshop Owner/widgets/owner_shimmer.dart';
import '../../Workshop Owner/widgets/owner_styled_dropdown.dart';
import '../../Workshop Owner/widgets/owner_ui_constants.dart';
import '../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../locker_shell.dart';
import '../widgets/locker_sidebar.dart' show LockerSidebarItem;
import 'locker_expenses_view_model.dart';

String _money(double v) => NumberFormat('#,##0.00').format(v);

class LockerExpensesView extends StatelessWidget {
  final bool isSupervisor;

  const LockerExpensesView({super.key, this.isSupervisor = true});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LockerExpensesViewModel(),
      child: _ExpensesBody(isSupervisor: isSupervisor),
    );
  }
}

class _ExpensesBody extends StatefulWidget {
  final bool isSupervisor;

  const _ExpensesBody({required this.isSupervisor});

  @override
  State<_ExpensesBody> createState() => _ExpensesBodyState();
}

class _ExpensesBodyState extends State<_ExpensesBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LockerExpensesViewModel>().init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<LockerExpensesViewModel>();

    return LockerShell(
      isSupervisor: widget.isSupervisor,
      currentItem: LockerSidebarItem.expenses,
      title: l10n.lockerExpensesTitle,
      backgroundColor: OwnerUi.scaffoldBackground,
      bottomOverlap: vm.tab == LockerExpensesTab.log
          ? TechDashboardOverlapFilters(
              startDate: vm.from,
              endDate: vm.to,
              dateOnly: true,
              onStartDateChanged: (d) => vm.setDateRange(d, vm.to, context),
              onEndDateChanged: (d) => vm.setDateRange(vm.from, d, context),
            )
          : null,
      body: _buildBody(context, vm, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LockerExpensesViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.isLoading && vm.expenses.isEmpty && vm.tab == LockerExpensesTab.log) {
      return const OwnerListPageShimmer(
        showKpi: true,
        kpiCount: 4,
        itemCount: 4,
        padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
      );
    }

    if (vm.isError && vm.expenses.isEmpty && vm.summary.lockerVaultBalance == 0) {
      return _ErrorState(
        message: vm.error ?? l10n.lockerAnErrorOccurred,
        onRetry: () => vm.refresh(context),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.refresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildKpiGrid(vm, l10n),
          const SizedBox(height: 12),
          _TabSwitcher(vm: vm),
          const SizedBox(height: 12),
          if (vm.tab == LockerExpensesTab.record)
            _RecordTab(vm: vm)
          else
            _LogTab(vm: vm),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(LockerExpensesViewModel vm, AppLocalizations l10n) {
    final s = vm.summary;
    final sar = l10n.lockerSarCurrency;
    return ReusableKpiGrid(
      metrics: [
        ReusableKpiMetric(
          title: l10n.lockerKpiLockerVault,
          value: '$sar ${_money(s.lockerVaultBalance)}',
          subtitle: l10n.lockerCashInTransit,
          icon: Icons.account_balance_wallet_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.lockerPostedExpenses,
          value: '$sar ${_money(s.totalAmount)}',
          icon: Icons.receipt_long_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.lockerPostedCount,
          value: '${s.expenseCount}',
          icon: Icons.format_list_numbered_rounded,
        ),
        ReusableKpiMetric(
          title: l10n.lockerKpiPendingApproval,
          value: '${s.pendingCount}',
          icon: Icons.hourglass_top_rounded,
        ),
      ],
      showFeatured: false,
      layout: KpiGridLayout.singleRow,
      iconOnTop: true,
      singleRowCardWidth: 148,
      mainAxisExtent: 112,
      padding: EdgeInsets.zero,
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  final LockerExpensesViewModel vm;

  const _TabSwitcher({required this.vm});

  static const _track = Color(0xFFF1F5F9);
  static const _trackBorder = Color(0xFFE2E8F0);
  static const _inactiveFg = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _track,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabBtn(
              label: l10n.lockerTabRecordExpenses,
              selected: vm.tab == LockerExpensesTab.record,
              onTap: () => vm.setTab(LockerExpensesTab.record),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabBtn(
              label: l10n.lockerTabExpensesLog,
              selected: vm.tab == LockerExpensesTab.log,
              badge: vm.summary.pendingCount > 0 ? vm.summary.pendingCount : null,
              onTap: () => vm.setTab(LockerExpensesTab.log),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimaryLight : _TabSwitcher._inactiveFg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.2,
                    color: fg,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Record tab ────────────────────────────────────────────────────────────────

class _RecordTab extends StatelessWidget {
  final LockerExpensesViewModel vm;

  const _RecordTab({required this.vm});

  Future<void> _handleSubmit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    final total = vm.linesTotal;
    final vault = vm.summary.lockerVaultBalance;
    if (total > vault + 0.01) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.lockerVaultBalanceDialog,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text(l10n.lockerExceedVaultBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.lockerCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.lockerSubmitAnyway),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    final err = await vm.submitBulk(context: context);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (vm.submitSuccess != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.submitSuccess!,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vm.submitError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Banner(
              message: vm.submitError!,
              color: Colors.red.shade700,
              bg: Colors.red.shade50,
              icon: Icons.warning_amber_rounded,
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.lockerExpenseLines,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
            Text(
              '${l10n.lockerSarCurrency} ${_money(vm.linesTotal)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.45),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: vm.submitting ? null : vm.addLine,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l10n.lockerAddLine),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryLight,
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...vm.lines.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExpenseLineCard(
              key: ValueKey(e.value.key),
              index: e.key,
              line: e.value,
              vm: vm,
            ),
          );
        }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: vm.submitting ? null : () => _handleSubmit(context),
            icon: vm.submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.receipt_rounded, size: 18),
            label: Text(
              vm.submitting
                  ? l10n.lockerSubmitting
                  : l10n.lockerSubmitLines('${vm.lines.length}'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryLight,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.secondaryLight.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseLineCard extends StatelessWidget {
  final int index;
  final ExpenseLineDraft line;
  final LockerExpensesViewModel vm;

  const _ExpenseLineCard({
    super.key,
    required this.index,
    required this.line,
    required this.vm,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: line.expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      vm.updateLine(line.key, expenseDate: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final branchValue = line.branchId ?? '';
    final branchOptions = [
      ...vm.branches.map((b) => OwnerDropdownOption(value: b.id, label: b.name)),
    ];
    final validBranch = branchOptions.any((o) => o.value == branchValue)
        ? branchValue
        : (branchOptions.isNotEmpty ? branchOptions.first.value : '');

    final catOptions = [
      ...vm.categories.map(
        (c) => OwnerDropdownOption(
          value: c,
          label: pettyCashExpenseCategoryLabel(c, lang),
        ),
      ),
    ];
    final validCat = catOptions.any((o) => o.value == line.category)
        ? line.category
        : (catOptions.isNotEmpty ? catOptions.first.value : line.category);

    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.lockerLineN('${index + 1}'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: vm.lines.length <= 1 || vm.submitting
                      ? null
                      : () => vm.removeLine(line.key),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: vm.lines.length <= 1
                        ? Colors.black26
                        : Colors.red.shade400,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            _FieldLabel(l10n.lockerLabelBranch),
            const SizedBox(height: 5),
            if (vm.branchesLoading)
              const _TinyLoader()
            else
              OwnerStyledDropdown<String>(
                value: validBranch.isEmpty ? null : validBranch,
                options: branchOptions,
                onChanged: vm.submitting
                    ? null
                    : (v) => vm.updateLine(line.key, branchId: v),
                hint: l10n.lockerFilterByBranch,
                height: 40,
                backgroundColor: Colors.white,
                borderColor: OwnerListStyle.cardBorder,
                triggerStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLight,
                ),
              ),
            const SizedBox(height: 10),
            _FieldLabel(l10n.lockerCategoryLabel),
            const SizedBox(height: 5),
            if (vm.categoriesLoading)
              const _TinyLoader()
            else
              OwnerStyledDropdown<String>(
                value: validCat,
                options: catOptions,
                onChanged: vm.submitting
                    ? null
                    : (v) {
                        if (v != null) vm.updateLine(line.key, category: v);
                      },
                hint: l10n.lockerSelectCategory,
                height: 40,
                backgroundColor: Colors.white,
                borderColor: OwnerListStyle.cardBorder,
                triggerStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLight,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                          l10n.lockerAmountLabel(l10n.lockerSarCurrency)
                              .toUpperCase()),
                      const SizedBox(height: 5),
                      _TextBox(
                        key: ValueKey('${line.key}-amount'),
                        initialValue: line.amount,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        enabled: !vm.submitting,
                        onChanged: (v) => vm.updateLine(line.key, amount: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l10n.lockerDateLabel),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: vm.submitting ? null : () => _pickDate(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: OwnerListStyle.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(line.expenseDate),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondaryLight,
                                  ),
                                ),
                              ),
                              Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Colors.black.withOpacity(0.35)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _FieldLabel(l10n.lockerNotes.toUpperCase()),
            const SizedBox(height: 5),
            _TextBox(
              key: ValueKey('${line.key}-desc'),
              initialValue: line.description,
              hint: l10n.lockerNotes,
              enabled: !vm.submitting,
              onChanged: (v) => vm.updateLine(line.key, description: v),
            ),
            const SizedBox(height: 10),
            _FieldLabel(l10n.lockerProofUrlOptional),
            const SizedBox(height: 5),
            _TextBox(
              key: ValueKey('${line.key}-proof'),
              initialValue: line.proofUrl,
              hint: 'https://…',
              keyboardType: TextInputType.url,
              enabled: !vm.submitting,
              onChanged: (v) => vm.updateLine(line.key, proofUrl: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        color: Colors.black.withOpacity(0.35),
      ),
    );
  }
}

class _TextBox extends StatefulWidget {
  final String initialValue;
  final String hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;

  const _TextBox({
    super.key,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<_TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends State<_TextBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _TextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text &&
        widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryLight,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.25),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: OwnerListStyle.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: OwnerListStyle.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: OwnerListStyle.cardBorder),
          ),
        ),
      ),
    );
  }
}

class _TinyLoader extends StatelessWidget {
  const _TinyLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black26),
        ),
      ),
    );
  }
}

// ── Log tab ───────────────────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final LockerExpensesViewModel vm;

  const _LogTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterPanel(context, vm, l10n, lang),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.lockerTabExpensesLog.toUpperCase(),
              style: TextStyle(
                color: Colors.black.withOpacity(0.3),
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              l10n.lockerRecordCount('${vm.expenses.length}'),
              style: TextStyle(
                color: Colors.black.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (vm.isLoading && vm.expenses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (vm.expenses.isEmpty)
          _EmptyInline(message: l10n.lockerNoResultsMatchFilters)
        else
          ...vm.expenses.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseLogCard(entry: e),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterPanel(
    BuildContext context,
    LockerExpensesViewModel vm,
    AppLocalizations l10n,
    String lang,
  ) {
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.hasActiveFilters)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => vm.clearFilters(context),
                    child: Text(
                      l10n.lockerClearAll,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    label: l10n.lockerLabelBranch,
                    value: vm.selectedBranchId ?? 'all',
                    isLoading: vm.branchesLoading,
                    hint: l10n.lockerAllBranches,
                    options: [
                      OwnerDropdownOption(
                          value: 'all', label: l10n.lockerAllBranches),
                      ...vm.branches.map(
                        (b) => OwnerDropdownOption(value: b.id, label: b.name),
                      ),
                    ],
                    onChanged: (v) => vm.setSelectedBranch(v, context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterDropdown(
                    label: l10n.lockerStatusLabel,
                    value: vm.selectedStatus,
                    hint: l10n.lockerFilterAll,
                    options: [
                      OwnerDropdownOption(
                          value: 'all', label: l10n.lockerFilterAll),
                      OwnerDropdownOption(
                          value: 'pending',
                          label: l10n.lockerPendingApproval),
                      OwnerDropdownOption(
                          value: 'posted', label: l10n.lockerStatusPosted),
                      OwnerDropdownOption(
                          value: 'rejected',
                          label: l10n.lockerStatusRejected),
                    ],
                    onChanged: (v) => vm.setSelectedStatus(v, context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _FilterDropdown(
              label: l10n.lockerCategoryLabel,
              value: vm.selectedCategory,
              isLoading: vm.categoriesLoading,
              hint: l10n.lockerFilterAll,
              options: [
                OwnerDropdownOption(value: 'all', label: l10n.lockerFilterAll),
                ...vm.categories.map(
                  (c) => OwnerDropdownOption(
                    value: c,
                    label: pettyCashExpenseCategoryLabel(c, lang),
                  ),
                ),
              ],
              onChanged: (v) => vm.setSelectedCategory(v, context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final String hint;
  final List<OwnerDropdownOption<String>> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = options.any((o) => o.value == value) ? value : 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: Colors.black.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 5),
        if (isLoading)
          const _TinyLoader()
        else
          OwnerStyledDropdown<String>(
            value: validValue,
            options: options,
            onChanged: onChanged,
            hint: hint,
            height: 40,
            backgroundColor: Colors.white,
            borderColor: OwnerListStyle.cardBorder,
            triggerStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight,
            ),
          ),
      ],
    );
  }
}

class _ExpenseLogCard extends StatelessWidget {
  final LockerExpenseEntry entry;

  const _ExpenseLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final categoryLabel = entry.category.isNotEmpty
        ? pettyCashExpenseCategoryLabel(entry.category, lang)
        : l10n.lockerExpensesTitle;
    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OwnerListIconBox(icon: Icons.receipt_long_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel,
                        style: OwnerListStyle.titleStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.branchName.isNotEmpty ? entry.branchName : '—',
                        style: OwnerListStyle.subtitleStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${l10n.lockerSarCurrency} ${_money(entry.amount)}',
                      style: OwnerListStyle.titleStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ExpenseStatusBadge(status: entry.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: OwnerListStyle.cardBorder),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _MetaChip(
                  icon: Icons.event_rounded,
                  text: entry.expenseDate.isNotEmpty ? entry.expenseDate : '—',
                ),
                _MetaChip(
                  icon: Icons.person_outline_rounded,
                  text: entry.createdByName?.isNotEmpty == true
                      ? entry.createdByName!
                      : '—',
                ),
                if (entry.journalEntryNumber?.isNotEmpty == true)
                  _MetaChip(
                    icon: Icons.menu_book_rounded,
                    text: entry.journalEntryNumber!,
                  ),
              ],
            ),
            if (entry.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                entry.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (entry.status.toLowerCase() == 'rejected' &&
                entry.rejectionReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                entry.rejectionReason!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (entry.proofUrl?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(entry.proofUrl!.trim());
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  l10n.lockerViewProof,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.black.withOpacity(0.35)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _ExpenseStatusBadge extends StatelessWidget {
  final String status;

  const _ExpenseStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = status.toLowerCase();
    late Color bg;
    late String label;
    if (s == 'posted' || s == 'approved') {
      bg = Colors.green.shade700;
      label = l10n.lockerStatusPosted;
    } else if (s == 'rejected') {
      bg = Colors.red.shade700;
      label = l10n.lockerStatusRejected;
    } else {
      bg = const Color(0xFF1E293B);
      label = l10n.lockerStatusPending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  final Color bg;
  final IconData icon;

  const _Banner({
    required this.message,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String message;

  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              child: Icon(Icons.wifi_off_rounded, size: 40, color: Colors.red.shade400),
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.lockerRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

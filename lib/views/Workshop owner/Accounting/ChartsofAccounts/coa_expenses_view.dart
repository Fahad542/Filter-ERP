import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../data/repositories/owner_repository.dart';
import '../../../../services/LocalizedApiText.dart';
import '../../../../services/owner_data_service.dart';
import '../../../../services/session_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import '../../../../widgets/pos_shimmer.dart';
import '../../../Workshop Owner/widgets/owner_app_bar.dart';
import '../../Reports/reports_search_bar.dart';
import '../../owner_shell.dart';
import '../../widgets/owner_branch_reload_registrar.dart';
import '../../widgets/owner_list_style.dart';
import '../../widgets/owner_shimmer.dart';
import '../../widgets/owner_ui_constants.dart';
import 'coa_expenses_view_model.dart';

/// Chart of Accounts → Expenses list (same API as web: GET /accounts?type=EXPENSE).
class CoaExpensesView extends StatefulWidget {
  const CoaExpensesView({super.key});

  @override
  State<CoaExpensesView> createState() => _CoaExpensesViewState();
}

class _CoaExpensesViewState extends State<CoaExpensesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CoaExpensesViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: l10n.ownerExpenseTitle),
        showBackButton: false,
        showNotification: true,
        onNotificationPressed: () => OwnerShell.goToNotifications(context),
        onMenuPressed: () => OwnerShell.openDrawer(context),
      ),
      body: Consumer<CoaExpensesViewModel>(
        builder: (context, vm, _) {
          final list = vm.accounts;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: ReportsSearchBar(
                  hint: l10n.ownerExpenseSearchHint,
                  onChanged: vm.setSearch,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.ownerExpenseTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.ownerExpenseAccountsCount(list.length),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    vm.error!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryLight,
                  onRefresh: vm.refresh,
                  child: vm.isLoading && list.isEmpty
                      ? const _ExpensesListShimmer()
                      : list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
                                ),
                                Center(
                                  child: Text(
                                    vm.search.isNotEmpty
                                        ? 'No results for "${vm.search}"'
                                        : 'No expense accounts',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: list.length,
                              itemBuilder: (_, i) =>
                                  _ExpenseAccountCard(account: list[i]),
                            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpensesListShimmer extends StatelessWidget {
  const _ExpensesListShimmer();

  @override
  Widget build(BuildContext context) {
    return PosShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: 8,
        itemBuilder: (_, i) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: OwnerCardRowShimmer(),
        ),
      ),
    );
  }
}

class CoaExpensesShellTab extends StatelessWidget {
  const CoaExpensesShellTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CoaExpensesViewModel(
        ownerRepository: ctx.read<OwnerRepository>(),
        sessionService: ctx.read<SessionService>(),
        ownerDataService: ctx.read<OwnerDataService>(),
      ),
      child: OwnerBranchReloadRegistrar(
        tabIndex: 36,
        onReload: (ctx) =>
            ctx.read<CoaExpensesViewModel>().syncWithSelectedBranch(),
        child: const CoaExpensesView(),
      ),
    );
  }
}

class _ExpenseAccountCard extends StatelessWidget {
  final CoaExpenseAccount account;
  const _ExpenseAccountCard({required this.account});

  static String _debitSuffix(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? 'مدين' : 'Dr';

  static String _creditSuffix(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? 'دائن' : 'Cr';

  static String _formatBalance(BuildContext context, CoaExpenseAccount a) {
    if (a.isDebitBalance) {
      return '${ownerFormatMoney(context, a.closingDebit)} ${_debitSuffix(context)}';
    }
    if (a.isCreditBalance) {
      return '${ownerFormatMoney(context, a.closingCredit)} ${_creditSuffix(context)}';
    }
    return '—';
  }

  static String _subtypeLabel(BuildContext context, CoaExpenseAccount a) {
    final l10n = AppLocalizations.of(context)!;
    if (a.subType.toUpperCase() == 'OPERATING_EXPENSE') {
      return l10n.ownerExpenseOperating;
    }
    return a.subtypeLabel;
  }

  static String _branchMeta(BuildContext context, CoaExpenseAccount a) {
    final l10n = AppLocalizations.of(context)!;
    if (a.branchLabel == 'Shared' && a.normalBalance == 'Debit') {
      return l10n.ownerExpenseSharedDebit;
    }
    return '${a.branchLabel} · ${a.normalBalance}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = account;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: OwnerListStyle.cardRadius,
          border: Border.all(color: OwnerListStyle.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OwnerListIconBox(
                icon: Icons.money_off_rounded,
                showActiveDot: a.isActive,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        if (a.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.ownerCommonActive,
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LocalizedApiText(
                          a.name,
                          style: OwnerListStyle.titleStyle
                              .copyWith(fontSize: 14.5),
                        ),
                        if (a.isAutoLinked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.ownerExpenseAutoLinked,
                              style: const TextStyle(
                                color: Color(0xFF92620A),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (a.isControl)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Control',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (a.description != null &&
                        a.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        a.description!,
                        style: OwnerListStyle.subtitleStyle.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 11.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatBalance(context, a),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _Meta(
                      icon: Icons.category_outlined,
                      text: _subtypeLabel(context, a),
                    ),
                    _Meta(
                      icon: Icons.account_balance_outlined,
                      text: _branchMeta(context, a),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: OwnerListStyle.mutedText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: OwnerListStyle.metaStyle.copyWith(fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

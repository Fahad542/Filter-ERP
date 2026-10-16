import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop Owner/widgets/reusable_kpi_grid.dart';
import '../../widgets/owner_shimmer.dart';
import '../accounting_models.dart';
import 'accounting_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChartOfAccountsTab
// ─────────────────────────────────────────────────────────────────────────────

class ChartOfAccountsTab extends StatelessWidget {
  const ChartOfAccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountingViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const OwnerListPageShimmer(showKpi: true, itemCount: 6);
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── KPI Grid (ReusableKpiGrid, showFeatured=false, 3 cols) ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ReusableKpiGrid(
                  showFeatured: false,
                  crossAxisCount: 3,
                  childAspectRatio: 1.55,
                  metrics: [
                    ReusableKpiMetric(
                      title: 'Assets',
                      value: '${vm.countByType(AccountType.assets)}',
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () => vm.setFilterType(
                          vm.filterType == AccountType.assets ? null : AccountType.assets),
                    ),
                    ReusableKpiMetric(
                      title: 'Liabilities',
                      value: '${vm.countByType(AccountType.liabilities)}',
                      icon: Icons.receipt_long_outlined,
                      onTap: () => vm.setFilterType(
                          vm.filterType == AccountType.liabilities ? null : AccountType.liabilities),
                    ),
                    ReusableKpiMetric(
                      title: 'Equity',
                      value: '${vm.countByType(AccountType.equity)}',
                      icon: Icons.pie_chart_outline_rounded,
                      onTap: () => vm.setFilterType(
                          vm.filterType == AccountType.equity ? null : AccountType.equity),
                    ),
                    ReusableKpiMetric(
                      title: 'Revenue',
                      value: '${vm.countByType(AccountType.revenue)}',
                      icon: Icons.trending_up_rounded,
                      onTap: () => vm.setFilterType(
                          vm.filterType == AccountType.revenue ? null : AccountType.revenue),
                    ),
                    ReusableKpiMetric(
                      title: 'Expenses',
                      value: '${vm.countByType(AccountType.expenses)}',
                      icon: Icons.money_off_rounded,
                      onTap: () => vm.setFilterType(
                          vm.filterType == AccountType.expenses ? null : AccountType.expenses),
                    ),
                    ReusableKpiMetric(
                      title: 'Total',
                      value: '${vm.allAccounts.length}',
                      icon: Icons.list_alt_rounded,
                      onTap: () => vm.setFilterType(null),
                    ),
                  ],
                ),
              ),
            ),

            // ── Active filter indicator ───────────────────────────────────
            if (vm.filterType != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _ActiveFilterChip(
                    label: _typeLabel(vm.filterType!),
                    onClear: () => vm.setFilterType(null),
                  ),
                ),
              ),

            // ── Search ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _SearchBar(vm: vm),
              ),
            ),

            // ── Note ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                child: Text(
                  'Tap any account row to open its ledger. Final balance from posted journals.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

            // ── Account groups ────────────────────────────────────────────
            if (vm.groupedAccounts.isEmpty)
              const SliverFillRemaining(child: _EmptySearchState())
            else
              ..._buildGroupSlivers(context, vm),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  List<Widget> _buildGroupSlivers(BuildContext context, AccountingViewModel vm) {
    final groups = vm.groupedAccounts;
    final result = <Widget>[];

    for (final type in AccountType.values) {
      final accounts = groups[type];
      if (accounts == null || accounts.isEmpty) continue;

      result.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: _GroupHeader(type: type, count: accounts.length),
        ),
      ));

      result.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: accounts.length,
          itemBuilder: (ctx, i) => _AccountCard(account: accounts[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 6),
        ),
      ));
    }

    return result;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _typeLabel(AccountType t) {
  switch (t) {
    case AccountType.assets: return 'Assets';
    case AccountType.liabilities: return 'Liabilities';
    case AccountType.equity: return 'Equity';
    case AccountType.revenue: return 'Revenue';
    case AccountType.expenses: return 'Expenses';
  }
}

// ─── Active Filter Chip ───────────────────────────────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _ActiveFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 11, color: AppColors.secondaryLight.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLight,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 12, color: AppColors.secondaryLight.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final AccountingViewModel vm;
  const _SearchBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: vm.updateSearchQuery,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryLight),
        decoration: InputDecoration(
          hintText: 'Search by code or name…',
          hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
          prefixIcon:
          Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
        ),
      ),
    );
  }
}

// ─── Group Header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final AccountType type;
  final int count;

  const _GroupHeader({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _typeLabel(type).toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.secondaryLight,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count accounts',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryLight.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Card — clean, theme-consistent, all info visible
// ─────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final ChartAccount account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final isChild = account.parentCode != null;
    final hasBalance =
        account.finalBalance != null && account.finalBalance! > 0;

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: isChild
            ? const EdgeInsets.only(left: 14)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChild
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top row: code | name + badge | balance + edit ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isChild)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            size: 10,
                            color: AppColors.primaryLight.withValues(alpha: 0.7),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          account.code,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Name + auto-linked badge + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                account.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondaryLight,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (account.isAutoLinked) ...[
                              const SizedBox(width: 6),
                              _AutoLinkedBadge(),
                            ],
                          ],
                        ),
                        if (account.description != null &&
                            account.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            account.description!,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.grey.shade400,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Right: balance + edit
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Edit button
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(Icons.edit_outlined,
                              size: 13, color: Colors.grey.shade500),
                        ),
                      ),
                      if (hasBalance) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${account.finalBalance!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        Text(
                          account.isCredit ? 'SAR Cr' : 'SAR Dr',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: account.isCredit
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(
                          '—',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade300),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom meta strip ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.secondaryLight.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14)),
                border: Border(
                    top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  _MetaTag(
                    icon: Icons.category_outlined,
                    label: account.subtype,
                  ),
                  const SizedBox(width: 10),
                  _MetaTag(
                    icon: Icons.store_outlined,
                    label: account.branch,
                  ),
                  const SizedBox(width: 10),
                  _MetaTag(
                    icon: Icons.swap_horiz_rounded,
                    label: account.normalBalance,
                  ),
                  const Spacer(),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: account.isActive
                          ? AppColors.primaryLight.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      account.isActive ? 'active' : 'inactive',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: account.isActive
                            ? AppColors.secondaryLight
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoLinkedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'Auto-linked',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryLight.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              'No accounts found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
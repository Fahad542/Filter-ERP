import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/cashier_cash_collection_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../utils/pos_tablet_layout.dart';
import '../../../widgets/pos_filter_tab_dropdown.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_widgets.dart';
import 'cash_collection_view_model.dart';

class PosCashCollectionView extends StatefulWidget {
  const PosCashCollectionView({super.key});

  @override
  State<PosCashCollectionView> createState() => _PosCashCollectionViewState();
}

class _PosCashCollectionViewState extends State<PosCashCollectionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<CashCollectionViewModel>();
      if (vm.hasRawItems || vm.loading) return;
      vm.load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<CashCollectionViewModel>();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: PosScreenAppBar(
          title: l10n.posNavCashCollection,
          showBackButton: false,
          showHamburger: true,
          onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
        ),
        body: wrapPosShellRailBody(
          context,
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildDateFilter(context, vm, l10n),
              ),
              Expanded(child: _buildBody(context, vm, l10n)),
              if (!vm.showInitialShimmer) _buildBottomBar(vm, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(
    BuildContext context,
    CashCollectionViewModel vm,
    AppLocalizations l10n,
  ) {
    String label(DateTime? d, String empty) {
      if (d == null) return empty;
      return DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString())
          .format(d);
    }

    Future<void> pick({required bool isFrom}) async {
      final initial = (isFrom ? vm.fromDate : vm.toDate) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked == null) return;
      if (isFrom) {
        await vm.setFromDate(picked);
      } else {
        await vm.setToDate(picked);
      }
    }

    Widget chip({
      required String title,
      required String value,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: PosFilterTabDropdown.dateChipHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2124),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          title: l10n.posClosingHistoryFrom,
          value: label(vm.fromDate, '—'),
          onTap: () => pick(isFrom: true),
        ),
        const SizedBox(width: 8),
        chip(
          title: l10n.posClosingHistoryTo,
          value: label(vm.toDate, '—'),
          onTap: () => pick(isFrom: false),
        ),
        const SizedBox(width: 8),
        PosFilterTabDropdown(
          selectedId: switch (vm.filter) {
            CashCollectionFilter.all => 'all',
            CashCollectionFilter.pending => 'pending',
            CashCollectionFilter.collected => 'collected',
          },
          options: [
            PosFilterTabOption(
              id: 'all',
              label: l10n.posClosingHistoryTabAll,
              count: vm.allCount,
            ),
            PosFilterTabOption(
              id: 'pending',
              label: l10n.posCashCollectionPending,
              count: vm.pendingCount,
            ),
            PosFilterTabOption(
              id: 'collected',
              label: l10n.posCashCollectionCollected,
              count: vm.collectedCount,
            ),
          ],
          onSelected: (id) {
            vm.setFilter(switch (id) {
              'pending' => CashCollectionFilter.pending,
              'collected' => CashCollectionFilter.collected,
              _ => CashCollectionFilter.all,
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(CashCollectionViewModel vm, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.posCashCollectionCollected}: ${l10n.ownerCurrencySar} ${vm.totalCollected.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.onSecondaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${l10n.posCashCollectionBalance}: ${l10n.ownerCurrencySar} ${vm.balance.toStringAsFixed(2)} · ${l10n.techSelectedDateRange}',
                      style: TextStyle(
                        color: AppColors.onSecondaryLight.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildBody(
    BuildContext context,
    CashCollectionViewModel vm,
    AppLocalizations l10n,
  ) {
    if (vm.showInitialShimmer) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 152,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const _CashCollectionShimmerCard(),
      );
    }

    if (vm.error != null && !vm.hasRawItems) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vm.error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => vm.load(refresh: true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                ),
                child: Text(l10n.posClosingHistoryRetry),
              ),
            ],
          ),
        ),
      );
    }

    final visible = vm.items;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          l10n.posCashCollectionEmpty,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: () => vm.load(refresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 152,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) => _CashCollectionCard(
          item: visible[index],
          l10n: l10n,
        ),
      ),
    );
  }
}

class _CashCollectionCard extends StatelessWidget {
  const _CashCollectionCard({required this.item, required this.l10n});

  final CashierCashCollectionItem item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = item.closedAt ?? item.createdAt;
    final dateLabel = date == null
        ? '—'
        : DateFormat('dd MMM yyyy · hh:mm a', locale).format(date);
    final statusColor =
        item.isCollected ? const Color(0xFF15803D) : const Color(0xFFEA580C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.secondaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.referenceCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF1E2124),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.isCollected
                      ? l10n.posCashCollectionCollected
                      : l10n.posCashCollectionPending,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          _kv(l10n.posCashCollectionExpected, item.expectedAmount),
          const SizedBox(height: 4),
          _kv(l10n.posCashCollectionCollected, item.collectedAmount, green: true),
          const SizedBox(height: 4),
          _kv(l10n.posCashCollectionBalance, item.balance, emphasize: true),
        ],
      ),
    );
  }

  Widget _kv(String label, double amount, {bool green = false, bool emphasize = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: emphasize ? const Color(0xFF1E2124) : Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          'SAR ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: green
                ? const Color(0xFF2E7D32)
                : emphasize
                    ? const Color(0xFF1E2124)
                    : const Color(0xFF1E2124),
          ),
        ),
      ],
    );
  }
}

class _CashCollectionShimmerCard extends StatelessWidget {
  const _CashCollectionShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PosShimmerBox(width: 36, height: 36, radius: 10),
                SizedBox(width: 10),
                Expanded(child: PosShimmerBox(width: 90, height: 12, radius: 6)),
                PosShimmerBox(width: 52, height: 18, radius: 8),
              ],
            ),
            SizedBox(height: 14),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
            SizedBox(height: 10),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
            SizedBox(height: 10),
            PosShimmerBox(width: double.infinity, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

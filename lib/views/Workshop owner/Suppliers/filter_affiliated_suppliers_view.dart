import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/toast_service.dart';
import '../../Workshop owner/Suppliers/add_affiliated_suppliers_screen.dart';
import '../../Workshop owner/Suppliers/affiliated_supplier_ledger_view.dart';
import '../../Workshop owner/Suppliers/affiliated_suppliers_view_model.dart';
import '../../Workshop owner/Suppliers/filter_affiliated_suppliers_models.dart';
import '../owner_shell.dart';
import '../widgets/owner_app_bar.dart';
import '../widgets/owner_list_style.dart';
import '../widgets/reusable_kpi_grid.dart';
import '../widgets/owner_shimmer.dart';

class FilterAffiliatedSuppliersView extends StatefulWidget {
  // Passed in directly (instead of pulled from a Provider above this widget)
  // so this screen works regardless of where it's opened from — no ancestor
  // ChangeNotifierProvider<AffiliatedSuppliersViewModel> required.
  final AffiliatedSuppliersViewModel viewModel;

  const FilterAffiliatedSuppliersView({super.key, required this.viewModel});

  @override
  State<FilterAffiliatedSuppliersView> createState() =>
      _FilterAffiliatedSuppliersViewState();
}

class _FilterAffiliatedSuppliersViewState
    extends State<FilterAffiliatedSuppliersView> {
  AffiliatedSuppliersViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) vm.syncWithSelectedBranch(force: true);
    });
  }

  Future<void> _refresh() => vm.refresh();

  Future<void> _openAddScreen() async {
    // Navigator.push builds the new route in the Navigator's Overlay, which
    // sits OUTSIDE this screen's widget tree — so we explicitly re-provide
    // the same ViewModel instance via ChangeNotifierProvider.value so the
    // pushed screen can find it via context.read/watch.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: AddAffiliatedSuppliersScreen(
            onAdd: (selected) {
              // The view model already refreshes the list internally after a
              // successful create call, so just confirm to the user here.
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selected.length == 1
                        ? '1 supplier added successfully.'
                        : '${selected.length} suppliers added successfully.',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openLedger(AffiliatedSupplier supplier) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: AffiliatedSupplierLedgerView(supplier: supplier),
        ),
      ),
    )
        .then((_) {
      // Balances may have changed while the ledger screen was open
      // (e.g. date range tied to new invoices) — keep the list in sync.
      if (mounted) vm.refresh();
    });
  }

  Future<void> _setActive(AffiliatedSupplier supplier, bool value) async {
    final ok = await vm.setSupplierActive(supplier, value);
    if (!ok && mounted) {
      ToastService.showError(context, 'Failed to update supplier status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds this subtree whenever the ViewModel calls
    // notifyListeners() — same effect as context.watch<T>(), but without
    // needing an ancestor Provider<AffiliatedSuppliersViewModel>.
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final suppliers = vm.suppliers;

        // ── KPI metrics using ReusableKpiGrid ──────────────────────────────
        final kpiMetrics = [
          ReusableKpiMetric(
            title: l10n.ownerAffiliatedPayable,
            value: formatKpiAmount(vm.aggregatePayable, context: context),
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppColors.primaryLight,
          ),
          ReusableKpiMetric(
            title: l10n.ownerAffiliatedTotal,
            value: ownerLocalizeDigits(context, '${suppliers.length}'),
            icon: Icons.storefront_rounded,
            accentColor: AppColors.primaryLight,
          ),
          ReusableKpiMetric(
            title: l10n.ownerAffiliatedActive,
            value: ownerLocalizeDigits(
              context,
              '${suppliers.where((s) => s.isActive).length}',
            ),
            icon: Icons.verified_rounded,
            accentColor: AppColors.primaryLight,
          ),
        ];

        return Scaffold(
          backgroundColor: OwnerUi.scaffoldBackground,
          appBar: OwnerAppBar(
            title: OwnerDashboardTitle(subtitle: l10n.ownerAffiliatedTitle),
            showDrawer: true,
            showBackButton: false,
            showNotification: false,
            onMenuPressed: () => OwnerShell.openDrawer(context),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddScreen,
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.secondaryLight,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              l10n.ownerAffiliatedAdd,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
          ),
          body: vm.isLoading && suppliers.isEmpty
              ? const OwnerListPageShimmer(showKpi: true, showFeaturedKpi: true)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReusableKpiGrid(
                      layout: KpiGridLayout.singleRow,
                      metrics: kpiMetrics,
                      showFeatured: false,
                      iconOnTop: true,
                      mainAxisExtent: 108,
                      singleRowCardWidth: 112,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primaryLight,
                        onRefresh: _refresh,
                        child: vm.loadError != null && suppliers.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: [
                                  _ErrorState(
                                      message: vm.loadError!,
                                      onRetry: _refresh),
                                ],
                              )
                            : suppliers.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      _EmptyAffiliatedSuppliersState(),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 110),
                                    itemCount: suppliers.length,
                                    itemBuilder: (context, index) {
                                      final supplier = suppliers[index];
                                      return _AffiliatedSupplierCard(
                                        serial: index + 1,
                                        supplier: supplier,
                                        onOpenLedger: () =>
                                            _openLedger(supplier),
                                        onActiveChanged: (v) =>
                                            _setActive(supplier, v),
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 44, color: Colors.red.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Card List ───────────────────────────────────────────────────────────────

class _AffiliatedSupplierCard extends StatelessWidget {
  final int serial;
  final AffiliatedSupplier supplier;
  final VoidCallback onOpenLedger;
  final ValueChanged<bool> onActiveChanged;

  const _AffiliatedSupplierCard({
    required this.serial,
    required this.supplier,
    required this.onOpenLedger,
    required this.onActiveChanged,
  });

  void _openActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AffiliatedSupplierActionsSheet(
        supplier: supplier,
        onOpenLedger: () {
          Navigator.pop(ctx);
          onOpenLedger();
        },
        onActiveChanged: onActiveChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = supplier.isActive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: OwnerListStyle.cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: OwnerListStyle.cardRadius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DecoratedBox(
                        decoration: OwnerListStyle.iconBoxDecoration,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primaryLight,
                            size: 18,
                          ),
                        ),
                      ),
                      if (active)
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43A047),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LocalizedApiText(
                              supplier.name,
                              style: OwnerListStyle.titleStyle
                                  .copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openActionsSheet(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 22,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        ownerFormatMoney(context, supplier.finalBalance),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _MetaGrid(
                        children: [
                          _MetaLine(
                            icon: Icons.tag_rounded,
                            text: l10n.ownerAffiliatedSNo(serial),
                          ),
                          _MetaLine(
                            icon: Icons.store_outlined,
                            text: supplier.branch,
                            localize: true,
                          ),
                          _MetaLine(
                            icon: Icons.account_balance_wallet_outlined,
                            text: l10n.ownerAffiliatedOpening(
                              ownerFormatMoney(context, supplier.openingBalance),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AffiliatedSupplierActionsSheet extends StatefulWidget {
  final AffiliatedSupplier supplier;
  final VoidCallback onOpenLedger;
  final ValueChanged<bool> onActiveChanged;

  const _AffiliatedSupplierActionsSheet({
    required this.supplier,
    required this.onOpenLedger,
    required this.onActiveChanged,
  });

  @override
  State<_AffiliatedSupplierActionsSheet> createState() =>
      _AffiliatedSupplierActionsSheetState();
}

class _AffiliatedSupplierActionsSheetState
    extends State<_AffiliatedSupplierActionsSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = widget.supplier.isActive;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LocalizedApiText(
                  widget.supplier.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ListTile(
              onTap: widget.onOpenLedger,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                AppLocalizations.of(context)!.ownerShellLedger,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLight,
                ),
              ),
              trailing:
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      active ? l10n.ownerCommonActiveLabel : l10n.ownerCommonInactive,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                  ),
                  Switch(
                    value: active,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF43A047),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (v) {
                      widget.onActiveChanged(v);
                      setState(() {});
                    },
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

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) {
      if (w is _MetaLine) {
        final t = w.text.trim();
        return t.isNotEmpty && t != '—';
      }
      return true;
    }).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i += 2) {
      final left = visible[i];
      final right = i + 1 < visible.length ? visible[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < visible.length ? 2 : 0),
          child: Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 8),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    this.localize = false,
  });

  final IconData icon;
  final String text;
  final bool localize;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty || text == '—') return const SizedBox.shrink();
    final style = OwnerListStyle.metaStyle.copyWith(fontSize: 11.5);
    return Row(
      children: [
        Icon(icon, size: 12, color: OwnerListStyle.mutedText),
        const SizedBox(width: 4),
        Expanded(
          child: localize
              ? LocalizedApiText(
                  text,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  text,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}

class _EmptyAffiliatedSuppliersState extends StatelessWidget {
  const _EmptyAffiliatedSuppliersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No affiliated suppliers yet',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
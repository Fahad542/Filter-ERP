import 'package:flutter/material.dart';

import '../../../../data/repositories/owner_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/LocalizedApiText.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/owner_l10n_helpers.dart';
import '../../widgets/owner_ui_constants.dart';
import '../../../../utils/app_text_styles.dart';
import '../../../Workshop owner/Suppliers/non_affiliated/add_non_affiliated_supplier_dialog.dart';
import '../../../Workshop owner/Suppliers/non_affiliated/non_affiliated_supplier_ledger_view.dart';
import '../../../Workshop owner/Suppliers/non_affiliated/non_affilidated_supplier_models.dart';
import '../../../Workshop owner/owner_shell.dart';
import '../../../Workshop owner/widgets/owner_app_bar.dart';
import '../../../Workshop owner/widgets/owner_list_style.dart';
import '../../../Workshop owner/widgets/reusable_kpi_grid.dart';
import '../../../Workshop owner/widgets/owner_shimmer.dart';

class NonAffiliatedSuppliersView extends StatefulWidget {
  /// Auth token for the workshop-owner session. Wire this to whatever the
  /// rest of the app uses to obtain it (e.g. an AuthProvider / SessionStore)
  /// if it isn't already passed in by the caller.
  final String token;

  /// Branch new suppliers get created under. Wire this to the workshop's
  /// currently active/selected branch if you have one; leave null for a
  /// workshop-wide supplier (if your backend allows that).
  final String? defaultBranchId;

  /// Header branch scope for the list API (`null` = all branches).
  final String? branchId;

  const NonAffiliatedSuppliersView({
    super.key,
    required this.token,
    this.defaultBranchId,
    this.branchId,
  });

  @override
  State<NonAffiliatedSuppliersView> createState() =>
      _NonAffiliatedSuppliersViewState();
}

class _NonAffiliatedSuppliersViewState
    extends State<NonAffiliatedSuppliersView> {
  final _repo = NonAffiliatedSuppliersRepository();

  late Future<NonAffiliatedSuppliersResponse> _future;
  List<NonAffiliatedSupplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant NonAffiliatedSuppliersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId ||
        oldWidget.token != widget.token) {
      _future = _load(force: true);
    }
  }

  Future<NonAffiliatedSuppliersResponse> _load({bool force = false}) async {
    final res = await _repo.getSuppliers(
      widget.token,
      branchId: widget.branchId ?? widget.defaultBranchId,
      forceRefresh: force,
    );
    if (mounted) {
      setState(() => _suppliers = res.suppliers);
    } else {
      _suppliers = res.suppliers;
    }
    return res;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load(force: true));
    await _future;
  }

  double get _aggregatePayable =>
      _suppliers.fold(0, (sum, s) => sum + s.finalBalance);

  Future<void> _openAddDialog() async {
    final created = await showDialog<NonAffiliatedSupplier>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddNonAffiliatedSupplierDialog(
        token: widget.token,
        repo: _repo,
        defaultBranchId: widget.defaultBranchId,
      ),
    );
    if (created != null) {
      await _refresh();
    }
  }

  Future<void> _editSupplier(NonAffiliatedSupplier supplier) async {
    final updated = await showDialog<NonAffiliatedSupplier>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddNonAffiliatedSupplierDialog(
        token: widget.token,
        repo: _repo,
        editing: supplier,
      ),
    );
    if (updated != null) {
      await _refresh();
    }
  }

  void _openLedger(NonAffiliatedSupplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NonAffiliatedSupplierLedgerView(
          supplier: supplier,
          token: widget.token,
          repo: _repo,
        ),
      ),
    );
  }

  Future<void> _toggleActive(NonAffiliatedSupplier supplier, bool value) async {
    // Optimistic update — instant feedback even on a slow connection.
    setState(() => supplier.isActive = value);
    try {
      await _repo.toggleActive(widget.token, id: supplier.id, isActive: value);
    } catch (e) {
      // Revert on failure and tell the user.
      if (!mounted) return;
      setState(() => supplier.isActive = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: OwnerUi.scaffoldBackground,
      appBar: OwnerAppBar(
        title: OwnerDashboardTitle(subtitle: l10n.ownerNonAffiliatedTitle),
        showDrawer: true,
        showBackButton: false,
        showNotification: false,
        onMenuPressed: () => OwnerShell.openDrawer(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.secondaryLight,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          l10n.ownerNonAffiliatedAdd,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryLight,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        onRefresh: _refresh,
        child: FutureBuilder<NonAffiliatedSuppliersResponse>(
          future: _future,
          builder: (context, snapshot) {
            final l10n = AppLocalizations.of(context)!;
            final isFirstLoad =
                snapshot.connectionState == ConnectionState.waiting &&
                    _suppliers.isEmpty;

            if (isFirstLoad) {
              return const _LoadingState();
            }

            if (snapshot.hasError && _suppliers.isEmpty) {
              return _ErrorState(
                message: '${snapshot.error}',
                onRetry: _refresh,
              );
            }

            final kpiMetrics = [
              ReusableKpiMetric(
                title: l10n.ownerAffiliatedPayable,
                value: formatKpiAmount(_aggregatePayable, context: context),
                icon: Icons.account_balance_wallet_rounded,
                accentColor: AppColors.primaryLight,
              ),
              ReusableKpiMetric(
                title: l10n.ownerAffiliatedTotal,
                value: ownerLocalizeDigits(context, '${_suppliers.length}'),
                icon: Icons.storefront_rounded,
                accentColor: AppColors.primaryLight,
              ),
              ReusableKpiMetric(
                title: l10n.ownerAffiliatedActive,
                value: ownerLocalizeDigits(
                  context,
                  '${_suppliers.where((s) => s.isActive).length}',
                ),
                icon: Icons.verified_rounded,
                accentColor: AppColors.primaryLight,
              ),
            ];

            return Column(
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
                  child: _suppliers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [_EmptyState()],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          itemCount: _suppliers.length,
                          itemBuilder: (context, index) {
                            final s = _suppliers[index];
                            return _SupplierCard(
                              key: ValueKey(s.id),
                              serial: index + 1,
                              supplier: s,
                              onOpenLedger: () => _openLedger(s),
                              onEdit: () => _editSupplier(s),
                              onActiveChanged: (v) =>
                                  _toggleActive(s, v),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Loading / error states ─────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const OwnerListPageShimmer(showKpi: true, showSearch: true);
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "Couldn't load suppliers",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card List ───────────────────────────────────────────────────────────────

class _SupplierCard extends StatelessWidget {
  final int serial;
  final NonAffiliatedSupplier supplier;
  final VoidCallback onOpenLedger;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;

  const _SupplierCard({
    super.key,
    required this.serial,
    required this.supplier,
    required this.onOpenLedger,
    required this.onEdit,
    required this.onActiveChanged,
  });

  void _openActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SupplierActionsSheet(
        supplier: supplier,
        onEdit: () {
          Navigator.pop(ctx);
          onEdit();
        },
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
                              supplier.openingBalance.toStringAsFixed(2),
                            ),
                          ),
                          if (supplier.mobile.isNotEmpty)
                            _MetaLine(
                              icon: Icons.phone_outlined,
                              text: supplier.mobile,
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

class _SupplierActionsSheet extends StatefulWidget {
  final NonAffiliatedSupplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onOpenLedger;
  final ValueChanged<bool> onActiveChanged;

  const _SupplierActionsSheet({
    required this.supplier,
    required this.onEdit,
    required this.onOpenLedger,
    required this.onActiveChanged,
  });

  @override
  State<_SupplierActionsSheet> createState() => _SupplierActionsSheetState();
}

class _SupplierActionsSheetState extends State<_SupplierActionsSheet> {
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
            _SupplierActionTile(
              label: 'Edit',
              onTap: widget.onEdit,
            ),
            _SupplierActionTile(
              label: 'Ledger',
              onTap: widget.onOpenLedger,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      active ? 'Active' : l10n.ownerCommonInactive,
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

class _SupplierActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SupplierActionTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryLight,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No non-affiliated suppliers yet',
            style: TextStyle(
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
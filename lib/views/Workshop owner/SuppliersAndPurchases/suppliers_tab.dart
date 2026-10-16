import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../../Workshop Owner/PurchaseInvoices/purchase_invoice_form_sheet.dart';
import '../widgets/owner_list_style.dart';
import 'suppliers_view_model.dart';

class SuppliersTab extends StatefulWidget {
  const SuppliersTab({super.key});

  @override
  State<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends State<SuppliersTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuppliersViewModel>();
    final query = _searchCtrl.text.trim().toLowerCase();
    final suppliers = vm.suppliersList.where((s) {
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.mobile.toLowerCase().contains(query) ||
          (s.vatNumber ?? '').toLowerCase().contains(query) ||
          s.category.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: vm.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SupplierSearchBar(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (suppliers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptySuppliersState(
                isFiltered: query.isNotEmpty,
                onClear: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _SupplierCard(supplier: suppliers[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SupplierSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SupplierSearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: l10n.ownerSuppliersSearchHint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon:
            Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color: Colors.grey.shade400, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.4),
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = supplier.status.toLowerCase() == 'active';
    final hasOutstanding = supplier.outstanding > 0;
    final category = supplier.category.trim().isEmpty
        ? l10n.ownerSuppliersRole
        : supplier.category;
    final subtitle = (supplier.contactPerson ?? '').trim().isNotEmpty
        ? supplier.contactPerson!.trim()
        : category;

    return DecoratedBox(
      decoration: OwnerListStyle.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: DecoratedBox(
                decoration: OwnerListStyle.iconBoxDecoration,
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
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
                        child: supplier.name.isEmpty
                            ? Text(
                                'Unknown supplier',
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : LocalizedApiText(
                                supplier.name,
                                style: OwnerListStyle.titleStyle
                                    .copyWith(fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0x38FCC247)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          isActive ? 'Active' : l10n.ownerCommonInactive,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.secondaryLight
                                : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          OwnerListStyle.subtitleStyle.copyWith(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasOutstanding) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Outstanding  ${ownerFormatMoney(context, supplier.outstanding)}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  _SupplierMetaGrid(
                    children: [
                      _SupplierMetaLine(
                        icon: Icons.phone_outlined,
                        text: supplier.mobile.trim().isEmpty
                            ? '—'
                            : supplier.mobile,
                      ),
                      _SupplierMetaLine(
                        icon: Icons.badge_outlined,
                        text: (supplier.crNumber ?? '').trim().isEmpty
                            ? '${l10n.ownerSuppliersCr} —'
                            : '${l10n.ownerSuppliersCr} ${supplier.crNumber}',
                      ),
                      _SupplierMetaLine(
                        icon: Icons.receipt_long_outlined,
                        text: (supplier.vatNumber ?? '').trim().isEmpty
                            ? '${l10n.ownerSuppliersVat} —'
                            : '${l10n.ownerSuppliersVat} ${supplier.vatNumber}',
                      ),
                      _SupplierMetaLine(
                        icon: Icons.sell_outlined,
                        text: category,
                        localize: supplier.category.trim().isNotEmpty,
                      ),
                      if ((supplier.email ?? '').trim().isNotEmpty)
                        _SupplierMetaLine(
                          icon: Icons.email_outlined,
                          text: supplier.email!,
                        ),
                      if ((supplier.address ?? '').trim().isNotEmpty)
                        _SupplierMetaLine(
                          icon: Icons.location_on_outlined,
                          text: supplier.address!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            _AddPurchaseAction(supplier: supplier),
          ],
        ),
      ),
    );
  }
}

class _SupplierMetaGrid extends StatelessWidget {
  const _SupplierMetaGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) {
      if (w is _SupplierMetaLine) return w.text.trim().isNotEmpty;
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

class _SupplierMetaLine extends StatelessWidget {
  const _SupplierMetaLine({
    required this.icon,
    required this.text,
    this.localize = false,
  });

  final IconData icon;
  final String text;
  final bool localize;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final style = OwnerListStyle.metaStyle.copyWith(fontSize: 12);
    return Row(
      children: [
        Icon(icon, size: 13, color: OwnerListStyle.mutedText),
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

class _AddPurchaseAction extends StatefulWidget {
  final Supplier supplier;
  const _AddPurchaseAction({required this.supplier});

  @override
  State<_AddPurchaseAction> createState() => _AddPurchaseActionState();
}

class _AddPurchaseActionState extends State<_AddPurchaseAction> {
  bool _loading = false;

  Future<void> _openSheet() async {
    if (_loading) return;
    setState(() => _loading = true);

    final vm = context.read<SuppliersViewModel>();
    final branchId = await vm.getDefaultBranchId();

    if (!mounted) return;

    await showNewPurchaseInvoiceSheet(
      context,
      initialSupplier: widget.supplier,
      initialBranchId: branchId,
    );

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _loading
              ? AppColors.secondaryLight.withValues(alpha: 0.6)
              : AppColors.secondaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 16,
              ),
      ),
    );
  }
}

class _EmptySuppliersState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onClear;

  const _EmptySuppliersState({
    required this.isFiltered,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 22),
          decoration: OwnerListStyle.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.storefront_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                isFiltered
                    ? 'No suppliers match your search'
                    : 'No suppliers yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear search'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

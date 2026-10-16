import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workshop_owner_models.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/owner_l10n_helpers.dart';
import '../widgets/owner_ui_constants.dart';
import '../widgets/owner_styled_dropdown.dart';
import '../../../utils/app_text_styles.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../services/owner_data_service.dart';
import '../../../services/session_service.dart';
import 'purchase_invoices_view_model.dart';

/// Reusable New Purchase Invoice sheet.
/// Can be opened from Purchase Invoices screen, Inventory, or a Supplier card.
///
/// Pass [initialSupplier] and [initialBranchId] to have supplier + branch
/// pre-selected when opening from a Supplier card.
///
/// ## Fast-open strategy
/// The sheet opens immediately while the VM initialises in the background.
/// The sheet shows a loading skeleton until [vm.isInitialised] is true, so
/// the bottom-sheet animation plays while data is fetching — perceived
/// open time drops from ~1-2 s to near-instant.
Future<void> showNewPurchaseInvoiceSheet(
    BuildContext context, {
      PurchaseInvoicesViewModel? existingVm,
      InvProduct? initialProduct,
      Supplier? initialSupplier,
      String? initialBranchId,
    }) async {
  if (!context.mounted) return;

  final ownsVm = existingVm == null;
  OwnerDataService? ownerData;
  try {
    ownerData = context.read<OwnerDataService>();
  } catch (_) {
    ownerData = null;
  }
  final vm = existingVm ??
      PurchaseInvoicesViewModel(
        repository: OwnerRepository(),
        sessionService: SessionService(),
        ownerDataService: ownerData,
      );

  // ── Kick off async init in parallel with the sheet open animation ─────────
  // We do NOT await here — the sheet skeleton shows while this runs.
  Future<void> initFuture = Future.value();
  if (ownsVm && !vm.isInitialised) {
    initFuture = vm.init().then((_) {
      vm.initNewInvoiceForm(branches: vm.branches);

      // Pre-select supplier from the card that was tapped
      if (initialSupplier != null) {
        vm.selectVendor(initialSupplier);
      }

      // Pre-select branch: prefer the one passed in, else default branch
      if (vm.branches.isNotEmpty) {
        final targetId = initialBranchId;
        final branch = targetId != null
            ? vm.branches.firstWhere(
              (b) => b.id == targetId,
          orElse: () => vm.branches.first,
        )
            : vm.branches.first;
        vm.selectBranch(branch);
      }

      // Pre-fill initial product line if provided
      if (initialProduct != null && vm.itemDrafts.isNotEmpty) {
        final draft = vm.itemDrafts.first;
        draft.productCtrl.text = initialProduct.name;
        draft.uom = initialProduct.unit;
        draft.priceCtrl.text = initialProduct.purchasePrice > 0
            ? initialProduct.purchasePrice.toStringAsFixed(2)
            : '';
        draft.lastSupplierPrice = initialProduct.purchasePrice > 0
            ? initialProduct.purchasePrice
            : null;
        vm.recalculate();
      }
    });
  } else {
    // Reusing an existing VM — can set up synchronously
    vm.initNewInvoiceForm(branches: vm.branches);
    if (initialSupplier != null) vm.selectVendor(initialSupplier);
    if (initialBranchId != null && vm.branches.isNotEmpty) {
      final branch = vm.branches.firstWhere(
            (b) => b.id == initialBranchId,
        orElse: () => vm.branches.first,
      );
      vm.selectBranch(branch);
    }
    if (initialProduct != null && vm.itemDrafts.isNotEmpty) {
      final draft = vm.itemDrafts.first;
      draft.productCtrl.text = initialProduct.name;
      draft.uom = initialProduct.unit;
      draft.priceCtrl.text = initialProduct.purchasePrice > 0
          ? initialProduct.purchasePrice.toStringAsFixed(2)
          : '';
      draft.lastSupplierPrice = initialProduct.purchasePrice > 0
          ? initialProduct.purchasePrice
          : null;
      vm.recalculate();
    }
  }

  // ── Show the sheet immediately — don't await init ─────────────────────────
  final sheet = NewPurchaseInvoiceSheet(
    initialSupplier: initialSupplier,
  );

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      if (ownsVm) {
        return ChangeNotifierProvider<PurchaseInvoicesViewModel>(
          create: (_) => vm,
          child: sheet,
        );
      }
      return ChangeNotifierProvider<PurchaseInvoicesViewModel>.value(
        value: vm,
        child: sheet,
      );
    },
  );

  // Silently swallow any init error — sheet is already closed by now
  await initFuture.catchError((_) {});
}


// Shared total row widget
class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool bold;
  final Color color;

  const _TotalRow(
      this.label,
      this.amount, {
        required this.currency,
        this.bold = false,
        this.color = Colors.black87,
      });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? AppColors.secondaryLight : Colors.grey.shade500)),
          Text(
            ownerFormatMoney(context, amount.abs(), currency: currency),
            style: AppTextStyles.bodySmall.copyWith(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color: color),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Loading skeleton — shown while VM.isInitialised == false (fast-open mode)
// =============================================================================

class _InvoiceLoadingSkeleton extends StatelessWidget {
  const _InvoiceLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier context chip
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.ownerPurchaseFormSettingUp,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ..._skeletonRows(4),
          const SizedBox(height: 20),
          _skeletonBox(height: 120),
          const SizedBox(height: 16),
          ..._skeletonRows(2),
        ],
      ),
    );
  }

  List<Widget> _skeletonRows(int count) => List.generate(count, (i) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skeletonBox(height: 10, width: 90),
        const SizedBox(height: 6),
        _skeletonBox(height: 44),
      ],
    ),
  ));

  Widget _skeletonBox({double height = 44, double? width}) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

// =============================================================================
// NewPurchaseInvoiceSheet  — single-scroll form (Header + Items + Footer)
// =============================================================================

class NewPurchaseInvoiceSheet extends StatefulWidget {
  /// Supplier passed from the card — shown in the title bar while loading.
  final Supplier? initialSupplier;

  const NewPurchaseInvoiceSheet({super.key, this.initialSupplier});

  @override
  State<NewPurchaseInvoiceSheet> createState() => _NewPurchaseInvoiceSheetState();
}

class _NewPurchaseInvoiceSheetState extends State<NewPurchaseInvoiceSheet> {
  @override
  Widget build(BuildContext context) {
    // NOTE: intentionally NOT using context.watch() here at the root.
    // Watching the whole VM forces the ENTIRE form to rebuild on every
    // keystroke. Small Consumer/Selector widgets below listen only to
    // the specific fields they render.
    final vm = context.read<PurchaseInvoicesViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: OwnerUi.sheetFormInitialSize,
      minChildSize: OwnerUi.sheetMinSize,
      maxChildSize: OwnerUi.sheetFormMaxSize,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // ── Title bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_rounded,
                        color: AppColors.secondaryLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.ownerPurchaseFormTitle,
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                        if (widget.initialSupplier != null)
                          Text(
                            widget.initialSupplier!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.grey.shade400, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Body: skeleton while loading, form when ready ──────────────
            Expanded(
              child: Selector<PurchaseInvoicesViewModel, bool>(
                selector: (_, vm) => vm.isInitialised,
                builder: (_, isReady, __) {
                  if (!isReady) return const _InvoiceLoadingSkeleton();
                  return ListView(
                    controller: ctrl,
                    padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      // ── Header section ──────────────────────────────────────
                      Consumer<PurchaseInvoicesViewModel>(
                        builder: (_, vm, __) => _buildHeaderSection(vm),
                      ),
                      const SizedBox(height: 20),

                      // ── Description field (doesn't need rebuilds — plain
                      // TextField driven by its own controller) ───────────────
                      _formField(
                        label: l10n.ownerPurchaseFormDescOptional,
                        icon: Icons.notes_rounded,
                        ctrl: vm.descCtrl,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),

                      // ── Items section label + add button ────────────────────
                      Row(
                        children: [
                          _sectionLabel(l10n.ownerPurchaseFormLineItems),
                          const Spacer(),
                          GestureDetector(
                            onTap: vm.addItemDraft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.secondaryLight.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      color: AppColors.secondaryLight, size: 15),
                                  const SizedBox(width: 4),
                                  Text(l10n.ownerPurchaseFormAddLine,
                                      style: const TextStyle(
                                          color: AppColors.secondaryLight,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Items as mobile cards ───────────────────────────────
                      // Selector on the draft count only: adding/removing a
                      // line rebuilds this block, but typing inside a line's
                      // own controllers does not bubble up here.
                      Selector<PurchaseInvoicesViewModel, int>(
                        selector: (_, vm) => vm.itemDrafts.length,
                        builder: (_, count, __) => Column(
                          children: List.generate(
                            count,
                                (i) => RepaintBoundary(
                              key: ValueKey('item_card_rb_$i'),
                              child: Selector<PurchaseInvoicesViewModel, String>(
                                selector: (_, vm) {
                                  if (i >= vm.itemDrafts.length) return '';
                                  final d = vm.itemDrafts[i];
                                  // productCtrl.text + priceCtrl.text included so that
                                  // selecting a product from the dropdown always triggers
                                  // a rebuild, even if uom/account/price happen to match
                                  // the previous draft's values.
                                  return '${d.productCtrl.text}|${d.priceCtrl.text}|'
                                      '${d.lineExcl}|${d.lineTax}|${d.lineIncl}|'
                                      '${d.uom}|${d.selectedAccount.code}|${d.selectedTaxCode.code}|'
                                      '${d.lastSupplierPrice}|${vm.showDescriptionColumn}|'
                                      '${vm.itemDrafts.length}';
                                },
                                builder: (_, __, ___) => _buildItemCard(vm, i),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tip banner — const, zero rebuilds
                      const _PurchaseTipBanner(),
                      const SizedBox(height: 12),

                      // Column toggles — using Wrap to avoid overflow
                      Consumer<PurchaseInvoicesViewModel>(
                        builder: (_, vm, __) => _buildColumnToggles(vm),
                      ),
                      const SizedBox(height: 20),

                      // ── Footer: Discount, Freight, Notes, Totals ────────────
                      Consumer<PurchaseInvoicesViewModel>(
                        builder: (_, vm, __) => _buildFooter(vm),
                      ),
                      const SizedBox(height: 12),

                      // AP banner — const, zero rebuilds
                      const _PurchaseApBanner(),
                      const SizedBox(height: 10),

                      // Update last purchase price checkbox
                      Selector<PurchaseInvoicesViewModel, bool>(
                        selector: (_, vm) => vm.updateLastPurchasePrice,
                        builder: (_, value, __) => _buildCheckboxTile(
                          label: AppLocalizations.of(context)!
                              .ownerPurchaseFormUpdateLastPrice,
                          value: value,
                          onChanged: vm.setUpdateLastPurchasePrice,
                          wrapLabel: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );            // end ListView
                },           // end Selector builder
              ),             // end Selector
            ),             // end Expanded
            // Bottom action buttons
            Consumer<PurchaseInvoicesViewModel>(
              builder: (_, vm, __) => _buildActionButtons(context, vm),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (Vendor, Branch, Issue date, Due days, Ref) ───────────────────

  Widget _buildHeaderSection(PurchaseInvoicesViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor dropdown
        _sectionLabel(l10n.ownerPurchaseFormSupplierVendor),
        _vendorDropdown(vm),
        const SizedBox(height: 12),

        // Branch dropdown — values from vm.branches (fetched on init)
        _sectionLabel(l10n.ownerPurchaseFormBranch),
        _buildBranchDropdown(vm),
        const SizedBox(height: 12),

        // Issue date row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(l10n.ownerPurchaseFormIssueDate),
                  _formField(
                    label: l10n.ownerPurchaseFormIssueDate,
                    icon: Icons.calendar_today_rounded,
                    ctrl: vm.issueDateCtrl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Due date type (Net / EOM / Custom) + computed due date
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(l10n.ownerPurchaseFormDueDate),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          child: _DueDateTypeDropdown(
                            value: vm.dueDateType,
                            onChanged: vm.setDueDateType,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (vm.dueDateType == DueDateType.net) ...[
                          Expanded(
                            child: _formField(
                              label: l10n.ownerPurchaseFormDays,
                              icon: Icons.timer_rounded,
                              ctrl: vm.dueDaysCtrl,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(l10n.ownerPurchaseFormDaysSuffix,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600)),
                        ] else if (vm.dueDateType ==
                            DueDateType.custom) ...[
                          Expanded(
                            child: _formField(
                              label: l10n.ownerPurchaseFormDueDate,
                              icon: Icons.event_rounded,
                              ctrl: vm.customDueDateCtrl,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      l10n.ownerPurchaseFormDueLabel(
                        ownerLocalizeDigits(context, vm.computedDueDate),
                      ),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Ref #
        _sectionLabel(l10n.ownerPurchaseFormRefOptional),
        _formField(
          label: l10n.ownerPurchaseFormVendorInv,
          icon: Icons.tag_rounded,
          ctrl: vm.refCtrl,
        ),
      ],
    );
  }

  Widget _vendorDropdown(PurchaseInvoicesViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerStyledDropdown<String>(
      value: vm.selectedVendorName.isNotEmpty ? vm.selectedVendorName : null,
      hint: l10n.ownerPurchaseFormSelectSupplier,
      height: 48,
      options: vm.suppliersList
          .map((s) => OwnerDropdownOption(value: s.name, label: s.name))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        final supplier = vm.suppliersList.firstWhere(
          (s) => s.name == v,
          orElse: () => Supplier(
            id: '',
            name: v,
            email: '',
            mobile: '',
            outstanding: 0,
            category: '',
          ),
        );
        // selectVendor is async — triggers last-prices + UOM fetch
        vm.selectVendor(supplier);
      },
      triggerStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }

  // ── Branch dropdown ────────────────────────────────────────────────────────

  Widget _buildBranchDropdown(PurchaseInvoicesViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerStyledDropdown<String>(
      value: vm.selectedBranchId.isNotEmpty ? vm.selectedBranchId : null,
      hint: vm.branches.isEmpty
          ? l10n.ownerPurchaseFormNoBranches
          : l10n.ownerPurchaseFormSelectBranch,
      height: 48,
      enabled: vm.branches.isNotEmpty,
      options: vm.branches
          .map((b) => OwnerDropdownOption(value: b.id, label: b.name))
          .toList(),
      onChanged: vm.branches.isEmpty
          ? null
          : (v) {
              if (v == null) return;
              final branch = vm.branches.firstWhere((b) => b.id == v);
              vm.selectBranch(branch);
            },
      triggerStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: vm.branches.isEmpty
            ? Colors.grey.shade400
            : AppColors.secondaryLight,
      ),
    );
  }

  // ── Item card (mobile-friendly vertical layout) ───────────────────────────

  Widget _buildItemCard(PurchaseInvoicesViewModel vm, int i) {
    final draft = vm.itemDrafts[i];
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header — item # + delete
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  l10n.ownerPurchaseFormItemN(
                    ownerLocalizeDigits(context, '${i + 1}'),
                  ),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => vm.removeItemDraft(i),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: vm.itemDrafts.length > 1
                        ? const Color(0xFFE53935)
                        : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Product search — autocomplete from pre-loaded products list
                _cardField(
                  label: l10n.ownerPurchaseFormProduct,
                  child: _ProductAutocomplete(
                    controller: draft.productCtrl,
                    products: vm.products,
                    onSelected: (product) => vm.selectProductForLine(i, product),
                    onChanged: (_) => vm.recalculate(),
                  ),
                ),
                const SizedBox(height: 10),

                // Account dropdown
                _cardField(
                  label: l10n.ownerPurchaseFormAccount,
                  child: _AccountDropdown(
                    value: draft.selectedAccount,
                    onChanged: (acc) => vm.setItemAccount(i, acc),
                  ),
                ),
                const SizedBox(height: 10),

                // Description (only if toggle enabled)
                if (vm.showDescriptionColumn) ...[
                  _cardField(
                    label: l10n.ownerPurchaseFormDescription,
                    child: _ItemTextField(
                      controller: draft.descriptionCtrl,
                      hint: l10n.ownerPurchaseFormDescriptionHint,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // QTY + UOM row
                Row(
                  children: [
                    Expanded(
                      child: _cardField(
                        label: l10n.ownerPurchaseFormQty,
                        child: _ItemTextField(
                          controller: draft.qtyCtrl,
                          hint: ownerLocalizeDigits(context, '1'),
                          isNumber: true,
                          textAlign: TextAlign.center,
                          onChanged: (_) => vm.recalculate(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _cardField(
                        label: l10n.ownerPurchaseFormUom,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            ownerLocalizedUnit(l10n, draft.uom),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Unit Price + Tax Code row
                Row(
                  children: [
                    Expanded(
                      child: _cardField(
                        label: l10n.ownerPurchaseFormUnitPriceExVat,
                        child: _ItemTextField(
                          controller: draft.priceCtrl,
                          hint: ownerLocalizeDigits(context, '0.00'),
                          isNumber: true,
                          textAlign: TextAlign.right,
                          onChanged: (_) => vm.recalculate(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _cardField(
                        label: l10n.ownerPurchaseFormTaxCode,
                        child: _TaxCodeDropdown(
                          value: draft.selectedTaxCode,
                          onChanged: (tc) => vm.setItemTaxCode(i, tc),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Calculated totals row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: OwnerUi.scaffoldBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.ownerPurchaseFormTotalExVat,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              ownerFormatMoney(context, draft.lineExcl,
                                  currency: vm.currency),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(l10n.ownerPurchaseFormTax,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              ownerFormatMoney(context, draft.lineTax,
                                  currency: vm.currency),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(l10n.ownerPurchaseFormTotalIncl,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              ownerFormatMoney(context, draft.lineIncl,
                                  currency: vm.currency),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Last from supplier
                if (draft.lastSupplierPrice != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.ownerPurchaseFormLastFromSupplier(
                        ownerFormatMoney(context, draft.lastSupplierPrice!,
                            currency: vm.currency),
                      ),
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small labeled wrapper for a form field inside an item card
  Widget _cardField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: child,
        ),
      ],
    );
  }

  // ── Tip banner ────────────────────────────────────────────────────────────

  // _buildTipBanner → moved to const _PurchaseTipBanner class below

  // ── Column toggles — uses Wrap to avoid overflow ──────────────────────────

  Widget _buildColumnToggles(PurchaseInvoicesViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        _buildCheckboxTile(
          label: l10n.ownerPurchaseFormColDescription,
          value: vm.showDescriptionColumn,
          onChanged: vm.setShowDescriptionColumn,
        ),
        _buildCheckboxTile(
          label: l10n.ownerPurchaseFormColDiscount,
          value: vm.showDiscountColumn,
          onChanged: vm.setShowDiscountColumn,
        ),
        _buildCheckboxTile(
          label: l10n.ownerPurchaseFormAmountsTaxInclusive,
          value: vm.amountsAreTaxInclusive,
          onChanged: vm.setAmountsAreTaxInclusive,
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool wrapLabel = false,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: wrapLabel ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.secondaryLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          wrapLabel
              ? Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          )
              : Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Footer: Discount + Freight + Notes + Totals — single column on mobile ─

  Widget _buildFooter(PurchaseInvoicesViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ownerLocalizedCurrency(context, vm.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Totals panel — placed prominently at top of footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OwnerUi.scaffoldBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _TotalRow(l10n.ownerPurchaseFormSubtotal, vm.draftSubtotal,
                  currency: vm.currency),
              _TotalRow(l10n.ownerPurchaseFormTotalTaxVat, vm.draftTax,
                  currency: vm.currency),
              const Divider(height: 16),
              _TotalRow(l10n.ownerPurchaseFormGrandTotal, vm.draftGrandTotal,
                  currency: vm.currency,
                  bold: true,
                  color: AppColors.secondaryLight),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Invoice Discount
        _sectionLabel(l10n.ownerPurchaseFormInvoiceDiscount),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _numericField(ctrl: vm.discountCtrl, vm: vm),
              ),
              const SizedBox(width: 8),
              _DiscountTypeDropdown(
                value: vm.discountType,
                onChanged: vm.setDiscountType,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Freight
        _sectionLabel(l10n.ownerPurchaseFormFreight(currency)),
        _numericField(ctrl: vm.freightCtrl, vm: vm),
        const SizedBox(height: 12),

        // Notes
        _sectionLabel(l10n.ownerPurchaseFormNotes),
        TextField(
          controller: vm.notesCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: l10n.ownerPurchaseFormInternalNotes,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontSize: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _numericField({
    required TextEditingController ctrl,
    required PurchaseInvoicesViewModel vm,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType:
      const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => vm.recalculate(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // ── AP info banner ────────────────────────────────────────────────────────

  // _buildApBanner → moved to const _PurchaseApBanner class below

  // ── Action buttons (Cancel / Save as Draft / Create) ─────────────────────

  Widget _buildActionButtons(
      BuildContext context, PurchaseInvoicesViewModel vm) {
    final l10n = AppLocalizations.of(context)!;
    final shapeRadius = BorderRadius.circular(14);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // ── Cancel (secondary filled) ─────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed:
                    vm.isSubmitting ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryLight,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.secondaryLight.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: shapeRadius),
                ),
                child: Text(
                  l10n.ownerCommonCancel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Save as Draft ─────────────────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: vm.isSubmitting
                    ? null
                    : () async {
                        final ok = await vm.saveAsDraft(context);
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                          _showSnack(context, l10n.ownerPurchaseFormSavedDraft,
                              isError: false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  disabledBackgroundColor:
                      AppColors.primaryLight.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: shapeRadius),
                ),
                child: Text(
                  l10n.ownerPurchaseFormSaveDraft,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Create Purchase Invoice ───────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: vm.isSubmitting
                    ? null
                    : () async {
                        final err = vm.validateStep(0);
                        if (err != null) {
                          _showSnack(context, err, isError: true);
                          return;
                        }
                        final err2 = vm.validateStep(1);
                        if (err2 != null) {
                          _showSnack(context, err2, isError: true);
                          return;
                        }
                        final ok = await vm.submitNewInvoice(context);
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                          _showSnack(context, l10n.ownerPurchaseFormCreated,
                              isError: false);
                        } else if (!ok && context.mounted) {
                          _showSnack(context,
                              l10n.ownerPurchaseFormCreateFailed,
                              isError: true);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.secondaryLight,
                  disabledBackgroundColor:
                      AppColors.primaryLight.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: shapeRadius),
                ),
                child: vm.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryLight,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.ownerPurchaseFormCreate,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small shared helpers for this bottom sheet ────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.secondaryLight,
        ),
      ),
    );
  }

  Widget _formField({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, size: 18, color: AppColors.secondaryLight),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondaryLight),
        ),
      ),
    );
  }

  void _showSnack(
      BuildContext context,
      String message, {
        required bool isError,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        ),
      );
  }
}


// =============================================================================
// Inline helper widgets for the items table
// =============================================================================

class _ItemTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isNumber;
  final TextAlign textAlign;
  final ValueChanged<String> onChanged;

  const _ItemTextField({
    required this.controller,
    required this.hint,
    this.isNumber = false,
    this.textAlign = TextAlign.left,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: textAlign,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 11),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        border: InputBorder.none,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final AccountCode value;
  final ValueChanged<AccountCode> onChanged;
  const _AccountDropdown(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerStyledDropdown<AccountCode>(
      value: value,
      hint: l10n.ownerPurchaseFormAccount,
      height: 36,
      options: AccountCode.all
          .map((a) => OwnerDropdownOption(value: a, label: a.display))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      triggerStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

class _TaxCodeDropdown extends StatelessWidget {
  final TaxCode value;
  final ValueChanged<TaxCode> onChanged;
  const _TaxCodeDropdown(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerStyledDropdown<TaxCode>(
      value: value,
      hint: l10n.ownerPurchaseFormTax,
      height: 36,
      options: TaxCode.all
          .map((t) => OwnerDropdownOption(value: t, label: t.label))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      triggerStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}

class _DiscountTypeDropdown extends StatelessWidget {
  final DiscountType value;
  final ValueChanged<DiscountType> onChanged;
  const _DiscountTypeDropdown(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = l10n.ownerCurrencySar;
    return OwnerStyledDropdown<DiscountType>(
      value: value,
      hint: l10n.ownerPurchaseFormDiscountType,
      height: 44,
      options: [
        OwnerDropdownOption(
          value: DiscountType.fixed,
          label: l10n.ownerPurchaseFormFixedAmount(currency),
        ),
        OwnerDropdownOption(
          value: DiscountType.percent,
          label: l10n.ownerPurchaseFormPercent,
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      triggerStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}


// =============================================================================
// Product Autocomplete — searches pre-loaded products list (no extra API call)
// =============================================================================

class _ProductAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final List<CatalogProductModel> products;
  final ValueChanged<CatalogProductModel> onSelected;
  final ValueChanged<String> onChanged;

  const _ProductAutocomplete({
    required this.controller,
    required this.products,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  State<_ProductAutocomplete> createState() => _ProductAutocompleteState();
}

class _ProductAutocompleteState extends State<_ProductAutocomplete> {
  OverlayEntry? _overlay;
  final _layerLink = LayerLink();
  final _overlayKey = GlobalKey();
  List<CatalogProductModel> _suggestions = [];

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay(List<CatalogProductModel> suggestions) {
    _removeOverlay();
    if (suggestions.isEmpty || !mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final l10n = AppLocalizations.of(context)!;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 2),
          child: Material(
            key: _overlayKey,
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                itemBuilder: (ctx, i) {
                  final p = suggestions[i];
                  return InkWell(
                    onTap: () {
                      widget.controller.text = p.name;
                      widget.onSelected(p);
                      _removeOverlay();
                      setState(() => _suggestions = []);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                              l10n.ownerPurchaseFormProductPriceMeta(
                                ownerLocalizedUnit(l10n, p.unit),
                                ownerFormatMoney(context, p.salePrice),
                              ),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _onTextChanged(String query) {
    widget.onChanged(query);
    if (query.trim().length < 2) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    final q = query.trim().toLowerCase();
    final matched = widget.products
        .where((p) => p.name.toLowerCase().contains(q))
        .take(20)
        .toList();
    setState(() => _suggestions = matched);
    _showOverlay(matched);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        style: const TextStyle(fontSize: 11),
        onChanged: _onTextChanged,
        onTapOutside: (event) {
          // Don't dismiss if the tap landed inside the suggestions
          // overlay — onTapOutside fires on pointer-down, which would
          // otherwise close the overlay before the suggestion's onTap
          // (pointer-up) has a chance to register the selection.
          final overlayBox =
          _overlayKey.currentContext?.findRenderObject() as RenderBox?;
          if (overlayBox != null) {
            final topLeft = overlayBox.localToGlobal(Offset.zero);
            final overlayRect = topLeft & overlayBox.size;
            if (overlayRect.contains(event.position)) return;
          }
          _removeOverlay();
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.ownerPurchaseFormSearchProduct,
          hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          suffixIcon: widget.controller.text.isNotEmpty
              ? GestureDetector(
            onTap: () {
              widget.controller.clear();
              _removeOverlay();
              widget.onChanged('');
            },
            child: Icon(Icons.close_rounded,
                size: 14, color: Colors.grey.shade400),
          )
              : null,
        ),
      ),
    );
  }
}

// NOTE: DueDateType enum lives in purchase_invoices_view_model.dart
// (already imported above) — do NOT redeclare it here, or Dart will
// treat the two as distinct types even though they look identical,
// causing "argument type X can't be assigned to parameter type X"
// errors.

class _DueDateTypeDropdown extends StatelessWidget {
  final DueDateType value;
  final ValueChanged<DueDateType> onChanged;
  const _DueDateTypeDropdown(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OwnerStyledDropdown<DueDateType>(
      value: value,
      hint: l10n.ownerPurchaseFormDueType,
      height: 48,
      options: [
        OwnerDropdownOption(value: DueDateType.net, label: l10n.ownerPurchaseFormDueNet),
        OwnerDropdownOption(value: DueDateType.eom, label: l10n.ownerPurchaseFormDueEom),
        OwnerDropdownOption(value: DueDateType.custom, label: l10n.ownerPurchaseFormDueCustom),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      triggerStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryLight,
      ),
    );
  }
}
// =============================================================================
// Static banners — const widgets, zero rebuilds
// =============================================================================

class _PurchaseTipBanner extends StatelessWidget {
  const _PurchaseTipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFEE58)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, color: Color(0xFFF9A825), size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11, color: Colors.black87),
                children: [
                  TextSpan(text: 'Tip: By default the unit column is '),
                  TextSpan(
                    text: 'ex VAT',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' (15% VAT is added on each line). Check '),
                  TextSpan(
                    text: 'Amounts are tax inclusive',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: ' to enter VAT-inclusive unit prices. Qty, unit price, and discount support math (e.g. 12*5).',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseApBanner extends StatelessWidget {
  const _PurchaseApBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.white70),
          children: [
            TextSpan(text: l10n.ownerPurchaseFormApCreates),
            TextSpan(
              text: l10n.ownerPurchaseFormApLabel,
              style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: l10n.ownerPurchaseFormApAfter,
            ),
          ],
        ),
      ),
    );
  }
}
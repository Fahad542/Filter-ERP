import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_keyboard_locale.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../utils/pos_shell_scaffold.dart' show PosShellScaffoldRegistry;
import '../../../models/create_invoice_model.dart';
import 'sales_return_view_model.dart';

String _salesReturnLang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _salesReturnDigits(BuildContext context, Object? value) {
  return AppTranslationService.localizeDigitsForLanguage(
    value?.toString() ?? '',
    _salesReturnLang(context),
  );
}

String _salesReturnRef(BuildContext context, String value) =>
    _salesReturnDigits(context, value);

String _salesReturnWesternDigits(String text) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var out = text;
  for (var i = 0; i < arabic.length; i++) {
    out = out.replaceAll(arabic[i], i.toString());
  }
  return out;
}

String _salesReturnMoney(BuildContext context, num amount) {
  final raw = amount.toStringAsFixed(2);
  if (_salesReturnLang(context) == 'ar') {
    return '${_salesReturnDigits(context, raw)} ر.س';
  }
  return AppLocalizations.of(context)!.posSalesReturnSarAmount(raw);
}

String _salesReturnDateText(BuildContext context, String rawDate) {
  final t = rawDate.trim();
  if (t.isEmpty) return t;
  final dt = DateTime.tryParse(t);
  final raw = dt == null ? t.split('T')[0] : dt.toIso8601String().split('T')[0];
  return _salesReturnDigits(context, raw);
}

String _salesReturnLinePrice(
  BuildContext context,
  double qty,
  double unitPrice,
) {
  final q = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
  if (_salesReturnLang(context) == 'ar') {
    return '${_salesReturnDigits(context, q)} × ${_salesReturnMoney(context, unitPrice)}';
  }
  return AppLocalizations.of(
    context,
  )!.posSalesReturnLinePrice(q, unitPrice.toStringAsFixed(2));
}

Widget _salesReturnDynamicProductText(
  BuildContext context,
  InvoiceItem item, {
  required TextStyle style,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final lang = _salesReturnLang(context);
  final ar = (item.productNameArabic ?? '').trim();
  if (lang == 'ar' && ar.isNotEmpty) {
    return Text(
      _salesReturnDigits(context, ar),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  return LocalizedApiText(
    item.productName,
    textDirection: lang == 'ar' ? TextDirection.rtl : null,
    textAlign: lang == 'ar' ? TextAlign.right : null,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
  );
}

void _salesReturnLocalizeSearchFieldDigits(
  BuildContext context,
  TextEditingController controller,
) {
  if (_salesReturnLang(context) != 'ar') return;
  final current = controller.text;
  final localized = _salesReturnDigits(context, current);
  if (localized == current) return;
  final selection = controller.selection;
  controller.value = TextEditingValue(
    text: localized,
    selection: selection.isValid
        ? TextSelection.collapsed(
            offset: selection.baseOffset.clamp(0, localized.length).toInt(),
          )
        : TextSelection.collapsed(offset: localized.length),
  );
}

class PosSalesReturnView extends StatefulWidget {
  /// Set to true when pushed via Navigator.push (e.g. from Home Screen).
  /// Set to false (default) when shown as a shell tab from the drawer.
  final bool showBackButton;
  const PosSalesReturnView({super.key, this.showBackButton = false});

  @override
  State<PosSalesReturnView> createState() => _PosSalesReturnViewState();
}

class _PosSalesReturnViewState extends State<PosSalesReturnView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<SalesReturnViewModel>();
      if (!widget.showBackButton) {
        // Drawer/shell tab — reset and clear results.
        vm.clearSelection();
        vm.searchController.clear();
        vm.searchInvoice(); // clears results
      } else if (vm.searchController.text.trim().isNotEmpty) {
        // Pushed from home with a pre-filled customer id — kick off the lookup
        // here so the cross-branch toast/banner lands on THIS screen instead of
        // firing under the home view during the route transition.
        vm.searchInvoice();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final vm = context.watch<SalesReturnViewModel>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: PosScreenAppBar(
        title: (!isTablet && vm.selectedInvoice != null)
            ? l10n.posSalesReturnMobileTitle(
                _salesReturnRef(
                  context,
                  vm.selectedInvoice!.invoiceNo.isNotEmpty
                      ? vm.selectedInvoice!.invoiceNo
                      : vm.selectedInvoice!.id,
                ),
              )
            : l10n.posSalesReturnTitle,
        showBackButton:
            widget.showBackButton || (!isTablet && vm.selectedInvoice != null),
        showHamburger:
            !widget.showBackButton &&
            !(!isTablet && vm.selectedInvoice != null),
        onMenuPressed: () => PosShellScaffoldRegistry.openDrawer(),
        onBack: () {
          if (!isTablet && vm.selectedInvoice != null) {
            vm.clearSelection();
          } else if (widget.showBackButton) {
            vm.clearSelection();
            Navigator.pop(context);
          }
        },
      ),
      body: wrapPosShellRailBody(
        context,
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side: Search and Results
            if (isTablet || vm.selectedInvoice == null)
              Expanded(
                flex: isTablet ? 4 : 10,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      _buildSearchHeader(vm, isTablet),
                      SizedBox(height: isTablet ? 3 : 5),
                      if (vm.searchResults.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 12 : 14,
                            vertical: isTablet ? 3 : 5,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: isTablet ? 13 : 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.posSalesReturnResults,
                                style: TextStyle(
                                  fontSize: isTablet ? 11 : 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E2124),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(child: _buildSearchResults(vm, isTablet)),
                    ],
                  ),
                ),
              ),

            if (isTablet)
              VerticalDivider(
                width: 1,
                color: Colors.grey.shade300.withValues(alpha: 0.5),
              ),
            // Right side: Return Form (visible if invoice selected)
            if (isTablet || vm.selectedInvoice != null)
              Expanded(
                flex: isTablet ? 6 : (vm.selectedInvoice != null ? 10 : 0),
                child: vm.selectedInvoice == null
                    ? _buildEmptyState(isTablet)
                    : _buildReturnDetails(vm, isTablet),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(SalesReturnViewModel vm, bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 12 : 12,
        isTablet ? 8 : 10,
        isTablet ? 12 : 12,
        isTablet ? 3 : 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PosWorkshopSearchBar(
                  controller: vm.searchController,
                  hintText: AppLocalizations.of(context)!.posSalesReturnSearchHint,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) {
                    _salesReturnLocalizeSearchFieldDigits(
                      context,
                      vm.searchController,
                    );
                    vm.searchInvoiceSuggestions();
                  },
                  onSubmitted: (_) => vm.searchInvoice(),
                ),
              ),
            ],
          ),
          if (vm.searchError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.localizedSearchError(context) ?? vm.searchError!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(SalesReturnViewModel vm, bool isTablet) {
    if (vm.searchController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (vm.isSearching) {
      return _InvoiceSearchResultsShimmer(isTablet: isTablet);
    }

    if (vm.searchController.text.isNotEmpty &&
        vm.searchResults.isEmpty &&
        vm.searchError == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.posSalesReturnNoInvoicesFound(
                _salesReturnRef(context, vm.searchController.text),
              ),
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 12,
        vertical: isTablet ? 3 : 5,
      ),
      itemCount: vm.searchResults.length,
      itemBuilder: (context, index) {
        final inv = vm.searchResults[index];
        final isSelected = vm.selectedInvoice?.id == inv.id;
        final isTablet = MediaQuery.of(context).size.width > 600;
        final cardR = isTablet ? 12.0 : 14.0;

        return Padding(
          padding: EdgeInsets.only(bottom: isTablet ? 6 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardR),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight.withValues(alpha: 0.8)
                    : Colors.grey.shade200,
                width: isSelected ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 12 : (isTablet ? 6 : 8),
                  offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
                  spreadRadius: isSelected ? -1 : 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => vm.selectInvoice(inv),
                borderRadius: BorderRadius.circular(cardR),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 10 : 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (inv.invoiceDate.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: isTablet ? 4 : 5),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: isTablet ? 12 : 12,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _salesReturnDateText(context, inv.invoiceDate),
                                style: TextStyle(
                                  fontSize: isTablet ? 11 : 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 6 : 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryLight.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: isTablet ? 16 : 16,
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.secondaryLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _salesReturnRef(
                                context,
                                inv.invoiceNo.isNotEmpty
                                    ? inv.invoiceNo
                                    : inv.id,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isTablet ? 13 : 14,
                                color: const Color(0xFF1E2124),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 7 : 8,
                              vertical: isTablet ? 4 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _salesReturnMoney(context, inv.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade700,
                                fontSize: isTablet ? 11 : 12,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 4 : 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: isTablet ? 15 : 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: LocalizedApiText(
                              inv.customerName.isNotEmpty
                                  ? inv.customerName
                                  : AppLocalizations.of(
                                      context,
                                    )!.posSalesReturnWalkInCustomer,
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.posSalesReturnSelectInvoiceTitle,
            style: TextStyle(
              fontSize: isTablet ? 17 : 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E2124),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 8),
          Text(
            AppLocalizations.of(context)!.posSalesReturnSelectInvoiceBody,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isTablet ? 12 : 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReturnDetails(SalesReturnViewModel vm, bool isTablet) {
    final inv = vm.selectedInvoice!;
    final selectedCount = vm.selectedItems.values.where((v) => v).length;

    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.07),
      child: Column(
        children: [
          // ── Invoice Summary Header ──
          Container(
            margin: EdgeInsets.fromLTRB(
              isTablet ? 12 : 12,
              isTablet ? 8 : 10,
              isTablet ? 12 : 12,
              0,
            ),
            padding: EdgeInsets.all(isTablet ? 12 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E2124), const Color(0xFF2C3036)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E2124).withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryLight,
                    size: isTablet ? 20 : 22,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _salesReturnRef(
                          context,
                          inv.invoiceNo.isNotEmpty ? inv.invoiceNo : inv.id,
                        ),
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: isTablet ? 3 : 5),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: isTablet ? 12 : 12,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: LocalizedApiText(
                              inv.customerName.isNotEmpty
                                  ? inv.customerName
                                  : AppLocalizations.of(
                                      context,
                                    )!.posSalesReturnWalkInCustomer,
                              style: TextStyle(
                                fontSize: isTablet ? 11 : 12,
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (inv.invoiceDate.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: isTablet ? 11 : 11,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _salesReturnDateText(context, inv.invoiceDate),
                              style: TextStyle(
                                fontSize: isTablet ? 10 : 11,
                                color: Colors.white38,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.posSalesReturnTotal,
                      style: TextStyle(
                        fontSize: isTablet ? 10 : 11,
                        color: Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _salesReturnMoney(context, inv.totalAmount),
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryLight,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 12 : 12,
                isTablet ? 8 : 12,
                isTablet ? 12 : 12,
                isTablet ? 10 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items section header
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: isTablet ? 12 : 14,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.inventory_2_rounded,
                        size: isTablet ? 13 : 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.posSalesReturnSelectItems,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2124),
                        ),
                      ),
                      const Spacer(),
                      if (selectedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _salesReturnDigits(
                              context,
                              AppLocalizations.of(
                                context,
                              )!.posSalesReturnSelectedCount(selectedCount),
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 10),

                  // Item List
                  ...inv.items.map(
                    (item) => _buildReturnItemRow(item, vm, isTablet),
                  ),

                  SizedBox(height: isTablet ? 12 : 16),

                  // Proof section header
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: isTablet ? 12 : 14,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: isTablet ? 13 : 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.posSalesReturnProof,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2124),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.posSalesReturnOptional,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 10),
                  _buildImagePicker(vm, isTablet),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ──
          Container(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 12 : 12,
              isTablet ? 8 : 10,
              isTablet ? 12 : 12,
              MediaQuery.of(context).padding.bottom + (isTablet ? 8 : 10),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  height: isTablet ? 42 : 46,
                  child: ElevatedButton(
                    onPressed: vm.isSubmitting ? null : vm.clearSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 14 : 18,
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.posSalesReturnCancel,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 12 : 13,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 8),
                Expanded(
                  child: SizedBox(
                    height: isTablet ? 42 : 46,
                    child: ElevatedButton(
                      onPressed: vm.isSubmitting || !vm.canSubmitReturn
                          ? null
                          : () => vm.submitReturnRequest(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: vm.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(
                                context,
                              )!.posSalesReturnSubmit,
                              style: TextStyle(
                                color: AppColors.secondaryLight,
                                fontWeight: FontWeight.w800,
                                fontSize: isTablet ? 12 : 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItemRow(
    InvoiceItem item,
    SalesReturnViewModel vm,
    bool isTablet,
  ) {
    final isSelected = vm.selectedItems[item.id] ?? false;
    final double qty = vm.returnQuantities[item.id] ?? 0.0;
    final reason = vm.returnReasons[item.id];
    final maxReturnQty = vm.availableReturnQty(item.id, item.qty);
    final blockReason = vm.itemReturnBlockReason(context, item.id, item.qty);
    final isBlocked = maxReturnQty <= 0;

    final cardR = isTablet ? 12.0 : 14.0;
    return Opacity(
      opacity: isBlocked ? 0.55 : 1,
      child: Container(
      margin: EdgeInsets.only(bottom: isTablet ? 6 : 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(cardR),
        border: Border.all(
          color: isSelected ? AppColors.primaryLight : Colors.grey.shade200,
          width: isSelected ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isSelected ? 14 : (isTablet ? 6 : 10),
            offset: isSelected ? const Offset(0, 4) : const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              onTap: isBlocked
                  ? null
                  : () => vm.toggleItemSelection(item.id, !isSelected, item.qty),
              borderRadius: isSelected
                  ? BorderRadius.vertical(top: Radius.circular(cardR))
                  : BorderRadius.circular(cardR),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 10 : 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryLight.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      width: isTablet ? 22 : 22,
                      height: isTablet ? 22 : 22,
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: isTablet ? 16 : 16,
                            )
                          : null,
                    ),
                    SizedBox(width: isTablet ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _salesReturnDynamicProductText(
                            context,
                            item,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isTablet ? 13 : 14,
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : const Color(0xFF1E2124),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 2 : 3),
                          Text(
                            _salesReturnLinePrice(
                              context,
                              item.qty,
                              item.unitPrice,
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isTablet ? 11 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (blockReason != null) ...[
                            SizedBox(height: isTablet ? 2 : 3),
                            Text(
                              blockReason,
                              style: TextStyle(
                                color: const Color(0xFFB42318),
                                fontSize: isTablet ? 10 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else if (maxReturnQty < item.qty) ...[
                            SizedBox(height: isTablet ? 2 : 3),
                            Text(
                              AppLocalizations.of(context)!
                                  .posSalesReturnQtyAvailable(maxReturnQty),
                              style: TextStyle(
                                color: const Color(0xFF8B5E00),
                                fontSize: isTablet ? 10 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 10,
                        vertical: isTablet ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryLight.withValues(alpha: 0.2)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        _salesReturnMoney(context, item.qty * item.unitPrice),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 12 : 13,
                          color: isSelected
                              ? AppColors.primaryLight
                              : const Color(0xFF1E2124),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Return Config
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1.5),
                  ),
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(cardR),
                  ),
                ),
                padding: EdgeInsets.all(isTablet ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Qty Stepper
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 12,
                        vertical: isTablet ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 5 : 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.numbers_rounded,
                                  size: isTablet ? 14 : 16,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 12),
                              Text(
                                AppLocalizations.of(context)!.posSalesReturnQty,
                                style: TextStyle(
                                  fontSize: isTablet ? 11 : 12,
                                  color: const Color(0xFF1E2124),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          _buildStepper(item.id, qty, maxReturnQty, vm, isTablet),
                        ],
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 10),
                    // Reason Dropdown
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 10 : 12,
                        vertical: isTablet ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: reason,
                          isExpanded: true,
                          hint: Text(
                            AppLocalizations.of(
                              context,
                            )!.posSalesReturnReasonHint,
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 13,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade600,
                              size: isTablet ? 14 : 16,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 13,
                            color: const Color(0xFF1E2124),
                            fontWeight: FontWeight.w700,
                          ),
                          items: vm.returnReasonOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                vm.localizedReturnReason(context, value),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              vm.updateReturnReason(item.id, newValue);
                            }
                          },
                        ),
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

  Widget _buildStepper(
    String itemId,
    double currentQty,
    double maxQty,
    SalesReturnViewModel vm,
    bool isTablet,
  ) {
    final btnSize = isTablet ? 30.0 : 34.0;
    final iconSz = isTablet ? 16.0 : 18.0;
    final fieldW = isTablet ? 36.0 : 42.0;
    final fieldFs = isTablet ? 12.0 : 13.0;
    // Generate controller with the current value.
    final int currentInt = currentQty.toInt();
    final int maxInt = maxQty.toInt();
    final String displayVal = _salesReturnDigits(context, currentInt);

    final controller = TextEditingController(text: displayVal);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepButton(
          icon: Icons.remove_rounded,
          isEnabled: currentInt > 0,
          size: btnSize,
          iconSize: iconSz,
          onPressed: () {
            final newQty = (currentInt - 1).clamp(0, maxInt).toDouble();
            vm.updateReturnQuantity(itemId, newQty);
          },
        ),
        Container(
          width: fieldW,
          alignment: Alignment.center,
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 4 : 5),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                final parsed = int.tryParse(
                  _salesReturnWesternDigits(controller.text),
                );
                if (parsed != null && parsed >= 1 && parsed <= maxInt) {
                  vm.updateReturnQuantity(itemId, parsed.toDouble());
                } else {
                  vm.updateReturnQuantity(itemId, currentQty);
                  controller.text = displayVal;
                }
              }
            },
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              hintLocales: appKeyboardHintLocales(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fieldFs,
                color: const Color(0xFF1E2124),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onFieldSubmitted: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed >= 1 && parsed <= maxInt) {
                  vm.updateReturnQuantity(itemId, parsed.toDouble());
                } else {
                  vm.updateReturnQuantity(itemId, currentQty);
                  controller.text = displayVal;
                }
              },
            ),
          ),
        ),
        _buildStepButton(
          icon: Icons.add_rounded,
          isEnabled: currentInt < maxInt,
          size: btnSize,
          iconSize: iconSz,
          onPressed: () {
            final newQty = (currentInt + 1).clamp(0, maxInt).toDouble();
            vm.updateReturnQuantity(itemId, newQty);
          },
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
    double size = 44,
    double iconSize = 22,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primaryLight : Colors.grey.shade100,
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: iconSize,
          color: isEnabled ? Colors.white : Colors.grey.shade400,
        ),
        padding: EdgeInsets.zero,
        onPressed: isEnabled ? onPressed : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2124),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(SalesReturnViewModel vm, bool isTablet) {
    return GestureDetector(
      onTap: vm.pickProofImage,
      child: Container(
        height: isTablet ? 104 : 118,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 14 : 20),
          border: Border.all(
            color: vm.proofImage != null
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: vm.proofImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(vm.proofImage!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: vm.pickProofImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.grey.shade500,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.posSalesReturnUploadProof,
                    style: TextStyle(
                      color: const Color(0xFF1E2124),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.posSalesReturnUploadFormats,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Skeleton matching invoice search result cards (date, receipt, amount, customer).
class _InvoiceSearchResultsShimmer extends StatelessWidget {
  const _InvoiceSearchResultsShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final cardR = isTablet ? 12.0 : 14.0;
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 12,
        vertical: isTablet ? 3 : 5,
      ),
      itemCount: 5,
      itemBuilder: (_, _) {
        return Padding(
          padding: EdgeInsets.only(bottom: isTablet ? 6 : 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardR),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: isTablet ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(isTablet ? 10 : 11),
            child: PosShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosShimmerBox(
                    width: isTablet ? 110 : 120,
                    height: isTablet ? 11 : 12,
                    radius: 6,
                  ),
                  SizedBox(height: isTablet ? 8 : 10),
                  Row(
                    children: [
                      PosShimmerBox(
                        width: isTablet ? 28 : 28,
                        height: isTablet ? 28 : 28,
                        radius: 10,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: PosShimmerLine(
                          width: double.infinity,
                          height: isTablet ? 13 : 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PosShimmerBox(
                        width: isTablet ? 64 : 72,
                        height: isTablet ? 22 : 24,
                        radius: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 10),
                  Row(
                    children: [
                      const PosShimmerCircle(size: 22),
                      const SizedBox(width: 5),
                      PosShimmerLine(
                        width: isTablet ? 120 : 140,
                        height: isTablet ? 12 : 13,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

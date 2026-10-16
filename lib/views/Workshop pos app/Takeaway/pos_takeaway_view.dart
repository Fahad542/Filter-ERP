import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/app_arabic_font_fallbacks.dart';
import '../../../utils/app_formatters.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/pos_tablet_layout.dart';
import '../../../utils/toast_service.dart';
import '../../../models/takeaway_models.dart';
import '../../../services/invoice_dialog_launcher.dart';
import '../../../widgets/pos_widgets.dart';
import '../../../widgets/pos_segmented_list_tabs.dart';
import '../../../widgets/pos_shimmer.dart';
import '../../../widgets/pos_shell_rail_layout.dart';
import '../Home Screen/pos_view_model.dart';
import '../Order Screen/pos_order_review_view.dart'
    show WalkInInvoiceFormResult;
import 'pos_takeaway_checkout_dialog.dart';
import '../Promo/promo_code_dialog.dart';
import '../Promo/promo_view_model.dart';
import '../Promo/referral_code_dialog.dart';
import '../../../services/softpos_bridge.dart';
import '../../../services/softpos_connection_guard.dart';
import '../../../services/softpos_invoice_flow.dart';
import 'takeaway_view_model.dart';

const double _kTakeawaySummaryCodeChipHeight = 36;
const Color _kTakeawaySummaryCodeChipBg = Color(0xFFFFF7E6);
const Color _kTakeawaySummaryAppliedChipBg = Color(0xFFE8F5E9);
const Color _kTakeawaySummaryAppliedChipBorder = Color(0xFF43A047);

Widget _takeawaySummaryCodeChip({
  required Color borderColor,
  required Widget leading,
  required String label,
  required Color labelColor,
  required FontWeight labelWeight,
  Color backgroundColor = _kTakeawaySummaryCodeChipBg,
  VoidCallback? onTap,
  Widget? trailingClose,
}) {
  return SizedBox(
    height: _kTakeawaySummaryCodeChipHeight,
    width: double.infinity,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 4),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: labelWeight,
                      fontSize: 11,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (trailingClose != null)
            SizedBox(
              width: 20,
              height: 20,
              child: Center(child: trailingClose),
            )
          else
            const SizedBox(width: 2),
        ],
      ),
    ),
  );
}

/// Same typography as [PosOrdersView] empty list and catalog empty in [PosProductGridView].
TextStyle _takeawayCatalogEmptyMessageTextStyle({bool tablet = false}) => TextStyle(
  fontSize: tablet ? 15 : 17,
  fontWeight: FontWeight.w700,
  color: Colors.grey.shade500,
  height: 1.35,
);


String _takeawayLang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _takeawayDigits(BuildContext context, Object? value) {
  return AppTranslationService.localizeDigitsForLanguage(
    value?.toString() ?? '',
    _takeawayLang(context),
  );
}

String _takeawayQtyText(BuildContext context, double qty) {
  final raw = (!qty.isFinite)
      ? '0'
      : (qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1));
  return _takeawayDigits(context, raw);
}

String _takeawayMoney(BuildContext context, num amount, {bool negative = false}) {
  final l10n = AppLocalizations.of(context)!;
  final localizedAmount = _takeawayDigits(context, amount.abs().toStringAsFixed(2));
  final money = l10n.posCommonSarAmount(localizedAmount);
  if (!negative) return money;
  return _takeawayLang(context) == 'ar' ? '$money-' : '-$money';
}

String _takeawayUnitLabel(BuildContext context, String unit) {
  final lang = _takeawayLang(context);
  final rawUnit = unit.trim();
  final normalized = rawUnit.toLowerCase();
  final localizedUnit = lang == 'ar'
      ? const <String, String>{
    'liter': 'لتر',
    'litre': 'لتر',
    'l': 'لتر',
    'pcs': 'قطعة',
    'pc': 'قطعة',
    'piece': 'قطعة',
    'pieces': 'قطع',
    'unit': 'وحدة',
    'units': 'وحدات',
  }[normalized] ?? AppTranslationService.localizeDigitsForLanguage(rawUnit, lang)
      : rawUnit;
  return AppLocalizations.of(context)!.posTakeawayUnit(localizedUnit);
}

/// Matches walk-in cart qty×price badge styles in [PosProductGridView].
EdgeInsets _takeawayCartQtyPriceRowPadding(bool isTablet) => EdgeInsets.symmetric(
      horizontal: isTablet ? 9 : 6,
      vertical: isTablet ? 5 : 4,
    );

BoxDecoration _takeawayCartQtyPriceRowDecoration() => BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(6),
    );

double _takeawayCartQtyPriceRowFontSize(bool isTablet) => isTablet ? 13 : 11;

TextStyle _takeawayCartQtyPriceMutedStyle(bool isTablet) => TextStyle(
      fontSize: _takeawayCartQtyPriceRowFontSize(isTablet),
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
      height: 1.0,
    );

TextStyle _takeawayCartQtyPriceValueStyle(BuildContext context, bool isTablet) =>
    TextStyle(
      fontSize: _takeawayCartQtyPriceRowFontSize(isTablet),
      fontWeight: localeFontWeight(context, FontWeight.w700),
      color: const Color(0xFF1E2124),
      height: 1.0,
    );

String _takeawayStockLabel(BuildContext context, TakeawayProduct product) {
  final l10n = AppLocalizations.of(context)!;
  final q = product.qtyOnHand == product.qtyOnHand.roundToDouble()
      ? product.qtyOnHand.round().toString()
      : product.qtyOnHand.toStringAsFixed(1);
  final localizedQty = _takeawayDigits(context, q);
  if (!product.isActive) return l10n.posTakeawayInactive;
  if (product.allowMinusQty && product.qtyOnHand <= 0) {
    return l10n.posTakeawayInStock(localizedQty);
  }
  if (product.qtyOnHand > 5) return l10n.posTakeawayInStock(localizedQty);
  if (product.qtyOnHand > 0) return l10n.posTakeawayLowStock(localizedQty);
  return l10n.posTakeawayOutOfStock;
}

class _TakeawayApiLabel extends StatelessWidget {
  const _TakeawayApiLabel(
      this.text, {
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    if (text.trim().toLowerCase() == 'all') {
      return Text(
        AppLocalizations.of(context)!.posTakeawayAll,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return LocalizedApiText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

String? _cleanTakeawayArabicName(Object? value) {
  final v = value?.toString().trim();
  if (v == null || v.isEmpty || v.toLowerCase() == 'null') return null;
  return v;
}

/// Order-screen catalog pattern: backend Arabic name first, else frontend translate.
Widget _takeawayProductTitle(
  BuildContext context,
  TakeawayProduct product, {
  TextStyle? style,
  int? maxLines,
  TextOverflow? overflow,
  TextAlign? textAlign,
}) {
  final langCode = Localizations.localeOf(context).languageCode;
  final backendArabic = langCode == 'ar'
      ? _cleanTakeawayArabicName(product.nameArabic)
      : null;

  if (backendArabic != null) {
    return Text(
      backendArabic,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  return LocalizedApiText(
    product.name,
    style: style,
    maxLines: maxLines,
    overflow: overflow,
    textAlign: textAlign,
  );
}

extension _TakeawayStockUi on TakeawayProduct {
  Color get _stockColor {
    if (!isActive) return Colors.grey;
    if (allowMinusQty && qtyOnHand <= 0) return const Color(0xFF7C3AED);
    if (qtyOnHand > 5) return const Color(0xFF4CAF50);
    if (qtyOnHand > 0) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get _stockLabel {
    if (!isActive) return 'Inactive';
    final q = qtyOnHand == qtyOnHand.roundToDouble()
        ? qtyOnHand.round()
        : qtyOnHand;
    if (allowMinusQty && qtyOnHand <= 0) return 'Available ($q)';
    if (qtyOnHand > 5) return 'In Stock ($q)';
    if (qtyOnHand > 0) return 'Low ($q)';
    return 'Out of Stock';
  }
}

/// Same layout & styling as [PosProductGridView] (main tab), wired to takeaway catalog + checkout.
class PosTakeawayView extends StatefulWidget {
  const PosTakeawayView({super.key});

  @override
  State<PosTakeawayView> createState() => _PosTakeawayViewState();
}

class _PosTakeawayViewState extends State<PosTakeawayView> {
  final ScrollController _departmentScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  String? _lastCategoryDeptId;

  @override
  void dispose() {
    _departmentScrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final vm = context.watch<TakeawayViewModel>();
    final currentDeptId = vm.selectedDepartmentId;
    if (_lastCategoryDeptId != currentDeptId) {
      _lastCategoryDeptId = currentDeptId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_departmentScrollController.hasClients) {
          _departmentScrollController.jumpTo(0);
        }
        if (_categoryScrollController.hasClients) {
          _categoryScrollController.jumpTo(0);
        }
      });
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: PosTabletLayout.textScaler(context),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF5F3F0),
        appBar: PosScreenAppBar(
          title: AppLocalizations.of(context)!.posTakeawayTitle,
          showBackButton: false,
        ),
        body: wrapPosShellRailBody(
          context,
          vm.catalogLoading && vm.catalog == null
              ? _TakeawayCatalogShimmer(isTablet: isTablet)
              : vm.catalogError != null && vm.catalog == null
              ? _buildCatalogError(context, vm.catalogError!)
              : _buildProductSection(context, vm, isTablet),
        ),
        bottomNavigationBar: (isTablet || vm.cartLineCount == 0)
            ? const SizedBox.shrink()
            : _buildBottomBar(context, vm, isTablet),
      ),
    );
  }

  Widget _buildCatalogError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalizedApiText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<TakeawayViewModel>().loadCatalog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.secondaryLight,
              ),
              child: Text(AppLocalizations.of(context)!.posTakeawayRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection(
      BuildContext context,
      TakeawayViewModel vm,
      bool isTablet,
      ) {
    if (isTablet) {
      final isPortrait =
          MediaQuery.of(context).orientation == Orientation.portrait;
      if (vm.catalog != null && !vm.catalogHasProducts) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 14, 10),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: _buildEmptyState(),
              ),
            );
          },
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.catalog != null && vm.catalogHasProducts) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: PosWorkshopSearchBar(
                              controller: vm.searchController,
                              onChanged: vm.setSearchQuery,
                              hintText: AppLocalizations.of(context)!.posTakeawaySearchHint,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () => vm.loadCatalog(),
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: AppLocalizations.of(context)!.posTakeawayRefresh,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildDepartmentSegmentedTabs(context, vm, true),
                      ),
                    ),
                    _buildCategoryChips(context, vm, true),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildListBody(context, vm, isTablet, isPortrait),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 340,
              child: _buildLiveInvoicePanel(context, vm),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.catalog != null && vm.catalogHasProducts) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: PosWorkshopSearchBar(
                    controller: vm.searchController,
                    onChanged: vm.setSearchQuery,
                    hintText: AppLocalizations.of(context)!.posTakeawaySearchHint,
                  ),
                ),
                IconButton(
                  onPressed: () => vm.loadCatalog(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildDepartmentSegmentedTabs(context, vm, false),
            ),
          ),
          _buildCategoryChips(context, vm, false),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: vm.catalog != null && !vm.catalogHasProducts
              ? _buildEmptyState()
              : _buildListBody(context, vm, isTablet, true),
        ),
      ],
    );
  }

  /// Right column on tablet — mirrors Products tab live invoice (narrow panel + totals).
  Widget _buildLiveInvoicePanel(BuildContext context, TakeawayViewModel vm) {
    final currency = vm.catalog?.currency ?? 'SAR';

    final gross = vm.grossExclVatBeforeLineDiscounts;
    final lineDiscount = vm.lineDiscountTotalExclVat;
    final subtotal = vm.subtotalBeforeOrderDiscount;
    final orderDiscInput = double.tryParse(vm.orderDiscountValueController.text.trim()) ?? 0.0;
    final isOrderDiscPercent = vm.orderDiscountType == 'percent' || vm.orderDiscountType == 'percentage';
    final orderDisc = isOrderDiscPercent
        ? (subtotal * (orderDiscInput / 100)).clamp(0, subtotal).toDouble()
        : orderDiscInput.clamp(0, subtotal).toDouble();
    final afterOrderDiscount = (subtotal - orderDisc).clamp(0, double.infinity).toDouble();

    final promoDiscount = vm.isPromoPercent
        ? (afterOrderDiscount * (vm.promoDiscountValue / 100))
        .clamp(0, afterOrderDiscount)
        .toDouble()
        : vm.promoDiscountValue.clamp(0, afterOrderDiscount).toDouble();
    final taxable = (afterOrderDiscount - promoDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    Widget buildRow(String label, String value, {Color? color, FontWeight weight = FontWeight.w500}) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.grey.shade600,
              fontWeight: weight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? const Color(0xFF1E2124),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.posTakeawayOrderItems,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryLight,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _takeawayDigits(context, vm.cartLineCount),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2124),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Only the cart list scrolls — totals + action buttons stay pinned.
          Expanded(
            child: vm.cart.isEmpty
                ? Center(
              child: Text(
                AppLocalizations.of(context)!.posTakeawayNoItems,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              itemCount: vm.cart.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) => _TakeawayCartItemCompactTile(
                key: ValueKey(vm.cart[index].product.id),
                line: vm.cart[index],
                currency: currency,
                vm: vm,
                isTablet: false,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildRow(AppLocalizations.of(context)!.posTakeawayGrossExVat, _takeawayMoney(context, gross)),
                const SizedBox(height: 6),
                buildRow(
                  AppLocalizations.of(context)!.posTakeawayLineDiscount,
                  _takeawayMoney(context, lineDiscount, negative: true),
                  color: lineDiscount > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                ),
                const SizedBox(height: 6),
                buildRow(
                  AppLocalizations.of(context)!.posTakeawayPriceAfterLineDiscount,
                  _takeawayMoney(context, subtotal),
                ),
                const SizedBox(height: 8),

                // Interactive order-level discount (same control as Products tab)
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.posTakeawayTotalDiscount,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 50,
                      height: 22,
                      child: TextField(
                        controller: vm.orderDiscountValueController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final d = double.tryParse(val) ?? 0;
                          vm.setOrderDiscountValue(d);
                        },
                        style: const TextStyle(fontSize: 11, color: Colors.green),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: const TextStyle(color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        vm.setOrderDiscountType(
                          isOrderDiscPercent ? AppLocalizations.of(context)!.posTakeawayAmount : AppLocalizations.of(context)!.posTakeawayPercent,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          isOrderDiscPercent ? '%' : AppLocalizations.of(context)!.posCommonSar,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                if (orderDisc > 0) ...[
                  buildRow(
                    AppLocalizations.of(context)!.posTakeawayTotalDiscountApplied,
                    _takeawayMoney(context, orderDisc, negative: true),
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 6),
                ],
                buildRow(AppLocalizations.of(context)!.posTakeawayPriceAfterTotalDiscount, _takeawayMoney(context, afterOrderDiscount)),
                const SizedBox(height: 8),
                const Divider(height: 14, thickness: 1, color: Color(0xFFE8ECF3)),
                // Promo + referral chips — same layout as Orders summary.
                SizedBox(
                  height: _kTakeawaySummaryCodeChipHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _takeawaySummaryCodeChip(
                          backgroundColor: vm.promoCodeController.text.trim().isNotEmpty
                              ? _kTakeawaySummaryAppliedChipBg
                              : _kTakeawaySummaryCodeChipBg,
                          borderColor: vm.promoCodeController.text.trim().isNotEmpty
                              ? _kTakeawaySummaryAppliedChipBorder
                              : const Color(0xFFFFC145).withValues(alpha: 0.6),
                          leading: Icon(
                            Icons.local_offer_outlined,
                            size: 14,
                            color: vm.promoCodeController.text.trim().isNotEmpty
                                ? Colors.green.shade700
                                : Colors.amber.shade700,
                          ),
                          label: vm.promoCodeController.text.trim().isEmpty
                              ? AppLocalizations.of(context)!.posTakeawayAddPromoCode
                              : AppLocalizations.of(context)!
                                  .posTakeawayPromoApplied(
                                    vm.promoCodeController.text.trim(),
                                  ),
                          labelColor: vm.promoCodeController.text.trim().isNotEmpty
                              ? Colors.green.shade700
                              : const Color(0xFF1E2124),
                          labelWeight: localeFontWeight(context, FontWeight.w700),
                          onTap: vm.cart.isEmpty
                              ? null
                              : () => _openTakeawayPromoFromPanel(context),
                          trailingClose: vm.promoCodeController.text.trim().isEmpty
                              ? null
                              : GestureDetector(
                                  onTap: () {
                                    final posVm = context.read<PosViewModel>();
                                    final promoVm = context.read<PromoViewModel>();
                                    posVm.clearPromoCode(isMainTab: false);
                                    promoVm.promoController.clear();
                                    promoVm.clearPromoError();
                                    vm.clearAppliedPromo();
                                    vm.refreshPreview();
                                  },
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _takeawaySummaryCodeChip(
                          backgroundColor: vm.referralCode.trim().isNotEmpty
                              ? _kTakeawaySummaryAppliedChipBg
                              : _kTakeawaySummaryCodeChipBg,
                          borderColor: vm.referralCode.trim().isNotEmpty
                              ? _kTakeawaySummaryAppliedChipBorder
                              : AppColors.primaryLight.withValues(alpha: 0.7),
                          leading: Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 14,
                            color: vm.referralCode.trim().isNotEmpty
                                ? Colors.green.shade700
                                : Colors.amber.shade700,
                          ),
                          label: vm.referralCode.trim().isNotEmpty
                              ? (_takeawayLang(context) == 'ar'
                                  ? 'إحالة: ${vm.referralCode.trim()}'
                                  : 'Referral: ${vm.referralCode.trim()}')
                              : (_takeawayLang(context) == 'ar'
                                  ? 'إضافة رمز إحالة'
                                  : 'Add referral code'),
                          labelColor: vm.referralCode.trim().isNotEmpty
                              ? Colors.green.shade700
                              : const Color(0xFF1E2124),
                          labelWeight: localeFontWeight(context, FontWeight.w700),
                          onTap: vm.cart.isEmpty
                              ? null
                              : () => _openTakeawayReferralFromPanel(context),
                          trailingClose: vm.referralCode.trim().isEmpty
                              ? null
                              : GestureDetector(
                                  onTap: () {
                                    vm.clearAppliedReferral();
                                    vm.refreshPreview();
                                  },
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondaryLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                buildRow(
                  AppLocalizations.of(context)!.posOrdersTotalBeforeVat,
                  _takeawayMoney(context, afterOrderDiscount),
                ),
                if (promoDiscount > 0.0001) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        size: 12,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.posTakeawayPromoDiscount,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      Text(
                        _takeawayMoney(context, promoDiscount, negative: true),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
                if (vm.referralCode.trim().isNotEmpty ||
                    vm.referralDiscountExclVat > 0.0001) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 12,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _takeawayLang(context) == 'ar'
                              ? 'خصم الإحالة${vm.referralCode.trim().isNotEmpty ? ' (${vm.referralCode.trim()})' : ''}'
                              : 'Referral${vm.referralCode.trim().isNotEmpty ? ': ${vm.referralCode.trim()}' : ' discount'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      if (vm.referralDiscountExclVat > 0.0001)
                        Text(
                          _takeawayMoney(
                            context,
                            vm.referralDiscountExclVat,
                            negative: true,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800,
                          ),
                        ),
                    ],
                  ),
                ],
                if (promoDiscount > 0.0001 ||
                    vm.referralDiscountExclVat > 0.0001) ...[
                  const SizedBox(height: 8),
                  buildRow(
                    AppLocalizations.of(context)!.posOrdersTotalAfterDiscount,
                    _takeawayMoney(
                      context,
                      (taxable - vm.referralDiscountExclVat)
                          .clamp(0, double.infinity),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                buildRow(
                  AppLocalizations.of(context)!.posTakeawayVat15,
                  _takeawayMoney(
                    context,
                    (vm.estimatedDisplayTotal -
                            (taxable - vm.referralDiscountExclVat)
                                .clamp(0, double.infinity))
                        .clamp(0, double.infinity),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.posTakeawayTotal,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _takeawayMoney(context, vm.estimatedDisplayTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: vm.cartLineCount == 0
                              ? null
                              : () => _openTakeawayCheckoutDetailsDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.onPrimaryLight,
                            disabledBackgroundColor: const Color(0xFFE8ECF3),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .posTakeawayCustomerAndPayment,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: !vm.canGenerateTakeawayInvoice
                              ? null
                              : () => _openCheckout(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC145),
                            foregroundColor: const Color(0xFF1E2124),
                            disabledBackgroundColor: const Color(0xFFE8ECF3),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .posTakeawayGenerateInvoice,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTakeawayReferralFromPanel(BuildContext context) async {
    final vm = context.read<TakeawayViewModel>();
    final beforeReferral = vm.estimatedTotalBeforeReferral;
    await ReferralCodeDialog.showLocal(
      context,
      orderAmountInclVat: beforeReferral,
      appliedReferralCode: vm.referralCode,
      customerMobile: vm.customerMobileController.text.trim(),
      onApply: (code, discount) async {
        vm.setAppliedReferral(code: code, discountInclVat: discount);
        return true;
      },
      onRemove: () async {
        vm.clearAppliedReferral();
        return true;
      },
    );
    if (context.mounted) vm.refreshPreview();
  }

  Future<void> _openTakeawayPromoFromPanel(BuildContext context) async {
    final vm = context.read<TakeawayViewModel>();
    await PromoCodeDialog.show(context, isMainTab: false);
    if (!context.mounted) return;
    final posVm = context.read<PosViewModel>();
    final code = posVm.getActivePromoCode(false).trim();
    if (code.isNotEmpty) {
      vm.setAppliedPromo(
        code: code,
        promoId: posVm.activePromoCodeId,
        discount: posVm.promoDiscount,
        isPercent: posVm.isPromoPercent,
      );
    } else {
      vm.clearAppliedPromo();
    }
    vm.refreshPreview();
  }

  String _takeawayDeptTabId(String? departmentId) =>
      (departmentId == null || departmentId.isEmpty) ? '' : departmentId;

  Widget _buildDepartmentSegmentedTabs(
    BuildContext context,
    TakeawayViewModel vm,
    bool isTablet,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = <PosSegmentedTab>[
      PosSegmentedTab(
        id: '',
        label: l10n.posTakeawayAll,
        count: vm.takeawayCountForDepartmentTab(null),
      ),
      if (vm.catalog != null)
        for (final d in vm.catalog!.departments)
          PosSegmentedTab(
            id: d.id,
            label: d.name,
            count: vm.takeawayCountForDepartmentTab(d.id),
          ),
    ];
    return PosSegmentedListTabs(
      tabs: tabs,
      selectedId: _takeawayDeptTabId(vm.selectedDepartmentId),
      onSelected: (id) => vm.setSelectedDepartmentId(id.isEmpty ? null : id),
    );
  }

  Widget _buildCategoryChips(
      BuildContext context,
      TakeawayViewModel vm,
      bool isTablet,
      ) {
    final subCats = vm.takeawayCategoryChipNames;
    final displaySubCats = ['All', ...subCats];
    final l10n = AppLocalizations.of(context)!;
    return PosSegmentedListTabs(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 12,
        vertical: 5,
      ),
      containerColor: Colors.white,
      unselectedTabColor: Colors.white,
      selectedTabColor: AppColors.secondaryLight,
      selectedLabelColor: AppColors.onSecondaryLight,
      tabs: [
        for (final subCat in displaySubCats)
          PosSegmentedTab(
            id: subCat,
            label: subCat == 'All' ? l10n.posTakeawayAll : subCat,
            count: vm.takeawayCountForCategoryTab(subCat),
          ),
      ],
      selectedId: vm.selectedCategory,
      onSelected: vm.setSelectedCategory,
    );
  }

  Widget _buildEmptyState() {
    return ColoredBox(
      color: const Color(0xFFFBFBFD),
      child: SizedBox.expand(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              AppLocalizations.of(context)!.posTakeawayNoProductsFound,
              textAlign: TextAlign.center,
              style: _takeawayCatalogEmptyMessageTextStyle(tablet: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListBody(
      BuildContext context,
      TakeawayViewModel vm,
      bool isTablet,
      bool isPortrait,
      ) {
    final filtered = vm.visibleProducts;
    final currency = vm.catalog?.currency ?? 'SAR';

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => vm.loadCatalog(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    AppLocalizations.of(context)!.posTakeawayNoProductsMatch,
                    textAlign: TextAlign.center,
                    style: _takeawayCatalogEmptyMessageTextStyle(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      return RefreshIndicator(
        onRefresh: () => vm.loadCatalog(),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isPortrait ? 2 : 3,
            mainAxisExtent: 142,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            return Consumer<TakeawayViewModel>(
              builder: (context, tvm, _) {
                final qty = tvm.qtyInCartForProduct(product.id);
                return _buildProductCardTablet(
                  context,
                  tvm,
                  product,
                  qty,
                  currency,
                );
              },
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.loadCatalog(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final product = filtered[index];
          return Consumer<TakeawayViewModel>(
            builder: (context, tvm, _) {
              final qty = tvm.qtyInCartForProduct(product.id);
              return _buildProductCardMobile(
                context,
                tvm,
                product,
                qty,
                currency,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCardMobile(
      BuildContext context,
      TakeawayViewModel vm,
      TakeawayProduct product,
      double cartQty,
      String currency,
      ) {
    final canSelect = product.isActive && !product.isOutOfStockForTakeaway;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canSelect ? () => vm.addProduct(product) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: cartQty > 0
                ? Border.all(color: AppColors.primaryLight, width: 2)
                : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: cartQty > 0 ? 44 : 0,
                                  ),
                                  child: _takeawayProductTitle(
                                    context,
                                    product,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: product.isActive
                                          ? null
                                          : Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          if (product.unit != null &&
                              product.unit!.isNotEmpty) ...[
                            Text(
                              _takeawayUnitLabel(context, product.unit.toString()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: product._stockColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _takeawayStockLabel(context, product),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: product._stockColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cartQty > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.posCommonQtyX(_takeawayQtyText(context, cartQty)),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _takeawayMoney(context, product.salePrice),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    if (canSelect) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyButton(
                            Icons.remove,
                            false,
                            onTap: cartQty > 0
                                ? () => vm.bumpProductQuantity(
                              product,
                              product.allowDecimalQty ? -0.5 : -1,
                            )
                                : null,
                          ),
                          Container(
                            height: 24,
                            width: 28,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              (!product.allowDecimalQty || cartQty % 1 == 0)
                                  ? _takeawayQtyText(context, cartQty)
                                  : _takeawayQtyText(context, cartQty),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _qtyButton(
                            Icons.add,
                            false,
                            onTap: () => vm.addProduct(product),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCardTablet(
      BuildContext context,
      TakeawayViewModel vm,
      TakeawayProduct product,
      double cartQty,
      String currency,
      ) {
    final canSelect = product.isActive && !product.isOutOfStockForTakeaway;
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSelect ? () => vm.addProduct(product) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: cartQty > 0
                    ? Border.all(color: AppColors.primaryLight, width: 2)
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 32,
                          child: _takeawayProductTitle(
                            context,
                            product,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.2,
                              color: product.isActive ? null : Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 14,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: (product.unit != null &&
                                product.unit!.isNotEmpty)
                                ? Text(
                              _takeawayUnitLabel(context, product.unit.toString()),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: product._stockColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _takeawayStockLabel(context, product),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: product._stockColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _takeawayMoney(context, product.salePrice),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.1,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (canSelect)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            children: [
                              _qtyButton(
                                Icons.remove,
                                true,
                                onTap: cartQty > 0
                                    ? () => vm.bumpProductQuantity(
                                  product,
                                  product.allowDecimalQty
                                      ? -0.5
                                      : -1,
                                )
                                    : null,
                              ),
                              Expanded(
                                child: Container(
                                  height: 26,
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    (!product.allowDecimalQty ||
                                        cartQty % 1 == 0)
                                        ? _takeawayQtyText(context, cartQty)
                                        : _takeawayQtyText(context, cartQty),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              _qtyButton(
                                Icons.add,
                                true,
                                onTap: () => vm.addProduct(product),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (cartQty > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.posCommonQtyX(_takeawayQtyText(context, cartQty)),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryLight,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, bool isTablet, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isTablet ? 26 : 28,
        height: isTablet ? 26 : 28,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.secondaryLight : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context,
      TakeawayViewModel vm,
      bool isTablet,
      ) {
    final currency = vm.catalog?.currency ?? 'SAR';
    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 18 : 16,
        12,
        isTablet ? 18 : 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: isTablet ? 18 : 17,
                  color: const Color(0xFF1E2124),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.posTakeawayItemsCount(vm.cartItemCountDisplay),
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2124),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.posTakeawayGrandTotal,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _takeawayMoney(context, vm.estimatedDisplayTotal),
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2124),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: isTablet ? 44 : 46,
                child: ElevatedButton(
                  onPressed: vm.cartLineCount == 0
                      ? null
                      : () => _openTakeawayCheckoutDetailsDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.onPrimaryLight,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.posTakeawayCustomerAndPayment,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isTablet ? 11 : 10,
                      height: 1.1,
                      color: AppColors.onPrimaryLight,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 8 : 6),
              SizedBox(
                height: isTablet ? 44 : 46,
                child: ElevatedButton.icon(
                  onPressed: vm.canGenerateTakeawayInvoice
                      ? () => _openCheckout(context, isTablet)
                      : null,
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    size: isTablet ? 18 : 18,
                  ),
                  label: Text(
                    AppLocalizations.of(context)!.posTakeawayGenerateInvoice,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isTablet ? 13 : 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC145),
                    foregroundColor: const Color(0xFF1E2124),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 14 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyTakeawayCheckoutDetails(
    TakeawayViewModel vm,
    TakeawayCheckoutDetailsResult result,
  ) {
    vm.customerNameController.text = result.customer.name.trim();
    vm.customerMobileController.text = result.customer.mobile.trim();
    vm.customerTaxIdController.text = result.customer.vat.trim();
    vm.vehiclePlateController.text = result.customer.vehicleNumber.trim();
    vm.setInvoicePaymentPreferences(
      isCorporate: result.payment.isCorporate,
      methods: result.payment.payments,
      amounts: result.payment.paymentAmounts,
    );
    vm.refreshPreview();
  }

  Future<void> _openTakeawayCheckoutDetailsDialog(BuildContext context) async {
    final vm = context.read<TakeawayViewModel>();
    if (vm.checkoutContext == null && !vm.checkoutContextLoading) {
      await vm.loadCheckoutContext();
    }
    if (!context.mounted) return;

    final initial = WalkInInvoiceFormResult(
      name: vm.customerNameController.text.trim(),
      mobile: vm.customerMobileController.text.trim(),
      vat: vm.customerTaxIdController.text.trim(),
      vehicleNumber: vm.vehiclePlateController.text.trim(),
      vin: '',
      make: '',
      model: '',
      year: '',
      color: '',
      odometer: 0,
    );

    final result = await showTakeawayCheckoutDetailsDialog(
      context: context,
      initialCustomer: initial,
      initialIsCorporate: vm.isCorporate,
      initialPayments: vm.invoicePaymentMethods,
      initialPaymentAmounts: vm.invoicePaymentAmounts,
      totalAmount: vm.estimatedDisplayTotal,
      branchEmployees: vm.branchEmployees,
      checkoutContextLoading: vm.checkoutContextLoading,
    );
    if (result == null || !context.mounted) return;
    _applyTakeawayCheckoutDetails(vm, result);
    ToastService.showSuccess(
      context,
      AppLocalizations.of(context)!.posTakeawayCheckoutSaved,
    );
  }

  Future<void> _openCheckout(BuildContext context, bool isTablet) async {
    final vm = context.read<TakeawayViewModel>();
    if (vm.cart.isEmpty) return;

    if (!vm.hasRequiredTakeawayBillingFields || !vm.paymentSelectionReady) {
      await _openTakeawayCheckoutDetailsDialog(context);
      if (!context.mounted) return;
      if (!vm.hasRequiredTakeawayBillingFields) {
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.posTakeawayCustomerRequired,
        );
        return;
      }
      if (!vm.paymentSelectionReady) {
        ToastService.showError(
          context,
          AppLocalizations.of(context)!.posTakeawaySelectPaymentFirst,
        );
        return;
      }
    }

    final totalAmount = vm.estimatedDisplayTotal;
    final pay = vm.buildPaymentPayloadForTotal(totalAmount);
    final pm = pay['paymentMethod'] as String?;
    final payments = pay['payments'] as List<Map<String, dynamic>>?;
    if (payments == null || payments.isEmpty) {
      ToastService.showError(context, AppLocalizations.of(context)!.posTakeawayValidPaymentAmounts);
      return;
    }
    if (pm != null && pm.isNotEmpty) {
      vm.setPaymentMethod(pm);
    } else {
      vm.setPayments(payments);
    }

    // SoftPOS / NFC — only when Tap to Pay is in the payment splits.
    if (vm.isCorporate != true && SoftPosBridge.splitsIncludeSoftPos(payments)) {
      if (!await SoftPosConnectionGuard.ensureStableOrToast(context)) return;
      if (!context.mounted) return;
      try {
        final lineSummary = vm.cart
            .take(3)
            .map((l) => l.product.name.trim())
            .where((n) => n.isNotEmpty)
            .join(', ');
        final softPosOk = await runSoftPosBeforeTakeawayCheckout(
          context: context,
          paymentSplits: payments,
          customerName: vm.customerNameController.text.trim(),
          customerMobile: vm.customerMobileController.text.trim(),
          lineSummary: lineSummary.isEmpty ? 'Takeaway' : lineSummary,
        );
        if (!context.mounted) return;
        if (!softPosOk) {
          ToastService.showError(
            context,
            'Tap to Pay was not approved on SoftPOS.',
          );
          return;
        }
      } on SoftPosBridgeException catch (e) {
        if (!context.mounted) return;
        ToastService.showError(context, e.message);
        return;
      }
    }

    final res = await vm.submitCheckout();
    if (!context.mounted) return;
    if (res == null || !res.success || vm.lastInvoice == null) {
      final rawError = vm.checkoutError ?? res?.message ?? AppLocalizations.of(context)!.posTakeawayInvoiceFailed;
      final localizedError = AppTranslationService.localizeDigitsForLanguage(
        rawError,
        _takeawayLang(context),
      );
      ToastService.showError(context, localizedError);
      return;
    }

    // [InvoiceDialog] already pops the dialog in its Done handler; do not pop again
    // here (that removed the shell route and caused a black screen).
    final inv = vm.lastInvoice!;
    final paymentText = invoiceDialogPaymentMethodText(
      inv,
      requestedPaymentMethod: pm ?? payments.map((p) => p['method']).join(' + '),
    );
    await showInvoiceDialogAfterPrintPrefetch(
      context: context,
      invoice: inv,
      paymentMethodText: paymentText,
      builder: (ctx) => InvoiceDialog(
        invoice: inv,
        requestedPaymentMethod: pm ?? payments.map((p) => p['method']).join(' + '),
        onDone: () {},
      ),
    );
    vm.resetLastInvoice();
  }
}

class _TakeawayCartItemCompactTile extends StatefulWidget {
  const _TakeawayCartItemCompactTile({
    super.key,
    required this.line,
    required this.currency,
    required this.vm,
    required this.isTablet,
  });

  final TakeawayCartLine line;
  final String currency;
  final TakeawayViewModel vm;
  final bool isTablet;

  @override
  State<_TakeawayCartItemCompactTile> createState() => _TakeawayCartItemCompactTileState();
}

class _TakeawayCartItemCompactTileState extends State<_TakeawayCartItemCompactTile> {
  late TextEditingController _discController;
  late TextEditingController _priceController;
  final FocusNode _priceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _discController = TextEditingController(
      text: widget.line.lineDiscountValue > 0
          ? (widget.line.lineDiscountValue % 1 == 0
          ? widget.line.lineDiscountValue.toInt().toString()
          : widget.line.lineDiscountValue.toString())
          : '',
    );
    _priceController = TextEditingController(
      text: widget.line.unitPrice > 0
          ? widget.line.unitPrice.toStringAsFixed(2)
          : '',
    );
    _priceFocus.addListener(() {
      if (!_priceFocus.hasFocus) {
        _commitUnitPrice();
        _syncPriceControllerFromModelIfNeeded();
      }
    });
  }

  double? _parseUnitPriceField(String raw) {
    final normalized =
        EnglishNumberFormatter.convert(raw.trim()).replaceAll(',', '.');
    if (normalized.isEmpty || normalized == '.' || normalized == '-') {
      return null;
    }
    var text = normalized;
    if (RegExp(r'^\d+\.$').hasMatch(text)) {
      text = '${text}0';
    }
    final p = double.tryParse(text);
    if (p == null || !p.isFinite || p <= 0) return null;
    return p;
  }

  void _syncPriceControllerFromModelIfNeeded() {
    final next = widget.line.unitPrice;
    final raw = EnglishNumberFormatter.convert(_priceController.text.trim())
        .replaceAll(',', '.');
    final fromField = double.tryParse(raw);
    final matches =
        fromField != null && (fromField - next).abs() < 0.005;
    if (!matches) {
      final s = next.toStringAsFixed(2);
      if (_priceController.text != s) {
        _priceController.text = s;
      }
    }
  }

  void _commitUnitPrice() {
    if (!widget.line.product.isPriceEditable) return;
    final parsed = _parseUnitPriceField(_priceController.text);
    if (parsed == null) {
      _syncPriceControllerFromModelIfNeeded();
      return;
    }
    final err = widget.vm.tryUpdateLineUnitPrice(widget.line.product.id, parsed);
    if (err == 'below_min') {
      final min = widget.line.product.minEditablePriceVatInclusive;
      ToastService.showError(
        context,
        'Price cannot be below SAR ${min.toStringAsFixed(2)} for this product.',
      );
      _syncPriceControllerFromModelIfNeeded();
      return;
    }
    if (err != null) {
      _syncPriceControllerFromModelIfNeeded();
      return;
    }
    _syncPriceControllerFromModelIfNeeded();
  }

  @override
  void didUpdateWidget(_TakeawayCartItemCompactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.lineDiscountValue != widget.line.lineDiscountValue) {
      final text = widget.line.lineDiscountValue > 0
          ? (widget.line.lineDiscountValue % 1 == 0
          ? widget.line.lineDiscountValue.toInt().toString()
          : widget.line.lineDiscountValue.toString())
          : '';
      if (_discController.text != text) {
        _discController.text = text;
      }
    }
    if (!_priceFocus.hasFocus) {
      _syncPriceControllerFromModelIfNeeded();
    }
  }

  @override
  void dispose() {
    _priceFocus.dispose();
    _priceController.dispose();
    _discController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final isPercent = (line.lineDiscountType ?? '') == 'percent' ||
        (line.lineDiscountType ?? '') == 'percentage';
    final grossLineTotal = line.unitPriceExclVat * line.qty;
    final lineDiscountAmount = isPercent
        ? (grossLineTotal * (line.lineDiscountValue / 100))
        : line.lineDiscountValue;
    final safeDiscount = min(grossLineTotal, max(0.0, lineDiscountAmount));
    final discountedLineTotal = max(0.0, grossLineTotal - safeDiscount);
    final priceEditable = line.product.isPriceEditable;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _takeawayProductTitle(
                  context,
                  line.product,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2124),
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (safeDiscount > 0)
                    Text(
                      _takeawayMoney(context, grossLineTotal),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                    ),
                  Text(
                    _takeawayMoney(context, discountedLineTotal),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2124),
                      height: 1.15,
                    ),
                  ),
                  if (safeDiscount > 0)
                    Text(
                      _takeawayMoney(context, safeDiscount, negative: true),
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => widget.vm.removeLine(line.product.id),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 11,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (priceEditable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: _takeawayCartQtyPriceRowDecoration(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _takeawayQtyText(context, line.qty),
                    style: _takeawayCartQtyPriceMutedStyle(false).copyWith(
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    ' × ${AppLocalizations.of(context)!.posCommonSar} ',
                    style: _takeawayCartQtyPriceMutedStyle(false).copyWith(
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _priceController,
                      focusNode: _priceFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: _takeawayCartQtyPriceValueStyle(
                        context,
                        false,
                      ).copyWith(fontSize: 10),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        border: InputBorder.none,
                        hintText: AppLocalizations.of(context)!
                            .posProductEditServicePriceHint,
                      ),
                      onChanged: (v) {
                        final p = _parseUnitPriceField(v);
                        if (p != null) {
                          final err = widget.vm.tryUpdateLineUnitPrice(
                            line.product.id,
                            p,
                          );
                          if (err == 'below_min') {
                            ToastService.showError(
                              context,
                              'Price cannot be below SAR ${line.product.minEditablePriceVatInclusive.toStringAsFixed(2)} for this product.',
                            );
                            _syncPriceControllerFromModelIfNeeded();
                            return;
                          }
                          if (err != null) {
                            _syncPriceControllerFromModelIfNeeded();
                          }
                        }
                      },
                      onEditingComplete: _commitUnitPrice,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: _takeawayCartQtyPriceRowDecoration(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _takeawayQtyText(context, line.qty),
                    style: _takeawayCartQtyPriceMutedStyle(false).copyWith(
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    ' × ${AppLocalizations.of(context)!.posCommonSar} ',
                    style: _takeawayCartQtyPriceMutedStyle(false).copyWith(
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _takeawayDigits(
                      context,
                      line.unitPrice.toStringAsFixed(2),
                    ),
                    style: _takeawayCartQtyPriceValueStyle(
                      context,
                      false,
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.posTakeawayDis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                height: 22,
                child: TextFormField(
                  controller: _discController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0;
                    widget.vm.updateLineDiscount(
                      line.product.id,
                      discountType: isPercent ? 'percent' : 'amount',
                      discountValue: d,
                    );
                  },
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  widget.vm.updateLineDiscount(
                    line.product.id,
                    discountType: isPercent ? 'amount' : 'percent',
                    discountValue: line.lineDiscountValue,
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC145).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isPercent
                        ? '%'
                        : AppLocalizations.of(context)!.posCommonSar,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2124),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TakeawayCatalogShimmer extends StatelessWidget {
  const _TakeawayCatalogShimmer({required this.isTablet});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isTablet ? 22 : 12, 16, isTablet ? 14 : 12, 12),
      child: isTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _catalogArea(context, true)),
                const SizedBox(width: 12),
                SizedBox(width: 360, child: _invoicePanel()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PosShimmer(
                  child: PosShimmerBox(
                    width: double.infinity,
                    height: 44,
                    radius: 14,
                  ),
                ),
                const SizedBox(height: 16),
                PosShimmer(child: _chipRow()),
                const SizedBox(height: 14),
                Expanded(child: _productList(false)),
              ],
            ),
    );
  }

  Widget _catalogArea(BuildContext context, bool tablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PosShimmer(
          child: PosShimmerBox(
            width: double.infinity,
            height: 46,
            radius: 14,
          ),
        ),
        const SizedBox(height: 14),
        PosShimmer(child: _chipRow()),
        const SizedBox(height: 12),
        PosShimmer(child: _chipRow(short: true)),
        const SizedBox(height: 14),
        Expanded(child: _productList(tablet)),
      ],
    );
  }

  Widget _chipRow({bool short = false}) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: short ? 4 : 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) =>
            PosShimmerBox(width: i == 0 ? 72 : 100, height: 36, radius: 12),
      ),
    );
  }

  Widget _productList(bool tablet) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tablet ? 8 : 5,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: tablet ? 2 : 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 96,
      ),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const PosShimmer(
          child: Row(
            children: [
              PosShimmerBox(width: 58, height: 58, radius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PosShimmerLine(width: double.infinity, height: 13),
                    SizedBox(height: 8),
                    PosShimmerLine(width: 120, height: 11),
                    SizedBox(height: 8),
                    PosShimmerLine(width: 74, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoicePanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const PosShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosShimmerLine(width: 140, height: 14),
            SizedBox(height: 16),
            PosShimmerBox(width: double.infinity, height: 48, radius: 12),
            SizedBox(height: 10),
            PosShimmerBox(width: double.infinity, height: 48, radius: 12),
            Spacer(),
            PosShimmerLine(width: double.infinity, height: 12),
            SizedBox(height: 10),
            PosShimmerLine(width: double.infinity, height: 12),
            SizedBox(height: 14),
            PosShimmerBox(width: double.infinity, height: 44, radius: 12),
          ],
        ),
      ),
    );
  }
}

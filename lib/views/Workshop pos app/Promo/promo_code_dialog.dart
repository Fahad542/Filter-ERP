import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../utils/app_keyboard_locale.dart';
import '../../../utils/toast_service.dart';
import '../../../models/pos_order_model.dart';
import '../Home Screen/pos_view_model.dart';
import 'promo_view_model.dart';
import 'promo_promotion_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/LocalizedApiText.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../widgets/pos_shimmer.dart';

/// Order Summary promo context: the dialog validates against the placed
/// order's lines and persists via the [onApply] / [onRemove] callbacks
/// instead of the live POS cart.
class PromoOrderTarget {
  final PosOrder order;
  final double orderAmountExclVat;
  final double orderAmountInclVat;

  /// Set when the order has exactly one promo-editable job — the backend then
  /// rebuilds that job's lines (incl. category ids) itself.
  final String? primaryJobId;
  final List<Map<String, dynamic>> lineItems;
  final String appliedPromoCode;
  final Future<bool> Function(String code, Map<String, dynamic> validResult)
      onApply;
  final Future<bool> Function() onRemove;

  const PromoOrderTarget({
    required this.order,
    required this.orderAmountExclVat,
    required this.orderAmountInclVat,
    this.primaryJobId,
    this.lineItems = const [],
    this.appliedPromoCode = '',
    required this.onApply,
    required this.onRemove,
  });
}

class PromoCodeDialog extends StatefulWidget {
  final bool isMainTab;
  final String? departmentId;
  final PromoOrderTarget? orderTarget;
  const PromoCodeDialog({
    super.key,
    this.isMainTab = false,
    this.departmentId,
    this.orderTarget,
  });

  static Future<void> show(
    BuildContext context, {
    bool isMainTab = false,
    String? departmentId,
    PromoOrderTarget? orderTarget,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PromoCodeDialog(
        isMainTab: isMainTab,
        departmentId: departmentId,
        orderTarget: orderTarget,
      ),
    );
  }

  @override
  State<PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends State<PromoCodeDialog> {
  String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode;
  bool _isAr(BuildContext context) => _lang(context) == 'ar';

  String _digits(BuildContext context, Object? value) {
    return AppTranslationService.localizeDigitsForLanguage(
      value?.toString() ?? '',
      _lang(context),
    );
  }

  String _money(BuildContext context, num amount) {
    final lang = _lang(context);
    final v = _digits(context, amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2));
    return lang == 'ar' ? '$v ر.س' : 'SAR $v';
  }

  String _discountText(BuildContext context, double discount, bool isPercent) {
    final amount = discount % 1 == 0
        ? discount.toStringAsFixed(0)
        : discount.toStringAsFixed(2);
    final d = _digits(context, amount);
    if (_isAr(context)) {
      return isPercent ? 'خصم $d٪' : 'خصم ${_money(context, discount)}';
    }
    return isPercent ? '$d% OFF' : '${_money(context, discount)} OFF';
  }

  String _validDiscountText(BuildContext context, Map<String, dynamic> result) {
    final rawDiscount = result['discount'];
    final discount = rawDiscount is num
        ? rawDiscount.toDouble()
        : double.tryParse(rawDiscount?.toString() ?? '') ?? 0;
    final isPercent = result['isPercent'] == true;
    return _discountText(context, discount, isPercent);
  }

  final TextEditingController _controller = TextEditingController();

  void _closeDialogSafely() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool get _isOrderMode => widget.orderTarget != null;
  bool _isPersistingToOrder = false;

  /// Code of the promotion card currently being applied end-to-end (validate +
  /// persist). While set, the "Valid Promo Code" conditions ticket is hidden so
  /// tapping "Apply Promo" on a card applies directly without an extra step.
  String? _cardApplyInFlightCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final promoVm = context.read<PromoViewModel>();
      if (_isOrderMode) {
        promoVm.clearPromoError();
        promoVm.clearPromoPreview();
        final appliedCode = widget.orderTarget!.appliedPromoCode.trim();
        if (appliedCode.isNotEmpty) {
          _controller.text = appliedCode.toUpperCase();
        } else {
          _controller.clear();
        }
        promoVm.fetchAvailablePromos(forceRefresh: true);
        return;
      }
      final posVm = context.read<PosViewModel>();
      final deptId = widget.departmentId ??
          posVm.getPromoContextDepartmentId(widget.isMainTab);
      if (deptId != null && deptId.trim().isNotEmpty) {
        posVm.setPromoContextDepartment(deptId, isMainTab: widget.isMainTab);
      }
      promoVm.clearPromoError(preserveAppliedPreview: true);
      final appliedCode =
          posVm.getActivePromoCode(widget.isMainTab, departmentId: deptId).trim();
      if (appliedCode.isNotEmpty) {
        posVm.reaffirmAppliedPromoOnCart(
          isMainTab: widget.isMainTab,
          departmentId: deptId,
        );
        _controller.text = appliedCode;
        promoVm.syncPreviewFromAppliedCartPromo(
          posVm,
          isMainTab: widget.isMainTab,
          departmentId: deptId,
        );
      } else {
        promoVm.clearPromoPreview();
        _controller.clear();
      }
      promoVm.fetchAvailablePromos(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkPromoCode() async {
    final promoVm = context.read<PromoViewModel>();
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    if (_isOrderMode) {
      final target = widget.orderTarget!;
      await promoVm.checkPromoCodeForOrder(
        code,
        orderAmountExclVat: target.orderAmountExclVat,
        orderAmountInclVat: target.orderAmountInclVat,
        primaryJobId: target.primaryJobId,
        lineItems: target.lineItems,
      );
    } else {
      final posVm = context.read<PosViewModel>();
      await promoVm.checkPromoCode(
        code,
        posVm,
        context,
        isMainTab: widget.isMainTab,
      );
    }

    if (!mounted) return;
    if (promoVm.promoErrorMessage != null) {
      ToastService.showError(context, promoVm.promoErrorMessage!);
    }
    setState(() {});
  }

  /// Order mode: persists the validated promo through [PromoOrderTarget.onApply].
  Future<void> _persistValidatedPromoToOrder(PromoViewModel promoVm) async {
    final validResult = promoVm.validResult;
    if (validResult == null) return;
    final code = promoVm.promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isPersistingToOrder = true);
    var applied = false;
    try {
      applied = await widget.orderTarget!.onApply(code, validResult);
    } finally {
      if (mounted) setState(() => _isPersistingToOrder = false);
    }
    if (!mounted) return;
    if (applied) {
      _closeDialogSafely();
    } else {
      setState(() {});
    }
  }

  Future<void> _applyFromList(String code) async {
    final promoVm = context.read<PromoViewModel>();
    _controller.text = code;

    if (_isOrderMode) {
      final target = widget.orderTarget!;
      setState(() => _cardApplyInFlightCode = code.trim().toUpperCase());
      try {
        final valid = await promoVm.validatePromoForOrderFromCard(
          code,
          orderAmountExclVat: target.orderAmountExclVat,
          orderAmountInclVat: target.orderAmountInclVat,
          primaryJobId: target.primaryJobId,
          lineItems: target.lineItems,
        );
        if (!mounted) return;
        if (!valid) {
          if (promoVm.promoErrorMessage != null) {
            ToastService.showError(context, promoVm.promoErrorMessage!);
          }
          setState(() {});
          return;
        }
        await _persistValidatedPromoToOrder(promoVm);
      } finally {
        if (mounted) setState(() => _cardApplyInFlightCode = null);
      }
      return;
    }

    final posVm = context.read<PosViewModel>();
    final applied = await promoVm.applyPromoFromCard(
      code,
      posVm,
      context,
      isMainTab: widget.isMainTab,
    );

    if (!mounted) return;
    if (applied) {
      _closeDialogSafely();
    } else {
      setState(() {});
    }
  }

  Future<void> _applyCheckedPromo() async {
    final promoVm = context.read<PromoViewModel>();

    if (_isOrderMode) {
      await _persistValidatedPromoToOrder(promoVm);
      return;
    }

    final posVm = context.read<PosViewModel>();
    final applied = await promoVm.applyCheckedPromoToCart(
      posVm,
      context,
      isMainTab: widget.isMainTab,
    );
    if (!mounted) return;
    if (applied) {
      _closeDialogSafely();
    } else {
      setState(() {});
    }
  }

  void _removeAppliedPromo() {
    final promoVm = context.read<PromoViewModel>();

    if (_isOrderMode) {
      promoVm.clearPromoPreview();
      _controller.clear();
      final hadAppliedPromo =
          widget.orderTarget!.appliedPromoCode.trim().isNotEmpty;
      if (!hadAppliedPromo) {
        setState(() {});
        return;
      }
      setState(() => _isPersistingToOrder = true);
      widget.orderTarget!.onRemove().whenComplete(() {
        if (!mounted) return;
        setState(() => _isPersistingToOrder = false);
        _closeDialogSafely();
      });
      return;
    }

    final posVm = context.read<PosViewModel>();
    final deptId = widget.departmentId ??
        posVm.getPromoContextDepartmentId(widget.isMainTab);
    promoVm.removeAppliedPromo(
      posVm,
      isMainTab: widget.isMainTab,
      departmentId: deptId,
    );
    _controller.clear();
    setState(() {});
  }

  int _promoGridCrossAxisCount(double screenWidth, bool isTablet) {
    if (isTablet || screenWidth >= 640) return 3;
    if (screenWidth >= 420) return 2;
    return 1;
  }

  double _promoGridHeight({
    required int itemCount,
    required int crossAxisCount,
    required double cardExtent,
    required double spacing,
    required double maxHeight,
  }) {
    if (itemCount <= 0) return 96;
    final rows = (itemCount + crossAxisCount - 1) ~/ crossAxisCount;
    final contentHeight = rows * cardExtent + (rows - 1) * spacing;
    return contentHeight.clamp(0.0, maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    final promoVm = context.watch<PromoViewModel>();
    final posVm = context.watch<PosViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogMaxHeight = (screenHeight * (isTablet ? 0.91 : 0.94)).clamp(
      460.0,
      isTablet ? 760.0 : 720.0,
    );
    final deptId = widget.departmentId ??
        posVm.getPromoContextDepartmentId(widget.isMainTab);
    final appliedPromoCode = _isOrderMode
        ? widget.orderTarget!.appliedPromoCode.trim().toUpperCase()
        : posVm
            .getActivePromoCode(widget.isMainTab, departmentId: deptId)
            .trim()
            .toUpperCase();
    final isPromoApplied = appliedPromoCode.isNotEmpty;
    final hasPromoSelection = isPromoApplied || promoVm.validResult != null;
    final shouldLockInput = hasPromoSelection;
    const gridSpacing = 8.0;
    final crossAxisCount = _promoGridCrossAxisCount(screenWidth, isTablet);
    final cardExtent = promoPromotionCardExtent(isTablet: isTablet);
    final promoCount = promoVm.availablePromotions.length;
    final shimmerCount = crossAxisCount * 2;
    final maxGridHeight = (dialogMaxHeight * 0.52).clamp(160.0, 420.0);
    final naturalGridHeight = promoVm.isLoadingPromos
        ? _promoGridHeight(
            itemCount: shimmerCount,
            crossAxisCount: crossAxisCount,
            cardExtent: cardExtent,
            spacing: gridSpacing,
            maxHeight: maxGridHeight,
          )
        : promoCount <= 0
            ? 96.0
            : _promoGridHeight(
                itemCount: promoCount,
                crossAxisCount: crossAxisCount,
                cardExtent: cardExtent,
                spacing: gridSpacing,
                maxHeight: maxGridHeight,
              );
    final gridScrollable = promoCount > 0 &&
        _promoGridHeight(
              itemCount: promoCount,
              crossAxisCount: crossAxisCount,
              cardExtent: cardExtent,
              spacing: gridSpacing,
              maxHeight: double.infinity,
            ) >
            maxGridHeight;
    // Card taps apply directly — never surface the intermediate
    // "check conditions" ticket while that flow is in flight.
    final hasValidResultTicket = promoVm.validResult != null &&
        promoVm.promoErrorMessage == null &&
        _cardApplyInFlightCode == null;

    return PopScope(
      canPop: false,
      child: Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 6,
        vertical: isTablet ? 10 : 8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet
              ? (screenWidth * 0.94).clamp(720.0, 980.0)
              : (screenWidth - 8),
          maxHeight: dialogMaxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.posPromoApplyPromoCode,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: isTablet ? 19 : 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.posPromoSelectPromoBelow,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                  fontSize: isTablet ? 13 : 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: naturalGridHeight,
                child: Builder(
                  builder: (_) {
                    if (promoVm.isLoadingPromos) {
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: shimmerCount,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: cardExtent,
                          crossAxisSpacing: gridSpacing,
                          mainAxisSpacing: gridSpacing,
                        ),
                        itemBuilder: (_, _) => const _PromoDialogCardShimmer(),
                      );
                    }
                    if (promoVm.availablePromotions.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.posPromoNoPromoCodesAvailable,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: gridScrollable
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      itemCount: promoVm.availablePromotions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: cardExtent,
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: gridSpacing,
                      ),
                      itemBuilder: (context, index) {
                        final promo = promoVm.availablePromotions[index];
                        final isCardBusy = promoVm.isApplyingAnyCard ||
                            promoVm.isChecking ||
                            _isPersistingToOrder;
                        final isAlreadyApplied = isPromoApplied &&
                            appliedPromoCode ==
                                promo.code.trim().toUpperCase();
                        final isThisCardApplying =
                            promoVm.isApplyingCard(promo.code) ||
                                _cardApplyInFlightCode ==
                                    promo.code.trim().toUpperCase();
                        return PromoPromotionCard(
                          promo: promo,
                          isApplying: isThisCardApplying,
                          onTap: isCardBusy || isAlreadyApplied
                              ? null
                              : () => _applyFromList(promo.code),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.posPromoEnterCodeManually,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _controller,
                hintLocales: appKeyboardHintLocales(context),
                textCapitalization: TextCapitalization.characters,
                readOnly: shouldLockInput,
                style: TextStyle(fontSize: isTablet ? 14 : 13),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.posPromoExampleSave10,
                  hintStyle: TextStyle(fontSize: isTablet ? 13 : 12),
                  filled: true,
                  fillColor: isPromoApplied
                      ? Colors.grey.shade200
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: hasPromoSelection
                      ? IconButton(
                          onPressed:
                              _isPersistingToOrder ? null : _removeAppliedPromo,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          tooltip: AppLocalizations.of(
                            context,
                          )!.posPromoRemovePromo,
                        )
                      : null,
                ),
              ),
              if (promoVm.promoErrorMessage != null) ...[
                const SizedBox(height: 6),
                LocalizedApiText(
                  promoVm.promoErrorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Show result ticket if valid
              if (hasValidResultTicket) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.posPromoValidPromoCode,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isPromoApplied) ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: promoVm.isApplyingAnyCard ||
                                      promoVm.isChecking ||
                                      _isPersistingToOrder
                                  ? null
                                  : _applyCheckedPromo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryLight,
                                foregroundColor: AppColors.onSecondaryLight,
                                disabledBackgroundColor:
                                    AppColors.secondaryLight.withOpacity(0.5),
                                disabledForegroundColor:
                                    AppColors.onSecondaryLight.withOpacity(0.7),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'تطبيق العرض'
                                    : 'Apply Promo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildResultRow(
                        AppLocalizations.of(context)!.posPromoDiscountLabel,
                        _validDiscountText(context, promoVm.validResult!),
                      ),
                      const SizedBox(height: 4),
                      _buildResultRow(
                        AppLocalizations.of(context)!.posPromoStoreLabel,
                        promoVm.validResult!['store'],
                      ),
                      const SizedBox(height: 4),
                      _buildResultRow(
                        AppLocalizations.of(context)!.posPromoProductsLabel,
                        promoVm.validResult!['products'],
                      ),
                      const SizedBox(height: 4),
                      _buildResultRow(
                        AppLocalizations.of(context)!.posCommonServices,
                        promoVm.validResult!['services'],
                      ),
                      const SizedBox(height: 4),
                      if (promoVm.validResult!['period'] != null)
                        _buildResultRow(
                          AppLocalizations.of(context)!.posPromoValidityLabel,
                          promoVm.validResult!['period'],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<PromoViewModel>()
                            .clearPromoError(preserveAppliedPreview: true);
                        _closeDialogSafely();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.posCommonCancel,
                        style: TextStyle(fontSize: isTablet ? 13 : 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (promoVm.isChecking ||
                              isPromoApplied ||
                              promoVm.isApplyingAnyCard ||
                              _isPersistingToOrder)
                          ? null
                          : _checkPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.primaryLight,
                        disabledForegroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: promoVm.isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.posPromoCheckCode,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: isTablet ? 13 : 12,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: LocalizedApiText(
            _digits(context, value),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Skeleton matching [PromoPromotionCard] rows in the apply-promo dialog.
class _PromoDialogCardShimmer extends StatelessWidget {
  const _PromoDialogCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: PosShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PosShimmerLine(width: double.infinity, height: 14),
                          SizedBox(height: 8),
                          PosShimmerLine(width: 140, height: 10),
                          SizedBox(height: 6),
                          PosShimmerLine(width: 100, height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PosShimmerBox(width: 72, height: 28, radius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 30,
                      radius: 7,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: PosShimmerBox(
                      width: double.infinity,
                      height: 30,
                      radius: 7,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

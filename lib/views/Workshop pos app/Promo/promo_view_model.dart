import 'dart:async';

import 'package:flutter/material.dart';
import '../../../services/session_service.dart';
import '../../../utils/toast_service.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../../models/pos_product_model.dart';
import '../../../models/promo_code_model.dart';
import '../Home Screen/pos_view_model.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../utils/promo_eligibility.dart';
import '../../../utils/promo_application_requirements.dart';

class AvailablePromotion {
  final String code;
  final String title;
  final String description;
  final double discount;
  final bool isPercent;
  final String applicableStore;
  final String applicableWorkshops;
  final String applicableProducts;
  final String applicableServices;
  final String validityPeriod;
  final String? promoCodeId;
  final List<String> productNames;
  final List<String> serviceNames;
  final String productScope;
  final String serviceScope;
  final String selectedItemMatchMode;
  final bool selectedServiceRequired;

  AvailablePromotion({
    required this.code,
    required this.title,
    required this.description,
    required this.discount,
    required this.isPercent,
    required this.applicableStore,
    required this.applicableWorkshops,
    required this.applicableProducts,
    required this.applicableServices,
    required this.validityPeriod,
    this.promoCodeId,
    this.productNames = const [],
    this.serviceNames = const [],
    this.productScope = 'all',
    this.serviceScope = 'all',
    this.selectedItemMatchMode = 'all_required',
    this.selectedServiceRequired = true,
  });
}

class PromoViewModel extends ChangeNotifier with TranslatableMixin {
  final SessionService sessionService;
  final PosRepository posRepository;

  PromoViewModel({
    required this.sessionService,
    required this.posRepository,
  });

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  Future<void> retranslate() async {
    notifyListeners();
  }

  bool _isLoading = false;
  bool _isChecking = false;
  String? _applyingCardCode;
  String? _promoErrorMessage;
  final TextEditingController promoController = TextEditingController();

  Map<String, dynamic>? _validResult;
  Map<String, dynamic>? get validResult => _validResult;

  List<AvailablePromotion> _availablePromotions = [];
  final Map<String, PromoData> _promoDataByCode = {};
  final Map<String, PromoData> _promoDataById = {};
  bool _isLoadingPromos = false;
  Timer? _revalidateDebounce;
  bool _isRevalidating = false;

  bool get isLoading => _isLoading;
  bool get isChecking => _isChecking;
  bool isApplyingCard(String code) =>
      _applyingCardCode?.trim().toUpperCase() ==
      code.trim().toUpperCase();
  bool get isApplyingAnyCard => _applyingCardCode != null;
  bool get isLoadingPromos => _isLoadingPromos;
  String? get promoErrorMessage => _promoErrorMessage;
  List<AvailablePromotion> get availablePromotions => _availablePromotions;

  static (String products, String services) _resolveProductServiceLabels(
    PromoData code,
  ) {
    final productsDirect = code.applicableProducts?.trim() ?? '';
    final servicesDirect = code.applicableServices?.trim() ?? '';
    if (servicesDirect.isNotEmpty) {
      return (
        productsDirect.isNotEmpty ? productsDirect : 'All Products',
        servicesDirect,
      );
    }
    if (productsDirect == 'All Products & Services') {
      return ('All Products', 'All Services');
    }
    const sep = ' · ';
    final idx = productsDirect.indexOf(sep);
    if (idx >= 0) {
      return (
        productsDirect.substring(0, idx).trim(),
        productsDirect.substring(idx + sep.length).trim(),
      );
    }
    return (
      productsDirect.isNotEmpty ? productsDirect : 'All Products',
      'All Services',
    );
  }

  Future<void> fetchAvailablePromos({bool forceRefresh = false}) async {
    if (!forceRefresh && _promoDataByCode.isNotEmpty) return;
    _isLoadingPromos = true;
    if (forceRefresh) {
      _availablePromotions = [];
    }
    notifyListeners();
    try {
      final token = await sessionService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await posRepository.getPromoCodes(token);
      if (response.success && response.promoCodes != null) {
        _promoDataByCode.clear();
        _promoDataById.clear();
        _availablePromotions = response.promoCodes!.map((code) {
          final normalizedCode = code.code.trim().toUpperCase();
          if (normalizedCode.isNotEmpty) {
            _promoDataByCode[normalizedCode] = code;
          }
          final id = code.id?.trim();
          if (id != null && id.isNotEmpty) {
            _promoDataById[id] = code;
          }
          final label = code.discountLabel?.trim();
          final promoTitle = code.promotionName?.trim();
          final (productsLabel, servicesLabel) =
              _resolveProductServiceLabels(code);
          return AvailablePromotion(
            code: code.code,
            title: (label != null && label.isNotEmpty)
                ? label
                : (code.isPercent
                    ? '${code.discount}% Discount'
                    : 'SAR ${code.discount} Discount'),
            description: (code.description?.trim().isNotEmpty == true)
                ? code.description!.trim()
                : (promoTitle?.isNotEmpty == true
                    ? promoTitle!
                    : 'Promotional discount'),
            discount: code.discount,
            isPercent: code.isPercent,
            applicableStore: code.applicableStore ?? 'All Branches',
            applicableWorkshops: code.workshopScope?.trim().isNotEmpty == true
                ? code.workshopScope!.trim()
                : (code.workshopIds.isEmpty
                    ? 'All Workshops'
                    : '${code.workshopIds.length} Workshops'),
            applicableProducts: productsLabel,
            applicableServices: servicesLabel,
            validityPeriod: code.validityPeriod ?? 'No Expiry',
            promoCodeId: code.id,
            productNames: code.productNames,
            serviceNames: code.serviceNames,
            productScope: code.productScope ?? 'all',
            serviceScope: code.serviceScope ?? 'all',
            selectedItemMatchMode: code.selectedItemMatchMode ?? 'all_required',
            selectedServiceRequired: code.selectedServiceRequired,
          );
        }).toList();
      } else {
        _availablePromotions = [];
        _promoDataByCode.clear();
        _promoDataById.clear();
      }
    } catch (_) {
      _availablePromotions = [];
      _promoDataByCode.clear();
      _promoDataById.clear();
    } finally {
      _isLoadingPromos = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _buildPromoLineItems(
    PosViewModel posVm,
    bool isMainTab,
  ) {
    final cart = isMainTab ? posVm.mainTabCartItems : posVm.cartItems;
    return cart.map((CartItem item) {
      final isService = item.product.isService;
      final categoryId = item.product.categoryId?.trim();
      return {
        'itemType': isService ? 'service' : 'product',
        if (isService) 'serviceId': item.product.id,
        if (!isService) 'productId': item.product.id,
        if (categoryId != null && categoryId.isNotEmpty)
          if (isService)
            'serviceCategoryId': categoryId
          else
            'productCategoryId': categoryId,
        'lineAmount': item.totalPriceExclVat,
        'quantity': item.quantity,
        'unitPrice': item.effectiveUnitPriceExclVat,
      };
    }).toList();
  }

  List<String> _buildPromoProductIds(
    PosViewModel posVm,
    bool isMainTab,
  ) {
    final cart = isMainTab ? posVm.mainTabCartItems : posVm.cartItems;
    return cart
        .where((item) => !item.product.isService)
        .map((item) => item.product.id)
        .toList();
  }

  List<String> _buildPromoServiceIds(
    PosViewModel posVm,
    bool isMainTab,
  ) {
    final cart = isMainTab ? posVm.mainTabCartItems : posVm.cartItems;
    return cart
        .where((item) => item.product.isService)
        .map((item) => item.product.id)
        .toList();
  }

  (String? discountLabel, String? appliesToLabel) _promoLabelsFromValidResult() {
    final map = _validResult;
    if (map == null) return (null, null);

    final discountLabel = map['message']?.toString().trim();
    final products = map['products']?.toString().trim() ?? '';
    final services = map['services']?.toString().trim() ?? '';
    final productScope =
        (map['productScope']?.toString() ?? '').trim().toLowerCase();
    final serviceScope =
        (map['serviceScope']?.toString() ?? '').trim().toLowerCase();
    final productCategoryIds = _parseStringListFromMap(map['productCategoryIds']);
    final serviceCategoryIds = _parseStringListFromMap(map['serviceCategoryIds']);
    final productIds = _parseStringListFromMap(map['productIds']);
    final serviceIds = _parseStringListFromMap(map['serviceIds']);

    final parts = <String>[];
    if (productScope == 'all' &&
        productCategoryIds.isEmpty &&
        productIds.isEmpty) {
      parts.add('All products');
    } else if (productScope == 'selected' ||
        productCategoryIds.isNotEmpty ||
        productIds.isNotEmpty) {
      if (products.isNotEmpty && products != 'All Products') {
        parts.add('Products: $products');
      } else if (productCategoryIds.isNotEmpty) {
        parts.add('Selected product categories');
      } else {
        parts.add('Selected products');
      }
    }
    if (serviceScope == 'all' &&
        serviceCategoryIds.isEmpty &&
        serviceIds.isEmpty) {
      parts.add('All services');
    } else if (serviceScope == 'selected' ||
        serviceCategoryIds.isNotEmpty ||
        serviceIds.isNotEmpty) {
      if (services.isNotEmpty && services != 'All Services') {
        parts.add('Services: $services');
      } else {
        parts.add('Selected services');
      }
    }
    if (parts.isEmpty) {
      if (products.isNotEmpty && products != 'All Products') {
        parts.add('Products: $products');
      }
      if (services.isNotEmpty && services != 'All Services') {
        parts.add('Services: $services');
      }
    }

    final appliesToLabel = parts.isEmpty ? null : parts.join(' · ');
    final requirementsSummary = buildPromoApplicationRequirementsSummary(
      selectedItemMatchMode:
          map['selectedItemMatchMode']?.toString() ?? 'all_required',
      selectedServiceRequired: map['selectedServiceRequired'] != false,
      productScope: map['productScope']?.toString() ?? 'all',
      serviceScope: map['serviceScope']?.toString() ?? 'all',
      productNames: _parseStringListFromMap(map['productNames']),
      serviceNames: _parseStringListFromMap(map['serviceNames']),
    );
    final combinedApplies = [
      if (requirementsSummary.isNotEmpty) requirementsSummary,
      if (appliesToLabel != null && appliesToLabel.isNotEmpty) appliesToLabel,
    ].join(' · ');
    return (
      (discountLabel != null && discountLabel.isNotEmpty) ? discountLabel : null,
      combinedApplies.isNotEmpty ? combinedApplies : null,
    );
  }

  List<String> _parseStringListFromMap(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e?.toString().trim() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  PromoEligibility? _resolveKnownEligibility(PromoEligibility? promoEligibility) {
    if (promoEligibility?.isKnown == true) return promoEligibility;
    final fromMap = PromoEligibility.fromMap(_validResult);
    return fromMap.isKnown ? fromMap : null;
  }

  Map<String, dynamic> _mapValidPromoResult(PromoData promo) {
    final message = promo.discountLabel ??
        (promo.isPercent
            ? '${promo.discount}% Discount'
            : 'SAR ${promo.discount} Discount');
    final (productsLabel, servicesLabel) = _resolveProductServiceLabels(promo);
    return {
      'id': promo.id,
      'discount': promo.discount,
      'isPercent': promo.isPercent,
      'discountAmount': promo.discountAmount,
      'message': message,
      'store': promo.applicableStore ?? 'All Branches',
      'workshops': promo.workshopScope?.trim().isNotEmpty == true
          ? promo.workshopScope!.trim()
          : (promo.workshopIds.isEmpty
              ? 'All Workshops'
              : '${promo.workshopIds.length} Workshops'),
      'products': productsLabel,
      'services': servicesLabel,
      'period': promo.validityPeriod ?? 'No Expiry',
      'productScope': promo.productScope,
      'serviceScope': promo.serviceScope,
      'productIds': promo.productIds,
      'serviceIds': promo.serviceIds,
      'productCategoryIds': promo.productCategoryIds,
      'serviceCategoryIds': promo.serviceCategoryIds,
      'productCategoryIds': promo.productCategoryIds,
      'serviceCategoryIds': promo.serviceCategoryIds,
      'selectedItemMatchMode': promo.selectedItemMatchMode,
      'selectedServiceRequired': promo.selectedServiceRequired,
    };
  }

  Future<PromoCodeResponse?> _applyPromoOnServer(
    String cleanCode,
    PosViewModel posVm,
    bool isMainTab,
  ) async {
    final token = await sessionService.getToken();
    if (token == null) throw Exception('Token not found');

    final cartAmount = posVm.getSubtotalExclVat(isMainTab);
    if (cartAmount <= 0) {
      return PromoCodeResponse(
        success: true,
        valid: false,
        message: 'Cart is empty',
        promoCode: null,
      );
    }

    final orderAmount = posVm.getPriceAfterJobDiscount(isMainTab);
    final orderAmountInclVat =
        posVm.getOrderTotalInclVatAfterJobDiscount(isMainTab);
    final lineItems = _buildPromoLineItems(posVm, isMainTab);
    final productIds = _buildPromoProductIds(posVm, isMainTab);
    final serviceIds = _buildPromoServiceIds(posVm, isMainTab);

    return posRepository.applyPromoCode(
      cleanCode,
      orderAmount,
      token,
      orderAmountInclVat: orderAmountInclVat,
      productIds: productIds,
      serviceIds: serviceIds,
      lineItems: lineItems,
    );
  }

  Map<String, dynamic> _mapPreviewFromAvailable(AvailablePromotion promo) {
    return {
      'id': promo.promoCodeId,
      'discount': promo.discount,
      'isPercent': promo.isPercent,
      'message': promo.title,
      'store': promo.applicableStore,
      'workshops': promo.applicableWorkshops,
      'products': promo.applicableProducts,
      'services': promo.applicableServices,
      'period': promo.validityPeriod,
    };
  }

  AvailablePromotion? _findAvailablePromotion(String cleanCode) {
    final upper = cleanCode.toUpperCase();
    for (final promo in _availablePromotions) {
      if (promo.code.trim().toUpperCase() == upper) return promo;
    }
    return null;
  }

  /// Applied-promo lookup for "see details" affordances (cached list, no API).
  AvailablePromotion? findAvailablePromotionByCode(String code) =>
      _findAvailablePromotion(code.trim());

  /// Promo Codes tab: show store/products/validity only — no cart rule validation.
  Future<void> previewPromoConditions(
    String code,
    BuildContext context, {
    AvailablePromotion? knownPromotion,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    _isLoading = true;
    _promoErrorMessage = null;
    _validResult = null;
    notifyListeners();

    try {
      AvailablePromotion? match = knownPromotion;
      if (match == null || match.code.trim().toUpperCase() != cleanCode) {
        match = _findAvailablePromotion(cleanCode);
      }
      if (match == null) {
        await fetchAvailablePromos();
        match = _findAvailablePromotion(cleanCode);
      }

      if (match == null) {
        _promoErrorMessage = await t('Invalid Promo Code');
        _validResult = null;
      } else {
        promoController.text = cleanCode;
        _validResult = _mapPreviewFromAvailable(match);
        _promoErrorMessage = null;
      }
    } catch (e) {
      _promoErrorMessage = e.toString().replaceFirst('Exception: ', '');
      _validResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPromoPreview() {
    _validResult = null;
    _promoErrorMessage = null;
    notifyListeners();
  }

  /// Restore dialog preview from the promo already applied on the cart (reopen flow).
  void syncPreviewFromAppliedCartPromo(
    PosViewModel posVm, {
    required bool isMainTab,
    String? departmentId,
  }) {
    final deptId = departmentId ?? posVm.getPromoContextDepartmentId(isMainTab);
    final code =
        posVm.getActivePromoCode(isMainTab, departmentId: deptId).trim();
    if (code.isEmpty) return;

    promoController.text = code;
    final promoId = posVm.getActivePromoCodeId(isMainTab, departmentId: deptId);
    final discountLabel = posVm.getActivePromoDiscountLabel(
      isMainTab,
      departmentId: deptId,
    );
    final appliesToLabel = posVm.getActivePromoAppliesToLabel(
      isMainTab,
      departmentId: deptId,
    );
    final isPercent = posVm.getActiveIsPromoPercent(isMainTab, departmentId: deptId);
    final discount = posVm.getActivePromoDiscount(isMainTab, departmentId: deptId);
    final computedAmount = posVm.getTotalPromoDiscountValue(
      isMainTab,
      departmentId: deptId,
    );
    final eligibility = posVm.getActivePromoEligibility(
      isMainTab,
      departmentId: deptId,
    );
    final knownEligibility =
        eligibility?.isKnown == true ? eligibility : null;
    final hasPinnedLines = posVm.hasPinnedCategoryPromoLines(
      isMainTab,
      departmentId: deptId,
    );

    // Cart state is authoritative — never rebuild preview from promo list cache alone.
    final cached = _lookupCachedPromoData(
      code: code,
      promoCodeId: promoId,
    );
    final cachedMapped =
        cached != null ? _mapValidPromoResult(cached) : null;
    final hasProductSelection = knownEligibility != null &&
        (knownEligibility.productIds.isNotEmpty ||
            knownEligibility.productCategoryIds.isNotEmpty);
    final hasServiceSelection = knownEligibility != null &&
        (knownEligibility.serviceIds.isNotEmpty ||
            knownEligibility.serviceCategoryIds.isNotEmpty);
    _validResult = {
      'id': promoId ?? cachedMapped?['id'],
      'discount': discount,
      'isPercent': isPercent,
      'discountAmount': computedAmount > 0.0001 ? computedAmount : null,
      'message': discountLabel ?? code,
      'store': cachedMapped?['store'] ?? 'All Branches',
      'products': hasProductSelection
          ? (cachedMapped?['products']?.toString() ?? '')
          : (hasPinnedLines
              ? ''
              : (cachedMapped?['products']?.toString() ?? 'All Products')),
      'services': hasServiceSelection
          ? (cachedMapped?['services']?.toString() ?? '')
          : (hasPinnedLines
              ? ''
              : (cachedMapped?['services']?.toString() ?? 'All Services')),
      'period': cachedMapped?['period'],
      'productScope': knownEligibility?.productScope ?? 'all',
      'serviceScope': knownEligibility?.serviceScope ?? 'all',
      'productIds': knownEligibility?.productIds.toList() ?? const <String>[],
      'serviceIds': knownEligibility?.serviceIds.toList() ?? const <String>[],
      'productCategoryIds':
          knownEligibility?.productCategoryIds.toList() ?? const <String>[],
      'serviceCategoryIds':
          knownEligibility?.serviceCategoryIds.toList() ?? const <String>[],
      'selectedItemMatchMode':
          knownEligibility?.selectedItemMatchMode ?? 'entire_order',
      'selectedServiceRequired':
          knownEligibility?.selectedServiceRequired ?? true,
    };
    if (appliesToLabel != null && appliesToLabel.isNotEmpty) {
      _validResult!['message'] = discountLabel ?? code;
    }
    _promoErrorMessage = null;
    notifyListeners();
  }

  Future<void> checkPromoCode(
    String code,
    PosViewModel posVm,
    BuildContext context, {
    bool isMainTab = false,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty || _isChecking || _applyingCardCode != null) return;

    _isChecking = true;
    _promoErrorMessage = null;
    _validResult = null;
    notifyListeners();

    try {
      final response = await _applyPromoOnServer(cleanCode, posVm, isMainTab);

      if (response != null &&
          response.success &&
          response.valid &&
          response.promoCode != null) {
        promoController.text = cleanCode;
        _validResult = _mapValidPromoResult(response.promoCode!);
        _promoErrorMessage = null;
      } else {
        final msg = (response?.message.isNotEmpty == true)
            ? response!.message
            : await t('Invalid Promo Code');
        _promoErrorMessage = msg;
        _validResult = null;
      }
    } catch (e) {
      _promoErrorMessage = e.toString().replaceFirst('Exception: ', '');
      _validResult = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Order Summary: validate a promo against a **placed order** (no live cart).
  /// When [primaryJobId] is set (single-job orders) the backend rebuilds the
  /// job's persisted lines — including category ids — itself; otherwise the
  /// caller passes [lineItems] built from the order's job items.
  Future<PromoCodeResponse?> _validatePromoForOrderOnServer(
    String cleanCode, {
    required double orderAmountExclVat,
    double? orderAmountInclVat,
    String? primaryJobId,
    List<Map<String, dynamic>>? lineItems,
  }) async {
    final token = await sessionService.getToken();
    if (token == null) throw Exception('Token not found');
    if (orderAmountExclVat <= 0) {
      return PromoCodeResponse(
        success: true,
        valid: false,
        message: 'Order has no billable items',
        promoCode: null,
      );
    }
    return posRepository.applyPromoCode(
      cleanCode,
      orderAmountExclVat,
      token,
      orderAmountInclVat: orderAmountInclVat,
      jobId: primaryJobId,
      lineItems: primaryJobId != null ? null : lineItems,
    );
  }

  /// Manual "Check Code" flow for the Order Summary promo dialog.
  Future<void> checkPromoCodeForOrder(
    String code, {
    required double orderAmountExclVat,
    double? orderAmountInclVat,
    String? primaryJobId,
    List<Map<String, dynamic>>? lineItems,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty || _isChecking || _applyingCardCode != null) return;

    _isChecking = true;
    _promoErrorMessage = null;
    _validResult = null;
    notifyListeners();

    try {
      final response = await _validatePromoForOrderOnServer(
        cleanCode,
        orderAmountExclVat: orderAmountExclVat,
        orderAmountInclVat: orderAmountInclVat,
        primaryJobId: primaryJobId,
        lineItems: lineItems,
      );

      if (response != null &&
          response.success &&
          response.valid &&
          response.promoCode != null) {
        promoController.text = cleanCode;
        _validResult = _mapValidPromoResult(response.promoCode!);
        _promoErrorMessage = null;
      } else {
        final msg = (response?.message.isNotEmpty == true)
            ? response!.message
            : await t('Invalid Promo Code');
        _promoErrorMessage = msg;
        _validResult = null;
      }
    } catch (e) {
      _promoErrorMessage = e.toString().replaceFirst('Exception: ', '');
      _validResult = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Card-tap flow for the Order Summary promo dialog. Validates only —
  /// persisting to the order is done by the caller. Returns `true` when valid.
  Future<bool> validatePromoForOrderFromCard(
    String code, {
    required double orderAmountExclVat,
    double? orderAmountInclVat,
    String? primaryJobId,
    List<Map<String, dynamic>>? lineItems,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty || _applyingCardCode != null || _isChecking) {
      return false;
    }

    _revalidateDebounce?.cancel();
    _applyingCardCode = cleanCode;
    notifyListeners();

    try {
      final response = await _validatePromoForOrderOnServer(
        cleanCode,
        orderAmountExclVat: orderAmountExclVat,
        orderAmountInclVat: orderAmountInclVat,
        primaryJobId: primaryJobId,
        lineItems: lineItems,
      );

      if (response != null &&
          response.success &&
          response.valid &&
          response.promoCode != null) {
        promoController.text = cleanCode;
        _validResult = _mapValidPromoResult(response.promoCode!);
        _promoErrorMessage = null;
        notifyListeners();
        return true;
      }

      final msg = (response?.message.isNotEmpty == true)
          ? response!.message
          : await t('Invalid Promo Code');
      _promoErrorMessage = msg;
      _validResult = null;
      notifyListeners();
      return false;
    } catch (e) {
      _promoErrorMessage = e.toString().replaceFirst('Exception: ', '');
      _validResult = null;
      notifyListeners();
      return false;
    } finally {
      _applyingCardCode = null;
      notifyListeners();
    }
  }

  /// Applies a promo from a grid card. Shows loader only on that card.
  /// Returns `true` when the promo was applied to the cart.
  Future<bool> applyPromoFromCard(
    String code,
    PosViewModel posVm,
    BuildContext context, {
    bool isMainTab = false,
    String? departmentId,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty || _applyingCardCode != null || _isChecking) {
      return false;
    }

    final targetDepartmentId =
        departmentId ?? posVm.getPromoContextDepartmentId(isMainTab);
    final activeCode = posVm
        .getActivePromoCode(isMainTab, departmentId: targetDepartmentId)
        .trim()
        .toUpperCase();
    if (activeCode == cleanCode && posVm.isPromoUserApplied(isMainTab)) {
      promoController.text = cleanCode;
      syncPreviewFromAppliedCartPromo(
        posVm,
        isMainTab: isMainTab,
        departmentId: targetDepartmentId,
      );
      return true;
    }

    _revalidateDebounce?.cancel();
    _applyingCardCode = cleanCode;
    notifyListeners();

    try {
      final response = await _applyPromoOnServer(cleanCode, posVm, isMainTab);

      if (response != null &&
          response.success &&
          response.valid &&
          response.promoCode != null) {
        promoController.text = cleanCode;
        _validResult = _mapValidPromoResult(response.promoCode!);
        applyValidatedPromoToCart(
          posVm,
          isMainTab: isMainTab,
          departmentId:
              departmentId ?? posVm.getPromoContextDepartmentId(isMainTab),
          promoEligibility:
              PromoEligibility.fromPromoData(response.promoCode!),
        );
        _promoErrorMessage = null;
        if (context.mounted) {
          final msg = response.promoCode!.discountLabel?.trim();
          if (msg != null && msg.isNotEmpty) {
            ToastService.showSuccess(context, msg, messageOnly: true);
          } else {
            ToastService.showSuccess(
              context,
              cleanCode,
              title: 'Promo applied',
            );
          }
        }
        return true;
      }

      final msg = (response?.message.isNotEmpty == true)
          ? response!.message
          : await t('Invalid Promo Code');
      _promoErrorMessage = msg;
      _validResult = null;
      notifyListeners();
      if (context.mounted) {
        ToastService.showError(context, msg);
      }
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _promoErrorMessage = msg;
      _validResult = null;
      notifyListeners();
      if (context.mounted) {
        ToastService.showError(context, msg);
      }
      return false;
    } finally {
      _applyingCardCode = null;
      notifyListeners();
    }
  }

  /// Applies the last [checkPromoCode] result to the cart (manual entry flow).
  /// Returns `true` only when the promo was validated and applied.
  Future<bool> applyCheckedPromoToCart(
    PosViewModel posVm,
    BuildContext context, {
    bool isMainTab = false,
    String? departmentId,
  }) async {
    if (_validResult == null) return false;
    final code = promoController.text.trim();
    if (code.isEmpty) return false;
    return applyPromoFromCard(
      code,
      posVm,
      context,
      isMainTab: isMainTab,
      departmentId: departmentId,
    );
  }

  Future<void> validatePromo(
    String code,
    PosViewModel posVm,
    BuildContext context, {
    bool isMainTab = false,
    String? departmentId,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    _isLoading = true;
    _promoErrorMessage = null;
    _validResult = null;
    notifyListeners();

    try {
      final response = await _applyPromoOnServer(cleanCode, posVm, isMainTab);

      if (response != null &&
          response.success &&
          response.valid &&
          response.promoCode != null) {
        promoController.text = cleanCode;
        _validResult = _mapValidPromoResult(response.promoCode!);
        applyValidatedPromoToCart(
          posVm,
          isMainTab: isMainTab,
          departmentId: departmentId,
          promoEligibility: PromoEligibility.fromPromoData(response.promoCode!),
        );
        if (context.mounted) {
          final msg = _validResult!['message']?.toString().trim();
          if (msg != null && msg.isNotEmpty) {
            ToastService.showSuccess(context, msg);
          }
        }
      } else {
        final msg = (response?.message.isNotEmpty == true)
            ? response!.message
            : await t('Invalid Promo Code');
        _promoErrorMessage = msg;
        _validResult = null;
      }
    } catch (e) {
      _promoErrorMessage = e.toString().replaceFirst('Exception: ', '');
      if (context.mounted) {
        ToastService.showError(context, _promoErrorMessage!);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyValidatedPromoToCart(
    PosViewModel posVm, {
    bool isMainTab = false,
    String? departmentId,
    PromoEligibility? promoEligibility,
  }) {
    if (_validResult == null) return;
    final code = promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    _revalidateDebounce?.cancel();
    final discountAmount = (_validResult!['discountAmount'] as num?)?.toDouble();
    final targetDepartmentId =
        departmentId ?? posVm.getPromoContextDepartmentId(isMainTab);
    final rawEligibility =
        promoEligibility ?? PromoEligibility.fromMap(_validResult);
    final eligibility = _resolveKnownEligibility(rawEligibility);
    final (discountLabel, appliesToLabel) = _promoLabelsFromValidResult();
    final isPercent = _validResult!['isPercent'] == true;
    final discountValue = (_validResult!['discount'] as num).toDouble();

    posVm.applyPromoCode(
      code,
      discountValue,
      isPercent,
      isMainTab: isMainTab,
      promoCodeId: _validResult!['id']?.toString(),
      departmentId: targetDepartmentId,
      computedDiscountAmount: discountAmount,
      eligibility: eligibility,
      discountLabel: discountLabel,
      appliesToLabel: appliesToLabel,
      refreshPinnedEligibleLines: true,
    );

    var computedTotal = posVm.getTotalPromoDiscountValue(
      isMainTab,
      departmentId: targetDepartmentId,
    );
    if (computedTotal <= 0.0001 &&
        discountAmount != null &&
        discountAmount > 0.0001) {
      computedTotal = discountAmount;
    }

    if (computedTotal > 0.0001) {
      final resolvedLabel = isPercent
          ? '${discountValue.toStringAsFixed(0)}% discount'
          : 'SAR ${computedTotal.toStringAsFixed(2)} Discount';
      posVm.applyPromoCode(
        code,
        discountValue,
        isPercent,
        isMainTab: isMainTab,
        promoCodeId: _validResult!['id']?.toString(),
        departmentId: targetDepartmentId,
        computedDiscountAmount: computedTotal,
        eligibility: eligibility,
        discountLabel: resolvedLabel,
        appliesToLabel: appliesToLabel,
        refreshPinnedEligibleLines: true,
      );
    }
    posVm.markPromoUserApplied(isMainTab);
  }

  Future<void> revalidateAllActivePromos(
    PosViewModel posVm, {
    required bool isMainTab,
  }) async {
    if (_isRevalidating || _isLoading) return;
    if (posVm.hasKnownPromoEligibility(isMainTab)) return;
    _revalidateDebounce?.cancel();
    _revalidateDebounce = Timer(const Duration(milliseconds: 500), () async {
      await _revalidateAllActivePromosNow(posVm, isMainTab: isMainTab);
    });
  }

  /// Revalidate without debounce — used when reopening a saved order so promo amount shows at once.
  Future<void> revalidateHydratedPromoImmediately(
    PosViewModel posVm, {
    required bool isMainTab,
  }) async {
    _revalidateDebounce?.cancel();
    if (_isRevalidating || _isLoading) return;
    if (!posVm.hasActivePromo(isMainTab)) return;
    if (posVm.hasKnownPromoEligibility(isMainTab)) return;
    await _revalidateAllActivePromosNow(posVm, isMainTab: isMainTab);
  }

  PromoData? lookupPromoData({
    required String code,
    String? promoCodeId,
  }) =>
      _lookupCachedPromoData(code: code, promoCodeId: promoCodeId);

  /// Promo scope for order-summary line badges (catalog cache, no API).
  PromoEligibility? resolveOrderSummaryPromoEligibility({
    required String promoCode,
    String? promoCodeId,
  }) {
    final cached = _lookupCachedPromoData(
      code: promoCode,
      promoCodeId: promoCodeId,
    );
    if (cached != null) {
      final eligibility = PromoEligibility.fromPromoData(cached);
      return eligibility.isKnown ? eligibility : null;
    }

    final normalized = promoCode.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final promo in _availablePromotions) {
      if (promo.code.trim().toUpperCase() != normalized) continue;
      return PromoEligibility(
        productScope: promo.productScope,
        serviceScope: promo.serviceScope,
        selectedItemMatchMode: promo.selectedItemMatchMode,
        selectedServiceRequired: promo.selectedServiceRequired,
      );
    }
    return null;
  }

  PromoData? _lookupCachedPromoData({
    required String code,
    String? promoCodeId,
  }) {
    final id = promoCodeId?.trim();
    if (id != null && id.isNotEmpty) {
      final byId = _promoDataById[id];
      if (byId != null) return byId;
    }
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return _promoDataByCode[normalized];
  }

  static bool _namesMatch(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  PromoEligibility? _eligibilityFromPromotionList({
    required String code,
    required List<CartItem> cart,
  }) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    AvailablePromotion? promo;
    for (final entry in _availablePromotions) {
      if (entry.code.trim().toUpperCase() == normalized) {
        promo = entry;
        break;
      }
    }
    if (promo == null) return null;

    final productScope = promo.productScope.trim().toLowerCase();
    final serviceScope = promo.serviceScope.trim().toLowerCase();
    final productIds = <String>{};
    final serviceIds = <String>{};

    for (final item in cart) {
      if (item.product.isService) {
        if (serviceScope == 'none') continue;
        if (serviceScope == 'all') {
          serviceIds.add(item.product.id.trim());
          continue;
        }
        if (promo.serviceNames.any((n) => _namesMatch(n, item.product.name))) {
          serviceIds.add(item.product.id.trim());
        }
      } else {
        if (productScope == 'none') continue;
        if (productScope == 'all') {
          productIds.add(item.product.id.trim());
          continue;
        }
        if (promo.productNames.isEmpty ||
            promo.productNames.any((n) => _namesMatch(n, item.product.name))) {
          productIds.add(item.product.id.trim());
        }
      }
    }

    if (productIds.isEmpty && serviceIds.isEmpty) return null;
    return PromoEligibility(
      productScope: productScope.isEmpty ? 'none' : productScope,
      serviceScope: serviceScope.isEmpty ? 'none' : serviceScope,
      productIds: productIds,
      serviceIds: serviceIds,
    );
  }

  /// Apply cached promo scope immediately so line badges show on reopen (no API wait).
  bool applyHydratedPromoEligibilityFromCache(
    PosViewModel posVm, {
    required String code,
    String? promoCodeId,
    required bool isMainTab,
  }) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    final activeCode =
        posVm.getActivePromoCode(isMainTab).trim().toUpperCase();
    if (activeCode.isNotEmpty && activeCode != normalized) return false;

    final cart = isMainTab ? posVm.mainTabCartItems : posVm.cartItems;
    final cached = _lookupCachedPromoData(code: code, promoCodeId: promoCodeId);
    var eligibility = cached != null
        ? PromoEligibility.fromPromoData(cached)
        : _eligibilityFromPromotionList(code: code, cart: cart);
    if (eligibility == null || !eligibility.isKnown) return false;

    final current = posVm.getActivePromoEligibility(isMainTab);
    if (posVm.isPromoUserApplied(isMainTab)) return true;
    if (posVm.hasPinnedCategoryPromoLines(isMainTab)) return true;
    if (current?.isKnown == true) {
      if (current!.hasSelectedScope) return true;
      final incomingIsNarrower = eligibility.hasSelectedScope;
      final currentIsBroadAll = current.productScope == 'all' &&
          current.serviceScope == 'all' &&
          !current.hasSelectedScope;
      if (!(incomingIsNarrower && currentIsBroadAll)) return true;
    }

    final (discountLabel, appliesToLabel) = cached != null
        ? _labelsFromPromoData(cached)
        : (null, null);

    posVm.patchHydratedPromoEligibility(
      isMainTab: isMainTab,
      eligibility: eligibility,
      discountLabel: discountLabel,
      appliesToLabel: appliesToLabel,
    );
    return true;
  }

  (String?, String?) _labelsFromPromoData(PromoData promo) {
    final discountLabel = promo.discountLabel?.trim();
    final (productsLabel, servicesLabel) = _resolveProductServiceLabels(promo);
    final appliesToLabel = [
      if (productsLabel.trim().isNotEmpty) 'Products: $productsLabel',
      if (servicesLabel.trim().isNotEmpty) 'Services: $servicesLabel',
    ].join(' · ');
    return (
      (discountLabel != null && discountLabel.isNotEmpty) ? discountLabel : null,
      appliesToLabel.isNotEmpty ? appliesToLabel : null,
    );
  }

  Future<void> ensurePromoCatalogLoaded() async {
    if (_promoDataByCode.isNotEmpty || _isLoadingPromos) return;
    await fetchAvailablePromos();
  }

  Future<void> _revalidateAllActivePromosNow(
    PosViewModel posVm, {
    required bool isMainTab,
  }) async {
    if (!posVm.hasActivePromo(isMainTab)) return;

    _isRevalidating = true;
    try {
      final departmentIds = posVm.activePromoDepartmentIds(isMainTab);
      if (departmentIds.isNotEmpty) {
        for (final departmentId in departmentIds) {
          final code = posVm
              .getActivePromoCode(isMainTab, departmentId: departmentId)
              .trim();
          if (code.isEmpty) continue;
          await _revalidateOne(
            posVm,
            code,
            isMainTab: isMainTab,
            departmentId: departmentId,
          );
        }
        return;
      }

      final code = posVm.getActivePromoCode(isMainTab).trim();
      if (code.isEmpty) return;
      await _revalidateOne(posVm, code, isMainTab: isMainTab);
    } finally {
      _isRevalidating = false;
    }
  }

  Future<void> _revalidateOne(
    PosViewModel posVm,
    String code, {
    required bool isMainTab,
    String? departmentId,
  }) async {
    if (posVm.hasKnownPromoEligibility(isMainTab, departmentId: departmentId)) {
      return;
    }
    if (posVm.getSubtotalExclVat(isMainTab) <= 0) {
      return;
    }

    final activeCode =
        posVm.getActivePromoCode(isMainTab, departmentId: departmentId).trim();
    if (activeCode.isNotEmpty &&
        activeCode.toUpperCase() != code.trim().toUpperCase()) {
      return;
    }

    try {
      final response = await _applyPromoOnServer(code, posVm, isMainTab);
      if (response != null &&
          response.success &&
          response.valid &&
          response.promoCode != null) {
        _validResult = _mapValidPromoResult(response.promoCode!);
        promoController.text = code;
        applyValidatedPromoToCart(
          posVm,
          isMainTab: isMainTab,
          departmentId: departmentId,
          promoEligibility: PromoEligibility.fromPromoData(response.promoCode!),
        );
        _promoErrorMessage = null;
      } else {
        // Keep the cart promo when background revalidation fails (user must remove explicitly).
        _promoErrorMessage = response?.message;
      }
    } catch (_) {
      // Keep last known promo amount on transient network errors.
    }
    notifyListeners();
  }

  void clearPromoError({bool preserveAppliedPreview = false}) {
    var changed = false;
    if (_promoErrorMessage != null) {
      _promoErrorMessage = null;
      changed = true;
    }
    if (!preserveAppliedPreview && _validResult != null) {
      _validResult = null;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void removeAppliedPromo(
    PosViewModel posVm, {
    bool isMainTab = false,
    String? departmentId,
  }) {
    _validResult = null;
    _promoErrorMessage = null;
    promoController.clear();
    posVm.clearPromoCode(isMainTab: isMainTab, userInitiated: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _revalidateDebounce?.cancel();
    unbindLocaleRetranslation();
    promoController.dispose();
    super.dispose();
  }
}

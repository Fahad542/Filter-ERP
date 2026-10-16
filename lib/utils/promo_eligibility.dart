import '../models/pos_product_model.dart';
import '../models/promo_code_model.dart';

/// Which cart lines a promo applies to (mirrors backend promo-code-applicability).
class PromoEligibility {
  final String productScope;
  final String serviceScope;
  final Set<String> productIds;
  final Set<String> serviceIds;
  final Set<String> productCategoryIds;
  final Set<String> serviceCategoryIds;
  final String selectedItemMatchMode;
  final bool selectedServiceRequired;
  /// False when scope/rules were not loaded — never treat as "all products".
  final bool isKnown;

  const PromoEligibility({
    this.productScope = 'none',
    this.serviceScope = 'none',
    this.productIds = const {},
    this.serviceIds = const {},
    this.productCategoryIds = const {},
    this.serviceCategoryIds = const {},
    this.selectedItemMatchMode = 'all_required',
    this.selectedServiceRequired = true,
    this.isKnown = true,
  });

  const PromoEligibility.unknown()
      : productScope = 'none',
        serviceScope = 'none',
        productIds = const {},
        serviceIds = const {},
        productCategoryIds = const {},
        serviceCategoryIds = const {},
        selectedItemMatchMode = 'all_required',
        selectedServiceRequired = true,
        isKnown = false;

  static String _normId(String id) => id.trim();

  static Set<String> _parseIds(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => _normId(e?.toString() ?? ''))
          .where((e) => e.isNotEmpty)
          .toSet();
    }
    return const {};
  }

  static String _resolveScope(
    String? scope,
    Set<String> itemIds,
    Set<String> categoryIds,
  ) {
    final normalized = (scope ?? '').trim().toLowerCase();
    if (normalized == 'selected' || normalized == 'none') {
      return normalized;
    }
    // Category/product ids always mean a narrowed scope, even if API says "all".
    if (itemIds.isNotEmpty || categoryIds.isNotEmpty) {
      return 'selected';
    }
    if (normalized == 'all') return 'all';
    return 'all';
  }

  static String _resolveMatchMode(String? raw) {
    final mode = (raw ?? '').trim().toLowerCase();
    if (mode == 'any_present' ||
        mode == 'any' ||
        mode == 'partial' ||
        mode == 'partial_match') {
      return 'any_present';
    }
    if (mode == 'entire_order' ||
        mode == 'entire_order_discount' ||
        mode == 'full_order') {
      return 'entire_order';
    }
    return 'all_required';
  }

  static bool _resolveServiceRequired(dynamic raw, {bool fallback = true}) {
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    final normalized = raw.toString().trim().toLowerCase();
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no' ||
        normalized == 'off') {
      return false;
    }
    return true;
  }

  factory PromoEligibility.fromPromoData(PromoData promo) {
    final productIds =
        promo.productIds.map(_normId).where((id) => id.isNotEmpty).toSet();
    final serviceIds =
        promo.serviceIds.map(_normId).where((id) => id.isNotEmpty).toSet();
    final productCategoryIds = promo.productCategoryIds
        .map(_normId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final serviceCategoryIds = promo.serviceCategoryIds
        .map(_normId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final hasScopeMeta = promo.productScope != null ||
        promo.serviceScope != null ||
        productIds.isNotEmpty ||
        serviceIds.isNotEmpty ||
        productCategoryIds.isNotEmpty ||
        serviceCategoryIds.isNotEmpty ||
        promo.selectedItemMatchMode != null;
    if (!hasScopeMeta) return const PromoEligibility.unknown();

    return PromoEligibility(
      productScope: _resolveScope(
        promo.productScope,
        productIds,
        productCategoryIds,
      ),
      serviceScope: _resolveScope(
        promo.serviceScope,
        serviceIds,
        serviceCategoryIds,
      ),
      productIds: productIds,
      serviceIds: serviceIds,
      productCategoryIds: productCategoryIds,
      serviceCategoryIds: serviceCategoryIds,
      selectedItemMatchMode:
          _resolveMatchMode(promo.selectedItemMatchMode),
      selectedServiceRequired: promo.selectedServiceRequired,
    );
  }

  factory PromoEligibility.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PromoEligibility.unknown();

    final productIds = _parseIds(map['productIds']);
    final serviceIds = _parseIds(map['serviceIds']);
    final productCategoryIds = _parseIds(map['productCategoryIds']);
    final serviceCategoryIds = _parseIds(map['serviceCategoryIds']);
    final hasScopeMeta = map.containsKey('productScope') ||
        map.containsKey('serviceScope') ||
        map['productIds'] is List ||
        map['serviceIds'] is List ||
        map['productCategoryIds'] is List ||
        map['serviceCategoryIds'] is List ||
        map.containsKey('selectedItemMatchMode');
    if (!hasScopeMeta) return const PromoEligibility.unknown();

    return PromoEligibility(
      productScope: _resolveScope(
        map['productScope']?.toString(),
        productIds,
        productCategoryIds,
      ),
      serviceScope: _resolveScope(
        map['serviceScope']?.toString(),
        serviceIds,
        serviceCategoryIds,
      ),
      productIds: productIds,
      serviceIds: serviceIds,
      productCategoryIds: productCategoryIds,
      serviceCategoryIds: serviceCategoryIds,
      selectedItemMatchMode: _resolveMatchMode(
        map['selectedItemMatchMode']?.toString(),
      ),
      selectedServiceRequired: _resolveServiceRequired(
        map['selectedServiceRequired'] ?? map['selected_service_required'],
      ),
    );
  }

  bool get usesEntireOrderDiscount => selectedItemMatchMode == 'entire_order';

  // Mirrors backend hasSelectedProductCriteria/hasSelectedServiceCriteria:
  // only an explicit "selected" scope with ids counts. Scope "all" must NOT
  // make selectedServiceRequired turn services into trigger-only lines.
  bool _hasSelectedProductCriteria() =>
      productScope == 'selected' &&
      (productIds.isNotEmpty || productCategoryIds.isNotEmpty);

  bool _hasSelectedServiceCriteria() =>
      serviceScope == 'selected' &&
      (serviceIds.isNotEmpty || serviceCategoryIds.isNotEmpty);

  bool get hasCategorySelection =>
      (productScope == 'selected' && productCategoryIds.isNotEmpty) ||
      (serviceScope == 'selected' && serviceCategoryIds.isNotEmpty);

  /// Per-line discount on each eligible cart item.
  bool usesPerEligibleLineDiscountForPromo({
    required bool isPercent,
  }) {
    if (!hasSelectedScope) return false;
    if (!usesEntireOrderDiscount) return true;
    if (hasCategorySelection) return true;
    return !isPercent;
  }

  bool get hasSelectedScope =>
      (productScope == 'selected' &&
          (productIds.isNotEmpty || productCategoryIds.isNotEmpty)) ||
      (serviceScope == 'selected' &&
          (serviceIds.isNotEmpty || serviceCategoryIds.isNotEmpty));

  bool _hasSelectedScope() => hasSelectedScope;

  bool get selectedServicesAreOptional =>
      !selectedServiceRequired &&
      _hasSelectedProductCriteria() &&
      _hasSelectedServiceCriteria();

  /// Required services unlock the promo but are not discounted (toggle ON + both scopes).
  bool get selectedServicesAreTriggerOnly =>
      selectedServiceRequired &&
      _hasSelectedProductCriteria() &&
      _hasSelectedServiceCriteria();

  bool _lineMatchesProduct(CartItem item) {
    if (item.product.isService) return false;
    if (productScope == 'none') return false;
    if (productScope == 'all') return true;
    final productId = _normId(item.product.id);
    if (productIds.isNotEmpty) {
      return productIds.contains(productId);
    }
    final categoryId = _normId(item.product.categoryId ?? '');
    return categoryId.isNotEmpty && productCategoryIds.contains(categoryId);
  }

  bool _lineMatchesService(CartItem item) {
    if (!item.product.isService) return false;
    if (selectedServicesAreTriggerOnly) return false;
    if (serviceScope == 'none') return false;
    if (serviceScope == 'all') return true;
    final serviceId = _normId(item.product.id);
    if (serviceIds.isNotEmpty) {
      return serviceIds.contains(serviceId);
    }
    final categoryId = _normId(item.product.categoryId ?? '');
    return categoryId.isNotEmpty && serviceCategoryIds.contains(categoryId);
  }

  bool isCartItemEligible(CartItem item) {
    if (!isKnown) return false;
    return _lineMatchesProduct(item) || _lineMatchesService(item);
  }

  /// True when the catalog item is one of the promo's own items — selected
  /// ids/categories (including trigger-only services) or anything under an
  /// "all" scope. Items outside this set never affect the promo.
  bool isProductPartOfPromo({
    required String productId,
    required bool isService,
    String? categoryId,
  }) {
    if (!isKnown) return false;
    final id = _normId(productId);
    final cat = _normId(categoryId ?? '');
    if (isService) {
      if (serviceScope == 'none') return false;
      if (serviceScope == 'all') return true;
      return serviceIds.contains(id) ||
          (cat.isNotEmpty && serviceCategoryIds.contains(cat));
    }
    if (productScope == 'none') return false;
    if (productScope == 'all') return true;
    return productIds.contains(id) ||
        (cat.isNotEmpty && productCategoryIds.contains(cat));
  }

  /// Saved-order line (no [CartItem]) — uses product id and optional name hints from promo catalog.
  bool isOrderJobItemEligible({
    required String productId,
    required String productName,
    required bool isService,
    Iterable<String> productNameHints = const [],
    Iterable<String> serviceNameHints = const [],
  }) {
    if (!isKnown) return false;
    final lineId = _normId(productId);
    final lineName = productName.trim().toLowerCase();

    bool nameMatches(Iterable<String> hints) {
      for (final hint in hints) {
        if (hint.trim().toLowerCase() == lineName) return true;
      }
      return false;
    }

    if (!isService) {
      if (productScope == 'none') return false;
      if (productScope == 'all') return true;
      if (lineId.isNotEmpty && productIds.contains(lineId)) return true;
      if (productNameHints.isNotEmpty && nameMatches(productNameHints)) {
        return true;
      }
      if (productCategoryIds.isNotEmpty && productNameHints.isNotEmpty) {
        return nameMatches(productNameHints);
      }
      return false;
    }

    if (selectedServicesAreTriggerOnly) return false;
    if (serviceScope == 'none') return false;
    if (serviceScope == 'all') return true;
    if (lineId.isNotEmpty && serviceIds.contains(lineId)) return true;
    if (serviceNameHints.isNotEmpty && nameMatches(serviceNameHints)) {
      return true;
    }
    if (serviceCategoryIds.isNotEmpty && serviceNameHints.isNotEmpty) {
      return nameMatches(serviceNameHints);
    }
    return false;
  }

  double _eligibleLineAmount(
    Iterable<CartItem> cart, {
    bool ignoreServices = false,
  }) {
    if (!isKnown) return 0;
    var total = 0.0;
    for (final item in cart) {
      if (ignoreServices && item.product.isService) continue;
      if (isCartItemEligible(item)) {
        total += item.totalPriceExclVat;
      }
    }
    return total;
  }

  bool _hasProductAndServiceTriggers(Iterable<CartItem> cart) {
    if (!_hasSelectedProductCriteria() || !_hasSelectedServiceCriteria()) {
      return true;
    }
    final hasProductTrigger =
        _eligibleLineAmount(cart, ignoreServices: true) > 0.0001;
    final hasServiceTrigger = cart.any((item) {
      if (!item.product.isService) return false;
      if (serviceScope == 'none') return false;
      if (serviceScope == 'all') return true;
      final serviceId = _normId(item.product.id);
      if (serviceIds.isNotEmpty) {
        return serviceIds.contains(serviceId);
      }
      final categoryId = _normId(item.product.categoryId ?? '');
      return categoryId.isNotEmpty && serviceCategoryIds.contains(categoryId);
    });
    return hasProductTrigger && hasServiceTrigger;
  }

  bool _allRequiredItemsPresent(Iterable<CartItem> cart) {
    final cartProducts = cart
        .where((i) => !i.product.isService)
        .map((i) => _normId(i.product.id))
        .where((id) => id.isNotEmpty)
        .toSet();
    final cartServices = cart
        .where((i) => i.product.isService)
        .map((i) => _normId(i.product.id))
        .where((id) => id.isNotEmpty)
        .toSet();

    if (productScope == 'selected' && productIds.isNotEmpty) {
      for (final id in productIds) {
        if (!cartProducts.contains(id)) return false;
      }
    }
    if (productScope == 'selected' &&
        productCategoryIds.isNotEmpty &&
        productIds.isEmpty) {
      final cartProductCategories = cart
          .where((i) => !i.product.isService)
          .map((i) => _normId(i.product.categoryId ?? ''))
          .where((id) => id.isNotEmpty)
          .toSet();
      for (final id in productCategoryIds) {
        if (!cartProductCategories.contains(id)) return false;
      }
    }
    if (serviceScope == 'selected' &&
        serviceIds.isNotEmpty &&
        !selectedServicesAreOptional) {
      for (final id in serviceIds) {
        if (!cartServices.contains(id)) return false;
      }
    }
    if (serviceScope == 'selected' &&
        serviceCategoryIds.isNotEmpty &&
        serviceIds.isEmpty &&
        !selectedServicesAreOptional) {
      final cartServiceCategories = cart
          .where((i) => i.product.isService)
          .map((i) => _normId(i.product.categoryId ?? ''))
          .where((id) => id.isNotEmpty)
          .toSet();
      for (final id in serviceCategoryIds) {
        if (!cartServiceCategories.contains(id)) return false;
      }
    }
    return true;
  }

  /// Rule 1–3 + service toggle — mirrors backend [canApplyPromoToOrder].
  bool canApplyToCart(Iterable<CartItem> cart) {
    if (!isKnown) return false;
    if (!_hasSelectedScope()) return true;

    final eligibleAmount = _eligibleLineAmount(cart);
    if (eligibleAmount <= 0.0001) return false;

    if (selectedItemMatchMode == 'all_required') {
      return _allRequiredItemsPresent(cart);
    }

    if (selectedServicesAreOptional) {
      return _eligibleLineAmount(cart, ignoreServices: true) > 0.0001;
    }
    if (!_hasProductAndServiceTriggers(cart)) {
      return false;
    }
    if (selectedItemMatchMode == 'any_present' || usesEntireOrderDiscount) {
      return true;
    }
    return _allRequiredItemsPresent(cart);
  }

  double eligibleCartBase(Iterable<CartItem> cart) => _eligibleLineAmount(cart);

  double linePromoDiscount({
    required CartItem item,
    required Iterable<CartItem> cart,
    required double totalPromoDiscount,
  }) {
    if (!isKnown || totalPromoDiscount <= 0.0001) return 0;

    if (usesEntireOrderDiscount) {
      if (!isCartItemEligible(item)) return 0;
      final eligibleBase = eligibleCartBase(cart);
      if (eligibleBase <= 0.0001) return 0;
      final lineBase = item.totalPriceExclVat;
      if (lineBase <= 0.0001) return 0;
      return (totalPromoDiscount * (lineBase / eligibleBase))
          .clamp(0, lineBase)
          .toDouble();
    }

    if (!isCartItemEligible(item)) return 0;
    final eligibleBase = eligibleCartBase(cart);
    if (eligibleBase <= 0.0001) return 0;
    final lineBase = item.totalPriceExclVat;
    if (lineBase <= 0.0001) return 0;
    return (totalPromoDiscount * (lineBase / eligibleBase))
        .clamp(0, lineBase)
        .toDouble();
  }
}

import '../../../models/pos_product_model.dart';

/// Holds cashier **cart line items** (walk-in vs main-tab) and pure cart mutations.
///
/// [PosViewModel] owns this object and passes [notifyListeners] so behaviour matches
/// the previous monolithic implementation (cart edits still rebuild POS listeners).
class PosCartSession {
  PosCartSession({
    required void Function() notifyListeners,
    required List<PosProduct> Function() catalogProducts,
  })  : _notifyListeners = notifyListeners,
        _catalogProducts = catalogProducts;

  final void Function() _notifyListeners;
  final List<PosProduct> Function() _catalogProducts;

  final List<CartItem> walkInCart = [];
  final List<CartItem> mainTabCart = [];

  List<CartItem> active(bool isMainTab) => isMainTab ? mainTabCart : walkInCart;

  static bool sameCartProduct(PosProduct a, PosProduct b) {
    return a.id == b.id &&
        a.isServiceType == b.isServiceType &&
        (a.departmentId ?? '') == (b.departmentId ?? '');
  }

  /// After catalog reload, cart lines may still reference old [PosProduct] instances.
  void refreshProductReferences() {
    final catalog = _catalogProducts();
    for (final item in walkInCart) {
      final fresh = _findInCatalog(catalog, item.product);
      if (fresh != null) item.product = fresh;
    }
    for (final item in mainTabCart) {
      final fresh = _findInCatalog(catalog, item.product);
      if (fresh != null) item.product = fresh;
    }
  }

  PosProduct? findCatalogProduct(PosProduct lineProduct) {
    return _findInCatalog(_catalogProducts(), lineProduct);
  }

  PosProduct? _findInCatalog(List<PosProduct> catalog, PosProduct lineProduct) {
    for (final p in catalog) {
      if (sameCartProduct(lineProduct, p)) return p;
    }
    return null;
  }

  void clearLineItems(bool isMainTab) {
    active(isMainTab).clear();
  }

  void removeLinesInDepartment(String departmentId, bool isMainTab) {
    final depId = departmentId.trim();
    if (depId.isEmpty) return;
    active(isMainTab).removeWhere(
      (item) => (item.product.departmentId ?? '') == depId,
    );
  }

  String? addToCart(
    PosProduct product, {
    double qty = 1.0,
    bool isMainTab = false,
  }) {
    if (product.isService || !product.allowDecimalQty) {
      if (qty % 1 != 0) qty = qty.floorToDouble();
    }
    final activeCart = active(isMainTab);
    final existingIndex = activeCart.indexWhere(
      (item) => sameCartProduct(item.product, product),
    );
    if (existingIndex != -1) {
      if (product.isServiceQtyLocked) {
        return 'Services can only be booked once per order.';
      }
      if (!product.isService &&
          activeCart[existingIndex].quantity + qty > product.stock) {
        return 'Cannot exceed available stock limit (${product.stock})';
      }
      activeCart[existingIndex].quantity += qty;
    } else {
      if (!product.isService && qty > product.stock) {
        return 'Cannot exceed available stock limit (${product.stock})';
      }
      activeCart.add(
        CartItem(product: product, quantity: qty, isDiscountPercent: false),
      );
    }
    _notifyListeners();
    return null;
  }

  void removeFromCart(PosProduct product, {bool isMainTab = false}) {
    active(isMainTab).removeWhere(
      (item) => sameCartProduct(item.product, product),
    );
    _notifyListeners();
  }

  String? updateQuantity(
    PosProduct product,
    double delta, {
    bool isMainTab = false,
  }) {
    if (product.isService || !product.allowDecimalQty) {
      if (delta % 1 != 0) delta = delta.floorToDouble();
    }
    final activeCart = active(isMainTab);
    final index = activeCart.indexWhere(
      (item) => sameCartProduct(item.product, product),
    );
    if (index != -1) {
      if (product.isServiceQtyLocked && delta > 0) {
        return 'Services can only be booked once per order.';
      }
      if (!product.isService &&
          activeCart[index].quantity + delta > product.stock) {
        return 'Cannot exceed available stock limit (${product.stock})';
      }
      activeCart[index].quantity += delta;
      if (activeCart[index].quantity <= 0) {
        activeCart.removeAt(index);
      }
      _notifyListeners();
    }
    return null;
  }

  String? setSpecificQuantity(
    PosProduct product,
    double qty, {
    bool isMainTab = false,
  }) {
    if (qty <= 0) {
      removeFromCart(product, isMainTab: isMainTab);
      return null;
    }
    if (product.isService || !product.allowDecimalQty) {
      if (qty % 1 != 0) qty = qty.floorToDouble();
    }

    if (product.isServiceQtyLocked && qty > 1) {
      return 'Services can only be booked once per order.';
    }

    if (!product.isService && qty > product.stock) {
      return 'Cannot exceed available stock limit (${product.stock})';
    }

    final activeCart = active(isMainTab);
    final index = activeCart.indexWhere(
      (item) => sameCartProduct(item.product, product),
    );
    if (index != -1) {
      activeCart[index].quantity = qty;
      _notifyListeners();
      return null;
    } else {
      return addToCart(product, qty: qty, isMainTab: isMainTab);
    }
  }

  void setIndividualDiscount(
    PosProduct product,
    double discount,
    bool isPercent, {
    bool isMainTab = false,
  }) {
    final activeCart = active(isMainTab);
    final index = activeCart.indexWhere(
      (item) => sameCartProduct(item.product, product),
    );
    if (index != -1) {
      activeCart[index].discount = discount;
      activeCart[index].isDiscountPercent = isPercent;
      _notifyListeners();
    }
  }

  void setServiceUnitPrice(
    PosProduct product,
    double? unitPrice, {
    bool isMainTab = false,
  }) {
    if (!product.isPriceEditable) return;
    final activeCart = active(isMainTab);
    final index = activeCart.indexWhere(
      (item) => sameCartProduct(item.product, product),
    );
    if (index == -1) return;
    if (unitPrice == null || unitPrice <= 0) {
      activeCart[index].serviceUnitPrice = null;
    } else {
      activeCart[index].serviceUnitPrice = unitPrice;
    }
    _notifyListeners();
  }

  void applyLocalEditableServiceUnitPrice(
    PosProduct product,
    double unitPriceVatInclusive, {
    bool isMainTab = false,
  }) {
    if (!product.isPriceEditable) return;
    if (unitPriceVatInclusive <= 0 || !unitPriceVatInclusive.isFinite) return;

    final activeCart = active(isMainTab);
    var index = activeCart.indexWhere(
      (item) => sameCartProduct(item.product, product),
    );
    if (index == -1) {
      activeCart.add(
        CartItem(product: product, quantity: 1.0, isDiscountPercent: false),
      );
      index = activeCart.length - 1;
    }
    activeCart[index].serviceUnitPrice = unitPriceVatInclusive;
    _notifyListeners();
  }
}

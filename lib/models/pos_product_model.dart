import 'package:flutter/material.dart';

class PosProduct {
  final String id;
  final String name;
  final String? productNameArabic;
  final String? unit;
  /// VAT-inclusive catalog price (salePrice / sellingPrice from backend).
  final double price;
  final double? _priceBeforeVat;
  /// VAT-exclusive catalog price; from backend or computed as price / 1.15.
  double get priceBeforeVat => _priceBeforeVat ?? _round2(price / 1.15);
  final double? purchasePrice;
  final int stock;
  String? categoryName;
  String? subCategoryName;
  String? categoryId;
  String? departmentId;
  String? departmentName;
  final String? imageUrl;
  final double vatRate;
  final int criticalStockPoint;
  final bool allowDecimalQty;
  /// When true (services/products), cashier may override unit price on orders.
  final bool isPriceEditable;
  /// VAT-inclusive floor when [isPriceEditable] (from master `min_price_editable`).
  final double? minPriceEditable;
  /// Branch catalog: unlimited stock — POS does not cap qty or reduce on invoice.
  final bool isInfiniteQty;
  /// Master catalog: may sell at 0 stock and go negative on hand.
  final bool allowMinusQty;
  /// Master/branch catalog: when non-null and > 0, cashier may change service qty.
  /// Null / missing → service qty locked at 1.
  final int? serviceQty;

  PosProduct({
    required this.id,
    required this.name,
    this.productNameArabic,
    this.unit,
    required this.price,
    double? priceBeforeVat,
    this.purchasePrice,
    required this.stock,
    this.categoryName,
    this.subCategoryName,
    this.categoryId,
    this.departmentId,
    this.departmentName,
    this.imageUrl,
    this.vatRate = 0.15,
    this.criticalStockPoint = 0,
    this.allowDecimalQty = false,
    this.isPriceEditable = false,
    this.minPriceEditable,
    this.isInfiniteQty = false,
    this.allowMinusQty = false,
    this.serviceQty,
  }) : _priceBeforeVat = priceBeforeVat;

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  /// Corporate quotation / order line price applied on top of branch catalog tiles.
  PosProduct withCatalogPrice(double salePriceInclVat) {
    final incl = _round2(salePriceInclVat);
    final copy = PosProduct(
      id: id,
      name: name,
      productNameArabic: productNameArabic,
      unit: unit,
      price: incl,
      priceBeforeVat: _round2(incl / 1.15),
      purchasePrice: purchasePrice,
      stock: stock,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      categoryId: categoryId,
      departmentId: departmentId,
      departmentName: departmentName,
      imageUrl: imageUrl,
      vatRate: vatRate,
      criticalStockPoint: criticalStockPoint,
      allowDecimalQty: allowDecimalQty,
      isPriceEditable: isPriceEditable,
      minPriceEditable: minPriceEditable,
      isInfiniteQty: isInfiniteQty,
      allowMinusQty: allowMinusQty,
      serviceQty: serviceQty,
    );
    copy.isServiceType = isServiceType;
    return copy;
  }

  /// Parses `serviceQty` / `service_qty`. Null/missing/0/false → qty OFF.
  static int? _parseServiceQty(Map<String, dynamic> json) {
    final v = json['serviceQty'] ?? json['service_qty'];
    if (v == null) return null;
    if (v == false || v == '') return null;
    if (v == true) return 1;
    if (v is num) {
      final n = v.toInt();
      return n > 0 ? n : null;
    }
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s.isEmpty || s == 'null' || s == 'false' || s == '0' || s == 'no') {
        return null;
      }
      if (s == 'true' || s == 'yes') return 1;
      final n = int.tryParse(s) ?? double.tryParse(s)?.toInt();
      if (n != null && n > 0) return n;
    }
    return null;
  }

  static bool _parseAllowMinusQty(Map<String, dynamic> json) {
    final v = json['allowMinusQty'] ?? json['allow_minus_qty'];
    if (v == true) return true;
    if (v == false) return false;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  static bool _parseIsInfiniteQty(Map<String, dynamic> json) {
    final v = json['isInfiniteQty'] ??
        json['is_infinite_qty'] ??
        json['isInfinite'] ??
        json['is_infinite'];
    if (v == true) return true;
    if (v == false) return false;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  /// Handles bool, int, and string forms for price-editable flags from various API layers.
  static bool _parseIsPriceEditable(Map<String, dynamic> json) {
    const keys = <String>[
      'isPriceEditable',
      'is_price_editable',
      'priceEditable',
      'price_editable',
    ];
    var anyTrue = false;
    var anyExplicitFalse = false;
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      if (v == true || (v is num && v != 0)) {
        anyTrue = true;
        continue;
      }
      if (v == false || (v is num && v == 0)) {
        anyExplicitFalse = true;
        continue;
      }
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes') {
          anyTrue = true;
        } else if (s == 'false' || s == '0' || s == 'no') {
          anyExplicitFalse = true;
        }
      }
    }
    if (anyTrue) return true;
    if (anyExplicitFalse) return false;
    return false;
  }

  static double? _parseMinPriceEditable(Map<String, dynamic> json) {
    const keys = <String>[
      'minPriceEditable',
      'min_price_editable',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v == null || v.toString().trim().isEmpty) continue;
      final n = double.tryParse(v.toString());
      if (n != null && n.isFinite && n >= 0) return _round2(n);
    }
    return null;
  }

  /// Handles bool, int, and common string forms from APIs (`"true"`, `"1"`).
  static bool _parseAllowDecimalQty(Map<String, dynamic> json) {
    final v = json['allowDecimalQty'] ?? json['allow_decimal_qty'];
    if (v == true) return true;
    if (v == false) return false;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    // Backend sometimes omits the flag for volume/weight UOM — allow decimals for those.
    final u = json['unit']?.toString().toLowerCase().trim() ?? '';
    if (u.isEmpty) return false;
    const decimalUnits = <String>{
      'liter',
      'litre',
      'l',
      'ml',
      'kg',
      'g',
      'gallon',
      'gal',
      'oz',
    };
    return decimalUnits.contains(u);
  }


  static String? _cleanArabicName(Object? value) {
    final v = value?.toString().trim();
    if (v == null || v.isEmpty || v.toLowerCase() == 'null') return null;
    return v;
  }

  static String? _parseArabicName(Map<String, dynamic> json) {
    final direct = _cleanArabicName(json['productNameArabic']) ??
        _cleanArabicName(json['product_name_arabic']) ??
        _cleanArabicName(json['productNameAr']) ??
        _cleanArabicName(json['product_name_ar']) ??
        _cleanArabicName(json['nameArabic']) ??
        _cleanArabicName(json['name_arabic']) ??
        _cleanArabicName(json['nameAr']) ??
        _cleanArabicName(json['name_ar']) ??
        _cleanArabicName(json['arabicName']) ??
        _cleanArabicName(json['arabic_name']);
    if (direct != null) return direct;

    for (final key in const ['product', 'service', 'item']) {
      final nested = json[key];
      if (nested is Map) {
        final parsed = _parseArabicName(Map<String, dynamic>.from(nested));
        if (parsed != null) return parsed;
      }
    }

    final translations = json['translations'];
    if (translations is Map) {
      final ar = translations['ar'] ?? translations['arabic'];
      if (ar is Map) {
        return _cleanArabicName(ar['name']) ??
            _cleanArabicName(ar['productName']) ??
            _cleanArabicName(ar['title']);
      }
    }
    return null;
  }

  /// Prefer live balance keys from cashier catalog; adoption/opening last (legacy shapes).
  /// Services often omit `type: service` when nested under a *Services* category/subcategory.
  static bool _parseIsServiceType(Map<String, dynamic> json) {
    for (final k in const ['type', 'itemType', 'productType', 'catalogType']) {
      final v = json[k]?.toString().trim().toLowerCase() ?? '';
      if (v == 'service' || v == 'services') return true;
    }
    if (json['isService'] == true || json['service'] == true) return true;
    if (json['serviceId'] != null &&
        (json['productId'] == null || json['productId'].toString().trim().isEmpty)) {
      return true;
    }
    for (final k in const [
      'categoryName',
      'category',
      'subCategoryName',
      'subcategory',
      'subCategory',
    ]) {
      final v = json[k]?.toString().trim().toLowerCase() ?? '';
      if (v.contains('service')) return true;
    }
    return false;
  }

  static int _parseCatalogStockQty(Map<String, dynamic> json) {
    const liveKeys = <String>[
      'qtyOnHand',
      'quantityOnHand',
      'currentStock',
      'currentQty',
      'stockQty',
      'stock_qty',
      'availableQty',
      'availableQuantity',
      'onHand',
      'balance',
    ];
    for (final k in liveKeys) {
      final v = json[k];
      if (v == null || v.toString().trim().isEmpty) continue;
      final n = num.tryParse(v.toString());
      if (n != null) return n.round();
    }
    for (final k in ['openingQty', 'opening_qty', 'adoptionQty']) {
      final v = json[k];
      if (v == null || v.toString().trim().isEmpty) continue;
      final n = num.tryParse(v.toString());
      if (n != null) return n.round();
    }
    return 0;
  }

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    final inclVat = double.tryParse(json['salePrice']?.toString() ?? json['sellingPrice']?.toString() ?? '0.0') ?? 0.0;
    final exclVat = double.tryParse(
      json['salePriceBeforeVat']?.toString() ??
      json['sellingPriceBeforeVat']?.toString() ??
      '',
    );
    final isInfiniteQty = _parseIsInfiniteQty(json);
    final allowMinusQty = _parseAllowMinusQty(json);
    final product = PosProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      productNameArabic: _parseArabicName(json),
      unit: json['unit'],
      price: inclVat,
      priceBeforeVat: exclVat,
      purchasePrice: double.tryParse(json['purchasePrice']?.toString() ?? '0.0'),
      stock: isInfiniteQty ? 0 : _parseCatalogStockQty(json),
      categoryName: json['categoryName'],
      subCategoryName: json['subCategoryName'],
      categoryId: json['categoryId']?.toString() ??
          json['productCategoryId']?.toString() ??
          json['serviceCategoryId']?.toString(),
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName'],
      imageUrl: json['imageUrl'],
      criticalStockPoint: int.tryParse(json['criticalStockPoint']?.toString() ?? '0') ?? 0,
      allowDecimalQty: _parseAllowDecimalQty(json),
      isPriceEditable: _parseIsPriceEditable(json),
      minPriceEditable: _parseMinPriceEditable(json),
      isInfiniteQty: isInfiniteQty,
      allowMinusQty: allowMinusQty,
      // Always parse — isServiceType may be set by parent category after fromJson.
      serviceQty: _parseServiceQty(json),
    );
    product.isServiceType = _parseIsServiceType(json);
    return product;
  }

  String get category => categoryName ?? 'Uncategorized';
  String get subtitle => unit ?? '';

  double get priceInclVat => price;

  bool isServiceType = false;

  bool get _inferredServiceFromCategory {
    for (final s in [categoryName, subCategoryName]) {
      final t = (s ?? '').trim().toLowerCase();
      if (t.contains('service')) return true;
    }
    return false;
  }

  // Stock Helper (Matches old UI logic)
  bool get isService => isServiceType || _inferredServiceFromCategory;

  /// Services: qty editable when catalog `serviceQty` is a positive int.
  /// Products always allow qty changes.
  bool get allowsServiceQty {
    if (!isService) return true;
    return serviceQty != null && serviceQty! > 0;
  }

  /// Service with qty locked at 1 (legacy “once only” behavior).
  bool get isServiceQtyLocked => isService && !allowsServiceQty;

  bool get hasUnlimitedStock => isInfiniteQty || allowMinusQty;

  Color get stockColor {
    if (isService || isInfiniteQty) return const Color(0xFF4CAF50);
    if (allowMinusQty && stock <= 0) return const Color(0xFF7C3AED);
    if (stock > 5) return const Color(0xFF4CAF50);
    if (stock > 0) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get stockLabel {
    if (isService) return 'Service';
    if (isInfiniteQty) return 'Infinite';
    if (allowMinusQty && stock <= 0) return 'Available ($stock)';
    if (stock > 5) return 'In Stock ($stock)';
    if (stock > 0) return 'Low ($stock)';
    return 'Out of Stock';
  }

  bool get isOutOfStockForPos =>
      !isService && !isInfiniteQty && !allowMinusQty && stock <= 0;

  /// VAT-inclusive minimum unit price when [isPriceEditable].
  double get minEditablePriceVatInclusive => minPriceEditable ?? 0;

  /// Returns null when valid; `invalid` or `below_min` when not.
  String? validateEditableUnitPrice(double price) {
    if (!isPriceEditable) return null;
    if (price <= 0 || !price.isFinite) return 'invalid';
    final min = minEditablePriceVatInclusive;
    if (price < min - 0.005) return 'below_min';
    return null;
  }

  bool cartQtyExceedsStock(double qty) =>
      !isService && !isInfiniteQty && !allowMinusQty && qty > stock;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (productNameArabic != null) 'productNameArabic': productNameArabic,
        if (unit != null) 'unit': unit,
        'salePrice': price,
        if (_priceBeforeVat != null) 'salePriceBeforeVat': _priceBeforeVat,
        if (purchasePrice != null) 'purchasePrice': purchasePrice,
        'qtyOnHand': stock,
        if (categoryName != null) 'categoryName': categoryName,
        if (subCategoryName != null) 'subCategoryName': subCategoryName,
        if (categoryId != null) 'categoryId': categoryId,
        if (departmentId != null) 'departmentId': departmentId,
        if (departmentName != null) 'departmentName': departmentName,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'vatRate': vatRate,
        'criticalStockPoint': criticalStockPoint,
        'allowDecimalQty': allowDecimalQty,
        'isPriceEditable': isPriceEditable,
        if (minPriceEditable != null) 'minPriceEditable': minPriceEditable,
        'isInfiniteQty': isInfiniteQty,
        'allowMinusQty': allowMinusQty,
        if (serviceQty != null) 'serviceQty': serviceQty,
        'type': isServiceType ? 'service' : 'product',
      };
}

class ProductSubCategory {
  final String id;
  final String name;
  final List<PosProduct> products;

  ProductSubCategory({
    required this.id,
    required this.name,
    required this.products,
  });

  factory ProductSubCategory.fromJson(Map<String, dynamic> json) {
    final subName = (json['name'] ?? '').toString();
    final subLooksLikeServices =
        subName.trim().toLowerCase().contains('service');
    final prods = (json['products'] as List?)?.map((p) {
      final item = PosProduct.fromJson(p);
      if (subLooksLikeServices) item.isServiceType = true;
      return item;
    }).toList() ??
        [];
    final servs = (json['services'] as List?)?.map((s) {
       final p = PosProduct.fromJson(s);
       p.isServiceType = true;
       return p;
    }).toList() ?? [];
    
    return ProductSubCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      products: [...prods, ...servs],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'products': products.map((p) => p.toJson()).toList(),
      };
}

class ProductCategory {
  final String id;
  final String name;
  final String type;
  final List<ProductSubCategory> subCategories;
  final List<PosProduct> productsWithoutSub;

  ProductCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.subCategories,
    required this.productsWithoutSub,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final catId = json['id']?.toString() ?? '';
    final catName = (json['name'] ?? '').toString();
    final catLooksLikeServices =
        catName.trim().toLowerCase().contains('service');
    final prods =
        ((json['productsWithoutSub'] ?? json['products']) as List?)
                ?.map((p) {
              final item = PosProduct.fromJson(p);
              item.categoryId = catId;
              item.categoryName = catName;
              if (catLooksLikeServices) item.isServiceType = true;
              return item;
            })
            .toList() ??
            [];
    final servs = ((json['servicesWithoutSub'] ?? json['services']) as List?)?.map((s) {
       final p = PosProduct.fromJson(s);
       p.categoryId = catId;
       p.categoryName = catName;
       p.isServiceType = true;
       return p;
    }).toList() ?? [];

    return ProductCategory(
      id: catId,
      name: catName,
      type: json['type'] ?? '',
      subCategories: (json['subCategories'] as List?)
              ?.map((s) => ProductSubCategory.fromJson(s))
              .toList() ??
          [],
      productsWithoutSub: [...prods, ...servs],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'subCategories': subCategories.map((s) => s.toJson()).toList(),
        'productsWithoutSub': productsWithoutSub.map((p) => p.toJson()).toList(),
      };
}

class ProductsResponse {
  final bool success;
  final String? workshopId;
  final List<ProductCategory> categories;
  final List<PosProduct> uncategorizedProducts;

  ProductsResponse({
    required this.success,
    this.workshopId,
    required this.categories,
    required this.uncategorizedProducts,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    final List<ProductCategory> allCategories = [];
    final List<PosProduct> allUncategorized = [];

    if (json.containsKey('departments') && json['departments'] != null) {
      final departments = json['departments'] as List;
      for (var deptJson in departments) {
        final deptId = deptJson['id']?.toString() ?? '';
        final deptName = deptJson['name']?.toString() ?? '';

        final cats = (deptJson['categories'] as List?)?.map((c) {
          final cat = ProductCategory.fromJson(c);
          for (var sub in cat.subCategories) {
            for (var p in sub.products) {
              p.categoryId = cat.id;
              p.categoryName = cat.name;
              p.subCategoryName = sub.name;
              p.departmentId = deptId;
              p.departmentName = deptName;
            }
          }
          for (var p in cat.productsWithoutSub) {
            p.categoryId = cat.id;
            p.categoryName = cat.name;
            p.departmentId = deptId;
            p.departmentName = deptName;
          }
          return cat;
        }).toList() ?? [];
        allCategories.addAll(cats);
        
        final uncatProd = (deptJson['uncategorizedProducts'] as List?)?.map((p) {
          final product = PosProduct.fromJson(p);
          product.departmentId = deptId;
          product.departmentName = deptName;
          return product;
        }).toList() ?? [];
        allUncategorized.addAll(uncatProd);
        
        final uncatServ = (deptJson['uncategorizedServices'] as List?)?.map((s) {
           final p = PosProduct.fromJson(s);
           p.isServiceType = true;
           p.departmentId = deptId;
           p.departmentName = deptName;
           return p;
        }).toList() ?? [];
        allUncategorized.addAll(uncatServ);
      }
    } else {
      final cats = (json['categories'] as List?)?.map((c) {
        final cat = ProductCategory.fromJson(c);
        for (var sub in cat.subCategories) {
          for (var p in sub.products) {
            p.categoryId = cat.id;
            p.categoryName = cat.name;
            p.subCategoryName = sub.name;
          }
        }
        for (var p in cat.productsWithoutSub) {
          p.categoryId = cat.id;
          p.categoryName = cat.name;
        }
        return cat;
      }).toList() ?? [];
      allCategories.addAll(cats);
      allUncategorized.addAll((json['uncategorizedProducts'] as List?)?.map((p) => PosProduct.fromJson(p)).toList() ?? []);
    }

    return ProductsResponse(
      success: json['success'] ?? false,
      workshopId: json['workshopId']?.toString() ?? json['branch']?['id']?.toString(),
      categories: allCategories,
      uncategorizedProducts: allUncategorized,
    );
  }

  Map<String, dynamic> toCatalogCacheJson() => {
        'success': success,
        if (workshopId != null) 'workshopId': workshopId,
        'categories': categories.map((c) => c.toJson()).toList(),
        'uncategorizedProducts':
            uncategorizedProducts.map((p) => p.toJson()).toList(),
      };
}

class CartItem {
  /// Mutable so cart lines can be re-pointed at refreshed catalog instances when products reload.
  PosProduct product;
  double quantity;
  double discount;
  bool isDiscountPercent;
  /// When [product.isPriceEditable], per-unit override; null = catalog [product.price].
  double? serviceUnitPrice;
  /// Corporate quotation / order line price (VAT-inclusive). Used for products and fixed-price services.
  double? lineUnitPriceOverride;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    this.discount = 0.0,
    this.isDiscountPercent = false,
    this.serviceUnitPrice,
    this.lineUnitPriceOverride,
  });

  /// VAT-inclusive unit price (catalog price or cashier / corporate override).
  double get effectiveUnitPrice {
    if (product.isPriceEditable) {
      final u = serviceUnitPrice;
      if (u != null && u > 0) return u;
    }
    final quoted = lineUnitPriceOverride;
    if (quoted != null && quoted > 0) return quoted;
    return product.price;
  }

  /// VAT-exclusive unit price.
  double get effectiveUnitPriceExclVat {
    if (product.isPriceEditable) {
      final u = serviceUnitPrice;
      if (u != null && u > 0) return PosProduct._round2(u / 1.15);
    }
    final quoted = lineUnitPriceOverride;
    if (quoted != null && quoted > 0) return PosProduct._round2(quoted / 1.15);
    return product.priceBeforeVat;
  }

  /// Gross amount VAT-inclusive (kept for backward compat / display).
  double get lineSubtotalGross => effectiveUnitPrice * quantity;

  /// Gross amount VAT-exclusive.
  double get lineSubtotalExclVat => effectiveUnitPriceExclVat * quantity;

  /// Line discount amount (computed on VAT-exclusive gross).
  double get actualDiscountAmount {
    if (isDiscountPercent) {
      return lineSubtotalExclVat * (discount / 100);
    }
    return discount;
  }

  /// Line total VAT-exclusive (after line discount).
  double get totalPriceExclVat => lineSubtotalExclVat - actualDiscountAmount;

  /// VAT for live invoice totals.
  /// Fixed-amount line discounts reduce ex-VAT only; VAT stays on the pre-discount base
  /// so the payable total drops by exactly the discount (e.g. 25 − 5 = 20, not 19.25).
  double get lineVatAmount {
    final baseVat = PosProduct._round2(lineSubtotalExclVat * 0.15);
    if (!isDiscountPercent && actualDiscountAmount > 0) {
      return baseVat;
    }
    return PosProduct._round2(totalPriceExclVat * 0.15);
  }

  /// Payable line total incl. VAT (matches live invoice "Total").
  double get totalPriceInclVat =>
      PosProduct._round2(totalPriceExclVat + lineVatAmount);

  /// Line total VAT-inclusive (for backward compat / display).
  double get totalPrice => totalPriceInclVat;
}

/// VAT for order-level discounts (global + promo).
///
/// Always compute VAT from the final taxable amount after *all* discounts
/// (line/item, order/global, promo) have been applied.
double computePosOrderLevelVat({
  required double afterItemExclVat,
  required double globalDiscount,
  required bool globalIsPercent,
  required double promoDiscount,
  required bool promoIsPercent,
}) {
  final baseAfterGlobal =
      (afterItemExclVat - globalDiscount).clamp(0, double.infinity).toDouble();
  final taxable =
      (baseAfterGlobal - promoDiscount).clamp(0, double.infinity).toDouble();
  if (taxable <= 0.0001) return 0;
  return PosProduct._round2(taxable * 0.15);
}

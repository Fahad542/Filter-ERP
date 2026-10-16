import 'pos_order_model.dart';
import 'pos_product_model.dart';

/// Cashier corporate catalog — primarily
/// `GET /cashier/corporate-accounts/:id/products` (also legacy portal routes).
class CorporateQuotedProductsResponse {
  final bool success;
  final String? corporateAccountId;
  final String? corporateName;
  final String? branchId;
  final List<String> departmentIds;
  final List<CorporateQuotedProduct> products;
  final List<CorporateQuotedProduct> services;
  final List<CorporateQuotedProduct> quotedLines;

  const CorporateQuotedProductsResponse({
    required this.success,
    this.corporateAccountId,
    this.corporateName,
    this.branchId,
    this.departmentIds = const [],
    this.products = const [],
    this.services = const [],
    this.quotedLines = const [],
  });

  /// All catalog rows, de-duplicated (`quotedLines` wins over `services` / `products`).
  List<CorporateQuotedProduct> get allLines {
    final byKey = <String, CorporateQuotedProduct>{};
    void addAll(List<CorporateQuotedProduct> list) {
      for (final q in list) {
        if (q.id.isEmpty) continue;
        byKey[q.catalogKey] = q;
      }
    }

    addAll(products);
    addAll(services);
    // `quotedLines` last — corporate quotation rows override catalog `products`/`services`.
    addAll(quotedLines);
    return byKey.values.toList();
  }

  /// Rows that carry a corporate/agreed price to overlay on the branch catalog.
  List<CorporateQuotedProduct> get quotationPriceOverlayLines {
    final byKey = <String, CorporateQuotedProduct>{};
    void put(CorporateQuotedProduct q) {
      if (q.id.trim().isEmpty && q.name.trim().isEmpty) return;
      if (!q.isEligibleForPriceOverlay) return;
      byKey[q.catalogKey] = q;
    }

    // Full catalog rows first; quotedLines last so explicit quotation rows win.
    for (final q in products) {
      put(q);
    }
    for (final q in services) {
      put(q);
    }
    for (final q in quotedLines) {
      put(q);
    }
    return byKey.values.toList();
  }

  factory CorporateQuotedProductsResponse.fromJson(dynamic raw) {
    if (raw is List) {
      final lines = _parseProductList(raw);
      return CorporateQuotedProductsResponse(
        success: true,
        products: lines,
      );
    }

    final json = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    final nestedData = json['data'];
    if (nestedData is Map) {
      final nested = CorporateQuotedProductsResponse.fromJson(
        Map<String, dynamic>.from(nestedData),
      );
      if (nested.allLines.isNotEmpty) return nested;
    }

    final deptIdsRaw = json['departmentIds'];
    final departmentIds = deptIdsRaw is List
        ? deptIdsRaw
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];

    final products = _parseProductList(json['products']);
    final services = _parseProductList(json['services']);
    final quotedFromApi = <CorporateQuotedProduct>[
      ..._parseProductList(json['quotedLines']),
      ..._parseProductList(json['quotationLines']),
      ..._parseProductList(json['quotationProducts']),
      ..._parseProductList(json['quotedProducts']),
      ..._parseProductList(json['corporateQuotationLines']),
      if (json['corporateQuotation'] is Map)
        ..._parseProductList(
          (json['corporateQuotation'] as Map)['lines'] ??
              (json['corporateQuotation'] as Map)['items'] ??
              (json['corporateQuotation'] as Map)['products'],
        ),
    ];
    final quotedLines = _dedupeQuotedLines(quotedFromApi);

    if (products.isNotEmpty || services.isNotEmpty || quotedLines.isNotEmpty) {
      return CorporateQuotedProductsResponse(
        success: json['success'] != false,
        corporateAccountId: _stringOrNull(json['corporateAccountId']),
        corporateName: _stringOrNull(json['corporateName']),
        branchId: _stringOrNull(json['branchId']),
        departmentIds: departmentIds,
        products: products,
        services: services,
        quotedLines: quotedLines,
      );
    }

    final legacyList = json['items'] ??
        json['data'] ??
        json['quotedProducts'] ??
        json['catalog'];
    return CorporateQuotedProductsResponse(
      success: json['success'] != false,
      corporateAccountId: _stringOrNull(json['corporateAccountId']),
      corporateName: _stringOrNull(json['corporateName']),
      branchId: _stringOrNull(json['branchId']),
      departmentIds: departmentIds,
      products: _parseProductList(legacyList),
    );
  }

  static List<CorporateQuotedProduct> _dedupeQuotedLines(
    List<CorporateQuotedProduct> lines,
  ) {
    final byKey = <String, CorporateQuotedProduct>{};
    for (final q in lines) {
      if (q.id.trim().isEmpty && q.name.trim().isEmpty) continue;
      byKey[q.catalogKey] = q;
    }
    return byKey.values.toList();
  }

  static List<CorporateQuotedProduct> _parseProductList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CorporateQuotedProduct.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  static String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class CorporateQuotedProduct {
  final String id;
  final bool isService;
  final String name;
  final String? nameArabic;
  final double quotedPriceInclVat;
  final double? quotedPriceExclVat;
  final double? standardPrice;
  final bool isCorporateQuotedPrice;
  final String? departmentId;
  final String? departmentName;
  final String? categoryName;
  final String? unit;
  final int stock;

  CorporateQuotedProduct({
    required this.id,
    required this.isService,
    required this.name,
    this.nameArabic,
    required this.quotedPriceInclVat,
    this.quotedPriceExclVat,
    this.standardPrice,
    this.isCorporateQuotedPrice = false,
    this.departmentId,
    this.departmentName,
    this.categoryName,
    this.unit,
    this.stock = 0,
  });

  double get effectiveQuotedPrice {
    if (quotedPriceInclVat > 0) return quotedPriceInclVat;
    if (quotedPriceExclVat != null && quotedPriceExclVat! > 0) {
      return quotedPriceExclVat!;
    }
    return 0;
  }

  /// True when this row should override branch tile price (quotation / agreed price).
  bool get isEligibleForPriceOverlay {
    if (effectiveQuotedPrice <= 0) return false;
    if (isCorporateQuotedPrice) return true;
    final std = standardPrice ?? 0;
    if (std > 0) {
      return (effectiveQuotedPrice - std).abs() > 0.009;
    }
    return false;
  }

  String get catalogKey => CorporateQuotedProduct.catalogKeyFor(id, isService);

  static String catalogKeyFor(String id, bool isService) =>
      '${id.trim()}|${isService ? 'service' : 'product'}';

  /// Fallback when branch catalog ids differ from corporate quotation lines.
  static String nameKeyFor(String name, bool isService) =>
      '${name.trim().toLowerCase()}|${isService ? 'service' : 'product'}';

  factory CorporateQuotedProduct.fromPosOrderJobItem(PosOrderJobItem item) {
    final isService = item.itemType.toLowerCase() == 'service';
    return CorporateQuotedProduct(
      id: item.productId,
      isService: isService,
      name: item.productName,
      nameArabic: item.productNameArabic.isNotEmpty ? item.productNameArabic : null,
      quotedPriceInclVat: item.unitPrice,
      quotedPriceExclVat:
          item.unitPriceExcludingVat > 0 ? item.unitPriceExcludingVat : null,
      isCorporateQuotedPrice: item.unitPrice > 0,
      departmentId: item.departmentId.isNotEmpty ? item.departmentId : null,
      departmentName: item.departmentName.isNotEmpty ? item.departmentName : null,
    );
  }

  factory CorporateQuotedProduct.fromJson(Map<String, dynamic> json) {
    final nested = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : json['service'] is Map
            ? Map<String, dynamic>.from(json['service'] as Map)
            : null;

    final typeRaw = (json['type'] ??
            json['itemType'] ??
            nested?['type'] ??
            nested?['itemType'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final isService = typeRaw == 'service' ||
        typeRaw == 'services' ||
        json['serviceId'] != null ||
        nested?['serviceId'] != null;

    final id = _firstNonEmpty([
          json['productId'],
          json['serviceId'],
          json['catalogProductId'],
          json['branchProductId'],
          json['inventoryProductId'],
          json['lineItemProductId'],
          json['itemId'],
          json['skuId'],
          json['id'],
          nested?['id'],
          nested?['productId'],
          nested?['serviceId'],
          nested?['catalogProductId'],
          nested?['branchProductId'],
          nested?['inventoryProductId'],
        ]) ??
        '';

    final name = _firstNonEmpty([
          json['name'],
          json['productName'],
          json['serviceName'],
          nested?['name'],
          nested?['productName'],
        ]) ??
        'Item';

    // Corporate quoted = unitPrice; branch retail = standardPrice / salePrice (do not swap).
    var incl = _parsePrice(json, const [
      'unitPrice',
      'unitPriceInclVat',
      'unitPriceIncludingVat',
      'quotedUnitPrice',
      'corporateUnitPrice',
      'quotedPrice',
      'quotedPriceInclVat',
      'quotationPrice',
      'corporatePrice',
      'agreedPrice',
      'contractPrice',
    ], nested: nested);
    if (incl <= 0) {
      final lineTotal = _parsePrice(json, const ['lineTotal', 'total'], nested: nested);
      final qty = _parsePrice(json, const ['qty', 'quantity'], nested: nested);
      if (lineTotal > 0 && qty > 0) {
        incl = lineTotal / qty;
      }
    }
    final excl = _parsePrice(json, const [
      'quotedPriceBeforeVat',
      'quotedPriceExclVat',
      'salePriceBeforeVat',
      'sellingPriceBeforeVat',
      'priceBeforeVat',
      'priceExclVat',
    ], nested: nested);
    // Do not treat `price` as standard — API uses it for resolved unitPrice too.
    final standard = _parsePrice(json, const [
      'standardPrice',
      'salePrice',
      'sellingPrice',
      'priceInclVat',
      'priceIncludingVat',
    ], nested: nested);

    final stockRaw = json['qtyOnHand'] ??
        json['stock'] ??
        json['stockQty'] ??
        nested?['qtyOnHand'] ??
        nested?['stock'];
    final stock = stockRaw is num
        ? stockRaw.round()
        : int.tryParse(stockRaw?.toString() ?? '') ?? 0;

    var quotedFlag = json['isCorporateQuotedPrice'] == true ||
        json['isCorporateQuotedPrice']?.toString().toLowerCase() == 'true';
    if (!quotedFlag &&
        standard > 0 &&
        incl > 0 &&
        (incl - standard).abs() > 0.009) {
      quotedFlag = true;
    }

    return CorporateQuotedProduct(
      id: id,
      isService: isService,
      name: name,
      nameArabic: _firstNonEmpty([
        json['productNameArabic'],
        json['nameArabic'],
        nested?['productNameArabic'],
      ]),
      quotedPriceInclVat: incl,
      quotedPriceExclVat: excl > 0 ? excl : null,
      standardPrice: standard > 0 ? standard : null,
      isCorporateQuotedPrice: quotedFlag,
      departmentId: _firstNonEmpty([
        json['departmentId'],
        nested?['departmentId'],
      ]),
      departmentName: _firstNonEmpty([
        json['departmentName'],
        nested?['departmentName'],
      ]),
      categoryName: _firstNonEmpty([
        json['categoryName'],
        json['category'],
        nested?['categoryName'],
      ]),
      unit: _firstNonEmpty([json['unit'], nested?['unit']]),
      stock: stock,
    );
  }

  PosProduct toPosProduct() {
    return PosProduct.fromJson({
      'id': id,
      'name': name,
      if (nameArabic != null) 'productNameArabic': nameArabic,
      if (unit != null) 'unit': unit,
      'salePrice': effectiveQuotedPrice,
      if (quotedPriceExclVat != null) 'salePriceBeforeVat': quotedPriceExclVat,
      'qtyOnHand': stock,
      if (departmentId != null) 'departmentId': departmentId,
      if (departmentName != null) 'departmentName': departmentName,
      if (categoryName != null) 'categoryName': categoryName,
      'type': isService ? 'service' : 'product',
    });
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return null;
  }

  static double _parsePrice(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic>? nested,
  }) {
    for (final source in [json, if (nested != null) nested]) {
      for (final k in keys) {
        final v = source[k];
        if (v == null) continue;
        final n = double.tryParse(v.toString());
        if (n != null && n > 0) return n;
      }
    }
    return 0;
  }
}

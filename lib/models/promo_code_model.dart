class PromoCodeResponse {
  final bool success;
  final bool valid;
  final String message;
  final PromoData? promoCode;

  PromoCodeResponse({
    required this.success,
    required this.valid,
    required this.message,
    this.promoCode,
  });

  factory PromoCodeResponse.fromJson(Map<String, dynamic> json) {
    return PromoCodeResponse(
      success: json['success'] ?? false,
      valid: json['valid'] ?? false,
      message: json['message'] ?? '',
      promoCode: json['promoCode'] != null
          ? PromoData.fromJson(json['promoCode'])
          : null,
    );
  }
}

class PromoData {
  final String? id;
  final double discount;
  final bool isPercent;
  final String code;
  final String? applicableStore;
  final String? applicableProducts;
  final String? applicableServices;
  final List<String> productNames;
  final List<String> serviceNames;
  final String? productScope;
  final String? serviceScope;
  final String? validityPeriod;
  final String? description;
  final String? discountLabel;
  final String? promotionName;
  final double? discountAmount;
  final String? workshopScope;
  final List<String> workshopIds;
  final List<String> productIds;
  final List<String> serviceIds;
  final List<String> productCategoryIds;
  final List<String> serviceCategoryIds;
  final String? selectedItemMatchMode;
  final bool selectedServiceRequired;

  PromoData({
    this.id,
    required this.discount,
    required this.isPercent,
    required this.code,
    this.applicableStore,
    this.applicableProducts,
    this.applicableServices,
    this.productNames = const [],
    this.serviceNames = const [],
    this.productScope,
    this.serviceScope,
    this.validityPeriod,
    this.description,
    this.discountLabel,
    this.promotionName,
    this.discountAmount,
    this.workshopScope,
    this.workshopIds = const [],
    this.productIds = const [],
    this.serviceIds = const [],
    this.productCategoryIds = const [],
    this.serviceCategoryIds = const [],
    this.selectedItemMatchMode,
    this.selectedServiceRequired = true,
  });

  static bool isPercentDiscountType(String? discountType) {
    final normalized = (discountType ?? '').trim().toLowerCase();
    return normalized.contains('percent') || normalized == 'percent';
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  factory PromoData.fromJson(Map<String, dynamic> json) {
    final isPercentValue = json['isPercent'] == true ||
        isPercentDiscountType(json['discountType']?.toString());

    final discount = double.tryParse(
          json['discountValue']?.toString() ??
              json['discount']?.toString() ??
              '0',
        ) ??
        0.0;

    String? validity;
    if (json['validityPeriod'] != null) {
      validity = json['validityPeriod']?.toString();
    } else if (json['validFrom'] != null && json['validTo'] != null) {
      validity = '${json['validFrom']} — ${json['validTo']}';
    } else if (json['validTo'] != null) {
      validity = 'Until ${json['validTo']}';
    } else {
      validity = json['period']?.toString();
    }

    return PromoData(
      id: json['id']?.toString() ?? json['promoCodeId']?.toString(),
      discount: discount,
      isPercent: isPercentValue,
      code: json['code'] ?? '',
      applicableStore:
          json['applicableStore']?.toString() ?? json['store']?.toString(),
      applicableProducts:
          json['applicableProducts']?.toString() ?? json['products']?.toString(),
      applicableServices:
          json['applicableServices']?.toString() ?? json['services']?.toString(),
      productNames: _parseStringList(json['productNames']),
      serviceNames: _parseStringList(json['serviceNames']),
      productScope: json['productScope']?.toString(),
      serviceScope: json['serviceScope']?.toString(),
      validityPeriod: validity,
      description: json['description']?.toString(),
      discountLabel: json['discountLabel']?.toString(),
      promotionName: json['promotionName']?.toString(),
      discountAmount: double.tryParse(
        json['discountAmount']?.toString() ?? '',
      ),
      workshopScope: json['workshopScope']?.toString(),
      workshopIds: _parseStringList(json['workshopIds']),
      productIds: _parseStringList(json['productIds']),
      serviceIds: _parseStringList(json['serviceIds']),
      productCategoryIds: _parseStringList(json['productCategoryIds']),
      serviceCategoryIds: _parseStringList(json['serviceCategoryIds']),
      selectedItemMatchMode: json['selectedItemMatchMode']?.toString() ??
          json['selected_item_match_mode']?.toString(),
      selectedServiceRequired: json['selectedServiceRequired'] == false ||
          json['selected_service_required'] == false
          ? false
          : true,
    );
  }
}

class PromoCodeListResponse {
  final bool success;
  final List<PromoData>? promoCodes;

  PromoCodeListResponse({required this.success, this.promoCodes});

  factory PromoCodeListResponse.fromJson(Map<String, dynamic> json) {
    return PromoCodeListResponse(
      success: json['success'] ?? false,
      promoCodes: json['promoCodes'] != null
          ? (json['promoCodes'] as List)
              .map((i) => PromoData.fromJson(Map<String, dynamic>.from(i)))
              .toList()
          : null,
    );
  }
}

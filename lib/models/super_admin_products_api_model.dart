class SuperAdminProductsResponse {
  final bool success;
  final List<SuperAdminProduct> products;

  SuperAdminProductsResponse({
    required this.success,
    required this.products,
  });

  factory SuperAdminProductsResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminProductsResponse(
      success: json['success'] ?? false,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => SuperAdminProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SuperAdminProduct {
  final String id;
  final String? workshopId;
  final List<String> branchIds;
  final String? branchId;
  final String? workshopName;
  final String? departmentId;
  final String? departmentName;
  final String? categoryId;
  final String? categoryName;
  final String? subCategoryId;
  final String? subCategoryName;
  final String name;
  final String? unit;
  final double purchasePrice;
  final double salePrice;
  final int openingQty;
  final bool isActive;

  SuperAdminProduct({
    required this.id,
    this.workshopId,
    required this.branchIds,
    this.branchId,
    this.workshopName,
    this.departmentId,
    this.departmentName,
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    required this.name,
    this.unit,
    required this.purchasePrice,
    required this.salePrice,
    required this.openingQty,
    required this.isActive,
  });

  factory SuperAdminProduct.fromJson(Map<String, dynamic> json) {
    return SuperAdminProduct(
      id: json['id']?.toString() ?? '',
      workshopId: json['workshopId']?.toString(),
      branchIds: (json['branchIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      branchId: json['branchId']?.toString(),
      workshopName: json['workshopName'],
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName'],
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'],
      subCategoryId: json['subCategoryId']?.toString(),
      subCategoryName: json['subCategoryName'],
      name: json['name'] ?? 'Unknown Product',
      unit: json['unit'],
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      openingQty: (json['openingQty'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}

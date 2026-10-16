class InvoicedOrderResponse {
  final bool success;
  final String? message;
  final List<InvoicedOrder> orders;

  InvoicedOrderResponse({
    required this.success,
    this.message,
    required this.orders,
  });

  factory InvoicedOrderResponse.fromJson(Map<String, dynamic> json) {
    return InvoicedOrderResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => InvoicedOrder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class InvoicedOrder {
  final String id;
  final String invoiceId;
  final String invoiceNo;
  final String status;
  final String totalDiscountType;
  final double totalDiscountValue;
  final String? promoCodeId;
  final String? promoCodeName;
  final double totalAmount;
  final String createdAt;
  final String customerId;
  final String customerName;
  final String? branchId;
  final String? branchName;
  final String? workshopId;
  final String? workshopName;
  final String? plateNumber;
  final String? vehicleMake;
  final String? vehicleModel;
  final List<InvoicedOrderItem> items;
  final List<String> technicianNames;

  InvoicedOrder({
    required this.id,
    required this.invoiceId,
    required this.invoiceNo,
    required this.status,
    required this.totalDiscountType,
    required this.totalDiscountValue,
    this.promoCodeId,
    this.promoCodeName,
    required this.totalAmount,
    required this.createdAt,
    this.customerId = '',
    this.customerName = '',
    this.branchId,
    this.branchName,
    this.workshopId,
    this.workshopName,
    this.plateNumber,
    this.vehicleMake,
    this.vehicleModel,
    required this.items,
    this.technicianNames = const [],
  });

  String get technicianDisplay => technicianNames.join(', ');

  factory InvoicedOrder.fromJson(Map<String, dynamic> json) {
    // Customer name may come as a top-level field or nested under 'customer'
    final customerMap = json['customer'] as Map<String, dynamic>?;
    final parsedName = json['customerName']?.toString() ??
        customerMap?['name']?.toString() ??
        '';
    final vehicleMap = json['vehicle'] as Map<String, dynamic>?;
    final plate = json['plateNumber']?.toString() ??
        vehicleMap?['resolvedPlate']?.toString() ??
        vehicleMap?['plateDisplay']?.toString() ??
        vehicleMap?['plateNo']?.toString();

    return InvoicedOrder(
      id: json['id']?.toString() ?? json['order_id']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? json['invoiceId']?.toString() ?? '',
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalDiscountType: json['totalDiscountType']?.toString() ?? '',
      totalDiscountValue:
          double.tryParse(json['totalDiscountValue']?.toString() ?? '0') ?? 0,
      promoCodeId: json['promoCodeId']?.toString(),
      promoCodeName: json['promoCodeName']?.toString(),
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: parsedName,
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      workshopId: json['workshopId']?.toString(),
      workshopName: json['workshopName']?.toString(),
      plateNumber: (plate ?? '').trim().isEmpty ? null : plate!.trim(),
      vehicleMake: vehicleMap?['make']?.toString(),
      vehicleModel: vehicleMap?['model']?.toString(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  InvoicedOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      technicianNames: _parseTechnicianNames(json),
    );
  }

  static List<String> _parseTechnicianNames(Map<String, dynamic> json) {
    final seen = <String>{};
    void add(String? raw) {
      final name = raw?.trim() ?? '';
      if (name.isEmpty) return;
      seen.add(name);
    }

    final direct = json['technicianNames'] ?? json['technician_names'];
    if (direct is List) {
      for (final item in direct) {
        add(item?.toString());
      }
    }

    final technicians = json['technicians'];
    if (technicians is List) {
      for (final item in technicians) {
        if (item is Map) {
          add(item['name']?.toString());
        } else {
          add(item?.toString());
        }
      }
    }

    final salesOrder = json['salesOrder'] is Map
        ? Map<String, dynamic>.from(json['salesOrder'] as Map)
        : null;
    final jobs = json['jobs'] ?? salesOrder?['jobs'];
    if (jobs is List) {
      for (final job in jobs) {
        if (job is! Map) continue;
        final assignments =
            job['technicians'] ?? job['jobAssignments'] ?? job['assignments'];
        if (assignments is! List) continue;
        for (final assignment in assignments) {
          if (assignment is Map) {
            final emp = assignment['assignedToEmployee'] is Map
                ? Map<String, dynamic>.from(
                    assignment['assignedToEmployee'] as Map,
                  )
                : null;
            add(
              assignment['name']?.toString() ?? emp?['name']?.toString(),
            );
          }
        }
      }
    }

    return seen.toList();
  }
}

class InvoicedOrderItem {
  final String id;
  final String itemType;
  final String productId;
  final String productName;
  final String departmentId;
  final String departmentName;
  final double qty;
  final double unitPrice;
  final String discountType;
  final double discountValue;
  final double lineTotal;

  InvoicedOrderItem({
    required this.id,
    required this.itemType,
    required this.productId,
    required this.productName,
    required this.departmentId,
    required this.departmentName,
    required this.qty,
    required this.unitPrice,
    required this.discountType,
    required this.discountValue,
    required this.lineTotal,
  });

  factory InvoicedOrderItem.fromJson(Map<String, dynamic> json) {
    return InvoicedOrderItem(
      id: json['id']?.toString() ?? '',
      itemType: json['itemType']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0,
      discountType: json['discountType']?.toString() ?? '',
      discountValue:
          double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0,
      lineTotal: double.tryParse(json['lineTotal']?.toString() ?? '0') ?? 0,
    );
  }
}

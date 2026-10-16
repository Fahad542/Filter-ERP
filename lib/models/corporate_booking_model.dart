class CorporateBookingApproveResult {
  final bool success;
  final String? salesOrderId;
  final String? message;

  const CorporateBookingApproveResult({
    required this.success,
    this.salesOrderId,
    this.message,
  });

  factory CorporateBookingApproveResult.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    String? salesOrderId;
    if (order is Map) {
      salesOrderId = order['salesOrderId']?.toString();
    }
    final explicit = json['success'];
    final success = explicit == true ||
        explicit?.toString().toLowerCase() == 'true';
    return CorporateBookingApproveResult(
      success: success,
      salesOrderId: salesOrderId,
      message: json['message']?.toString(),
    );
  }
}

class CorporateBookingResponse {
  final bool success;
  final List<CorporateBooking> bookings;

  CorporateBookingResponse({
    required this.success,
    required this.bookings,
  });

  factory CorporateBookingResponse.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final bookingsRaw = root['bookings'];
    final bookings = bookingsRaw is List
        ? bookingsRaw
            .whereType<Map>()
            .map((e) => CorporateBooking.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CorporateBooking>[];
    final explicitSuccess = root['success'];
    final success = explicitSuccess == true ||
        explicitSuccess?.toString().toLowerCase() == 'true' ||
        bookings.isNotEmpty;
    return CorporateBookingResponse(
      success: success,
      bookings: bookings,
    );
  }
}

class CorporateBooking {
  final String id;
  /// Cashier walk-in / sales order id after approval (may differ from [id]).
  final String? orderId;
  final String bookingCode;
  final String status;
  final String statusDisplay;
  final String companyName;
  final String vehicleName;
  final String vehiclePlate;
  final String department;
  final DateTime bookedDateTime;
  final String branchId;
  final String branchName;
  final DateTime submittedAt;
  final String? orderStatus;
  final String? rejectionReason;
  final String? corporateAccountId;
  final List<String>? preSelectedProducts;
  final List<dynamic>? items;

  CorporateBooking({
    required this.id,
    this.orderId,
    required this.bookingCode,
    required this.status,
    required this.statusDisplay,
    required this.companyName,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.department,
    required this.bookedDateTime,
    required this.branchId,
    required this.branchName,
    required this.submittedAt,
    this.orderStatus,
    this.rejectionReason,
    this.corporateAccountId,
    this.preSelectedProducts,
    this.items,
  });

  factory CorporateBooking.fromJson(Map<String, dynamic> json) {
    List<dynamic>? parseLineItems() {
      final lineItems = json['lineItems'];
      if (lineItems is List && lineItems.isNotEmpty) {
        return List<dynamic>.from(lineItems);
      }
      final items = json['items'];
      if (items is List && items.isNotEmpty) {
        return List<dynamic>.from(items);
      }
      final jobs = json['jobs'];
      if (jobs is List) {
        final collected = <dynamic>[];
        for (final job in jobs) {
          if (job is! Map) continue;
          final ji = job['items'];
          if (ji is List && ji.isNotEmpty) {
            collected.addAll(ji);
          }
        }
        if (collected.isNotEmpty) return collected;
      }
      return null;
    }

    return CorporateBooking(
      id: json['id']?.toString() ?? '',
      orderId: _firstNonEmptyString([
        json['orderId'],
        json['walkInOrderId'],
        json['salesOrderId'],
        json['sales_order_id'],
        json['cashierOrderId'],
        (json['order'] is Map) ? (json['order'] as Map)['id'] : null,
        (json['walkInOrder'] is Map) ? (json['walkInOrder'] as Map)['id'] : null,
      ]),
      bookingCode: json['bookingCode'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['statusDisplay'] ?? '',
      companyName: json['corporateName'] ?? '',
      vehicleName: json['vehicle'] ?? '',
      vehiclePlate: json['plate'] ?? '',
      department: json['department'] ?? '',
      bookedDateTime: json['bookedFor'] != null
          ? DateTime.tryParse(json['bookedFor']) ?? DateTime.now()
          : DateTime.now(),
      branchId: json['branchId']?.toString() ?? '',
      branchName: json['branchName'] ?? '',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt']) ?? DateTime.now()
          : DateTime.now(),
      orderStatus: _firstNonEmptyString([
        json['orderStatus'],
        json['salesOrderStatus'],
        json['walkInOrderStatus'],
        (json['order'] is Map)
            ? (json['order'] as Map)['status']
            : null,
      ]),
      rejectionReason: _firstNonEmptyString([
        json['rejectionReason'],
        json['rejectReason'],
        json['rejectedReason'],
        json['reason'],
      ]),
      corporateAccountId: _firstNonEmptyString([
        json['corporateAccountId'],
        json['corporateId'],
        json['accountId'],
        (json['corporate'] is Map)
            ? (json['corporate'] as Map)['id']
            : null,
        (json['corporateAccount'] is Map)
            ? (json['corporateAccount'] as Map)['id']
            : null,
      ]),
      items: parseLineItems(),
    );
  }

  CorporateBooking copyWith({
    String? id,
    String? orderId,
    String? bookingCode,
    String? status,
    String? statusDisplay,
    String? companyName,
    String? vehicleName,
    String? vehiclePlate,
    String? department,
    DateTime? bookedDateTime,
    String? branchId,
    String? branchName,
    DateTime? submittedAt,
    String? orderStatus,
    String? rejectionReason,
    String? corporateAccountId,
    List<String>? preSelectedProducts,
    List<dynamic>? items,
  }) {
    return CorporateBooking(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      bookingCode: bookingCode ?? this.bookingCode,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      companyName: companyName ?? this.companyName,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      department: department ?? this.department,
      bookedDateTime: bookedDateTime ?? this.bookedDateTime,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      submittedAt: submittedAt ?? this.submittedAt,
      orderStatus: orderStatus ?? this.orderStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      corporateAccountId: corporateAccountId ?? this.corporateAccountId,
      preSelectedProducts: preSelectedProducts ?? this.preSelectedProducts,
      items: items ?? this.items,
    );
  }
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final v in values) {
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

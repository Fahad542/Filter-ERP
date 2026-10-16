class SalesReturnListResponse {
  final bool success;
  final int total;
  final int limit;
  final int offset;
  final List<SalesReturnInfo> salesReturns;

  SalesReturnListResponse({
    required this.success,
    required this.total,
    required this.limit,
    required this.offset,
    required this.salesReturns,
  });

  factory SalesReturnListResponse.fromJson(Map<String, dynamic> json) {
    return SalesReturnListResponse(
      success: json['success'] ?? false,
      total: (json['total'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      salesReturns: (json['salesReturns'] as List?)
              ?.map((e) => SalesReturnInfo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalesReturnInfo {
  final String id;
  final String returnNo;
  final String? creditNoteNo;
  final String? returnScope;
  final String invoiceId;
  final String invoiceNo;
  final String orderId;
  final String customerId;
  final String customerName;
  final String returnDate;
  final String createdAt;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final String? reason;
  final String status;
  final String? rejectionReason;
  final List<SalesReturnItemInfo> items;

  SalesReturnInfo({
    required this.id,
    required this.returnNo,
    this.creditNoteNo,
    this.returnScope,
    required this.invoiceId,
    required this.invoiceNo,
    required this.orderId,
    required this.customerId,
    this.customerName = '',
    required this.returnDate,
    required this.createdAt,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    this.reason,
    required this.status,
    this.rejectionReason,
    required this.items,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory SalesReturnInfo.fromJson(Map<String, dynamic> json) {
    return SalesReturnInfo(
      id: json['id']?.toString() ?? '',
      returnNo: json['returnNo'] ?? '',
      creditNoteNo: json['creditNoteNo']?.toString(),
      returnScope: json['returnScope']?.toString(),
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceNo: json['invoiceNo'] ?? '',
      orderId: json['orderId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ??
          (json['customer'] as Map<String, dynamic>?)?['name']?.toString() ??
          '',
      returnDate: json['returnDate'] ?? '',
      createdAt: json['createdAt'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (json['vatAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? '',
      rejectionReason: json['rejectionReason']?.toString(),
      items: (json['items'] as List?)
              ?.map((e) => SalesReturnItemInfo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalesReturnItemInfo {
  final String id;
  final String salesOrderItemId;
  final double qty;
  final double lineTotal;
  final String? reason;

  SalesReturnItemInfo({
    required this.id,
    required this.salesOrderItemId,
    required this.qty,
    required this.lineTotal,
    this.reason,
  });

  factory SalesReturnItemInfo.fromJson(Map<String, dynamic> json) {
    return SalesReturnItemInfo(
      id: json['id']?.toString() ?? '',
      salesOrderItemId: json['salesOrderItemId']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString(),
    );
  }
}

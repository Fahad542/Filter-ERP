class SubmitSalesReturnRequest {
  final String invoiceId;
  final String orderId;
  final String customerId;
  final String? reason;
  final String? proofUrl;
  final List<SalesReturnItem> items;

  SubmitSalesReturnRequest({
    required this.invoiceId,
    required this.orderId,
    required this.customerId,
    this.reason,
    this.proofUrl,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'orderId': orderId,
      'customerId': customerId,
      if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
      if (proofUrl != null) 'proofUrl': proofUrl,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class SalesReturnItem {
  final String salesOrderItemId;
  final double qty;
  final String reason;

  SalesReturnItem({
    required this.salesOrderItemId,
    required this.qty,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'salesOrderItemId': salesOrderItemId,
      'qty': qty,
      'reason': reason,
    };
  }
}

class SubmitSalesReturnResponse {
  final bool success;
  final String message;
  final SubmittedSalesReturn? salesReturn;

  SubmitSalesReturnResponse({
    required this.success,
    required this.message,
    this.salesReturn,
  });

  factory SubmitSalesReturnResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['salesReturn'];
    return SubmitSalesReturnResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      salesReturn: raw is Map
          ? SubmittedSalesReturn.fromJson(Map<String, dynamic>.from(raw))
          : null,
    );
  }
}

class SubmittedSalesReturn {
  final String id;
  final String returnNo;
  final String? creditNoteNo;
  final String? returnScope;
  final String status;
  final double totalAmount;

  SubmittedSalesReturn({
    required this.id,
    required this.returnNo,
    this.creditNoteNo,
    this.returnScope,
    required this.status,
    required this.totalAmount,
  });

  factory SubmittedSalesReturn.fromJson(Map<String, dynamic> json) {
    return SubmittedSalesReturn(
      id: json['id']?.toString() ?? '',
      returnNo: json['returnNo']?.toString() ?? '',
      creditNoteNo: json['creditNoteNo']?.toString(),
      returnScope: json['returnScope']?.toString(),
      status: json['status']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

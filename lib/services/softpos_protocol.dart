/// LAN bridge contract between Filter POS and SoftPOS (demo until bank SDK).
abstract final class SoftPosProtocol {
  static const defaultServerPort = 8787;
  static const defaultCallbackPort = 8788;

  static const statusApproved = 'approved';
  static const statusDeclined = 'declined';
  static const statusCancelled = 'cancelled';
}

class SoftPosPaymentRequest {
  final String requestId;
  final String callbackUrl;
  final double amount;
  final String currency;
  final String orderId;
  final String? orderNo;
  final String? customerName;
  final String? customerMobile;
  final String? plateNo;
  final String? lineSummary;
  final String paymentLabel;
  final String? intentUuid;

  const SoftPosPaymentRequest({
    required this.requestId,
    required this.callbackUrl,
    required this.amount,
    this.currency = 'SAR',
    required this.orderId,
    this.orderNo,
    this.customerName,
    this.customerMobile,
    this.plateNo,
    this.lineSummary,
    this.paymentLabel = 'Tap to Pay',
    this.intentUuid,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'callbackUrl': callbackUrl,
        'amount': amount,
        'currency': currency,
        'orderId': orderId,
        if (orderNo != null) 'orderNo': orderNo,
        if (customerName != null) 'customerName': customerName,
        if (customerMobile != null) 'customerMobile': customerMobile,
        if (plateNo != null) 'plateNo': plateNo,
        if (lineSummary != null) 'lineSummary': lineSummary,
        'paymentLabel': paymentLabel,
        if (intentUuid != null && intentUuid!.isNotEmpty)
          'intentUuid': intentUuid,
      };
}

class SoftPosPaymentResult {
  final String requestId;
  final String status;
  final double amount;
  final String? authCode;
  final String? message;
  final String? processedAt;

  const SoftPosPaymentResult({
    required this.requestId,
    required this.status,
    required this.amount,
    this.authCode,
    this.message,
    this.processedAt,
  });

  bool get approved => status == SoftPosProtocol.statusApproved;

  bool get cancelled => status == SoftPosProtocol.statusCancelled;

  factory SoftPosPaymentResult.fromJson(Map<String, dynamic> json) {
    return SoftPosPaymentResult(
      requestId: json['requestId']?.toString() ?? '',
      status: json['status']?.toString() ?? SoftPosProtocol.statusDeclined,
      amount: (json['amount'] ?? 0).toDouble(),
      authCode: json['authCode']?.toString(),
      message: json['message']?.toString(),
      processedAt: json['processedAt']?.toString(),
    );
  }
}

/// SoftPOS payment bridge contract (backend Socket.IO).
abstract final class SoftPosProtocol {
  static const defaultServerPort = 8787;
  static const defaultCallbackPort = 8788;

  /// Sentinel callback — SoftPOS reports results to the backend, not LAN.
  static const socketCallbackUrl = 'socket://backend';

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
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleVin;
  final int? mileage;
  final int? nextOilChangeKm;
  final String? customerType;
  final String? customerTaxId;
  final String? lineSummary;
  final List<Map<String, dynamic>> lineItems;
  final double? totalBeforeDiscount;
  final double? totalDiscount;
  final double? vatAmount;
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
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleVin,
    this.mileage,
    this.nextOilChangeKm,
    this.customerType,
    this.customerTaxId,
    this.lineSummary,
    this.lineItems = const [],
    this.totalBeforeDiscount,
    this.totalDiscount,
    this.vatAmount,
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
        if (vehicleMake != null) 'vehicleMake': vehicleMake,
        if (vehicleModel != null) 'vehicleModel': vehicleModel,
        if (vehicleVin != null) 'vehicleVin': vehicleVin,
        if (mileage != null) 'mileage': mileage,
        if (nextOilChangeKm != null) 'nextOilChangeKm': nextOilChangeKm,
        if (customerType != null) 'customerType': customerType,
        if (customerTaxId != null) 'customerTaxId': customerTaxId,
        if (lineSummary != null) 'lineSummary': lineSummary,
        if (lineItems.isNotEmpty) 'lineItems': lineItems,
        if (totalBeforeDiscount != null)
          'totalBeforeDiscount': totalBeforeDiscount,
        if (totalDiscount != null) 'totalDiscount': totalDiscount,
        if (vatAmount != null) 'vatAmount': vatAmount,
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

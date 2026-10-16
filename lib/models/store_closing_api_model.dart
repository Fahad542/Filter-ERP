class StoreClosingApiResponse {
  final bool success;
  final String date;
  final String workshopId;
  final String branchId;
  final int totalInvoices;
  final double totalAmount;
  final double cashAmount;
  final double bankAmount;
  final double corporateAmount;

  StoreClosingApiResponse({
    required this.success,
    required this.date,
    required this.workshopId,
    required this.branchId,
    required this.totalInvoices,
    required this.totalAmount,
    required this.cashAmount,
    required this.bankAmount,
    required this.corporateAmount,
  });

  factory StoreClosingApiResponse.fromJson(Map<String, dynamic> json) {
    return StoreClosingApiResponse(
      success: json['success'] ?? false,
      date: json['date'] ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      totalInvoices: json['totalInvoices'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      cashAmount: (json['cashAmount'] ?? 0).toDouble(),
      bankAmount: (json['bankAmount'] ?? 0).toDouble(),
      corporateAmount: (json['corporateAmount'] ?? 0).toDouble(),
    );
  }
}

class WalletBalanceResponse {
  final bool success;
  final double balance;
  final String currency;
  final String? walletId;
  final String? status;
  final double lowBalanceThreshold;
  final bool isLowBalance;
  final bool requestFundRecommended;
  final String message;

  WalletBalanceResponse({
    required this.success,
    required this.balance,
    required this.currency,
    this.walletId,
    this.status,
    this.lowBalanceThreshold = 100.0,
    this.isLowBalance = false,
    this.requestFundRecommended = false,
    this.message = '',
  });

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    bool isSuccess = false;
    if (json['success'] is bool) {
      isSuccess = json['success'];
    } else if (json['success'] is String) {
      isSuccess = json['success'].toString().toLowerCase() == 'true';
    }
    // Some wallet APIs don't return success explicitly.
    if (!isSuccess && json.containsKey('balance')) {
      isSuccess = true;
    }

    return WalletBalanceResponse(
      success: isSuccess,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'SAR',
      walletId: json['walletId']?.toString(),
      status: json['status'],
      lowBalanceThreshold:
          double.tryParse(json['lowBalanceThreshold']?.toString() ?? '100') ??
          100.0,
      isLowBalance: json['isLowBalance'] == true,
      requestFundRecommended: json['requestFundRecommended'] == true,
      message: json['message'] ?? '',
    );
  }
}

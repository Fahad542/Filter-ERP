class CashierCompleteJobResponse {
  final bool success;
  final String message;
  final Commission? commission;

  CashierCompleteJobResponse({
    required this.success,
    required this.message,
    this.commission,
  });

  factory CashierCompleteJobResponse.fromJson(Map<String, dynamic> json) {
    return CashierCompleteJobResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      commission: json['commission'] != null
          ? Commission.fromJson(json['commission'])
          : null,
    );
  }
}

class CashierJobReadyResponse {
  final bool success;
  final bool isReady;
  final String message;
  final CashierReadyJob? job;

  CashierJobReadyResponse({
    required this.success,
    required this.isReady,
    required this.message,
    this.job,
  });

  factory CashierJobReadyResponse.fromJson(Map<String, dynamic> json) {
    return CashierJobReadyResponse(
      success: json['success'] == true,
      isReady: json['isReady'] == true,
      message: json['message']?.toString() ?? '',
      job: json['job'] is Map<String, dynamic>
          ? CashierReadyJob.fromJson(json['job'])
          : null,
    );
  }
}

class CashierReadyJob {
  final String id;
  final String departmentName;
  final int itemsCount;

  CashierReadyJob({
    required this.id,
    required this.departmentName,
    required this.itemsCount,
  });

  factory CashierReadyJob.fromJson(Map<String, dynamic> json) {
    return CashierReadyJob(
      id: json['id']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Commission {
  final String technicianId;
  final String technicianName;
  final double commissionAmount;

  Commission({
    required this.technicianId,
    required this.technicianName,
    required this.commissionAmount,
  });

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      technicianId: json['technicianId']?.toString() ?? '',
      technicianName: json['technicianName'] ?? '',
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

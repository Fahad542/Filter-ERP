class TechnicianSalaryPaymentsResponse {
  const TechnicianSalaryPaymentsResponse({
    required this.success,
    required this.total,
    required this.totalNetPaid,
    required this.limit,
    required this.offset,
    required this.payments,
  });

  final bool success;
  final int total;
  final double totalNetPaid;
  final int limit;
  final int offset;
  final List<TechSalaryPayment> payments;

  factory TechnicianSalaryPaymentsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['payments'] ?? json['list'] ?? json['items'];
    final list = <TechSalaryPayment>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(TechSalaryPayment.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return TechnicianSalaryPaymentsResponse(
      success: json['success'] == true,
      total: _asInt(json['total'], list.length),
      totalNetPaid: _asDouble(json['totalNetPaid']),
      limit: _asInt(json['limit'], 50),
      offset: _asInt(json['offset'], 0),
      payments: list,
    );
  }
}

class TechSalaryPayment {
  const TechSalaryPayment({
    required this.id,
    required this.period,
    this.paymentDate,
    this.basicSalary = 0,
    this.commissionAmount = 0,
    this.advanceDeduction = 0,
    this.penalties = 0,
    this.penaltyNotes,
    this.totalDeductions = 0,
    this.grossSalary = 0,
    this.netSalary = 0,
    this.payFromAccountName,
    this.method,
    this.status,
    this.technicianAckStatus = 'pending',
    this.technicianAckAt,
    this.notes,
    this.journalId,
    this.createdAt,
  });

  final String id;
  final String period;
  final DateTime? paymentDate;
  final double basicSalary;
  final double commissionAmount;
  final double advanceDeduction;
  final double penalties;
  final String? penaltyNotes;
  final double totalDeductions;
  final double grossSalary;
  final double netSalary;
  final String? payFromAccountName;
  final String? method;
  final String? status;
  final String technicianAckStatus;
  final DateTime? technicianAckAt;
  final String? notes;
  final String? journalId;
  final DateTime? createdAt;

  /// e.g. `2026-06` → `June 2026`
  String get periodLabel {
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(period.trim());
    if (m == null) return period;
    final year = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    if (year == null || month == null || month < 1 || month > 12) {
      return period;
    }
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month - 1]} $year';
  }

  bool get isPaid => (status ?? 'paid').toLowerCase() == 'paid';

  bool get isAckPending => technicianAckStatus.toLowerCase() == 'pending';

  bool get isAckAccepted => technicianAckStatus.toLowerCase() == 'accepted';

  bool get isAckRejected => technicianAckStatus.toLowerCase() == 'rejected';

  String get ackStatusLabel {
    switch (technicianAckStatus.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  factory TechSalaryPayment.fromJson(Map<String, dynamic> json) {
    return TechSalaryPayment(
      id: json['id']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
      paymentDate: _parseDate(json['paymentDate'] ?? json['payment_date']),
      basicSalary: _asDouble(json['basicSalary']),
      commissionAmount: _asDouble(json['commissionAmount']),
      advanceDeduction: _asDouble(json['advanceDeduction']),
      penalties: _asDouble(json['penalties']),
      penaltyNotes: json['penaltyNotes']?.toString(),
      totalDeductions: _asDouble(json['totalDeductions']),
      grossSalary: _asDouble(json['grossSalary']),
      netSalary: _asDouble(json['netSalary']),
      payFromAccountName: json['payFromAccountName']?.toString(),
      method: json['method']?.toString(),
      status: json['status']?.toString(),
      technicianAckStatus:
          json['technicianAckStatus']?.toString() ?? 'pending',
      technicianAckAt: _parseDate(
        json['technicianAckAt'] ?? json['technician_ack_at'],
      ),
      notes: json['notes']?.toString(),
      journalId: json['journalId']?.toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

class TechnicianSalaryAdvancesResponse {
  const TechnicianSalaryAdvancesResponse({
    required this.success,
    required this.total,
    required this.totalOutstanding,
    required this.totalIssued,
    required this.totalDeducted,
    required this.limit,
    required this.offset,
    required this.transactions,
    required this.advances,
  });

  final bool success;
  final int total;
  final double totalOutstanding;
  final double totalIssued;
  final double totalDeducted;
  final int limit;
  final int offset;
  final List<TechAdvanceTransaction> transactions;
  final List<TechSalaryAdvance> advances;

  factory TechnicianSalaryAdvancesResponse.fromJson(Map<String, dynamic> json) {
    final txRaw = json['transactions'];
    final transactions = <TechAdvanceTransaction>[];
    if (txRaw is List) {
      for (final e in txRaw) {
        if (e is Map) {
          transactions.add(
            TechAdvanceTransaction.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    final raw = json['advances'] ?? json['list'] ?? json['items'];
    final advances = <TechSalaryAdvance>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          advances.add(TechSalaryAdvance.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    // Backward compat: if API only returns advances, map them to +issued lines.
    if (transactions.isEmpty && advances.isNotEmpty) {
      for (final a in advances) {
        transactions.add(
          TechAdvanceTransaction(
            id: 'issued-${a.id}',
            type: 'issued',
            amount: a.amount,
            signedAmount: a.amount,
            date: a.date,
            description: a.reason?.trim().isNotEmpty == true
                ? a.reason!.trim()
                : a.sourceLabel,
            source: a.source,
            payFromAccountName: a.payFromAccountName,
            period: null,
            status: a.status,
          ),
        );
      }
    }

    final totalIssued = _asDouble(
      json['totalIssued'],
      fallback: transactions
          .where((t) => t.isIssued)
          .fold<double>(0, (s, t) => s + t.amount),
    );
    final totalDeducted = _asDouble(
      json['totalDeducted'],
      fallback: transactions
          .where((t) => t.isDeducted)
          .fold<double>(0, (s, t) => s + t.amount),
    );

    return TechnicianSalaryAdvancesResponse(
      success: json['success'] == true,
      total: _asInt(json['total'], transactions.length),
      totalOutstanding: _asDouble(json['totalOutstanding']),
      totalIssued: totalIssued,
      totalDeducted: totalDeducted,
      limit: _asInt(json['limit'], 50),
      offset: _asInt(json['offset'], 0),
      transactions: transactions,
      advances: advances,
    );
  }
}

/// One ledger line on the technician Advances tab (+ issued / − deducted).
class TechAdvanceTransaction {
  const TechAdvanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.signedAmount,
    this.date,
    this.description,
    this.source,
    this.payFromAccountName,
    this.period,
    this.status,
  });

  final String id;
  /// `issued` (plus) or `deducted` (minus).
  final String type;
  final double amount;
  final double signedAmount;
  final DateTime? date;
  final String? description;
  final String? source;
  final String? payFromAccountName;
  final String? period;
  final String? status;

  bool get isIssued => type.toLowerCase() == 'issued';

  bool get isDeducted => type.toLowerCase() == 'deducted';

  String get title {
    if (isDeducted) {
      if (period?.trim().isNotEmpty == true) {
        return 'Salary deduction · ${period!.trim()}';
      }
      return 'Salary deduction';
    }
    if ((source ?? '').toLowerCase() == 'petty_cash') return 'Petty cash advance';
    final name = payFromAccountName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Salary advance';
  }

  factory TechAdvanceTransaction.fromJson(Map<String, dynamic> json) {
    final type = (json['type']?.toString() ?? 'issued').toLowerCase();
    final amount = _asDouble(json['amount']);
    final signed = json['signedAmount'] != null
        ? _asDouble(json['signedAmount'])
        : (type == 'deducted' ? -amount : amount);
    return TechAdvanceTransaction(
      id: json['id']?.toString() ?? '',
      type: type,
      amount: amount,
      signedAmount: signed,
      date: _parseDate(json['date']),
      description: json['description']?.toString() ?? json['reason']?.toString(),
      source: json['source']?.toString(),
      payFromAccountName: json['payFromAccountName']?.toString(),
      period: json['period']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class TechSalaryAdvance {
  const TechSalaryAdvance({
    required this.id,
    required this.amount,
    required this.balance,
    required this.repaidAmount,
    this.date,
    this.reason,
    this.status,
    this.payFromAccountName,
    this.source,
    this.createdAt,
  });

  final String id;
  final double amount;
  final double balance;
  final double repaidAmount;
  final DateTime? date;
  final String? reason;
  final String? status;
  final String? payFromAccountName;
  final String? source;
  final DateTime? createdAt;

  bool get isFullyRepaid => balance <= 0.01;

  bool get isPettyCash => (source ?? '').toLowerCase() == 'petty_cash';

  String get sourceLabel {
    if (isPettyCash) return 'Petty cash';
    final name = payFromAccountName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Cash / Bank';
  }

  factory TechSalaryAdvance.fromJson(Map<String, dynamic> json) {
    return TechSalaryAdvance(
      id: json['id']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      balance: _asDouble(json['balance']),
      repaidAmount: _asDouble(json['repaidAmount']),
      date: _parseDate(json['date']),
      reason: json['reason']?.toString(),
      status: json['status']?.toString(),
      payFromAccountName: json['payFromAccountName']?.toString(),
      source: json['source']?.toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

double _asDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

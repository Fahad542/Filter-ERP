enum PettyCashStatus {
  pending,
  approved,
  rejected
}

class PettyCashExpense {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String? receiptPath;
  final DateTime date;
  final PettyCashStatus status;

  PettyCashExpense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    this.receiptPath,
    required this.date,
    this.status = PettyCashStatus.pending,
  });
}

class FundRequest {
  final String id;
  final double amount;
  final String reason;
  final DateTime date;
  final PettyCashStatus status;

  FundRequest({
    required this.id,
    required this.amount,
    required this.reason,
    required this.date,
    this.status = PettyCashStatus.pending,
  });
}

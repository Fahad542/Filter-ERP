class SoftPosAdjustmentRow {
  final String orderId;
  final String status;
  final String plate;
  final String customerName;
  final double paidAmount;
  final double orderTotal;
  final double difference;
  final String? invoiceNo;
  /// SoftPOS prepaid timestamp (ISO) from API `prepaidAt`.
  final String? prepaidAt;
  /// When the order was placed (ISO) from API `orderCreatedAt`.
  final String? orderCreatedAt;
  /// When the invoice was generated (ISO) from API `invoiceIssuedAt`.
  final String? invoiceIssuedAt;

  const SoftPosAdjustmentRow({
    required this.orderId,
    required this.status,
    required this.plate,
    required this.customerName,
    required this.paidAmount,
    required this.orderTotal,
    required this.difference,
    this.invoiceNo,
    this.prepaidAt,
    this.orderCreatedAt,
    this.invoiceIssuedAt,
  });

  factory SoftPosAdjustmentRow.fromJson(Map<String, dynamic> json) {
    return SoftPosAdjustmentRow(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      plate: json['plate']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      paidAmount: double.tryParse(json['paidAmount']?.toString() ?? '0') ?? 0,
      orderTotal: double.tryParse(json['orderTotal']?.toString() ?? '0') ?? 0,
      difference: double.tryParse(json['difference']?.toString() ?? '0') ?? 0,
      invoiceNo: json['invoiceNo']?.toString(),
      prepaidAt: json['prepaidAt']?.toString(),
      orderCreatedAt: json['orderCreatedAt']?.toString(),
      invoiceIssuedAt: json['invoiceIssuedAt']?.toString(),
    );
  }

  static DateTime? _parseIso(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  DateTime? get prepaidAtDate => _parseIso(prepaidAt);
  DateTime? get orderCreatedAtDate => _parseIso(orderCreatedAt);
  DateTime? get invoiceIssuedAtDate => _parseIso(invoiceIssuedAt);
}

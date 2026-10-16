class CashierCashCollectionItem {
  const CashierCashCollectionItem({
    required this.id,
    required this.referenceCode,
    required this.status,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.balance,
    this.officerName,
    this.collectedAt,
    this.createdAt,
    this.closedAt,
  });

  final String id;
  final String referenceCode;
  final String status;
  final double expectedAmount;
  final double collectedAmount;
  final double balance;
  final String? officerName;
  final DateTime? collectedAt;
  final DateTime? createdAt;
  final DateTime? closedAt;

  bool get isCollected => status.toLowerCase() == 'collected';
  bool get isPending => !isCollected;

  factory CashierCashCollectionItem.fromJson(Map<String, dynamic> json) {
    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    return CashierCashCollectionItem(
      id: json['id']?.toString() ?? '',
      referenceCode: json['referenceCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      expectedAmount: n(json['expectedAmount']),
      collectedAmount: n(json['collectedAmount']),
      balance: n(json['balance']),
      officerName: json['officerName']?.toString(),
      collectedAt: parseDt(json['collectedAt']),
      createdAt: parseDt(json['createdAt']),
      closedAt: parseDt(json['closedAt']),
    );
  }
}

class CashierCashCollectionResponse {
  const CashierCashCollectionResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    this.totalExpected = 0,
    this.totalCollected = 0,
    this.balance = 0,
  });

  final List<CashierCashCollectionItem> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final double totalExpected;
  final double totalCollected;
  final double balance;

  factory CashierCashCollectionResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (e) => CashierCashCollectionItem.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <CashierCashCollectionItem>[];

    final pagination = json['pagination'];
    final p = pagination is Map
        ? Map<String, dynamic>.from(pagination)
        : <String, dynamic>{};

    int i(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return CashierCashCollectionResponse(
      items: items,
      page: i(p['page'], 1),
      pageSize: i(p['pageSize'], 20),
      total: i(p['total']),
      totalPages: i(p['totalPages'], 1),
      totalExpected: n(json['totalExpected']),
      totalCollected: n(json['totalCollected']),
      balance: n(json['balance']),
    );
  }
}

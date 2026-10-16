class CommissionHistoryResponse {
  final bool success;
  final int month;
  final int year;
  final int total;
  final double totalCommission;
  final int limit;
  final int offset;
  /// Workshop/business IANA zone for calendar semantics (same as server `displayYmd`).
  final String? businessTimeZone;
  final List<CommissionEntry> entries;

  CommissionHistoryResponse({
    required this.success,
    required this.month,
    required this.year,
    required this.total,
    required this.totalCommission,
    required this.limit,
    required this.offset,
    this.businessTimeZone,
    required this.entries,
  });

  factory CommissionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CommissionHistoryResponse(
      success: json['success'] ?? false,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      total: json['total'] ?? 0,
      totalCommission: (json['totalCommission'] ?? 0.0).toDouble(),
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
      businessTimeZone: json['businessTimeZone']?.toString() ??
          json['business_time_zone']?.toString(),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => CommissionEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class CommissionEntry {
  final String orderId;
  final double commission;
  final String date;
  final String status;
  final String? invoiceId;
  final String? paidAt;
  /// Parsed from API; may be null after hot reload or if server omits it (use [displayYmd] getter).
  final String? _displayYmd;

  CommissionEntry({
    required this.orderId,
    required this.commission,
    required this.date,
    required this.status,
    this.invoiceId,
    this.paidAt,
    String? displayYmd,
  }) : _displayYmd = displayYmd;

  /// Single calendar key for range + list: paid → invoice day; pending → completion day in workshop zone.
  /// Never null (empty string if nothing could be derived).
  String get displayYmd {
    final raw = _displayYmd?.trim();
    if (raw != null &&
        raw.length >= 10 &&
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
      return raw.substring(0, 10);
    }
    final src = isPaid
        ? (paidAt?.trim().isNotEmpty == true ? paidAt!.trim() : date.trim())
        : date.trim();
    return _normalizeIsoDatePrefix(src) ?? '';
  }

  bool get isPaid => status.toLowerCase() == 'paid';

  /// Completion instant for list display (matches Assigned Orders).
  String get displayDate => date;

  static String? _normalizeIsoDatePrefix(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.length < 10) return null;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t)) return null;
    return t.substring(0, 10);
  }

  static String _deriveDisplayYmd(Map<String, dynamic> json) {
    final direct = _normalizeIsoDatePrefix(
      json['displayYmd']?.toString() ?? json['display_ymd']?.toString(),
    );
    if (direct != null) return direct;

    final status = (json['status'] ?? '').toString().toLowerCase();
    final paid = status == 'paid';
    if (paid) {
      return _normalizeIsoDatePrefix(
            json['invoiceDate']?.toString() ??
                json['invoice_date']?.toString() ??
                json['paidAt']?.toString() ??
                json['paid_at']?.toString() ??
                json['date']?.toString(),
          ) ??
          '';
    }
    return _normalizeIsoDatePrefix(
          json['dateYmd']?.toString() ??
              json['date_ymd']?.toString() ??
              json['date']?.toString(),
        ) ??
        '';
  }

  factory CommissionEntry.fromJson(Map<String, dynamic> json) {
    final derived = _deriveDisplayYmd(json);
    return CommissionEntry(
      orderId: 'ORD-${json['orderId']?.toString().replaceAll(RegExp(r'^ORD-'), '') ?? ''}',
      commission: (json['commission'] ?? 0.0).toDouble(),
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      invoiceId: json['invoiceId']?.toString(),
      paidAt: json['paidAt']?.toString(),
      displayYmd: derived.isEmpty ? null : derived,
    );
  }
}

/// One calendar day within a selected month (for commission timeline chart).
class MonthlyCommissionDay {
  final int day;
  final double amount;

  const MonthlyCommissionDay({required this.day, required this.amount});
}

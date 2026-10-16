class CashierActiveBroadcastsResponse {
  const CashierActiveBroadcastsResponse({
    required this.success,
    required this.windowSeconds,
    required this.soonThresholdSeconds,
    required this.activeCount,
    required this.broadcasts,
  });

  final bool success;
  final int windowSeconds;
  final int soonThresholdSeconds;
  final int activeCount;
  final List<CashierActiveBroadcastItem> broadcasts;

  factory CashierActiveBroadcastsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['broadcasts'];
    final list = <CashierActiveBroadcastItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CashierActiveBroadcastItem.fromJson(e));
        } else if (e is Map) {
          list.add(CashierActiveBroadcastItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return CashierActiveBroadcastsResponse(
      success: json['success'] == true,
      windowSeconds: _asInt(json['windowSeconds'], 300),
      soonThresholdSeconds: _asInt(json['soonThresholdSeconds'], 60),
      activeCount: _asInt(json['activeCount'], list.length),
      broadcasts: list,
    );
  }
}

class CashierActiveBroadcastItem {
  const CashierActiveBroadcastItem({
    required this.broadcastId,
    required this.jobId,
    required this.orderId,
    required this.broadcastType,
    required this.title,
    required this.subtitle,
    this.departmentId,
    this.departmentName,
    this.customerName,
    this.vehiclePlate,
    this.vehicleLabel,
    this.broadcastedAt,
    this.expiresAt,
    this.remainingSeconds = 0,
    this.serverIsSoon = false,
  });

  final String broadcastId;
  final String jobId;
  final String orderId;
  final String broadcastType;
  final String title;
  final String subtitle;
  final String? departmentId;
  final String? departmentName;
  final String? customerName;
  final String? vehiclePlate;
  final String? vehicleLabel;
  final DateTime? broadcastedAt;
  final DateTime? expiresAt;
  final int remainingSeconds;
  final bool serverIsSoon;

  /// Heading for cards when [title] is empty (e.g. legacy API shape).
  String get displayTitle {
    final t = title.trim();
    if (t.isNotEmpty) return t;
    final d = departmentName?.trim();
    if (d != null && d.isNotEmpty) return d;
    final s = subtitle.trim();
    if (s.isNotEmpty) return s;
    if (jobId.isNotEmpty) return 'Job #$jobId';
    return 'Broadcast';
  }

  CashierActiveBroadcastItem copyWith({
    DateTime? expiresAt,
    int? remainingSeconds,
  }) {
    return CashierActiveBroadcastItem(
      broadcastId: broadcastId,
      jobId: jobId,
      orderId: orderId,
      broadcastType: broadcastType,
      title: title,
      subtitle: subtitle,
      departmentId: departmentId,
      departmentName: departmentName,
      customerName: customerName,
      vehiclePlate: vehiclePlate,
      vehicleLabel: vehicleLabel,
      broadcastedAt: broadcastedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      serverIsSoon: serverIsSoon,
    );
  }

  factory CashierActiveBroadcastItem.fromJson(Map<String, dynamic> json) {
    return CashierActiveBroadcastItem(
      broadcastId: json['broadcastId']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      broadcastType: json['broadcastType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      customerName: json['customerName']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      vehicleLabel: json['vehicleLabel']?.toString(),
      broadcastedAt: _parseDate(json['broadcastedAt']),
      expiresAt: _parseDate(json['expiresAt']),
      remainingSeconds: _asInt(json['remainingSeconds'], 0),
      serverIsSoon: json['isSoon'] == true,
    );
  }
}

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

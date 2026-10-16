/// Active job broadcast offered to a technician (GET /technician/broadcasts).
class TechnicianBroadcastsFetchResult {
  const TechnicianBroadcastsFetchResult({
    required this.broadcasts,
    this.windowSeconds = 300,
    this.soonThresholdSeconds = 60,
    this.activeCount = 0,
  });

  final List<TechBroadcast> broadcasts;
  final int windowSeconds;
  final int soonThresholdSeconds;
  final int activeCount;
}

class TechBroadcast {
  TechBroadcast({
    required this.jobId,
    this.broadcastId,
    this.orderId,
    this.title,
    this.subtitle,
    this.serviceName,
    this.departmentName,
    this.broadcastMode,
    this.expiresAt,
    this.amountLabel,
    this.customerName,
    this.vehiclePlate,
    this.vehicleLabel,
    this.remainingSecondsBootstrap = 0,
    this.serverIsSoon = false,
  });

  final String jobId;
  final String? broadcastId;
  final String? orderId;
  final String? title;
  final String? subtitle;
  final String? serviceName;
  final String? departmentName;
  final String? broadcastMode;
  final DateTime? expiresAt;
  final String? amountLabel;
  final String? customerName;
  final String? vehiclePlate;
  final String? vehicleLabel;
  final int remainingSecondsBootstrap;
  final bool serverIsSoon;

  String get displayTitle {
    final d = departmentName?.trim();
    if (d != null && d.isNotEmpty) return d;
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final s = serviceName?.trim();
    if (s != null && s.isNotEmpty) return s;
    return 'Broadcast · Job';
  }

  String get displaySubtitle {
    final s = subtitle?.trim();
    if (s != null && s.isNotEmpty) return s;
    final parts = <String>[];
    final c = customerName?.trim();
    if (c != null && c.isNotEmpty) parts.add(c);
    final v = vehicleLabel?.trim().isNotEmpty == true
        ? vehicleLabel!.trim()
        : vehiclePlate?.trim();
    if (v != null && v.isNotEmpty) parts.add(v);
    if (parts.isEmpty && orderId != null && orderId!.isNotEmpty) {
      parts.add('Order #$orderId');
    }
    return parts.join(' · ');
  }

  factory TechBroadcast.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    final rawExp = json['expiresAt'] ?? json['expires_at'] ?? json['expiry'];
    if (rawExp != null) {
      try {
        exp = DateTime.tryParse(rawExp.toString())?.toLocal();
      } catch (_) {}
    }

    final rs = _asInt(json['remainingSeconds'], -1);
    if (exp == null && rs >= 0) {
      exp = DateTime.now().add(Duration(seconds: rs));
    }

    final job = json['job'];
    Map<String, dynamic>? jobMap;
    if (job is Map) jobMap = Map<String, dynamic>.from(job);

    String? name = json['serviceName']?.toString() ??
        json['service']?.toString() ??
        jobMap?['serviceName']?.toString() ??
        jobMap?['title']?.toString() ??
        jobMap?['name']?.toString();

    String? mode = json['broadcastType']?.toString() ??
        json['broadcastMode']?.toString() ??
        json['type']?.toString() ??
        jobMap?['broadcastType']?.toString();
    final statusStr = json['status']?.toString();
    if ((mode == null || mode.isEmpty) && statusStr != null) {
      final s = statusStr.toLowerCase();
      if (s.contains('on_call')) {
        mode = 'on_call';
      } else if (s.contains('workshop')) {
        mode = 'workshop';
      }
    }

    String? amt = json['amountLabel']?.toString();
    if (amt == null && json['amount'] != null) {
      amt = 'SAR ${json['amount']}';
    }
    if (amt == null && json['items'] is List) {
      double sum = 0;
      for (final it in json['items'] as List) {
        if (it is Map) {
          final lt = it['lineTotal'] ?? it['line_total'];
          if (lt is num) {
            sum += lt.toDouble();
          } else if (lt != null) {
            sum += double.tryParse(lt.toString()) ?? 0;
          }
        }
      }
      if (sum > 0) {
        amt = sum == sum.roundToDouble() ? 'SAR ${sum.toInt()}' : 'SAR ${sum.toStringAsFixed(2)}';
      }
    }

    final title = json['title']?.toString();
    final subtitle = json['subtitle']?.toString();

    final department = json['department'];
    Map<String, dynamic>? departmentMap;
    if (department is Map) departmentMap = Map<String, dynamic>.from(department);

    final deptFromJob = jobMap?['department'];
    Map<String, dynamic>? jobDeptMap;
    if (deptFromJob is Map) jobDeptMap = Map<String, dynamic>.from(deptFromJob);

    String? departmentName = json['departmentName']?.toString() ??
        departmentMap?['name']?.toString() ??
        jobMap?['departmentName']?.toString() ??
        jobDeptMap?['name']?.toString();

    return TechBroadcast(
      jobId: json['jobId']?.toString() ??
          json['job_id']?.toString() ??
          jobMap?['id']?.toString() ??
          '',
      broadcastId: json['broadcastId']?.toString(),
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      title: title,
      subtitle: subtitle,
      serviceName: name,
      departmentName: departmentName,
      broadcastMode: mode,
      expiresAt: exp,
      amountLabel: amt,
      customerName: json['customerName']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      vehicleLabel: json['vehicleLabel']?.toString(),
      remainingSecondsBootstrap: rs >= 0 ? rs : 0,
      serverIsSoon: json['isSoon'] == true,
    );
  }
}

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

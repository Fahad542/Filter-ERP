class AiOrderBayEvent {
  const AiOrderBayEvent({
    required this.id,
    this.detectedAt,
    this.snapshotUrl,
    this.confidence,
    this.departmentId,
    this.departmentName,
    this.cameraId,
    this.cameraName,
  });

  final String id;
  final DateTime? detectedAt;
  final String? snapshotUrl;
  final double? confidence;
  final String? departmentId;
  final String? departmentName;
  final String? cameraId;
  final String? cameraName;

  factory AiOrderBayEvent.fromJson(Map<String, dynamic> json) {
    final dept = json['department'];
    final cam = json['camera'];
    return AiOrderBayEvent(
      id: json['id']?.toString() ?? '',
      detectedAt: _parseDate(json['detectedAt']),
      snapshotUrl: json['snapshotUrl']?.toString(),
      confidence: _asDouble(json['confidence']),
      departmentId: dept is Map ? dept['id']?.toString() : null,
      departmentName: dept is Map ? dept['name']?.toString() : null,
      cameraId: cam is Map ? cam['id']?.toString() : null,
      cameraName: cam is Map ? cam['name']?.toString() : null,
    );
  }
}

class AiOrderLinkedSalesOrder {
  const AiOrderLinkedSalesOrder({
    required this.id,
    this.status,
    this.source,
    this.createdAt,
    this.customerName,
    this.customerMobile,
    this.plateNo,
    this.invoiceNo,
  });

  final String id;
  final String? status;
  final String? source;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerMobile;
  final String? plateNo;
  final String? invoiceNo;

  factory AiOrderLinkedSalesOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final vehicle = json['vehicle'];
    final invoice = json['invoice'];
    return AiOrderLinkedSalesOrder(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString(),
      source: json['source']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      customerName: customer is Map ? customer['name']?.toString() : null,
      customerMobile: customer is Map ? customer['mobile']?.toString() : null,
      plateNo: vehicle is Map
          ? (vehicle['plateNo'] ?? vehicle['plateNumber'])?.toString()
          : null,
      invoiceNo: invoice is Map ? invoice['invoiceNo']?.toString() : null,
    );
  }
}

class AiOrderCashier {
  const AiOrderCashier({
    required this.id,
    required this.captureNo,
    required this.plateNumber,
    this.plateDisplay,
    this.isCompanyVehicle = false,
    required this.status,
    this.workshopId,
    this.branchId,
    this.branchName,
    this.entranceDetectedAt,
    this.firstServiceBayAt,
    this.confidence,
    this.snapshotUrl,
    this.cashierOrderId,
    this.cashierNotifiedAt,
    this.cashierAcknowledgedAt,
    this.matchedAt,
    this.minutesSinceFirstBay,
    this.unbilledGraceMinutes,
    this.isUnbilledAlert = false,
    this.hasOpenPosOrder = false,
    this.entranceCameraName,
    this.serviceBayEvents = const [],
    this.matchingSalesOrderId,
    this.linkedSalesOrder,
  });

  final String id;
  final String captureNo;
  final String plateNumber;
  final String? plateDisplay;
  final bool isCompanyVehicle;
  final String status;
  final String? workshopId;
  final String? branchId;
  final String? branchName;
  final DateTime? entranceDetectedAt;
  final DateTime? firstServiceBayAt;
  final double? confidence;
  final String? snapshotUrl;
  final String? cashierOrderId;
  final DateTime? cashierNotifiedAt;
  final DateTime? cashierAcknowledgedAt;
  final DateTime? matchedAt;
  final int? minutesSinceFirstBay;
  final int? unbilledGraceMinutes;
  final bool isUnbilledAlert;
  final bool hasOpenPosOrder;
  final String? entranceCameraName;
  final List<AiOrderBayEvent> serviceBayEvents;
  final String? matchingSalesOrderId;
  final AiOrderLinkedSalesOrder? linkedSalesOrder;

  String get displayPlate =>
      (plateDisplay != null && plateDisplay!.trim().isNotEmpty)
          ? plateDisplay!.trim()
          : plateNumber;

  String? get lastBayName {
    if (serviceBayEvents.isEmpty) return null;
    for (var i = serviceBayEvents.length - 1; i >= 0; i--) {
      final n = serviceBayEvents[i].departmentName;
      if (n != null && n.trim().isNotEmpty) return n;
    }
    return null;
  }

  factory AiOrderCashier.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'];
    final entranceCam = json['entranceCamera'];
    final eventsRaw = json['serviceBayEvents'];
    final linked = json['linkedSalesOrder'];
    return AiOrderCashier(
      id: json['id']?.toString() ?? '',
      captureNo: json['captureNo']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      plateDisplay: json['plateDisplay']?.toString(),
      isCompanyVehicle: json['isCompanyVehicle'] == true,
      status: json['status']?.toString() ?? '',
      workshopId: json['workshopId']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: branch is Map ? branch['name']?.toString() : null,
      entranceDetectedAt: _parseDate(json['entranceDetectedAt']),
      firstServiceBayAt: _parseDate(json['firstServiceBayAt']),
      confidence: _asDouble(json['confidence']),
      snapshotUrl: json['snapshotUrl']?.toString(),
      cashierOrderId: json['cashierOrderId']?.toString(),
      cashierNotifiedAt: _parseDate(json['cashierNotifiedAt']),
      cashierAcknowledgedAt: _parseDate(json['cashierAcknowledgedAt']),
      matchedAt: _parseDate(json['matchedAt']),
      minutesSinceFirstBay: _asInt(json['minutesSinceFirstBay']),
      unbilledGraceMinutes: _asInt(json['unbilledGraceMinutes']),
      isUnbilledAlert: json['isUnbilledAlert'] == true,
      hasOpenPosOrder: json['hasOpenPosOrder'] == true,
      entranceCameraName:
          entranceCam is Map ? entranceCam['name']?.toString() : null,
      serviceBayEvents: eventsRaw is List
          ? eventsRaw
              .whereType<Map>()
              .map((e) => AiOrderBayEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      matchingSalesOrderId: json['matchingSalesOrderId']?.toString(),
      linkedSalesOrder: linked is Map
          ? AiOrderLinkedSalesOrder.fromJson(Map<String, dynamic>.from(linked))
          : null,
    );
  }
}

class AiOrdersListResult {
  const AiOrdersListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    this.unbilledGraceMinutes,
  });

  final List<AiOrderCashier> data;
  final int total;
  final int page;
  final int limit;
  final int? unbilledGraceMinutes;

  factory AiOrdersListResult.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => AiOrderCashier.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AiOrderCashier>[];
    return AiOrdersListResult(
      data: list,
      total: _asInt(json['total']) ?? list.length,
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 50,
      unbilledGraceMinutes: _asInt(json['unbilledGraceMinutes']),
    );
  }
}

class AiOrderByPlateResult {
  const AiOrderByPlateResult({
    required this.found,
    this.aiOrder,
    this.matchingSalesOrderId,
  });

  final bool found;
  final AiOrderCashier? aiOrder;
  final String? matchingSalesOrderId;

  factory AiOrderByPlateResult.fromJson(Map<String, dynamic> json) {
    final order = json['aiOrder'];
    return AiOrderByPlateResult(
      found: json['found'] == true,
      aiOrder: order is Map
          ? AiOrderCashier.fromJson(Map<String, dynamic>.from(order))
          : null,
      matchingSalesOrderId: json['matchingSalesOrderId']?.toString(),
    );
  }
}

class OpenPosOrderByPlateItem {
  const OpenPosOrderByPlateItem({
    required this.id,
    this.status,
    this.createdAt,
    this.customerName,
    this.customerMobile,
    this.plateNo,
  });

  final String id;
  final String? status;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerMobile;
  final String? plateNo;

  factory OpenPosOrderByPlateItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final vehicle = json['vehicle'];
    return OpenPosOrderByPlateItem(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      customerName: customer is Map ? customer['name']?.toString() : null,
      customerMobile: customer is Map ? customer['mobile']?.toString() : null,
      plateNo: vehicle is Map
          ? (vehicle['plateNo'] ?? vehicle['plateNumber'])?.toString()
          : null,
    );
  }
}

class OpenPosOrdersByPlateResult {
  const OpenPosOrdersByPlateResult({
    required this.plateNumber,
    required this.found,
    required this.orders,
  });

  final String plateNumber;
  final bool found;
  final List<OpenPosOrderByPlateItem> orders;

  factory OpenPosOrdersByPlateResult.fromJson(Map<String, dynamic> json) {
    final raw = json['orders'];
    return OpenPosOrdersByPlateResult(
      plateNumber: json['plateNumber']?.toString() ?? '',
      found: json['found'] == true,
      orders: raw is List
          ? raw
              .whereType<Map>()
              .map(
                (e) =>
                    OpenPosOrderByPlateItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
    );
  }
}

class AiOrdersSettings {
  const AiOrdersSettings({
    this.unbilledGraceMinutes = 15,
    this.repeatAlertMinutes,
    this.socketEventUnbilled = 'cashier.ai-order.unbilled',
    this.socketEventMatched = 'cashier.ai-order.matched',
    this.notificationType = 'workshop_cashier_ai_vehicle_unbilled',
  });

  final int unbilledGraceMinutes;
  final int? repeatAlertMinutes;
  final String socketEventUnbilled;
  final String socketEventMatched;
  final String notificationType;

  factory AiOrdersSettings.fromJson(Map<String, dynamic> json) {
    return AiOrdersSettings(
      unbilledGraceMinutes: _asInt(json['unbilledGraceMinutes']) ?? 15,
      repeatAlertMinutes: _asInt(json['repeatAlertMinutes']),
      socketEventUnbilled:
          json['socketEventUnbilled']?.toString() ??
          json['socketEvent']?.toString() ??
          'cashier.ai-order.unbilled',
      socketEventMatched:
          json['socketEventMatched']?.toString() ?? 'cashier.ai-order.matched',
      notificationType: json['notificationType']?.toString() ??
          'workshop_cashier_ai_vehicle_unbilled',
    );
  }
}

class AiStaffVehicle {
  const AiStaffVehicle({
    required this.id,
    required this.plateNumber,
    this.staffName,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String plateNumber;
  final String? staffName;
  final String? notes;
  final bool isActive;

  factory AiStaffVehicle.fromJson(Map<String, dynamic> json) {
    return AiStaffVehicle(
      id: json['id']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString() ?? '',
      staffName: json['staffName']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}

class WorkshopNotificationItem {
  const WorkshopNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.entityType,
    this.entityId,
    this.readAt,
    this.createdAt,
    this.isUnread = true,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? entityType;
  final String? entityId;
  final DateTime? readAt;
  final DateTime? createdAt;
  final bool isUnread;

  bool get isAiUnbilled =>
      type == 'workshop_cashier_ai_vehicle_unbilled' ||
      entityType == 'ai_order';

  String? get aiOrderId {
    if (entityType == 'ai_order' && entityId != null && entityId!.isNotEmpty) {
      return entityId;
    }
    return data?['aiOrderId']?.toString();
  }

  WorkshopNotificationItem copyWith({bool? isUnread, DateTime? readAt}) {
    return WorkshopNotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      entityType: entityType,
      entityId: entityId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  factory WorkshopNotificationItem.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return WorkshopNotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: dataRaw is Map
          ? Map<String, dynamic>.from(dataRaw)
          : null,
      entityType: json['entityType']?.toString(),
      entityId: json['entityId']?.toString(),
      readAt: _parseDate(json['readAt']),
      createdAt: _parseDate(json['createdAt']),
      isUnread: json['isUnread'] == true || json['readAt'] == null,
    );
  }
}

class WorkshopNotificationsInboxResult {
  const WorkshopNotificationsInboxResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
  });

  final List<WorkshopNotificationItem> items;
  final int totalCount;
  final int page;
  final int limit;

  factory WorkshopNotificationsInboxResult.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => WorkshopNotificationItem.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <WorkshopNotificationItem>[];
    return WorkshopNotificationsInboxResult(
      items: list,
      totalCount: _asInt(json['totalCount']) ?? list.length,
      page: _asInt(json['page']) ?? 1,
      limit: _asInt(json['limit']) ?? 50,
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

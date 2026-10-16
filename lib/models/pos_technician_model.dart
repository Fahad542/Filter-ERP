class PosTechnicianResponse {
  final bool success;
  final List<PosTechnician> technicians;

  PosTechnicianResponse({required this.success, required this.technicians});

  factory PosTechnicianResponse.fromJson(Map<String, dynamic> json) {
    final technicians =
        (json['technicians'] as List?)
                ?.map((t) => PosTechnician.fromJson(t))
                .toList() ??
            [];
    sortPosTechniciansList(technicians);
    return PosTechnicianResponse(
      success: json['success'] ?? false,
      technicians: technicians,
    );
  }
}

class PosTechnician {
  final String id;
  final String name;
  final String mobile;
  final String employeeType;
  final String technicianType;
  final String commissionPercent;
  final String basicSalary;
  final String workshopId;
  final String branchId;
  final String userId;
  final bool isActive;
  final bool isEligible;
  final List<PosDepartmentInfo> departments;
  final PosTechnicianStatus status;
  final int slotsUsed;
  final int totalSlots;
  /// Cashier API: duty flags (workshop / on-call / both).
  final bool workshopDuty;
  final bool onCallDuty;
  final String? dutyMode;
  /// Cashier API: only [true] when technician may be assigned (typically online).
  final bool assignable;

  /// Cashier API: `'offline' | 'on_call' | 'inactive' | 'active'` (duty + presence).
  final String? assignmentStatus;

  // Compatibility getters
  String get serviceCategory => technicianType;
  String get statusInfo => status.status;
  bool get isOnline {
    final s = status.status.toLowerCase();
    return s == 'online' || s == 'available';
  }

  /// Normalized API status, with fallback when older backends omit [assignmentStatus].
  String get effectiveAssignmentStatus {
    final raw = assignmentStatus?.trim().toLowerCase();
    if (raw != null &&
        raw.isNotEmpty &&
        raw != 'null' &&
        raw != 'undefined') {
      return raw;
    }
    if (!isOnline) return 'offline';
    final dm = dutyMode?.toLowerCase().trim() ?? '';
    if (dm == 'on_call') return 'on_call';
    if (dm == 'inactive') return 'inactive';
    if (onCallDuty && !workshopDuty) return 'on_call';
    if (workshopDuty || dm == 'workshop' || dm == 'both') return 'active';
    return 'inactive';
  }

  String get assignmentStatusDisplayLabel {
    switch (effectiveAssignmentStatus) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Not available';
      case 'on_call':
        return 'On call';
      case 'offline':
        return 'Offline';
      default:
        return 'Unknown';
    }
  }

  /// Workshop POS: assignable row — presence online, [workshopDuty] (workshop / both), floor [active].
  bool get isEligibleWorkshopAssignmentRow =>
      isOnline &&
      workshopDuty &&
      effectiveAssignmentStatus == 'active';

  String get formattedLastSeen {
    if (status.lastSeenAt.isEmpty) return 'Never';
    try {
      final dateTime = DateTime.parse(status.lastSeenAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return status.lastSeenAt.split('T')[0]; // Return YYYY-MM-DD as fallback
    } catch (e) {
      return '';
    }
  }

  PosTechnician({
    required this.id,
    required this.name,
    this.mobile = '',
    this.employeeType = '',
    this.technicianType = '',
    this.commissionPercent = '0',
    this.basicSalary = '0',
    this.workshopId = '',
    this.branchId = '',
    this.userId = '',
    this.isActive = true,
    this.isEligible = true,
    this.departments = const [],
    this.status = const PosTechnicianStatus(status: 'offline', lastSeenAt: ''),
    this.slotsUsed = 0,
    this.totalSlots = 3,
    this.workshopDuty = false,
    this.onCallDuty = false,
    this.dutyMode,
    this.assignable = true,
    this.assignmentStatus,
  });

  PosTechnician copyWith({
    int? slotsUsed,
    int? totalSlots,
    PosTechnicianStatus? status,
    bool? assignable,
    bool? workshopDuty,
    bool? onCallDuty,
    String? dutyMode,
    String? assignmentStatus,
  }) {
    return PosTechnician(
      id: id,
      name: name,
      mobile: mobile,
      employeeType: employeeType,
      technicianType: technicianType,
      commissionPercent: commissionPercent,
      basicSalary: basicSalary,
      workshopId: workshopId,
      branchId: branchId,
      userId: userId,
      isActive: isActive,
      isEligible: isEligible,
      departments: departments,
      status: status ?? this.status,
      slotsUsed: slotsUsed ?? this.slotsUsed,
      totalSlots: totalSlots ?? this.totalSlots,
      workshopDuty: workshopDuty ?? this.workshopDuty,
      onCallDuty: onCallDuty ?? this.onCallDuty,
      dutyMode: dutyMode ?? this.dutyMode,
      assignable: assignable ?? this.assignable,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
    );
  }

  static int _firstInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v == null) continue;
      final n = int.tryParse(v.toString());
      if (n != null) return n;
    }
    return -1;
  }

  static int _parseSlotsUsed(Map<String, dynamic> json) {
    // Cashier API exposes root slotsUsed (same as slots.active); prefer it.
    final rootUsed = json['slotsUsed'];
    if (rootUsed != null) {
      final n = int.tryParse(rootUsed.toString());
      if (n != null) return n;
    }
    final slots = json['slots'];
    if (slots is Map) {
      final m = Map<String, dynamic>.from(slots as Map);
      final n = _firstInt(m, [
        'active',
        'used',
        'inUse',
        'in_use',
        'assigned',
        'current',
        'count',
        'busy',
      ]);
      if (n >= 0) return n;
    }
    for (final key in ['activeSlots', 'assignedJobs', 'activeJobs']) {
      final v = json[key];
      if (v != null) {
        final n = int.tryParse(v.toString());
        if (n != null) return n;
      }
    }
    return 0;
  }

  static int _parseTotalSlots(Map<String, dynamic> json) {
    final rootTotal = json['totalSlots'];
    if (rootTotal != null) {
      final n = int.tryParse(rootTotal.toString());
      if (n != null && n > 0) return n;
    }
    final slots = json['slots'];
    if (slots is Map) {
      final m = Map<String, dynamic>.from(slots as Map);
      final n = _firstInt(m, ['total', 'max', 'capacity', 'limit', 'maxSlots']);
      if (n > 0) return n;
    }
    return 3;
  }

  factory PosTechnician.fromJson(Map<String, dynamic> json) {
    final parsedStatus = PosTechnicianStatus.fromJson(
      (json['technicianStatus'] is Map<String, dynamic>)
          ? json['technicianStatus'] as Map<String, dynamic>
          : (json['status'] is Map<String, dynamic>)
              ? json['status'] as Map<String, dynamic>
              : {
                  'status': json['onlineStatus'] ?? json['status'] ?? 'offline',
                  'lastSeenAt': json['lastSeenAt'] ?? '',
                },
    );
    final online =
        parsedStatus.status.toLowerCase() == 'online' ||
            parsedStatus.status.toLowerCase() == 'available';
    final assignableRaw = json['assignable'];
    final assignable = assignableRaw is bool
        ? assignableRaw
        : (assignableRaw?.toString().toLowerCase() == 'true')
            ? true
            : (assignableRaw?.toString().toLowerCase() == 'false')
                ? false
                : online;

    final dm = json['dutyMode']?.toString().toLowerCase().trim();
    var wd = json['workshopDuty'] == true;
    var oc = json['onCallDuty'] == true;
    if (dm != null && dm.isNotEmpty) {
      if (dm == 'both') {
        wd = true;
        oc = false;
      } else if (dm == 'workshop') {
        wd = true;
        oc = false;
      } else if (dm == 'on_call') {
        wd = false;
        oc = true;
      } else if (dm == 'inactive') {
        wd = false;
        oc = false;
      }
    }

    return PosTechnician(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      employeeType: json['employeeType'] ?? '',
      technicianType: json['technicianType'] ?? '',
      commissionPercent: json['commissionPercent']?.toString() ?? '0',
      basicSalary: json['basicSalary']?.toString() ?? '0',
      workshopId: json['workshopId']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      isActive: json['isActive'] ?? false,
      isEligible: json['isEligible'] ?? true,
      departments:
          (json['departments'] as List?)
              ?.map((d) => PosDepartmentInfo.fromJson(d))
              .toList() ??
          [],
      status: parsedStatus,
      assignable: assignable,
      slotsUsed: _parseSlotsUsed(json),
      totalSlots: _parseTotalSlots(json),
      workshopDuty: wd,
      onCallDuty: oc,
      dutyMode: json['dutyMode']?.toString(),
      assignmentStatus: json['assignmentStatus']?.toString(),
    );
  }
}

class PosDepartmentInfo {
  final String id;
  final String name;

  PosDepartmentInfo({required this.id, required this.name});

  factory PosDepartmentInfo.fromJson(Map<String, dynamic> json) {
    return PosDepartmentInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class PosTechnicianStatus {
  final String status;
  final String lastSeenAt;

  const PosTechnicianStatus({required this.status, required this.lastSeenAt});

  const PosTechnicianStatus.empty() : status = 'offline', lastSeenAt = '';

  factory PosTechnicianStatus.fromJson(Map<String, dynamic> json) {
    return PosTechnicianStatus(
      status:
          json['status']?.toString() ??
          json['onlineStatus']?.toString() ??
          'offline',
      lastSeenAt: json['lastSeenAt'] ?? '',
    );
  }
}

/// Stable cashier technician list order (name, then employee id).
int comparePosTechniciansStable(PosTechnician a, PosTechnician b) {
  final nameCmp = a.name.toLowerCase().trim().compareTo(b.name.toLowerCase().trim());
  if (nameCmp != 0) return nameCmp;
  return a.id.compareTo(b.id);
}

void sortPosTechniciansList(List<PosTechnician> list) {
  if (list.length < 2) return;
  list.sort(comparePosTechniciansStable);
}

import 'pos_order_model.dart';

class AssignTechnicianRequest {
  final List<String> employeeIds;

  AssignTechnicianRequest({required this.employeeIds});

  Map<String, dynamic> toJson() => {
        'employeeIds': employeeIds,
      };
}

class AssignTechnicianResponse {
  final bool success;
  final String message;
  final TechnicianAssignment? assignment;
  /// From `assignments` or `assigned` on POST /cashier/job/:id/assign (for immediate UI).
  final List<JobTechnician> assignedTechnicians;
  /// Echoes replace mode when the server supports `sync: true` on the request body.
  final bool? sync;
  /// Active assignment rows cancelled in this call (0 under add-only or when none removed).
  final int removedCount;

  AssignTechnicianResponse({
    required this.success,
    required this.message,
    this.assignment,
    this.assignedTechnicians = const [],
    this.sync,
    this.removedCount = 0,
  });

  /// POST can return `success: true` with `assigned: []` when the server skips every
  /// id (e.g. invalid ids, or historically when duplicate checks counted cancelled rows).
  /// With **sync/replace** (`sync == true`), trust [success] and [message] even if the
  /// assigned list is empty in edge cases (e.g. roster unchanged wording from API).
  bool isEffectiveAssignFailure(List<String> requestedEmployeeIds) {
    if (!success) return true;
    if (requestedEmployeeIds.isEmpty) return false;
    if (sync == true) return false;
    return assignedTechnicians.isEmpty;
  }

  static List<JobTechnician> _listToJobTechnicians(List<dynamic> raw) {
    final out = <JobTechnician>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(JobTechnician.fromJson(e));
      } else if (e is Map) {
        out.add(JobTechnician.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }

  /// Prefer non-empty `assigned` (delta of new rows). When `assigned` is `[]` (roster unchanged /
  /// sync already applied), the current roster with commission fields is in `assignments`.
  static List<JobTechnician> _parseTechnicianList(Map<String, dynamic> json) {
    final assigned = json['assigned'];
    if (assigned is List && assigned.isNotEmpty) {
      return _listToJobTechnicians(assigned);
    }
    if (json['data'] is Map) {
      final d = Map<String, dynamic>.from(json['data'] as Map);
      final inner = d['assigned'];
      if (inner is List && inner.isNotEmpty) {
        return _listToJobTechnicians(inner);
      }
    }

    dynamic raw = json['assignments'] ?? json['technicians'];
    if (raw == null && json['data'] is Map) {
      final d = Map<String, dynamic>.from(json['data'] as Map);
      raw = d['assignments'] ?? d['technicians'];
    }
    if (raw is! List) return [];
    return _listToJobTechnicians(List<dynamic>.from(raw))
        .where((t) => t.isActiveAssignment)
        .toList();
  }

  factory AssignTechnicianResponse.fromJson(Map<String, dynamic> json) {
    final syncRaw = json['sync'];
    bool? syncParsed;
    if (syncRaw is bool) {
      syncParsed = syncRaw;
    } else if (syncRaw != null) {
      syncParsed = syncRaw.toString().toLowerCase() == 'true';
    }
    final removed = json['removedCount'] ?? json['removed_count'];
    final removedN = removed is num
        ? removed.toInt()
        : int.tryParse(removed?.toString() ?? '') ?? 0;

    return AssignTechnicianResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      assignment: json['assignment'] != null
          ? TechnicianAssignment.fromJson(
              Map<String, dynamic>.from(json['assignment'] as Map),
            )
          : null,
      assignedTechnicians: _parseTechnicianList(json),
      sync: syncParsed,
      removedCount: removedN,
    );
  }
}

class TechnicianAssignment {
  final String id;
  final String jobId;
  final String departmentName;
  final String employeeId;
  final String employeeName;
  final String employeeMobile;
  final String status;
  final String assignedAt;

  TechnicianAssignment({
    required this.id,
    required this.jobId,
    required this.departmentName,
    required this.employeeId,
    required this.employeeName,
    required this.employeeMobile,
    required this.status,
    required this.assignedAt,
  });

  factory TechnicianAssignment.fromJson(Map<String, dynamic> json) {
    return TechnicianAssignment(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      departmentName: json['departmentName'] ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName'] ?? '',
      employeeMobile: json['employeeMobile'] ?? '',
      status: json['status'] ?? '',
      assignedAt: json['assignedAt'] ?? '',
    );
  }
}

class SuperAdminDepartmentsResponse {
  final bool success;
  final List<SuperAdminDepartment> departments;

  SuperAdminDepartmentsResponse({
    required this.success,
    required this.departments,
  });

  factory SuperAdminDepartmentsResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminDepartmentsResponse(
      success: json['success'] ?? false,
      departments: (json['departments'] as List?)
              ?.map((d) => SuperAdminDepartment.fromJson(d))
              .toList() ??
          [],
    );
  }
}

class SuperAdminDepartment {
  final String id;
  final String workshopId;
  final String workshopName;
  final String name;
  final bool isActive;

  SuperAdminDepartment({
    required this.id,
    required this.workshopId,
    required this.workshopName,
    required this.name,
    required this.isActive,
  });

  factory SuperAdminDepartment.fromJson(Map<String, dynamic> json) {
    return SuperAdminDepartment(
      id: json['id']?.toString() ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      workshopName: json['workshopName'] ?? 'Unknown',
      name: json['name'] ?? 'Unnamed Dept',
      isActive: json['isActive'] ?? false,
    );
  }
}

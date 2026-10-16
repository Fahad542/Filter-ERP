class DepartmentResponse {
  final bool success;
  final List<Department> departments;

  DepartmentResponse({required this.success, required this.departments});

  factory DepartmentResponse.fromJson(Map<String, dynamic> json) {
    return DepartmentResponse(
      success: json['success'] ?? false,
      departments: (json['departments'] as List<dynamic>?)
              ?.map((e) => Department.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Department {
  final String id;
  final String name;
  final String workshopId;
  final bool isActive;

  Department({
    required this.id,
    required this.name,
    required this.workshopId,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workshopId': workshopId,
      'isActive': isActive,
    };
  }
}

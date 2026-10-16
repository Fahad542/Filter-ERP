class SuperAdminUsersResponse {
  final bool success;
  final List<SuperAdminUser> users;

  SuperAdminUsersResponse({
    required this.success,
    required this.users,
  });

  factory SuperAdminUsersResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminUsersResponse(
      success: json['success'] ?? false,
      users: (json['users'] as List<dynamic>?)
              ?.map((e) => SuperAdminUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SuperAdminUser {
  final String id;
  final String userType;
  final String name;
  final String email;
  final String mobile;
  final String? workshopId;
  final String? branchId;
  final bool isActive;
  final String createdAt;

  SuperAdminUser({
    required this.id,
    required this.userType,
    required this.name,
    required this.email,
    required this.mobile,
    this.workshopId,
    this.branchId,
    required this.isActive,
    required this.createdAt,
  });

  factory SuperAdminUser.fromJson(Map<String, dynamic> json) {
    return SuperAdminUser(
      id: json['id']?.toString() ?? '',
      userType: json['userType'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      workshopId: json['workshopId']?.toString(),
      branchId: json['branchId']?.toString(),
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

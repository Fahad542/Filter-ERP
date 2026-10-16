class SuperAdminBranchesResponse {
  final bool success;
  final List<SuperAdminBranch> branches;

  SuperAdminBranchesResponse({
    required this.success,
    required this.branches,
  });

  factory SuperAdminBranchesResponse.fromJson(Map<String, dynamic> json) {
    return SuperAdminBranchesResponse(
      success: json['success'] ?? false,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => SuperAdminBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SuperAdminBranch {
  final String id;
  final String workshopId;
  final String workshopName;
  final String name;
  final String? branchCode;
  final String address;
  final String? gpsLat;
  final String? gpsLng;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? vatId;
  final String? crNumber;
  final bool isActive;
  final String status;

  SuperAdminBranch({
    required this.id,
    required this.workshopId,
    required this.workshopName,
    required this.name,
    this.branchCode,
    required this.address,
    this.gpsLat,
    this.gpsLng,
    this.contactPerson,
    this.phone,
    this.email,
    this.vatId,
    this.crNumber,
    required this.isActive,
    required this.status,
  });

  factory SuperAdminBranch.fromJson(Map<String, dynamic> json) {
    return SuperAdminBranch(
      id: json['id']?.toString() ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      workshopName: json['workshopName'] ?? '',
      name: json['name'] ?? '',
      branchCode: json['branchCode'],
      address: json['address'] ?? '',
      gpsLat: json['gpsLat'],
      gpsLng: json['gpsLng'],
      contactPerson: json['contactPerson'],
      phone: json['phone'],
      email: json['email'],
      vatId: json['vatId'],
      crNumber: json['crNumber'],
      isActive: json['isActive'] ?? false,
      status: json['status'] ?? '',
    );
  }
}

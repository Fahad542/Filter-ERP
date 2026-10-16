class AuthResponse {
  final bool? success;
  final String? message;
  final String? token;
  final User? user;

  AuthResponse({this.success, this.message, this.token, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // If workshop or branch are at the root level, inject them into the user object
    final userJson = json['user'] != null ? Map<String, dynamic>.from(json['user']) : null;
    if (userJson != null) {
      if (json['workshop'] != null) userJson['workshop'] = json['workshop'];
      if (json['branch'] != null) userJson['branch'] = json['branch'];
    }

    // Support both 'token' and 'accessToken' field names
    final token = json['token'] ?? json['accessToken'];

    return AuthResponse(
      success: json['success'],
      message: json['message'],
      token: token?.toString(),
      user: userJson != null ? User.fromJson(userJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'user': user?.toJson(),
    };
  }
}

class User {
  final String? id;
  final String? name;
  final String? email;
  final String? userType;
  final String? workshopId;
  final String? branchId;
  final String? workshopName;
  final String? branchName;
  final String? lockerPortalRole;
  final String? workshopStaffRole;
  final Cashier? cashier;
  final TechnicianData? technician;
  final Workshop? workshop;

  User({
    this.id,
    this.name,
    this.email,
    this.userType,
    this.workshopId,
    this.branchId,
    this.workshopName,
    this.branchName,
    this.lockerPortalRole,
    this.workshopStaffRole,
    this.cashier,
    this.technician,
    this.workshop,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle nested Workshop/Branch objects if they exist
    final workshopObj = json['workshop'] is Map ? json['workshop'] : null;
    final branchObj = json['branch'] is Map ? json['branch'] : null;

    return User(
      id: json['id']?.toString(),
      name: json['name'],
      email: json['email'],
      userType: json['userType'],
      workshopId: json['workshopId']?.toString() ?? workshopObj?['id']?.toString(),
      branchId: json['branchId']?.toString() ?? branchObj?['id']?.toString() ?? json['cashier']?['branchId']?.toString(),
      workshopName: json['workshopName'] ?? json['workshop_name'] ?? workshopObj?['name'],
      branchName: json['branchName'] ?? json['branch_name'] ?? branchObj?['name'],
      lockerPortalRole: json['lockerPortalRole']?.toString() ??
          json['locker_portal_role']?.toString(),
      workshopStaffRole: json['workshopStaffRole']?.toString() ??
          json['workshop_staff_role']?.toString(),
      cashier: json['cashier'] != null ? Cashier.fromJson(json['cashier']) : null,
      technician: json['technician'] != null ? TechnicianData.fromJson(json['technician']) : null,
      workshop: json['workshop'] != null ? Workshop.fromJson(json['workshop'] is Map<String, dynamic> ? json['workshop'] : {}) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'workshopId': workshopId,
      'branchId': branchId,
      'workshopName': workshopName,
      'branchName': branchName,
      if (lockerPortalRole != null) 'lockerPortalRole': lockerPortalRole,
      if (workshopStaffRole != null) 'workshopStaffRole': workshopStaffRole,
      'cashier': cashier?.toJson(),
      'technician': technician?.toJson(),
      'workshop': workshop?.toJson(),
    };
  }
}

class Cashier {
  final String? cashierId;
  final String? cashierName;
  final String? branchId;

  Cashier({this.cashierId, this.cashierName, this.branchId});

  factory Cashier.fromJson(Map<String, dynamic> json) {
    return Cashier(
      cashierId: json['cashierId'],
      cashierName: json['cashierName'],
      branchId: json['branchId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashierId': cashierId,
      'cashierName': cashierName,
      'branchId': branchId,
    };
  }
}

class TechnicianData {
  final String? employeeId;
  final String? technicianType;
  /// Persisted from login/profile so cold start matches server before GET profile.
  final String? dutyMode;
  final bool? workshopDuty;
  final bool? onCallDuty;
  final int? commissionPercent;
  final List<Department>? departments;

  TechnicianData({
    this.employeeId,
    this.technicianType,
    this.dutyMode,
    this.workshopDuty,
    this.onCallDuty,
    this.commissionPercent,
    this.departments,
  });

  factory TechnicianData.fromJson(Map<String, dynamic> json) {
    return TechnicianData(
      employeeId: json['employeeId']?.toString(),
      technicianType: json['technicianType']?.toString(),
      dutyMode: json['dutyMode']?.toString(),
      workshopDuty: json['workshopDuty'] is bool ? json['workshopDuty'] as bool : null,
      onCallDuty: json['onCallDuty'] is bool ? json['onCallDuty'] as bool : null,
      commissionPercent: json['commissionPercent'] is int ? json['commissionPercent'] : int.tryParse(json['commissionPercent']?.toString() ?? ''),
      departments: json['departments'] != null
          ? (json['departments'] as List).map((i) => Department.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'technicianType': technicianType,
      if (dutyMode != null) 'dutyMode': dutyMode,
      if (workshopDuty != null) 'workshopDuty': workshopDuty,
      if (onCallDuty != null) 'onCallDuty': onCallDuty,
      'commissionPercent': commissionPercent,
      'departments': departments?.map((e) => e.toJson()).toList(),
    };
  }
}

class Department {
  final String? id;
  final String? name;

  Department({this.id, this.name});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id']?.toString(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Workshop {
  final String? id;
  final String? name;

  Workshop({this.id, this.name});

  factory Workshop.fromJson(Map<String, dynamic> json) {
    return Workshop(
      id: json['id']?.toString(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

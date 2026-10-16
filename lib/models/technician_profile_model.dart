class TechnicianProfileResponse {
  bool? success;
  TechnicianProfile? profile;

  TechnicianProfileResponse({this.success, this.profile});

  TechnicianProfileResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    profile = json['profile'] != null ? TechnicianProfile.fromJson(json['profile']) : null;
  }
}

class TechnicianProfile {
  String? id;
  String? name;
  String? email;
  String? mobile;
  String? employeeId;
  String? technicianType;
  String? dutyMode;
  String? onlineStatus;
  bool? workshopDuty;
  bool? onCallDuty;
  double? commissionPercent;
  List<Department>? departments;
  Workshop? workshop;
  Branch? branch;

  TechnicianProfile({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.employeeId,
    this.technicianType,
    this.dutyMode,
    this.onlineStatus,
    this.workshopDuty,
    this.onCallDuty,
    this.commissionPercent,
    this.departments,
    this.workshop,
    this.branch,
  });

  TechnicianProfile.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name']?.toString() ??
        json['fullName']?.toString() ??
        json['technicianName']?.toString();
    email = json['email'];
    mobile = json['mobile'];
    employeeId = json['employeeId'].toString();
    technicianType = json['technicianType'];
    dutyMode = json['dutyMode'];
    onlineStatus = json['onlineStatus']?.toString() ??
        json['technicianStatus']?['status']?.toString() ??
        json['status']?.toString();
    workshopDuty = json['workshopDuty'];
    onCallDuty = json['onCallDuty'];
    commissionPercent = double.tryParse(json['commissionPercent']?.toString() ?? '0');
    if (json['departments'] != null) {
      departments = <Department>[];
      json['departments'].forEach((v) {
        departments!.add(Department.fromJson(v));
      });
    }
    workshop = json['workshop'] != null ? Workshop.fromJson(json['workshop']) : null;
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
  }
}

class Department {
  String? id;
  String? name;

  Department({this.id, this.name});

  Department.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
  }
}

class Workshop {
  String? id;
  String? name;

  Workshop({this.id, this.name});

  Workshop.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
  }
}

class Branch {
  String? id;
  String? name;

  Branch({this.id, this.name});

  Branch.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
  }
}

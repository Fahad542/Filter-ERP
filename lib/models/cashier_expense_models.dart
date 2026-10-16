/// Branch-level employee row from GET /cashier/employees (or legacy branch-employees alias).
///
/// Typical API: `{ id, name, mobile, employeeType }` (sorted by name).
class BranchEmployee {
  final String id;
  final String name;
  final String? mobile;
  /// e.g. `staff`, `technician`, `cashier`; only when backend sends it.
  final String? employeeType;

  BranchEmployee({
    required this.id,
    required this.name,
    this.mobile,
    this.employeeType,
  });

  factory BranchEmployee.fromJson(Map<String, dynamic> json) {
    final mob = json['mobile'];
    final mobileRaw =
        mob == null || mob.toString().trim().isEmpty ? null : mob.toString().trim();
    final et = json['employeeType'];
    final typeRaw =
        et == null || et.toString().trim().isEmpty ? null : et.toString().trim();
    return BranchEmployee(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? '',
      mobile: mobileRaw,
      employeeType: typeRaw,
    );
  }

  /// Human-readable badge for chips (`staff` → Staff).
  String get employeeTypeDisplay {
    final t = employeeType?.trim();
    if (t == null || t.isEmpty) return '';
    switch (t.toLowerCase()) {
      case 'staff':
        return 'Staff';
      case 'technician':
        return 'Technician';
      case 'cashier':
        return 'Cashier';
      case 'manager':
        return 'Manager';
      case 'supervisor':
        return 'Supervisor';
      case 'team_leader':
        return 'Team leader';
      case 'locker_supervisor':
        return 'Locker supervisor';
      case 'locker_collector':
        return 'Locker collector';
      case 'accounting':
        return 'Accounting';
      default:
        return t
            .split('_')
            .where((p) => p.isNotEmpty)
            .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
            .join(' ');
    }
  }
}

/// Parsed list from `/cashier/employees` or legacy expense branch-employees (flexible shapes).
class BranchEmployeesResponse {
  final bool success;
  final List<BranchEmployee> employees;

  const BranchEmployeesResponse({
    required this.success,
    required this.employees,
  });

  static List<BranchEmployee> _parseList(dynamic raw) {
    if (raw is! List) return [];
    final out = <BranchEmployee>[];
    for (final item in raw) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = m['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        out.add(BranchEmployee.fromJson(m));
      }
    }
    return out;
  }

  factory BranchEmployeesResponse.fromDynamic(dynamic data) {
    if (data is List) {
      return BranchEmployeesResponse(success: true, employees: _parseList(data));
    }
    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['employees'] ?? data['items'] ?? data['results'];
      final employees = _parseList(list is List ? list : const []);
      final ok = data['success'] == true || employees.isNotEmpty;
      return BranchEmployeesResponse(success: ok, employees: employees);
    }
    return const BranchEmployeesResponse(success: false, employees: []);
  }
}

/// Single row from GET /cashier/expense/history.
class CashierExpenseHistoryEntry {
  final String id;
  final String kind; // fund_request | expense
  final String status;
  final String? rejectionReason;
  final String? category;
  final double amount;
  final String? currency;
  final String? proof;
  final String? description;
  final String? employeeName;
  final String? approvedBy;
  final String? approvedByRoleLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CashierExpenseHistoryEntry({
    required this.id,
    required this.kind,
    required this.status,
    this.rejectionReason,
    this.category,
    required this.amount,
    this.currency,
    this.proof,
    this.description,
    this.employeeName,
    this.approvedBy,
    this.approvedByRoleLabel,
    this.createdAt,
    this.updatedAt,
  });

  factory CashierExpenseHistoryEntry.fromJson(Map<String, dynamic> json) {
    String? categoryLabel;
    final cat = json['category'];
    if (cat is Map<String, dynamic>) {
      categoryLabel = cat['name']?.toString() ?? cat['id']?.toString();
    } else if (cat is String) {
      categoryLabel = cat;
    }

    String? employeeName;
    final emp = json['employee'];
    if (emp is Map<String, dynamic>) {
      employeeName = emp['name']?.toString() ?? emp['fullName']?.toString();
    } else {
      employeeName = json['employeeName']?.toString();
    }

    String? approvedBy;
    String? approvedByRoleLabel;
    final ab = json['approvedBy'];
    if (ab is Map) {
      final abMap = Map<String, dynamic>.from(ab);
      final name = abMap['name']?.toString().trim();
      approvedBy = (name != null && name.isNotEmpty) ? name : null;
      final roleRaw =
          abMap['roleLabel']?.toString() ?? abMap['role']?.toString();
      final role = roleRaw?.trim();
      approvedByRoleLabel =
          (role != null && role.isNotEmpty) ? role : null;
    } else if (ab != null) {
      final name = ab.toString().trim();
      approvedBy = name.isNotEmpty ? name : null;
    }

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return CashierExpenseHistoryEntry(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'expense',
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: json['rejectionReason']?.toString(),
      category: categoryLabel,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString(),
      proof: json['proof']?.toString() ?? json['proofUrl']?.toString(),
      description: json['description']?.toString() ?? json['notes']?.toString() ?? json['reason']?.toString(),
      employeeName: employeeName,
      approvedBy: approvedBy,
      approvedByRoleLabel: approvedByRoleLabel,
      createdAt: parseDt(json['createdAt'] ?? json['requestedAt'] ?? json['submittedAt']),
      updatedAt: parseDt(json['updatedAt'] ?? json['approvedAt']),
    );
  }
}

class CashierExpenseHistoryResponse {
  final bool success;
  final List<CashierExpenseHistoryEntry> items;
  final int total;
  final int limit;
  final int offset;
  final CashierExpenseHistoryFilters? filters;
  final String? message;

  const CashierExpenseHistoryResponse({
    required this.success,
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    this.filters,
    this.message,
  });

  factory CashierExpenseHistoryResponse.fromDynamic(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const CashierExpenseHistoryResponse(
        success: false,
        items: [],
        total: 0,
        limit: 20,
        offset: 0,
        filters: null,
      );
    }
    final raw = data['items'] ?? data['data'] ?? data['history'] ?? data['requests'] ?? data['records'];
    final list = <CashierExpenseHistoryEntry>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(
            CashierExpenseHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          );
        }
      }
    }
    return CashierExpenseHistoryResponse(
      success: data['success'] == true || list.isNotEmpty,
      items: list,
      total: int.tryParse(data['total']?.toString() ?? '${list.length}') ?? list.length,
      limit: int.tryParse(data['limit']?.toString() ?? '20') ?? 20,
      offset: int.tryParse(data['offset']?.toString() ?? '0') ?? 0,
      filters: data['filters'] is Map<String, dynamic>
          ? CashierExpenseHistoryFilters.fromJson(
              data['filters'] as Map<String, dynamic>,
            )
          : null,
      message: data['message']?.toString(),
    );
  }
}

class CashierExpenseHistoryFilters {
  final String? status;
  final String? from;
  final String? to;
  final String? categoryId;

  const CashierExpenseHistoryFilters({
    this.status,
    this.from,
    this.to,
    this.categoryId,
  });

  factory CashierExpenseHistoryFilters.fromJson(Map<String, dynamic> json) {
    return CashierExpenseHistoryFilters(
      status: json['status']?.toString(),
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      categoryId: json['categoryId']?.toString(),
    );
  }
}

class ExpenseCategory {
  final String id;
  final String name;
  /// API: true for Salary Advances (also accept name variants client-side).
  final bool requiresEmployee;

  ExpenseCategory({
    required this.id,
    required this.name,
    this.requiresEmployee = false,
  });

  /// True if UI must collect [employeeId] on submit (API + name fallback).
  bool get requiresEmployeeSelection {
    if (requiresEmployee) return true;
    final t = name.trim().toLowerCase();
    return t == 'salary advances' || t == 'salary advance';
  }

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      requiresEmployee: json['requiresEmployee'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ExpenseCategoriesResponse {
  final bool success;
  final List<ExpenseCategory> categories;

  ExpenseCategoriesResponse({
    required this.success,
    required this.categories,
  });

  factory ExpenseCategoriesResponse.fromDynamic(dynamic data) {
    final Map<String, ExpenseCategory> uniqueCategories = {};

    void addFromList(List<dynamic> list) {
      for (final item in list) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item as Map);
          if (m.containsKey('id') && m.containsKey('name')) {
            final cat = ExpenseCategory.fromJson(m);
            uniqueCategories[cat.id] = cat;
          }
        }
      }
    }

    if (data is List) {
      addFromList(data);
      return ExpenseCategoriesResponse(
        success: uniqueCategories.isNotEmpty,
        categories: uniqueCategories.values.toList(),
      );
    }

    final json = (data is Map<String, dynamic>) ? data : <String, dynamic>{};

    if (json['data'] is List) addFromList(json['data'] as List);
    if (json['categories'] is List) addFromList(json['categories'] as List);

    json.forEach((key, value) {
      if (key == 'data' || key == 'categories' || key == 'success') return;
      if (value is Map<String, dynamic> &&
          value.containsKey('id') &&
          value.containsKey('name')) {
        final cat = ExpenseCategory.fromJson(value);
        uniqueCategories[cat.id] = cat;
      }
    });

    bool isSuccess = false;
    if (json['success'] is bool) {
      isSuccess = json['success'];
    } else if (json['success'] is String) {
      isSuccess = json['success'].toString().toLowerCase() == 'true';
    }
    if (!isSuccess && uniqueCategories.isNotEmpty) {
      isSuccess = true;
    }

    return ExpenseCategoriesResponse(
      success: isSuccess,
      categories: uniqueCategories.values.toList(),
    );
  }
}

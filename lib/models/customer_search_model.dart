class CustomerSearchResponse {
  final bool success;
  final String message;
  final List<SearchedCustomer> customers;

  CustomerSearchResponse({
    required this.success,
    required this.message,
    required this.customers,
  });

  factory CustomerSearchResponse.fromJson(Map<String, dynamic> json) {
    return CustomerSearchResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      customers: (json['customers'] as List? ?? [])
          .map((c) => SearchedCustomer.fromJson(c))
          .toList(),
    );
  }
}

class SearchedCustomer {
  final String id;
  final String name;
  final String mobile;
  final String? taxId;
  final String? whatsapp;
  final String customerType;
  final List<SearchedCustomerOrder> orders;

  SearchedCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    this.taxId,
    this.whatsapp,
    required this.customerType,
    required this.orders,
  });

  factory SearchedCustomer.fromJson(Map<String, dynamic> json) {
    return SearchedCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      taxId: json['taxId'],
      whatsapp: json['whatsapp'],
      customerType: json['customerType'] ?? 'regular',
      orders: (json['orders'] as List? ?? [])
          .map((o) => SearchedCustomerOrder.fromJson(o))
          .toList(),
    );
  }

  /// Newest order that still has usable vehicle data (plate/make/model/vin).
  SearchedCustomerOrder? get bestOrderWithVehicle =>
      bestSearchedCustomerOrderWithVehicle(orders);

  /// Vehicle snapshot for POS home / customer-history cards.
  SearchedCustomerVehicle? get vehicleSnapshot => bestOrderWithVehicle?.vehicle;
}

DateTime _searchedCustomerOrderDate(SearchedCustomerOrder order) {
  try {
    return DateTime.parse(order.createdAt);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

bool _searchedCustomerVehicleHasData(SearchedCustomerVehicle? vehicle) {
  if (vehicle == null) return false;
  return vehicle.resolvedPlate.isNotEmpty ||
      vehicle.make.trim().isNotEmpty ||
      vehicle.model.trim().isNotEmpty ||
      (vehicle.vin ?? '').trim().isNotEmpty;
}

SearchedCustomerOrder? bestSearchedCustomerOrderWithVehicle(
  List<SearchedCustomerOrder> orders,
) {
  if (orders.isEmpty) return null;
  final sorted = [...orders]
    ..sort((a, b) => _searchedCustomerOrderDate(b).compareTo(_searchedCustomerOrderDate(a)));
  for (final order in sorted) {
    if (_searchedCustomerVehicleHasData(order.vehicle)) return order;
  }
  return sorted.first;
}

class SearchedCustomerOrder {
  final String id;
  final String status;
  final String source;
  final int odometerReading;
  final String createdAt;
  final SearchedCustomerVehicle? vehicle;
  final String? invoiceNo;
  final String? branchId;
  final String? branchName;
  final String? workshopId;
  final String? workshopName;
  final List<String> technicianNames;

  SearchedCustomerOrder({
    required this.id,
    required this.status,
    required this.source,
    required this.odometerReading,
    required this.createdAt,
    this.vehicle,
    this.invoiceNo,
    this.branchId,
    this.branchName,
    this.workshopId,
    this.workshopName,
    this.technicianNames = const [],
  });

  String get technicianDisplay => technicianNames.join(', ');

  factory SearchedCustomerOrder.fromJson(Map<String, dynamic> json) {
    final invoiceMap = json['invoice'] is Map
        ? Map<String, dynamic>.from(json['invoice'] as Map)
        : null;
    return SearchedCustomerOrder(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? '',
      source: json['source'] ?? '',
      odometerReading: json['odometerReading'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      vehicle: json['vehicle'] != null
          ? SearchedCustomerVehicle.fromJson(json['vehicle'])
          : null,
      invoiceNo:
          json['invoiceNo']?.toString() ??
          json['invoice_no']?.toString() ??
          invoiceMap?['invoiceNo']?.toString() ??
          json['invoiceId']?.toString() ??
          json['invoice_id']?.toString() ??
          invoiceMap?['id']?.toString(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
      workshopId: json['workshopId']?.toString(),
      workshopName: json['workshopName']?.toString(),
      technicianNames: _parseSearchedTechnicianNames(json),
    );
  }
}

List<String> _parseSearchedTechnicianNames(Map<String, dynamic> json) {
  final seen = <String>{};
  void add(String? raw) {
    final name = raw?.trim() ?? '';
    if (name.isNotEmpty) seen.add(name);
  }

  final direct = json['technicianNames'] ?? json['technician_names'];
  if (direct is List) {
    for (final item in direct) {
      add(item?.toString());
    }
  }
  final technicians = json['technicians'];
  if (technicians is List) {
    for (final item in technicians) {
      if (item is Map) {
        add(item['name']?.toString());
      } else {
        add(item?.toString());
      }
    }
  }
  return seen.toList();
}

class SearchedCustomerVehicle {
  final String id;
  final String plateNo;
  final String? plateDisplay;
  final String make;
  final String model;
  final String? year;
  final String? vin;

  SearchedCustomerVehicle({
    required this.id,
    required this.plateNo,
    this.plateDisplay,
    required this.make,
    required this.model,
    this.year,
    this.vin,
  });

  /// Formatted plate from API when present, else compact [plateNo].
  String get resolvedPlate {
    final display = (plateDisplay ?? '').trim();
    if (display.isNotEmpty) return display;
    return plateNo.trim();
  }

  factory SearchedCustomerVehicle.fromJson(Map<String, dynamic> json) {
    String? opt(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return SearchedCustomerVehicle(
      id: json['id']?.toString() ?? '',
      plateNo: json['plateNo']?.toString() ?? '',
      plateDisplay: opt(json['plateDisplay']) ?? opt(json['plate_display']),
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: opt(json['year']),
      vin: opt(json['vin']) ?? opt(json['carNo']),
    );
  }
}

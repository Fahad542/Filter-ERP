class CashierCorporateFleetVehiclesResponse {
  final bool success;
  final List<CashierCorporateFleetVehicle> vehicles;

  CashierCorporateFleetVehiclesResponse({
    required this.success,
    required this.vehicles,
  });

  factory CashierCorporateFleetVehiclesResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CashierCorporateFleetVehiclesResponse(
      success: json['success'] == true,
      vehicles: (json['vehicles'] as List?)
              ?.map(
                (v) => CashierCorporateFleetVehicle.fromJson(
                  v as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }
}

class CashierCorporateFleetVehicle {
  final String id;
  final String plateNo;
  final String? plateDisplay;
  final String? carNo;
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final int odometer;
  final String label;

  CashierCorporateFleetVehicle({
    required this.id,
    required this.plateNo,
    this.plateDisplay,
    this.carNo,
    this.make,
    this.model,
    this.year,
    this.color,
    this.odometer = 0,
    this.label = '',
  });

  factory CashierCorporateFleetVehicle.fromJson(Map<String, dynamic> json) {
    final yearRaw = json['year'];
    int? year;
    if (yearRaw is int) {
      year = yearRaw;
    } else if (yearRaw != null) {
      year = int.tryParse(yearRaw.toString());
    }
    return CashierCorporateFleetVehicle(
      id: json['id']?.toString() ?? '',
      plateNo: json['plateNo']?.toString() ?? '',
      plateDisplay: json['plateDisplay']?.toString(),
      carNo: json['carNo']?.toString(),
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      year: year,
      color: json['color']?.toString(),
      odometer: (json['odometer'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? '',
    );
  }
}

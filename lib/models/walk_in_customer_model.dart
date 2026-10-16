import '../utils/app_formatters.dart';

class WalkInCustomerRequest {
  final String? orderId;
  final String? customerName;
  final String? vatNumber;
  final String? mobile;
  final String? vehicleNumber;
  final String? vehiclePlateCountry;
  final String? vehiclePlateEmirate;
  /// Corporate fleet vehicle selected in POS (skip plate-based duplicate create).
  final String? vehicleId;
  final String? vinNumber;
  final String? make;
  final String? model;
  final int? odometerReading;
  final List<String> departmentIds;
  final List<RequestedProduct>? products;
  final List<RequestedService>? services;
  final String? totalDiscountType;
  final double? totalDiscountValue;
  final String? promoCode;
  final String? promoCodeId;
  final double? amountBeforeDiscount;
  final double? amountAfterDiscount;
  final double? amountAfterPromo;
  final double? vat;
  final double? totalAmount;
  /// When set, request is treated as corporate flow on POST /cashier/walk-in-order.
  final String? corporateAccountId;
  /// Shared walk-in endpoint behavior for corporate flow:
  /// - false / null => keep as `unapproved`
  /// - true => transition to `waiting for corporate approval`
  final bool? sendForApproval;
  /// Payment customer type used by cashier payment draft.
  final bool? isCorporate;
  /// Optional payment draft rows to persist with corporate walk-in approval payload.
  final List<RequestedPayment>? payments;
  /// Per-department (job) discount + promo for corporate approval (matches POS job breakdown).
  final List<RequestedJobPricing>? jobPricing;

  WalkInCustomerRequest({
    this.orderId,
    this.customerName,
    this.vatNumber,
    this.mobile,
    this.vehicleNumber,
    this.vehiclePlateCountry,
    this.vehiclePlateEmirate,
    this.vehicleId,
    this.vinNumber,
    this.make,
    this.model,
    this.odometerReading,
    required this.departmentIds,
    this.products,
    this.services,
    this.totalDiscountType,
    this.totalDiscountValue,
    this.promoCode,
    this.promoCodeId,
    this.amountBeforeDiscount,
    this.amountAfterDiscount,
    this.amountAfterPromo,
    this.vat,
    this.totalAmount,
    this.corporateAccountId,
    this.sendForApproval,
    this.isCorporate,
    this.payments,
    this.jobPricing,
  });

  static void _appendClientClockFields(Map<String, dynamic> data) {
    final now = DateTime.now();
    data['clientSubmittedAt'] = now.toIso8601String();
    data['utcOffsetMinutes'] = now.timeZoneOffset.inMinutes;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'departmentIds': departmentIds,
    };

    final isCorporateSubmit =
        corporateAccountId != null && corporateAccountId!.trim().isNotEmpty;

    if (orderId != null && orderId!.isNotEmpty) data['orderId'] = orderId;

    // Standard POST /cashier/walk-in-order: customerName/mobile optional unless corporate.
    // Corporate submit-for-approval: customerName required (validated in view model); VAT/mobile optional.
    if (isCorporateSubmit) {
      if (customerName != null && customerName!.trim().isNotEmpty) {
        data['customerName'] = customerName!.trim();
      }
      if (vatNumber != null && vatNumber!.trim().isNotEmpty) {
        data['vatNumber'] = vatNumber!.trim();
      }
      if (mobile != null && mobile!.trim().isNotEmpty) {
        data['mobile'] = mobile!.trim();
      }
    } else {
      if (customerName != null && customerName!.trim().isNotEmpty) {
        data['customerName'] = customerName!.trim();
      }
      if (vatNumber != null && vatNumber!.trim().isNotEmpty) {
        data['vatNumber'] = vatNumber!.trim();
      }
      if (mobile != null && mobile!.trim().isNotEmpty) {
        data['mobile'] = mobile!.trim();
      }
    }

    // DTO still requires vehicleNumber on append — send whenever we have a value.
    final reg = parseGccPlate(
      vehicleNumber?.trim(),
      countryCode: vehiclePlateCountry ?? 'SA',
      emirate: vehiclePlateEmirate,
    );
    if (reg.display.isNotEmpty) {
      data['vehicleNumber'] = reg.display;
      data['vehiclePlate'] = reg.toJson();
    }
    if (vinNumber != null && vinNumber!.trim().isNotEmpty) {
      data['vinNumber'] = vinNumber!.trim();
    }
    if (make != null && make!.trim().isNotEmpty) data['make'] = make!.trim();
    if (model != null && model!.trim().isNotEmpty) data['model'] = model!.trim();
    if (odometerReading != null && odometerReading! > 0) {
      data['odometerReading'] = odometerReading;
    }
    if (vehicleId != null && vehicleId!.trim().isNotEmpty) {
      data['vehicleId'] = vehicleId!.trim();
    }

    if (products != null && products!.isNotEmpty) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    if (services != null && services!.isNotEmpty) {
      data['services'] = services!.map((v) => v.toJson()).toList();
    }
    
    if (totalDiscountType != null) data['totalDiscountType'] = totalDiscountType;
    if (totalDiscountValue != null) data['totalDiscountValue'] = totalDiscountValue;
    if (promoCode != null) data['promoCode'] = promoCode;
    if (promoCodeId != null) data['promoCodeId'] = promoCodeId;
    if (amountBeforeDiscount != null) data['amountBeforeDiscount'] = amountBeforeDiscount;
    if (amountAfterDiscount != null) data['amountAfterDiscount'] = amountAfterDiscount;
    if (amountAfterPromo != null) data['amountAfterPromo'] = amountAfterPromo;
    if (vat != null) data['VAT'] = vat;
    if (totalAmount != null) data['TotalAmount'] = totalAmount;
    if (corporateAccountId != null && corporateAccountId!.isNotEmpty) {
      data['corporateAccountId'] = corporateAccountId;
      if (sendForApproval != null) {
        data['sendForApproval'] = sendForApproval;
      }
      if (isCorporate != null) {
        data['isCorporate'] = isCorporate;
      }
      if (payments != null && payments!.isNotEmpty) {
        data['payments'] = payments!.map((p) => p.toJson()).toList();
      }
      if (jobPricing != null && jobPricing!.isNotEmpty) {
        data['jobPricing'] = jobPricing!.map((j) => j.toJson()).toList();
      }
    }

    _appendClientClockFields(data);
    return data;
  }

  /// First walk-in create: vehicle + departments; optional customerName / mobile when set on [WalkInCustomerRequest].
  /// Throws if [vehicleNumber] is missing or [departmentIds] is empty.
  Map<String, dynamic> toShellCreateJson() {
    final reg = parseGccPlate(
      vehicleNumber?.trim(),
      countryCode: vehiclePlateCountry ?? 'SA',
      emirate: vehiclePlateEmirate,
    );
    if (reg.display.isEmpty) {
      throw StateError('vehicleNumber is required for walk-in shell create');
    }
    if (departmentIds.isEmpty) {
      throw StateError('departmentIds is required for walk-in shell create');
    }
    final cn = customerName?.trim() ?? '';
    final mob = mobile?.trim() ?? '';
    final data = <String, dynamic>{
      'vehicleNumber': reg.display,
      'vehiclePlate': reg.toJson(),
      'departmentIds': departmentIds,
      if (cn.isNotEmpty) 'customerName': cn,
      if (mob.isNotEmpty) 'mobile': mob,
      if (vatNumber != null && vatNumber!.trim().isNotEmpty)
        'vatNumber': vatNumber!.trim(),
      if (make != null && make!.trim().isNotEmpty) 'make': make!.trim(),
      if (model != null && model!.trim().isNotEmpty) 'model': model!.trim(),
      if (odometerReading != null && odometerReading! > 0)
        'odometerReading': odometerReading,
      if (vinNumber != null && vinNumber!.trim().isNotEmpty) 'vinNumber': vinNumber!.trim(),
      if (corporateAccountId != null && corporateAccountId!.trim().isNotEmpty)
        'corporateAccountId': corporateAccountId!.trim(),
    };
    _appendClientClockFields(data);
    return data;
  }
}

class RequestedPayment {
  final String method;
  final double amount;

  RequestedPayment({
    required this.method,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'amount': amount,
    };
  }
}

class RequestedJobPricing {
  final String? jobId;
  final String? departmentId;
  final String? totalDiscountType;
  final double? totalDiscountValue;
  final String? promoCode;
  final String? promoCodeId;

  RequestedJobPricing({
    this.jobId,
    this.departmentId,
    this.totalDiscountType,
    this.totalDiscountValue,
    this.promoCode,
    this.promoCodeId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> out = {};
    if (jobId != null && jobId!.trim().isNotEmpty) out['jobId'] = jobId!.trim();
    if (departmentId != null && departmentId!.trim().isNotEmpty) {
      out['departmentId'] = departmentId!.trim();
    }
    if (totalDiscountType != null && totalDiscountType!.trim().isNotEmpty) {
      out['totalDiscountType'] = totalDiscountType!.trim();
    }
    if (totalDiscountValue != null) {
      out['totalDiscountValue'] = totalDiscountValue;
    }
    if (promoCode != null && promoCode!.trim().isNotEmpty) {
      out['promoCode'] = promoCode!.trim();
    }
    if (promoCodeId != null && promoCodeId!.trim().isNotEmpty) {
      out['promoCodeId'] = promoCodeId!.trim();
    }
    return out;
  }
}

class RequestedProduct {
  final String productId;
  final String departmentId;
  final double qty;
  final String? discountType;
  final double? discountValue;
  /// VAT-inclusive unit price shown in POS (corporate quote or catalog).
  final double? unitPrice;

  RequestedProduct({
    required this.productId,
    required this.departmentId,
    required this.qty,
    this.discountType,
    this.discountValue,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'productId': productId,
      'departmentId': departmentId,
      'qty': qty,
    };
    if (discountType != null) data['discountType'] = discountType;
    if (discountValue != null) data['discountValue'] = discountValue;
    if (unitPrice != null && unitPrice! > 0) data['unitPrice'] = unitPrice;
    return data;
  }
}

class RequestedService {
  final String serviceId;
  final String departmentId;
  final double qty;
  final String? discountType;
  final double? discountValue;
  /// Sent when service is price-editable; must be > 0 when provided.
  final double? unitPrice;

  RequestedService({
    required this.serviceId,
    required this.departmentId,
    this.qty = 1.0,
    this.discountType,
    this.discountValue,
    this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'serviceId': serviceId,
      'departmentId': departmentId,
      'qty': qty,
    };
    if (discountType != null) data['discountType'] = discountType;
    if (discountValue != null) data['discountValue'] = discountValue;
    if (unitPrice != null && unitPrice! > 0) data['unitPrice'] = unitPrice;
    return data;
  }
}

class WalkInCustomerResponse {
  final bool success;
  final String message;
  final WalkInOrder? order;

  WalkInCustomerResponse({
    required this.success,
    required this.message,
    this.order,
  });

  factory WalkInCustomerResponse.fromJson(Map<String, dynamic> json) {
    return WalkInCustomerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      order: json['order'] != null ? WalkInOrder.fromJson(json['order']) : null,
    );
  }
}

class WalkInOrder {
  final String id;
  final String? jobId;
  final String status;
  final String source;
  final int odometerReading;
  final WalkInCustomer? customer;
  final WalkInVehicle? vehicle;
  final List<WalkInDepartment> departments;
  final List<dynamic> items;

  WalkInOrder({
    required this.id,
    this.jobId,
    required this.status,
    required this.source,
    required this.odometerReading,
    this.customer,
    this.vehicle,
    required this.departments,
    required this.items,
  });

  factory WalkInOrder.fromJson(Map<String, dynamic> json) {
    return WalkInOrder(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString(),
      status: json['status'] ?? '',
      source: json['source'] ?? '',
      odometerReading: json['odometerReading'] ?? 0,
      customer: json['customer'] != null ? WalkInCustomer.fromJson(json['customer']) : null,
      vehicle: json['vehicle'] != null ? WalkInVehicle.fromJson(json['vehicle']) : null,
      departments: json['departments'] != null
          ? (json['departments'] as List).map((i) => WalkInDepartment.fromJson(i)).toList()
          : [],
      items: json['items'] ?? [],
    );
  }
}

class WalkInDepartment {
  final String? jobId;
  final String? departmentId;
  final String? name;
  final String? status;

  WalkInDepartment({
    this.jobId,
    this.departmentId,
    this.name,
    this.status,
  });

  factory WalkInDepartment.fromJson(Map<String, dynamic> json) {
    return WalkInDepartment(
      jobId: json['jobId']?.toString(),
      departmentId: json['departmentId']?.toString(),
      name: json['name']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class WalkInCustomer {
  final String id;
  final String name;
  final String mobile;
  final String taxId;

  WalkInCustomer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.taxId,
  });

  factory WalkInCustomer.fromJson(Map<String, dynamic> json) {
    return WalkInCustomer(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      taxId: json['taxId'] ?? '',
    );
  }
}

String? _walkInVehicleJsonString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

class WalkInVehicle {
  final String id;
  final String plateNo;
  final String make;
  final String model;
  final String? year;
  final String? color;
  final String? vin;

  WalkInVehicle({
    required this.id,
    required this.plateNo,
    required this.make,
    required this.model,
    this.year,
    this.color,
    this.vin,
  });

  factory WalkInVehicle.fromJson(Map<String, dynamic> json) {
    return WalkInVehicle(
      id: json['id']?.toString() ?? '',
      plateNo: json['plateNo']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: _walkInVehicleJsonString(json['year']),
      color: _walkInVehicleJsonString(json['color']),
      vin: _walkInVehicleJsonString(json['vin']) ??
          _walkInVehicleJsonString(json['carNo']),
    );
  }
}

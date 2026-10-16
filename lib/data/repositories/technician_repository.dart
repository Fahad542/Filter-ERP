import '../network/api_constants.dart';
import '../network/base_api_service.dart';
import '../../models/technician_performance_model.dart';
import '../../models/technician_today_performance_model.dart';
import '../../models/technician_dashboard_kpis_model.dart';
import '../../models/technician_profile_model.dart';
import '../../models/technician_assigned_orders_model.dart';
import '../../models/technician_order_details_model.dart';
import '../../models/technician_advance_model.dart';
import '../../models/technician_commission_history_model.dart';
import '../../models/technician_salary_payment_model.dart';
import '../../models/technician_broadcast_model.dart';

class TechnicianRepository {
  final BaseApiService _apiService = BaseApiService();

  Future<TechnicianPerformance> getDailyPerformance(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.technicianDailyPerformanceEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianPerformance.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianTodayPerformance> getTodayPerformance(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.technicianTodayPerformanceEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianTodayPerformance.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianDashboardKpis> getDashboardKpis(
    String token, {
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async {
    try {
      String query;
      if (month != null && year != null) {
        query =
            '${ApiConstants.technicianDashboardKpisEndpoint}?month=$month&year=$year';
      } else {
        query = _rangeQuery(
          ApiConstants.technicianDashboardKpisEndpoint,
          from,
          to,
        );
      }
      final response = await _apiService.get(
        query,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianDashboardKpis.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianProfileResponse> getTechnicianProfile(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.technicianProfileEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianProfileResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateDutyStatus(String token, String dutyMode) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.technicianDutyStatusEndpoint,
        {'dutyMode': dutyMode},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateOnlineStatus(String token, String status) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.technicianOnlineStatusEndpoint,
        {'status': status},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getOnlineStatus(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.technicianOnlineStatusEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianAssignedOrdersResponse> getAssignedOrders(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final query = _rangeQuery(
        ApiConstants.technicianAssignedOrdersEndpoint,
        from,
        to,
      );
      final response = await _apiService.get(
        query,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianAssignedOrdersResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianOrderDetailsResponse> getOrderDetails(String token, String jobId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.technicianOrderDetailsEndpoint(jobId),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianOrderDetailsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeOrder(String token, String jobId) async {
    try {
      await _apiService.post(
        ApiConstants.technicianCompleteOrderEndpoint(jobId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptOrder(String token, String jobId) async {
    try {
      await _apiService.post(
        ApiConstants.technicianAcceptOrderEndpoint(jobId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrder(String token, String jobId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.technicianCancelOrderEndpoint(jobId),
        {},
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }

  Future<void> startOrder(String token, String jobId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.technicianStartOrderEndpoint(jobId),
        {},
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to start order');
      }
    } catch (e) {
      throw Exception('Error starting order: $e');
    }
  }

  Future<TechnicianBroadcastsFetchResult> getBroadcasts(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.technicianBroadcastsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final map = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      final raw = map['broadcasts'] ?? map['data'] ?? map['items'];
      final list = <TechBroadcast>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map) continue;
          final b = TechBroadcast.fromJson(Map<String, dynamic>.from(e));
          if (b.jobId.isNotEmpty) list.add(b);
        }
      }
      return TechnicianBroadcastsFetchResult(
        broadcasts: list,
        windowSeconds: _parseInt(map['windowSeconds'], 300),
        soonThresholdSeconds: _parseInt(map['soonThresholdSeconds'], 60),
        activeCount: _parseInt(map['activeCount'], list.length),
      );
    } catch (e) {
      rethrow;
    }
  }

  int _parseInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  Future<void> acceptBroadcast(String token, String jobId) async {
    await _apiService.post(
      ApiConstants.technicianBroadcastAcceptEndpoint(jobId),
      {},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  Future<void> rejectBroadcast(String token, String jobId) async {
    await _apiService.post(
      ApiConstants.technicianBroadcastRejectEndpoint(jobId),
      {},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  static String _rangeQuery(
    String endpoint,
    DateTime? from,
    DateTime? to,
  ) {
    final qp = Uri(queryParameters: {
      'from': _commissionQueryDateTime(from ?? DateTime.now()),
      'to': _commissionQueryDateTime(to ?? DateTime.now()),
    });
    return '$endpoint?${qp.query}';
  }

  /// Device-local wall clock + UTC offset so the API filters the same instants shown in the UI.
  static String _commissionQueryDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final totalMinutes = d.timeZoneOffset.inMinutes;
    final sign = totalMinutes >= 0 ? '+' : '-';
    final absMinutes = totalMinutes.abs();
    final oh = absMinutes ~/ 60;
    final om = absMinutes % 60;
    final offsetStr = '$sign${two(oh)}:${two(om)}';
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
        'T${two(d.hour)}:${two(d.minute)}$offsetStr';
  }

  /// Query by inclusive date range (`from` / `to`) or calendar month (`month` / `year`).
  Future<CommissionHistoryResponse> getCommissionHistory(
    String token, {
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async {
    try {
      String query;
      if (month != null && year != null) {
        query =
            '${ApiConstants.technicianCommissionHistoryEndpoint}?month=$month&year=$year';
      } else {
        query = _rangeQuery(
          ApiConstants.technicianCommissionHistoryEndpoint,
          from,
          to,
        );
      }
      final response = await _apiService.get(
        query,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return CommissionHistoryResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianSalaryPaymentsResponse> getSalaryPayments(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _apiService.get(
        _dateOnlyRangeQuery(
          ApiConstants.technicianSalaryPaymentsEndpoint,
          from,
          to,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianSalaryPaymentsResponse.fromJson(
        response is Map ? Map<String, dynamic>.from(response) : {},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TechnicianSalaryAdvancesResponse> getSalaryAdvances(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _apiService.get(
        _dateOnlyRangeQuery(
          ApiConstants.technicianSalaryAdvancesEndpoint,
          from,
          to,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TechnicianSalaryAdvancesResponse.fromJson(
        response is Map ? Map<String, dynamic>.from(response) : {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Calendar-day range (no clock) — backend expands to full inclusive days.
  static String _dateOnlyRangeQuery(
    String endpoint,
    DateTime? from,
    DateTime? to,
  ) {
    String ymd(DateTime d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
    }
    final qp = Uri(queryParameters: {
      'from': ymd(from ?? DateTime.now()),
      'to': ymd(to ?? DateTime.now()),
    });
    return '$endpoint?${qp.query}';
  }

  Future<Map<String, dynamic>> respondToSalaryPayment(
    String token,
    String paymentId,
    String response,
  ) async {
    final result = await _apiService.patch(
      ApiConstants.technicianSalaryPaymentAckEndpoint(paymentId),
      {'response': response},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return result is Map ? Map<String, dynamic>.from(result) : {};
  }
}

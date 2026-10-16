import 'package:flutter/foundation.dart';

import '../../models/cashier_ai_order_model.dart';
import '../../utils/gcc_plate.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

class AiOrdersRepository {
  final BaseApiService _apiService = BaseApiService();

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  Future<AiOrdersListResult> listAiOrders(
    String token, {
    String? status,
    bool unbilledOnly = false,
    bool companyVehiclesOnly = false,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.trim().isNotEmpty) {
      qp['status'] = status.trim();
    }
    if (unbilledOnly) qp['unbilledOnly'] = 'true';
    if (companyVehiclesOnly) qp['companyVehiclesOnly'] = 'true';
    if (search != null && search.trim().isNotEmpty) {
      qp['search'] = search.trim();
    }
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierAiOrdersEndpoint,
      qp,
      token,
    );
    return AiOrdersListResult.fromJson(_asMap(response));
  }

  Future<AiOrdersListResult> listUnbilledAlerts(
    String token, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierAiOrdersUnbilledAlertsEndpoint,
      {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      token,
    );
    return AiOrdersListResult.fromJson(_asMap(response));
  }

  Future<AiOrderCashier> getAiOrder(String token, String id) async {
    final response = await _apiService.get(
      ApiConstants.cashierAiOrderDetailEndpoint(id),
      headers: _authHeaders(token),
    );
    return AiOrderCashier.fromJson(_asMap(response));
  }

  Future<AiOrderByPlateResult> getByPlate(String token, String plate) async {
    final normalized = canonicalSaudiPlateForApi(plate);
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierAiOrdersByPlateEndpoint,
      {'plate': normalized.isNotEmpty ? normalized : plate.trim()},
      token,
    );
    return AiOrderByPlateResult.fromJson(_asMap(response));
  }

  Future<OpenPosOrdersByPlateResult> openPosByPlate(
    String token,
    String plate,
  ) async {
    final normalized = canonicalSaudiPlateForApi(plate);
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierAiOrdersOpenPosByPlateEndpoint,
      {'plate': normalized.isNotEmpty ? normalized : plate.trim()},
      token,
    );
    return OpenPosOrdersByPlateResult.fromJson(_asMap(response));
  }

  Future<AiOrderCashier> acknowledge(String token, String id) async {
    final response = await _apiService.post(
      ApiConstants.cashierAiOrderAcknowledgeEndpoint(id),
      <String, dynamic>{},
      headers: _authHeaders(token),
    );
    return AiOrderCashier.fromJson(_asMap(response));
  }

  Future<AiOrderCashier> linkOrder(
    String token,
    String aiOrderId,
    String salesOrderId,
  ) async {
    final response = await _apiService.post(
      ApiConstants.cashierAiOrderLinkOrderEndpoint(aiOrderId),
      {'salesOrderId': salesOrderId},
      headers: _authHeaders(token),
    );
    return AiOrderCashier.fromJson(_asMap(response));
  }

  Future<AiOrdersSettings> getSettings(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.cashierAiOrdersSettingsEndpoint,
        headers: _authHeaders(token),
      );
      return AiOrdersSettings.fromJson(_asMap(response));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AI Orders] settings fetch failed: $e');
      }
      return const AiOrdersSettings();
    }
  }

  Future<List<AiStaffVehicle>> listStaffVehicles(String token) async {
    final response = await _apiService.get(
      ApiConstants.cashierAiOrdersStaffVehiclesEndpoint,
      headers: _authHeaders(token),
    );
    final map = _asMap(response);
    final raw = map['data'] ?? map['vehicles'] ?? map['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AiStaffVehicle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // --- Workshop notifications (cashier inbox) -------------------------

  static const String _cashierRole = 'cashier_user';

  Future<WorkshopNotificationsInboxResult> listInbox(
    String token, {
    int page = 1,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    final qp = <String, String>{
      'role': _cashierRole,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (unreadOnly) qp['unreadOnly'] = 'true';
    final response = await _apiService.getWithQueryParams(
      ApiConstants.workshopNotificationsInboxEndpoint,
      qp,
      token,
    );
    return WorkshopNotificationsInboxResult.fromJson(_asMap(response));
  }

  Future<void> markNotificationRead(String token, String notificationId) async {
    await _apiService.patch(
      '${ApiConstants.workshopNotificationReadEndpoint(notificationId)}'
      '?role=$_cashierRole',
      <String, dynamic>{},
      headers: _authHeaders(token),
    );
  }

  Future<void> deleteNotification(String token, String notificationId) async {
    await _apiService.delete(
      '${ApiConstants.workshopNotificationDeleteEndpoint(notificationId)}'
      '?role=$_cashierRole',
      headers: _authHeaders(token),
    );
  }

  Future<void> clearAllNotifications(String token) async {
    await _apiService.delete(
      '${ApiConstants.workshopNotificationsClearAllEndpoint}?role=$_cashierRole',
      headers: _authHeaders(token),
    );
  }
}

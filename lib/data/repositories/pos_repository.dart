import '../../models/department_model.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';
import '../../models/walk_in_customer_model.dart';
import '../../models/pos_technician_model.dart';
import '../../models/technician_assignment_model.dart';
import '../../models/pos_order_model.dart';
import '../../models/customer_search_model.dart';
import '../../models/pos_product_model.dart';
import '../../models/create_invoice_model.dart';
import '../../models/promo_code_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/expense_category_model.dart';
import '../../models/cashier_expense_models.dart';
import '../../models/wallet_balance_model.dart'; // Added import
import '../../models/corporate_booking_model.dart'; // Added import
import '../../models/store_closing_api_model.dart'; // Added import
import '../../models/cashier_closing_history_model.dart';
import '../../models/cashier_cash_collection_model.dart';
import '../../models/technician_salary_payment_model.dart';
import '../../models/technician_advance_model.dart';
import '../../models/cashier_complete_job_model.dart';
import '../../models/cashier_corporate_accounts_api_model.dart';
import '../../models/invoiced_orders_model.dart';
import '../../models/submit_sales_return_model.dart';
import '../../models/sales_return_list_model.dart';
import '../../models/purchase_order_models.dart';
import '../../models/takeaway_models.dart';
import '../../models/softpos_adjustment_model.dart';
import '../../models/cashier_active_broadcasts_model.dart';
import '../../models/inventory_sales_api_model.dart';
import '../../models/cashier_corporate_fleet_vehicle_model.dart';
import '../../models/corporate_quoted_products_model.dart';


class PosRepository {
  final BaseApiService _apiService = BaseApiService();

  String _safeEncode(Object? data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  void _logWalkInRequest(String endpoint, Object? body) {
    debugPrint('[WALKIN][REQUEST] $endpoint');
    if (body != null) {
      debugPrint(_safeEncode(body));
    }
  }

  void _logWalkInResponse(String endpoint, Object? response) {
    debugPrint('[WALKIN][RESPONSE] $endpoint');
    debugPrint(_safeEncode(response));
  }

  void _logWalkInError(String endpoint, Object error) {
    debugPrint('[WALKIN][ERROR] $endpoint');
    debugPrint(error.toString());
  }

  Future<WalkInCustomerResponse> createWalkInOrder(WalkInCustomerRequest request, String token) async {
    const endpoint = ApiConstants.walkInCustomerEndpoint;
    final body = request.toJson();
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return WalkInCustomerResponse.fromJson(response);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// POST /cashier/walk-in-order with an explicit JSON body (e.g. shell create: vehicle + departmentIds only).
  Future<WalkInCustomerResponse> postWalkInOrder(
    Map<String, dynamic> body,
    String token,
  ) async {
    const endpoint = ApiConstants.walkInCustomerEndpoint;
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return WalkInCustomerResponse.fromJson(response);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// POST /cashier/order/:orderId/jobs — append departments as new pending jobs.
  Future<Map<String, dynamic>> addJobsToCashierOrder(
    String orderId,
    List<String> departmentIds,
    String token,
  ) async {
    final endpoint = ApiConstants.cashierOrderJobsEndpoint(orderId);
    final body = {'departmentIds': departmentIds};
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// GET /cashier/technicians?departmentId=…
  Future<PosTechnicianResponse> getCashierTechnicians(
    String token, {
    String? departmentId,
  }) async {
    final endpoint = ApiConstants.cashierTechniciansEndpoint;
    _logWalkInRequest(endpoint, {'departmentId': departmentId});
    try {
      final Map<String, String> qp = {};
      if (departmentId != null && departmentId.trim().isNotEmpty) {
        qp['departmentId'] = departmentId.trim();
      }
      final dynamic response = qp.isEmpty
          ? await _apiService.get(
              ApiConstants.cashierTechniciansEndpoint,
              headers: {'Authorization': 'Bearer $token'},
            )
          : await _apiService.getWithQueryParams(
              ApiConstants.cashierTechniciansEndpoint,
              qp,
              token,
            );
      if (kDebugMode) {
        final m = response as Map<String, dynamic>;
        final list = m['technicians'];
        final n = list is List ? list.length : 0;
        debugPrint('[POS] GET $endpoint → $n technicians');
      }
      return PosTechnicianResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// PATCH /cashier/job/:jobId/cancel
  Future<Map<String, dynamic>> cancelCashierJob(
    String jobId,
    String reason,
    String token,
  ) async {
    final endpoint = ApiConstants.cashierJobCancelEndpoint(jobId);
    final body = {'reason': reason};
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.patch(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  Future<PosTechnicianResponse> getTechnicians(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.techniciansEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return PosTechnicianResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /cashier/technicians/:employeeId/online-status — cashier sets technician presence.
  /// Body: `{ "status": "online" | "offline" }`.
  Future<Map<String, dynamic>> patchCashierTechnicianOnlineStatus(
    String token,
    String employeeId,
    String status,
  ) async {
    final endpoint =
        ApiConstants.cashierTechnicianOnlineStatusEndpoint(employeeId);
    final body = {'status': status};
    if (kDebugMode) {
      debugPrint('[POS] PATCH $endpoint body=$body');
    }
    final response = await _apiService.patch(
      endpoint,
      body,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  /// PATCH /cashier/technicians/:employeeId/duty-status — workshop / on-call / both / inactive.
  Future<Map<String, dynamic>> patchCashierTechnicianDutyMode(
    String token,
    String employeeId,
    String dutyMode,
  ) async {
    final endpoint =
        ApiConstants.cashierTechnicianDutyStatusEndpoint(employeeId);
    final body = {'dutyMode': dutyMode};
    if (kDebugMode) {
      debugPrint('[POS] PATCH $endpoint body=$body');
    }
    final response = await _apiService.patch(
      endpoint,
      body,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  /// POST body includes `{ employeeIds: [...], sync: true }` when [ApiConstants.cashierAssignSendSyncReplace].
  /// Response may include `sync`, `removedCount`, and a detailed `message` (roster synced / unchanged).
  Future<AssignTechnicianResponse> assignTechnicians(
      String jobId, List<String> employeeIds, String token) async {
    final endpoint = ApiConstants.assignTechnicianEndpoint(jobId);
    final body = <String, dynamic>{'employeeIds': employeeIds};
    if (ApiConstants.cashierAssignSendSyncReplace) {
      body['sync'] = true;
    }
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return AssignTechnicianResponse.fromJson(response);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// [dutyMode] e.g. `workshop` or `on_call` — sent as JSON `type` per backend.
  Future<Map<String, dynamic>> postJobBroadcast(
    String jobId,
    String dutyMode,
    String token,
  ) async {
    try {
      return await _apiService.post(
        ApiConstants.cashierJobBroadcastEndpoint(jobId),
        {'type': dutyMode},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelJobBroadcast(String jobId, String token) async {
    try {
      return await _apiService.post(
        ApiConstants.cashierJobBroadcastCancelEndpoint(jobId),
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

  Future<CashierCompleteJobResponse> completeCashierJob(String jobId, String token, {Map<String, dynamic>? body}) async {
    final endpoint = ApiConstants.cashierCompleteJobEndpoint(jobId);
    final reqBody = body ?? {};
    _logWalkInRequest(endpoint, reqBody);
    try {
      final response = await _apiService.post(
        endpoint,
        reqBody,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return CashierCompleteJobResponse.fromJson(response);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// POST body replaces line items for that job when the backend implements replace-all semantics.
  /// If the server **merges** lines instead, clearing/removing products from the cashier cart
  /// may not remove old lines — confirm with backend.
  Future<Map<String, dynamic>> updateJobPricing(
    String jobId,
    Map<String, dynamic> body,
    String token,
  ) async {
    final endpoint = ApiConstants.cashierJobPricingEndpoint(jobId);
    final normalizedBody = Map<String, dynamic>.from(body);
    final items = normalizedBody['items'];
    if (items is List && items.isNotEmpty) {
      // Backend contract: when `items` is present, treat it as the only line source.
      normalizedBody.remove('products');
      normalizedBody.remove('services');
    }
    _logWalkInRequest(endpoint, normalizedBody);
    try {
      final response = await _apiService.post(
        endpoint,
        normalizedBody,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// Unlocks a **completed** job for pricing/technician edits (`completed` → `edited`).
  ///
  /// Tries **PATCH** first (contract); if production only registered **POST** (common mismatch),
  /// retries once with POST on the same path. A **404** on both means the route is not deployed
  /// on that server — backend must expose `/cashier/job/:jobId/mark-edited`.
  Future<Map<String, dynamic>> markCashierJobEdited(String jobId, String token) async {
    final endpoint = ApiConstants.cashierJobMarkEditedEndpoint(jobId);
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    try {
      final response = await _apiService.patch(
        endpoint,
        <String, dynamic>{},
        headers: headers,
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      final lower = e.toString().toLowerCase();
      // Express: "Cannot PATCH /cashier/job/…/mark-edited" when no PATCH handler exists.
      if (lower.contains('cannot patch')) {
        try {
          if (kDebugMode) {
            debugPrint('[WALKIN] mark-edited: PATCH unavailable, retrying POST $endpoint');
          }
          final response = await _apiService.post(
            endpoint,
            <String, dynamic>{},
            headers: headers,
          );
          _logWalkInResponse('$endpoint (POST)', response);
          return response as Map<String, dynamic>;
        } catch (e2) {
          _logWalkInError('$endpoint (POST fallback)', e2);
          rethrow;
        }
      }
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  Future<CashierJobReadyResponse> checkJobCompleteReady(
    String jobId,
    String token,
  ) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.cashierCompleteReadyEndpoint(jobId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return CashierJobReadyResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<CashierOrdersResponse> getCashierOrders(
    String token, {
    String? status,
    int? limit,
    int? offset,
  }) async {
    final endpoint = ApiConstants.cashierOrdersEndpoint;
    final Map<String, String> qp = {};
    if (status != null && status.trim().isNotEmpty) {
      qp['status'] = status.trim();
    }
    if (limit != null) qp['limit'] = limit.toString();
    if (offset != null) qp['offset'] = offset.toString();

    final ordersUrl = Uri.parse('${ApiConstants.baseUrl}$endpoint')
        .replace(queryParameters: qp.isEmpty ? null : qp)
        .toString();
    debugPrint('[Orders Hub] GET $ordersUrl');
    _logWalkInRequest(endpoint, {'url': ordersUrl, 'status': status, 'limit': limit, 'offset': offset});

    try {
      final dynamic response = qp.isEmpty
          ? await _apiService.get(
              ApiConstants.cashierOrdersEndpoint,
              headers: {'Authorization': 'Bearer $token'},
            )
          : await _apiService.getWithQueryParams(
              ApiConstants.cashierOrdersEndpoint,
              qp,
              token,
            );
      // Do not _logWalkInResponse here: payload is large and JsonEncoder blocks the UI isolate.
      if (kDebugMode) {
        final m = response as Map<String, dynamic>;
        final raw = m['orders'];
        final n = raw is List ? raw.length : 0;
        final total = m['total'];
        final limit = m['limit'];
        debugPrint(
          '[Orders Hub] GET $ordersUrl → $n orders (total=$total, limit=$limit)',
        );
      }
      return CashierOrdersResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Orders Hub] GET $ordersUrl → ERROR: $e');
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// GET /cashier/softpos-adjustments — SoftPOS prepaid vs order/invoice mismatches.
  Future<({List<SoftPosAdjustmentRow> items, double totalDifference})>
      getSoftPosAdjustments(String token) async {
    final endpoint = ApiConstants.cashierSoftPosAdjustmentsEndpoint;
    final response = await _apiService.get(
      endpoint,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final map = Map<String, dynamic>.from(response as Map);
    final raw = map['items'];
    final items = <SoftPosAdjustmentRow>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          items.add(
            SoftPosAdjustmentRow.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    final total =
        double.tryParse(map['totalDifference']?.toString() ?? '0') ?? 0;
    return (items: items, totalDifference: total);
  }

  /// GET /cashier/order/:orderId — jobs, pendingDepartments, corporate fields.
  Future<Map<String, dynamic>> getCashierOrderDetail(String orderId, String token) async {
    final endpoint = ApiConstants.cashierOrderDetailEndpoint(orderId);
    _logWalkInRequest(endpoint, null);
    try {
      final response = await _apiService.get(
        endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// Corporate walk-in quote save (creates/updates status = unapproved).
  Future<WalkInCustomerResponse> saveWalkInCorporateUnapproved(
    WalkInCustomerRequest request,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.cashierWalkInCorporateUnapprovedEndpoint,
        request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return WalkInCustomerResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Transition corporate walk-in order from `unapproved` to `waiting for corporate approval`.
  Future<Map<String, dynamic>> sendWalkInCorporateForApproval(
    String orderId,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.cashierWalkInCorporateSendForApprovalEndpoint(orderId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// After corporate approval — create one job for a department with pending lines.
  Future<Map<String, dynamic>> startCorporateWalkInDepartment(
    String orderId,
    String departmentId,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.cashierWalkInCorporateStartDepartmentEndpoint(orderId),
        {'departmentId': departmentId},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches invoiced orders for [customerId].
  ///
  /// Pass [scope] = `'all'` for the cross-branch read-only history view (chevron `>`
  /// on the home customer card). Omit it for the branch-scoped sales-return picker —
  /// when the customer was serviced only from another branch the backend responds with
  /// `success: false` + `message: 'This customer belongs to another branch.'`.
  Future<InvoicedOrderResponse> getInvoicedOrdersByCustomer(
    String customerId,
    String token, {
    String? scope,
  }) async {
    try {
      final base = ApiConstants.invoicedOrdersEndpoint(customerId);
      final endpoint = (scope != null && scope.isNotEmpty)
          ? '$base?scope=${Uri.encodeQueryComponent(scope)}'
          : base;
      final response = await _apiService.get(
        endpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return InvoicedOrderResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<InvoicedOrderResponse> getInvoicedOrdersByInvoiceNo(
    String invoiceNo,
    String token,
  ) async {
    try {
      final trimmed = invoiceNo.trim();
      final endpoint =
          ApiConstants.invoicedOrderByInvoiceNoEndpoint(trimmed);
      final response = await _apiService.get(
        endpoint,
        headers: {'Authorization': 'Bearer $token'},
      );
      return InvoicedOrderResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<CashierCorporateFleetVehiclesResponse> getCorporateAccountVehicles(
    String token,
    String corporateAccountId,
  ) async {
    try {
      final corpId = corporateAccountId.trim();
      final endpoint =
          ApiConstants.cashierCorporateAccountVehiclesEndpoint(corpId);
      final response = await _apiService.get(
        endpoint,
        headers: {'Authorization': 'Bearer $token'},
      );
      return CashierCorporateFleetVehiclesResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> editOrder(String orderId, String jobId, Map<String, dynamic> body, String token) async {
    final endpoint = ApiConstants.editOrderEndpoint(orderId, jobId);
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.patch(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// PATCH /cashier/order/:orderId/billing — walk_in orders without corporate account only.
  Future<Map<String, dynamic>> patchWalkInOrderBilling(
    String orderId,
    Map<String, dynamic> body,
    String token,
  ) async {
    final endpoint = ApiConstants.cashierOrderBillingEndpoint(orderId);
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.patch(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// PATCH `/cashier/order/:orderId/payment-method` — draft POS payment modal before invoice.
  Future<Map<String, dynamic>> patchOrderPaymentMethod(
    String orderId,
    Map<String, dynamic> body,
    String token,
  ) async {
    final endpoint = ApiConstants.cashierOrderPaymentMethodEndpoint(orderId);
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.patch(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// POST `/cashier/order/:orderId/record-prepayment` — after Request Payment.
  Future<Map<String, dynamic>> recordOrderPrepayment({
    required String orderId,
    required String token,
    required bool isCorporate,
    required List<Map<String, dynamic>> payments,
    required double paidAmount,
    String? intentUuid,
    bool softPosAppBar = false,
  }) async {
    final endpoint = ApiConstants.cashierOrderRecordPrepaymentEndpoint(orderId);
    final body = <String, dynamic>{
      'customerKind': isCorporate ? 'corporate' : 'individual',
      'paidAmount': paidAmount,
      'payments': payments,
      if (intentUuid != null && intentUuid.trim().isNotEmpty)
        'intentUuid': intentUuid.trim(),
      if (softPosAppBar) 'softPosAppBar': true,
    };
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// PATCH `/cashier/order/:orderId/maintenance-checklist` — saves six checklist ticks for invoice print.
  Future<Map<String, dynamic>> patchOrderMaintenanceChecklist({
    required String orderId,
    required List<bool> checks,
    required String token,
  }) async {
    if (checks.length != 6) {
      throw ArgumentError('maintenance checklist expects 6 booleans');
    }
    final endpoint =
        ApiConstants.cashierOrderMaintenanceChecklistEndpoint(orderId);
    final body = <String, dynamic>{'checks': checks};
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.patch(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason, String token) async {
    final endpoint = ApiConstants.cancelOrderEndpoint(orderId);
    final body = {'reason': reason};
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return response as Map<String, dynamic>;
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  Future<SubmitSalesReturnResponse> submitSalesReturn(SubmitSalesReturnRequest request, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.submitSalesReturnEndpoint,
        request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return SubmitSalesReturnResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// [scope] `all` = every branch in the workshop (customer history search); `branch` = current branch only.
  Future<CustomerSearchResponse> searchCustomers(
    Map<String, String> queryParams,
    String token, {
    String scope = 'all',
  }) async {
    try {
      final params = Map<String, String>.from(queryParams);
      if (scope.trim().isNotEmpty) {
        params['scope'] = scope.trim();
      }
      final response = await _apiService.getWithQueryParams(
        ApiConstants.searchCustomerEndpoint,
        params,
        token,
      );
      return CustomerSearchResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductsResponse> getProducts(
    String workshopId,
    String token, {
    String? departmentId,
    String? branchId,
    String? corporateAccountId,
    int? limit,
    int? offset,
  }) async {
    try {
      if (branchId != null && branchId.isNotEmpty) {
        final queryParams = <String, String>{};
        if (departmentId != null && departmentId.isNotEmpty) {
          queryParams['departmentId'] = departmentId;
        }
        final corpId = corporateAccountId?.trim() ?? '';
        if (corpId.isNotEmpty) {
          queryParams['corporateAccountId'] = corpId;
        }
        if (limit != null) queryParams['limit'] = limit.toString();
        if (offset != null) queryParams['offset'] = offset.toString();
        
        final response = await _apiService.getWithQueryParams(
          ApiConstants.branchCatalogEndpoint(branchId),
          queryParams,
          token,
        );
        return ProductsResponse.fromJson(response);
      } else {
        final queryParams = {'workshopId': workshopId};
        if (departmentId != null && departmentId.isNotEmpty) {
          queryParams['departmentId'] = departmentId;
        }
        if (limit != null) queryParams['limit'] = limit.toString();
        if (offset != null) queryParams['offset'] = offset.toString();
        final response = await _apiService.getWithQueryParams(
          ApiConstants.productsEndpoint,
          queryParams,
          token,
        );
        return ProductsResponse.fromJson(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH branch service VAT-inclusive selling price (catalog override).
  Future<Map<String, dynamic>> patchBranchServiceSellingPrice({
    required String branchId,
    required String serviceId,
    required double sellingPriceVatInclusive,
    required String token,
  }) async {
    final endpoint = ApiConstants.branchServiceSellingPriceEndpoint(
      branchId,
      serviceId,
    );
    final response = await _apiService.patch(
      endpoint,
      {'sellingPrice': sellingPriceVatInclusive},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': false, 'message': 'Unexpected response'};
  }

  Future<CreateInvoiceResponse> createInvoice(CreateInvoiceRequest request, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createInvoiceEndpoint,
        request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return CreateInvoiceResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<CreateInvoiceResponse> getInvoiceByOrder(String orderId, String token) async {
    final endpoint = ApiConstants.getInvoiceByOrderEndpoint;
    final body = {'orderId': orderId};
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return CreateInvoiceResponse.fromJson(response);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// POST /cashier/invoice/by-order/public-link — public invoice URL for WhatsApp share.
  Future<Map<String, dynamic>> getPublicInvoiceLinkByOrder(
    String orderId,
    String token,
  ) async {
    final endpoint = ApiConstants.getInvoicePublicLinkByOrderEndpoint;
    final body = {'orderId': orderId};
    _logWalkInRequest(endpoint, body);
    try {
      final response = await _apiService.post(
        endpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      _logWalkInResponse(endpoint, response);
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      _logWalkInError(endpoint, e);
      rethrow;
    }
  }

  /// POST /cashier/invoice/:orderId/payment
  /// Payload examples:
  /// - { isCorporate: true, payments: [{method, amount}] }
  /// - { isCorporate: false, payments: [{method, amount}, ...] }
  Future<Map<String, dynamic>> saveInvoicePayment(
    String orderId,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.invoicePaymentEndpoint(orderId),
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      rethrow;
    }
  }

  Future<PromoCodeResponse> applyPromoCode(
    String code,
    double orderAmount,
    String token, {
    double? orderAmountInclVat,
    List<String>? productIds,
    List<String>? serviceIds,
    List<Map<String, dynamic>>? lineItems,
    String? jobId,
  }) async {
    try {
      final body = <String, dynamic>{
        'code': code,
        'orderAmount': orderAmount,
      };
      if (jobId != null && jobId.trim().isNotEmpty) {
        // Backend resolves the job's persisted lines (incl. category ids) itself.
        body['jobId'] = jobId.trim();
      }
      if (orderAmountInclVat != null && orderAmountInclVat > 0) {
        body['orderAmountInclVat'] = orderAmountInclVat;
        body['order_amount_incl_vat'] = orderAmountInclVat;
      }
      if (productIds != null && productIds.isNotEmpty) {
        body['productIds'] = productIds;
      }
      if (serviceIds != null && serviceIds.isNotEmpty) {
        body['serviceIds'] = serviceIds;
      }
      if (lineItems != null && lineItems.isNotEmpty) {
        body['lineItems'] = lineItems;
      }

      final response = await _apiService.post(
        ApiConstants.promoCodeApplyEndpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return PromoCodeResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyReferralCode(
    String code,
    String token, {
    double? orderAmountInclVat,
    String? orderId,
    String? customerMobile,
  }) async {
    final body = <String, dynamic>{
      'code': code.trim(),
      if (orderAmountInclVat != null && orderAmountInclVat > 0)
        'orderAmountInclVat': orderAmountInclVat,
      if (orderId != null && orderId.trim().isNotEmpty) 'orderId': orderId.trim(),
      if (customerMobile != null && customerMobile.trim().isNotEmpty)
        'customerMobile': customerMobile.trim(),
    };
    final response = await _apiService.post(
      ApiConstants.referralCodeApplyEndpoint,
      body,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> setOrderReferralCode(
    String orderId,
    String token, {
    String? referralCode,
    bool clear = false,
  }) async {
    final body = <String, dynamic>{
      if (clear) 'clear': true,
      if (!clear && referralCode != null) 'referralCode': referralCode.trim(),
    };
    final response = await _apiService.post(
      ApiConstants.cashierOrderReferralEndpoint(orderId),
      body,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<PromoCodeListResponse> getPromoCodes(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.cashierPromoCodesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return PromoCodeListResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ExpenseCategoriesResponse> getExpenseCategories(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.expenseCategoriesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return ExpenseCategoriesResponse.fromDynamic(response);
    } catch (e) {
      rethrow;
    }
  }

  /// [employeeId] only for Salary Advances; omitted when null/empty.
  /// Receipt: multipart field `proof` when [receiptFilePath] exists; else JSON (optional proofUrl in [extraJson]).
  Future<Map<String, dynamic>> submitExpense({
    required double amount,
    String? categoryId,
    required String description,
    String? employeeId,
    String? receiptFilePath,
    List<String>? receiptFilePaths,
    Map<String, dynamic>? extraJson,
    required String token,
  }) async {
    try {
      final paths = <String>[
        ...?receiptFilePaths?.map((p) => p.trim()).where((p) => p.isNotEmpty),
        if ((receiptFilePath ?? '').trim().isNotEmpty) receiptFilePath!.trim(),
      ].where((p) => File(p).existsSync()).toSet().toList();
      final emp = employeeId?.trim();
      final extraFields = <String, String>{};
      extraJson?.forEach((key, value) {
        if (value == null) return;
        extraFields[key] = value.toString();
      });

      if (paths.isNotEmpty) {
        final fields = <String, String>{
          'amount': amount.toString(),
          if ((categoryId ?? '').trim().isNotEmpty) 'categoryId': categoryId!.trim(),
          'description': description,
          ...extraFields,
        };
        if (emp != null && emp.isNotEmpty) fields['employeeId'] = emp;
        final files = <http.MultipartFile>[];
        for (final path in paths) {
          files.add(await http.MultipartFile.fromPath('proof', path));
        }
        final response = await _apiService.postMultipart(
          ApiConstants.expenseSubmitEndpoint,
          fields,
          files,
          token,
        );
        return Map<String, dynamic>.from(response as Map<dynamic, dynamic>);
      }

      final data = <String, dynamic>{
        'amount': amount,
        if ((categoryId ?? '').trim().isNotEmpty) 'categoryId': categoryId!.trim(),
        'description': description,
        if (extraJson != null) ...extraJson,
      };
      if (emp != null && emp.isNotEmpty) {
        data['employeeId'] = emp;
      } else {
        data.remove('employeeId');
      }
      final response = await _apiService.post(
        ApiConstants.expenseSubmitEndpoint,
        data,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return Map<String, dynamic>.from(response as Map<dynamic, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Cashier JWT — active employees for current branch from [GET /cashier/employees].
  ///
  /// [employeeType] optional: `'staff'` or `'technician'`. Omit to include all roles
  /// reported by the API (aligned with expense dropdown behaviour).
  Future<BranchEmployeesResponse> getCashierEmployees(
    String token, {
    String? employeeType,
  }) async {
    try {
      final trimmed = employeeType?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        final response = await _apiService.getWithQueryParams(
          ApiConstants.cashierEmployeesEndpoint,
          {'employeeType': trimmed},
          token,
        );
        return BranchEmployeesResponse.fromDynamic(response);
      }
      final response = await _apiService.get(
        ApiConstants.cashierEmployeesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return BranchEmployeesResponse.fromDynamic(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Legacy name — salary-advance / expense employee picker.
  /// Hits [expenseBranchEmployeesEndpoint] (all active employees of cashier branch).
  Future<BranchEmployeesResponse> getExpenseBranchEmployees(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.expenseBranchEmployeesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return BranchEmployeesResponse.fromDynamic(response);
    } catch (e) {
      // Fallback to /cashier/employees if alias route is unavailable.
      return getCashierEmployees(token);
    }
  }

  Future<CashierExpenseHistoryResponse> getExpenseHistory(
    String token, {
    String? status,
    String? from,
    String? to,
    String? categoryId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (from != null && from.isNotEmpty) params['from'] = from;
      if (to != null && to.isNotEmpty) params['to'] = to;
      if (categoryId != null && categoryId.isNotEmpty) params['categoryId'] = categoryId;
      final response = await _apiService.getWithQueryParams(
        ApiConstants.expenseHistoryEndpoint,
        params,
        token,
      );
      return CashierExpenseHistoryResponse.fromDynamic(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestPettyCashFund(
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.pettyCashRequestFundEndpoint,
        data,
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

  Future<WalletBalanceResponse> getWalletBalance(String token) async {
    try {
      final response = await _apiService.getWithQueryParams(
        ApiConstants.walletBalanceEndpoint,
        {'currency': 'SAR'},
        token,
      );
      return WalletBalanceResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<DepartmentResponse> getDepartments(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.departmentsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return DepartmentResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<CorporateBooking?> getCorporateBookingDetail(
    String bookingId,
    String token,
  ) async {
    try {
      final response = await BaseApiService.runWithoutUnauthorizedLogout(
        () => _apiService.get(
          ApiConstants.cashierCorporateBookingDetailEndpoint(bookingId),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      final data = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
      final bookingRaw = data['booking'] ?? data['data'] ?? data;
      if (bookingRaw is Map) {
        return CorporateBooking.fromJson(Map<String, dynamic>.from(bookingRaw));
      }
      return null;
    } on UnauthorisedException {
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<CorporateBookingResponse> getCorporateBookings(
    String filter,
    String? branchId,
    String token, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final query = <String, String>{
        'filter': filter,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      final bid = branchId?.trim() ?? '';
      if (bid.isNotEmpty) {
        query['branchId'] = bid;
      }
      final response = await _apiService.getWithQueryParams(
        ApiConstants.corporateBookingsEndpoint,
        query,
        token,
      );
      return CorporateBookingResponse.fromJson(
        response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<CorporateBooking?> getCorporateWalkInOrder(String orderId, String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.corporateWalkInOrderEndpoint(orderId),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = Map<String, dynamic>.from(response as Map);
      final orderRaw = data['order'];
      if (orderRaw is Map<String, dynamic>) {
        return CorporateBooking.fromJson(orderRaw);
      }
      if (orderRaw is Map) {
        return CorporateBooking.fromJson(Map<String, dynamic>.from(orderRaw));
      }
      return CorporateBooking.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<CorporateBookingApproveResult> approveCorporateBooking(
    String bookingId,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.approveCorporateBookingEndpoint(bookingId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return CorporateBookingApproveResult.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rejectCorporateBooking(String bookingId, String reason, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.rejectCorporateBookingEndpoint(bookingId),
        {
          'reason': reason,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response['success'] is bool) {
        return response['success'];
      } else if (response['success'] is String) {
        return response['success'].toString().toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Corporate catalog for POS — `GET /cashier/corporate-accounts/:id/products` first.
  Future<CorporateQuotedProductsResponse> getCorporateQuotedProducts(
    String token,
    String corporateAccountId, {
    String? departmentId,
    List<String>? departmentIds,
    bool quotedOnly = false,
  }) async {
    final corpId = corporateAccountId.trim();
    final deptIdSet = <String>{
      if (departmentIds != null)
        ...departmentIds.map((d) => d.trim()).where((d) => d.isNotEmpty),
      if (departmentId != null && departmentId.trim().isNotEmpty)
        departmentId.trim(),
    };

    Map<String, String> buildQuery({bool scopedDepartments = true}) {
      final q = <String, String>{};
      if (quotedOnly) q['quotedOnly'] = 'true';
      if (scopedDepartments && deptIdSet.isNotEmpty) {
        q['departmentIds'] = deptIdSet.join(',');
      }
      return q;
    }

    Future<CorporateQuotedProductsResponse> fetchPath(
      String path,
      Map<String, String> query,
    ) async {
      final response = await BaseApiService.runWithoutUnauthorizedLogout(
        () => _apiService.getWithQueryParams(path, query, token),
      );
      return CorporateQuotedProductsResponse.fromJson(response);
    }

    bool hasLines(CorporateQuotedProductsResponse r) => r.allLines.isNotEmpty;

    for (final path in [
      ApiConstants.cashierCorporateAccountProductsEndpoint(corpId),
      ApiConstants.cashierCorporateAccountCatalogEndpoint(corpId),
    ]) {
      try {
        var parsed = await fetchPath(path, buildQuery());
        if (hasLines(parsed)) return parsed;
        if (deptIdSet.isNotEmpty) {
          parsed = await fetchPath(path, buildQuery(scopedDepartments: false));
          if (hasLines(parsed)) return parsed;
        }
      } on UnauthorisedException {
        continue;
      }
    }

    try {
      final legacyQuery = <String, String>{
        'corporateAccountId': corpId,
        if (deptIdSet.isNotEmpty) 'departmentIds': deptIdSet.join(','),
      };
      final response = await BaseApiService.runWithoutUnauthorizedLogout(
        () => _apiService.getWithQueryParams(
          ApiConstants.corporateProductsEndpoint,
          legacyQuery,
          token,
        ),
      );
      return CorporateQuotedProductsResponse.fromJson(response);
    } on UnauthorisedException {
      return const CorporateQuotedProductsResponse(success: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<CashierCorporateAccountsResponse> getCashierCorporateAccounts(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.cashierCorporateAccountsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return CashierCorporateAccountsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<StoreClosingApiResponse> getStoreClosing(String token, String date, String workshopId) async {
    try {
      final response = await _apiService.getWithQueryParams(
        ApiConstants.storeClosingEndpoint,
        {
          'date': date,
          if (workshopId.isNotEmpty) 'workshopId': workshopId,
        },
        token,
      );
      return StoreClosingApiResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Raw JSON variant so callers can access fields the typed model doesn't parse.
  /// Omit [date] to use the active POS session window (current shift).
  Future<Map<String, dynamic>> getStoreClosingRaw(
    String token, {
    String? date,
    String workshopId = '',
  }) async {
    try {
      final response = await _apiService.getWithQueryParams(
        ApiConstants.storeClosingEndpoint,
        {
          if (date != null && date.isNotEmpty) 'date': date,
          if (workshopId.isNotEmpty) 'workshopId': workshopId,
        },
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitCounterClosing(String token, Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(
        ApiConstants.counterClosingEndpoint,
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<CashierClosingHistoryResponse> getClosingHistory(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? from,
    String? to,
  }) async {
    try {
      final response = await _apiService.getWithQueryParams(
        ApiConstants.closingHistoryEndpoint,
        {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
        },
        token,
      );
      return CashierClosingHistoryResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<CashierCashCollectionResponse> getCashCollectionHistory(
    String token, {
    int page = 1,
    int pageSize = 20,
    String? from,
    String? to,
  }) async {
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashCollectionEndpoint,
      {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
      token,
    );
    return CashierCashCollectionResponse.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  static String _ymd(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  Future<TechnicianSalaryPaymentsResponse> getCashierSalaryPayments(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierSalaryPaymentsEndpoint,
      {
        if (from != null) 'from': _ymd(from),
        if (to != null) 'to': _ymd(to),
      },
      token,
    );
    return TechnicianSalaryPaymentsResponse.fromJson(
      response is Map ? Map<String, dynamic>.from(response) : {},
    );
  }

  Future<TechnicianSalaryAdvancesResponse> getCashierSalaryAdvances(
    String token, {
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierSalaryAdvancesEndpoint,
      {
        if (from != null) 'from': _ymd(from),
        if (to != null) 'to': _ymd(to),
      },
      token,
    );
    return TechnicianSalaryAdvancesResponse.fromJson(
      response is Map ? Map<String, dynamic>.from(response) : {},
    );
  }

  Future<Map<String, dynamic>> respondToCashierSalaryPayment(
    String token,
    String paymentId,
    String response,
  ) async {
    final result = await _apiService.patch(
      ApiConstants.cashierSalaryPaymentAckEndpoint(paymentId),
      {'response': response},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return result is Map ? Map<String, dynamic>.from(result) : {};
  }

  Future<SalesReturnListResponse> getSalesReturns(String token, {int limit = 50, int offset = 0, String? invoiceId}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (invoiceId != null && invoiceId.isNotEmpty) 'invoiceId': invoiceId,
      };
      
      final response = await _apiService.getWithQueryParams(
        ApiConstants.salesReturnListEndpoint,
        queryParams,
        token,
      );
      return SalesReturnListResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<TakeawayCatalogData> getTakeawayProductsCatalog(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.cashierTakeawayProductsCatalogEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TakeawayCatalogData.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TakeawayCheckoutResponse> postTakeawayCheckout(
    TakeawayCheckoutRequest request,
    String token,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.cashierTakeawayCheckoutEndpoint,
        request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return TakeawayCheckoutResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<CashierActiveBroadcastsResponse> getCashierActiveBroadcasts(String token) async {
    const endpoint = ApiConstants.cashierBroadcastsActiveEndpoint;
    try {
      final response = await _apiService.get(
        endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return CashierActiveBroadcastsResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      rethrow;
    }
  }

  String _dateOnlyParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Product-level sales by day for the cashier branch. Backend: [ApiConstants.cashierInventorySalesEndpoint].
  /// Omit [utcOffsetMinutes] so the server uses BUSINESS_TIMEZONE (Asia/Riyadh).
  /// Optional [fromTime]/[toTime] as `HH:mm` — only sent together; when null, server uses full calendar days.
  Future<InventorySalesResponse> getCashierInventorySales(
    String token, {
    required DateTime from,
    required DateTime toInclusive,
    int? utcOffsetMinutes,
    String? fromTime,
    String? toTime,
  }) async {
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(toInclusive.year, toInclusive.month, toInclusive.day);
    final query = <String, String>{
      'from': _dateOnlyParam(fromDay),
      'to': _dateOnlyParam(toDay),
      if (utcOffsetMinutes != null)
        'utcOffsetMinutes': '$utcOffsetMinutes',
      if (fromTime != null &&
          fromTime.isNotEmpty &&
          toTime != null &&
          toTime.isNotEmpty) ...{
        'fromTime': fromTime,
        'toTime': toTime,
      },
    };
    try {
      final dynamic response = await _apiService.getWithQueryParams(
        ApiConstants.cashierInventorySalesEndpoint,
        query,
        token,
      );
      final Map<String, dynamic> normalized;
      if (response is List) {
        normalized = {'sales': List<dynamic>.from(response)};
      } else if (response is Map) {
        normalized = Map<String, dynamic>.from(response);
      } else {
        normalized = {};
      }
      return InventorySalesResponse.fromJson(normalized);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getPurchaseOrderNextReference(String token) async {
    final response = await _apiService.get(
      ApiConstants.cashierPurchaseOrderNextReferenceEndpoint,
      headers: _authHeaders(token),
    );
    final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    return '${map['reference'] ?? ''}'.trim();
  }

  Future<List<PoAffiliatedSupplier>> getLocalSuppliers(String token) async {
    final response = await _apiService.get(
      ApiConstants.cashierLocalSuppliersEndpoint,
      headers: _authHeaders(token),
    );
    final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    final rows = map['suppliers'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => PoAffiliatedSupplier.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Department>> getCashierDepartments(String token) async {
    final response = await _apiService.get(
      ApiConstants.cashierDepartmentsEndpoint,
      headers: _authHeaders(token),
    );
    final parsed = DepartmentResponse.fromJson(
      response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{},
    );
    return parsed.departments.where((d) => d.isActive && d.name.trim().isNotEmpty).toList();
  }

  Future<List<PoAffiliatedSupplier>> getPurchaseOrderSuppliers(
    String token,
  ) async {
    final response = await _apiService.get(
      ApiConstants.cashierPurchaseOrderSuppliersEndpoint,
      headers: _authHeaders(token),
    );
    final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    final rows = map['suppliers'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => PoAffiliatedSupplier.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<PoBranchProduct>> getPurchaseOrderProducts(
    String token, {
    String? supplierId,
  }) async {
    final query = <String, String>{};
    final sid = supplierId?.trim() ?? '';
    if (sid.isNotEmpty) query['supplierId'] = sid;
    final response = await _apiService.getWithQueryParams(
      ApiConstants.cashierPurchaseOrderProductsEndpoint,
      query,
      token,
    );
    final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    final rows = map['products'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => PoBranchProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> createPurchaseOrder(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiService.post(
      ApiConstants.cashierPurchaseOrdersEndpoint,
      body,
      headers: _authHeaders(token),
    );
    return response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{'success': true};
  }

  Future<List<PurchaseOrderSummary>> listPurchaseOrders(String token) async {
    final response = await _apiService.get(
      ApiConstants.cashierPurchaseOrdersEndpoint,
      headers: _authHeaders(token),
    );
    final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    final rows = map['invoices'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => PurchaseOrderSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<IncomingSupplierInvoiceSummary>> listIncomingPurchaseInvoices(
    String token,
  ) async {
    final response = await _apiService.get(
      ApiConstants.cashierIncomingPurchaseInvoicesEndpoint,
      headers: _authHeaders(token),
    );
    final map = response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{};
    final rows = map['invoices'] ?? map['rows'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) =>
            IncomingSupplierInvoiceSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<IncomingSupplierInvoiceDetail> getIncomingPurchaseInvoice(
    String token,
    String invoiceId,
  ) async {
    final response = await _apiService.get(
      ApiConstants.cashierIncomingPurchaseInvoiceDetailEndpoint(invoiceId),
      headers: _authHeaders(token),
    );
    return IncomingSupplierInvoiceDetail.fromJson(
      response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> receivePurchaseInvoice(
    String token,
    String invoiceId,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiService.post(
      ApiConstants.cashierReceivePurchaseInvoiceEndpoint(invoiceId),
      body,
      headers: _authHeaders(token),
    );
    return response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{'success': true};
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
}


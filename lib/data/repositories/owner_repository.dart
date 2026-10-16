import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../models/workshop_owner_models.dart';
import '../../utils/riyadh_business_range.dart';
import '../../views/Workshop owner/Suppliers/filter_affiliated_suppliers_models.dart';
import '../../views/Workshop owner/Suppliers/non_affiliated/non_affilidated_supplier_models.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

class OwnerRepository {
  final BaseApiService _apiService = BaseApiService();

  /// Riyadh calendar day `YYYY-MM-DD` (no device-TZ shift).
  static String calendarDateOnly(DateTime d) => riyadhCalendarDateOnly(d);

  /// Reports / dashboard range start → UTC ISO.
  /// [d]'s fields are treated as Asia/Riyadh wall clock (matches web).
  static String reportsRangeStartIso(DateTime d) => riyadhWallToApiIso(d);

  /// Reports / dashboard range end → UTC ISO (same minute precision as web).
  static String reportsRangeEndIso(DateTime d) => riyadhWallToApiIso(d);

  static Map<String, String> _reportsDateParams({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return {
      if (startDate != null) ...{
        'startDate': reportsRangeStartIso(startDate),
        'start_date': reportsRangeStartIso(startDate),
        // Same full ISO as web `riyadhRangeToApiIso` (not calendar-only).
        'dateFrom': reportsRangeStartIso(startDate),
        'date_from': reportsRangeStartIso(startDate),
      },
      if (endDate != null) ...{
        'endDate': reportsRangeEndIso(endDate),
        'end_date': reportsRangeEndIso(endDate),
        'dateTo': reportsRangeEndIso(endDate),
        'date_to': reportsRangeEndIso(endDate),
      },
    };
  }

  Future<dynamic> createBranch(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createBranchEndpoint,
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

  Future<dynamic> createDepartment(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createDepartmentEndpoint,
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

  Future<dynamic> createCorporateAccount(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.corporateRegisterEndpoint,
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

  Future<dynamic> getCorporateCustomers(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.corporateCustomersEndpoint,
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

  Future<dynamic> createCorporateUser(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createCorporateUserEndpoint,
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

  Future<dynamic> createTechnician(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createTechnicianEndpoint,
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

  Future<dynamic> createCashier(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createCashierEndpoint,
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

  Future<dynamic> createSupplier(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createSupplierEndpoint,
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

  Future<dynamic> createProduct(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createProductEndpoint,
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

  Future<dynamic> createCategory(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createCategoryEndpoint,
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

  Future<dynamic> getProductsCategories(String token, String type) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.getProductsCategoriesEndpoint}?type=$type',
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

  Future<dynamic> createSubCategory(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createSubCategoryEndpoint,
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

  Future<dynamic> getBranches(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.getBranchesEndpoint,
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

  // GET /workshop-catalog/branches/{branchId}/products
  // Returns: { success, branchId, products: [ { id, name, sku, departmentId,
  //   departmentName, categoryName, openingQty, currentQty, criticalStockPoint,
  //   workshopUnit, warehouseUnit, conversionFactor, salePrice,
  //   product.purchasePrice, isActive, uomProfileId } ] }
  Future<dynamic> getBranchProducts(String token, String branchId) async {
    try {
      final response = await _apiService.get(
        '/workshop-catalog/branches/$branchId/products',
        headers: {'Authorization': 'Bearer $token'},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/products — workshop-wide when [allBranches] is true (sums stock).
  Future<dynamic> getWorkshopStaffProducts(
    String token, {
    bool allBranches = false,
    String? branchId,
    String? workshopId,
  }) async {
    try {
      final params = <String, String>{
        if (allBranches && (branchId == null || branchId.isEmpty))
          'allBranches': 'true',
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (workshopId != null && workshopId.isNotEmpty) 'workshopId': workshopId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/products',
        params,
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/branches/{branchId}/products — same source as web Manage Inventory.
  /// Response is often nested `categories` / `uncategorizedProducts` (not a flat `products` list).
  Future<dynamic> getWorkshopStaffBranchProducts(
    String token,
    String branchId, {
    String? workshopId,
  }) async {
    try {
      final params = <String, String>{
        if (workshopId != null && workshopId.isNotEmpty) 'workshopId': workshopId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/branches/$branchId/products',
        params,
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Branch Catalog — departments
  Future<dynamic> getCatalogDepartments(String token) async {
    try {
      return await _apiService.get(
        ApiConstants.catalogDepartmentsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Branch Catalog — categories
  Future<dynamic> getCatalogCategories(String token) async {
    try {
      return await _apiService.get(
        ApiConstants.catalogCategoriesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Branch Catalog — products
  Future<dynamic> getCatalogProducts(
      String token, {
        bool allBranches = true,
        String? branchId,
      }) async {
    try {
      String endpoint = ApiConstants.productsEndpoint;
      if (branchId != null && branchId.isNotEmpty) {
        endpoint += '?branchId=$branchId';
      } else if (allBranches) {
        endpoint += '?allBranches=true';
      }
      return await _apiService.get(
        endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Branch Catalog — services
  Future<dynamic> getCatalogServices(
      String token, {
        bool allBranches = true,
        String? branchId,
      }) async {
    try {
      String endpoint = '/workshop-catalog/my/services';
      if (branchId != null && branchId.isNotEmpty) {
        endpoint += '?branchId=$branchId';
      } else if (allBranches) {
        endpoint += '?allBranches=true';
      }
      return await _apiService.get(
        endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getTechnicians(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.techniciansEndpoint,
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

  Future<dynamic> getEmployees(String token) async {
    try {
      final response = await _apiService.getWithQueryParams(
        ApiConstants.employeesEndpoint,
        const {'limit': '200', 'offset': '0'},
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getRoles(String token) async {
    try {
      return await _apiService.get(
        ApiConstants.rolesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createRole(Map<String, dynamic> data, String token) async {
    try {
      return await _apiService.post(
        ApiConstants.rolesEndpoint,
        data,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateRole(String token, String id, Map<String, dynamic> data) async {
    try {
      return await _apiService.patch(
        ApiConstants.roleByIdEndpoint(id),
        data,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteRole(String token, String id) async {
    try {
      return await _apiService.delete(
        ApiConstants.roleByIdEndpoint(id),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDepartments(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.departmentsEndpoint,
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

  Future<dynamic> getReferrers(String token, {String? search}) async {
    try {
      String endpoint = ApiConstants.referrersEndpoint;
      if (search != null && search.trim().isNotEmpty) {
        endpoint += '?search=${Uri.encodeQueryComponent(search.trim())}';
      }
      final response = await _apiService.get(
        endpoint,
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

  Future<dynamic> getBillingDashboard(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.billingDashboardEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getReportsAnalytics(
      String token, {
        bool allBranches = true,
        String? branchId,
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    try {
      final params = <String, String>{
        if (branchId != null && branchId.isNotEmpty) ...{
          'branchId': branchId,
          'branch_id': branchId,
        } else
          'allBranches': 'true',
        ..._reportsDateParams(startDate: startDate, endDate: endDate),
      };
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final endpoint =
          '${ApiConstants.reportsAnalyticsEndpoint}${query.isNotEmpty ? '?$query' : ''}';
      final response = await _apiService.get(
        endpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/reports/recent-orders — same params as web.
  Future<dynamic> getRecentOrders(
      String token, {
        bool allBranches = true,
        String? branchId,
        DateTime? startDate,
        DateTime? endDate,
        String? search,
        String? paymentMethod,
        int limit = 100,
        int offset = 0,
      }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (allBranches && (branchId == null || branchId.isEmpty))
          'allBranches': 'true',
        if (branchId != null && branchId.isNotEmpty) ...{
          'branchId': branchId,
          'branch_id': branchId,
        },
        ..._reportsDateParams(startDate: startDate, endDate: endDate),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
      };
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final endpoint =
          '/workshop-staff/reports/recent-orders${query.isNotEmpty ? '?$query' : ''}';
      final response = await _apiService.get(
        endpoint,
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

  /// GET /workshop-staff/reports/recent-orders/:invoiceId/pdf — same as web invoice preview.
  Future<dynamic> getRecentOrderInvoicePdf(
    String token,
    String invoiceId, {
    bool allBranches = true,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final id = invoiceId.trim();
      if (id.isEmpty) throw ArgumentError('invoiceId is required');
      final params = <String, String>{
        if (allBranches && (branchId == null || branchId.isEmpty))
          'allBranches': 'true',
        if (branchId != null && branchId.isNotEmpty) ...{
          'branchId': branchId,
          'branch_id': branchId,
        },
        ..._reportsDateParams(startDate: startDate, endDate: endDate),
      };
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final endpoint =
          '/workshop-staff/reports/recent-orders/${Uri.encodeComponent(id)}/pdf'
          '${query.isNotEmpty ? '?$query' : ''}';
      final response = await _apiService.get(
        endpoint,
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

  Future<dynamic> getPromoCodes(String token) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.promoCodesEndpoint}?isActive=true&limit=20&offset=0',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createPromoCode(String token, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConstants.createPromoCodeEndpoint,
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

  Future<dynamic> getCategories(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.categoriesEndpoint,
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

  Future<dynamic> getSubCategories(String token, String categoryId) async {
    try {
      final response = await _apiService.getWithQueryParams(
        ApiConstants.getSubCategoriesEndpoint,
        {'categoryId': categoryId},
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getProducts(String token, String workshopId, {String? departmentId}) async {
    try {
      String endpoint = '${ApiConstants.productsEndpoint}?workshopId=$workshopId';
      if (departmentId != null && departmentId.isNotEmpty) {
        endpoint += '&departmentId=$departmentId';
      }
      final response = await _apiService.get(
        endpoint,
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

  Future<dynamic> getProductUnits(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.productUnitsEndpoint,
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

  Future<dynamic> getWorkshopServices(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.workshopServicesEndpoint,
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

  Future<dynamic> createWorkshopService(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.workshopServicesEndpoint,
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

  Future<dynamic> getDashboardData(
    String token, {
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        ..._reportsDateParams(startDate: startDate, endDate: endDate),
      };
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final endpoint =
          '${ApiConstants.dashboardEndpoint}${query.isNotEmpty ? '?$query' : ''}';
      final response = await _apiService.get(
        endpoint,
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

  Future<dynamic> getSupplierStats(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.suppliersStatsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Supplier>> getSuppliers(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.suppliersEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response != null && response is Map<String, dynamic> && response['success'] == true) {
        final List<dynamic> suppliersData = response['suppliers'] ?? [];
        return suppliersData.map((json) => Supplier.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Workshop suppliers (linked-only list, richer fields) ─────────────────
  // GET /workshop-staff/suppliers?limit=500&offset=0
  // Same base path as [getSuppliers] above but parsed into the richer
  // [RegisteredSupplier] shape (contactPerson, crNumber, etc.) and wrapped
  // with currencyCode/total/limit/offset so the Suppliers tab can show more
  // detail without a second round trip.
  Future<WorkshopSuppliersResponse> getWorkshopSuppliers(
      String token, {
        int limit = 500,
        int offset = 0,
      }) async {
    final raw = await _apiService.get(
      ApiConstants.workshopSuppliersEndpoint(limit: limit, offset: offset),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ) as Map<String, dynamic>;
    return WorkshopSuppliersResponse.fromJson(raw);
  }

  // ── Registered suppliers (full platform registry, for the picker) ────────
  // GET /workshop-staff/suppliers/registered?limit=500&offset=0
  // Each entry carries isLinkedToWorkshop so the Add Supplier dialog can
  // show "Linked" vs a selectable Select button without extra lookups.
  Future<RegisteredSuppliersResponse> getRegisteredSuppliers(
      String token, {
        int limit = 500,
        int offset = 0,
      }) async {
    final raw = await _apiService.get(
      ApiConstants.registeredSuppliersEndpoint(limit: limit, offset: offset),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ) as Map<String, dynamic>;
    return RegisteredSuppliersResponse.fromJson(raw);
  }

  // ── Link existing registered suppliers to this workshop ──────────────────
  // POST /workshop-staff/suppliers/link  body: {"supplierIds": ["3","4"]}
  Future<LinkSuppliersResponse> linkSuppliers(
      List<String> supplierIds,
      String token,
      ) async {
    final raw = await _apiService.post(
      ApiConstants.linkSuppliersEndpoint,
      {'supplierIds': supplierIds},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ) as Map<String, dynamic>;
    return LinkSuppliersResponse.fromJson(raw);
  }

  // ── Create a workshop-only (local) supplier — no portal login ────────────
  // POST /workshop-staff/supplier/create
  // body: {"name","workshopLocalOnly":true,"mobile","address","vatId","notes"}
  Future<dynamic> createWorkshopOnlySupplier(
      String token, {
        required String name,
        String mobile = '',
        String address = '',
        String vatId = '',
        String notes = '',
      }) async {
    final payload = <String, dynamic>{
      'name': name,
      'workshopLocalOnly': true,
      if (mobile.isNotEmpty) 'mobile': mobile,
      if (address.isNotEmpty) 'address': address,
      if (vatId.isNotEmpty) 'vatId': vatId,
      if (notes.isNotEmpty) 'notes': notes,
    };
    final response = await _apiService.post(
      ApiConstants.createSupplierEndpoint,
      payload,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<dynamic> getAccountingSummary(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.accountingSummaryEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /accounts — same as web `getAccounts` (optional type / branchId).
  Future<List<Map<String, dynamic>>> getChartAccounts(
    String token, {
    String? type,
    String? branchId,
  }) async {
    final q = <String, String>{
      '_t': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    if (type != null && type.isNotEmpty) q['type'] = type;
    if (branchId != null && branchId.isNotEmpty) q['branchId'] = branchId;
    final qs = q.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final raw = await _apiService.get(
      '${ApiConstants.accountsListEndpoint}?$qs',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) {
      for (final key in ['data', 'list', 'items', 'accounts']) {
        final v = raw[key];
        if (v is List) {
          return v
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return [];
  }

  /// GET /accounts/:id/ledger — same as web `getAccountLedger`.
  Future<Map<String, dynamic>> getAccountLedger(
    String token,
    String accountId, {
    String? dateFrom,
    String? dateTo,
    String? branchId,
    String? expenseCategory,
    String? walletUserId,
    bool topupsOnly = false,
    int limit = 10000,
  }) async {
    final q = <String, String>{
      'limit': '$limit',
      '_t': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    if (dateFrom != null && dateFrom.isNotEmpty) q['dateFrom'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) q['dateTo'] = dateTo;
    if (branchId != null && branchId.isNotEmpty) q['branchId'] = branchId;
    if (expenseCategory != null && expenseCategory.isNotEmpty) {
      q['expenseCategory'] = expenseCategory;
    }
    if (walletUserId != null && walletUserId.isNotEmpty) {
      q['walletUserId'] = walletUserId;
    }
    if (topupsOnly) q['topupsOnly'] = 'true';

    final qs = q.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final id = Uri.encodeComponent(accountId);
    final raw = await _apiService.get(
      '${ApiConstants.accountsListEndpoint}/$id/ledger?$qs',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  /// GET /accounts/reports/pl — same as web `getPLReport`.
  Future<Map<String, dynamic>> getProfitAndLossReport(
    String token, {
    String? dateFrom,
    String? dateTo,
    String? branchId,
  }) async {
    final q = <String, String>{};
    if (dateFrom != null && dateFrom.isNotEmpty) q['dateFrom'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) q['dateTo'] = dateTo;
    if (branchId != null && branchId.isNotEmpty) q['branchId'] = branchId;
    q['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    final qs = q.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final raw = await _apiService.get(
      '${ApiConstants.accountsProfitLossEndpoint}?$qs',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  /// GET /accounts/branches — COA / P&L branch dropdown.
  Future<List<Map<String, dynamic>>> getAccountsBranches(String token) async {
    final raw = await _apiService.get(
      ApiConstants.accountsBranchesEndpoint,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  String _qs(Map<String, String> q) => q.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  Map<String, String> _auth(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Workshop commissions — same query contract as web (`allBranches=true`).
  Future<Map<String, dynamic>> getCommissionsSummary(
    String token, {
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    final q = <String, String>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (branchId == null || branchId.isEmpty) 'allBranches': 'true',
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final raw = await _apiService.get(
      '${ApiConstants.workshopCommissionsSummaryEndpoint}?${_qs(q)}',
      headers: _auth(token),
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<List<Map<String, dynamic>>> getCommissionsPendingByEmployee(
    String token, {
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    final q = <String, String>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (branchId == null || branchId.isEmpty) 'allBranches': 'true',
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
    };
    final raw = await _apiService.get(
      '${ApiConstants.workshopCommissionsPendingEndpoint}?${_qs(q)}',
      headers: _auth(token),
    );
    List? list;
    if (raw is Map) {
      list = raw['employees'] as List? ?? raw['data']?['employees'] as List?;
    } else if (raw is List) {
      list = raw;
    }
    return (list ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> getCommissionsList(
    String token, {
    String? status,
    String? employeeId,
    String? startDate,
    String? endDate,
    String? branchId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final q = <String, String>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (branchId == null || branchId.isEmpty) 'allBranches': 'true',
      if (status != null && status.isNotEmpty && status != 'all')
        'status': status,
      if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      'page': '$page',
      'pageSize': '$pageSize',
    };
    final raw = await _apiService.get(
      '${ApiConstants.workshopCommissionsListEndpoint}?${_qs(q)}',
      headers: _auth(token),
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'items': raw is List ? raw : [], 'total': 0};
  }

  Future<List<Map<String, dynamic>>> getCommissionRules(
    String token, {
    String? search,
  }) async {
    final path = (search != null && search.trim().isNotEmpty)
        ? '${ApiConstants.workshopCommissionsRulesEndpoint}?search=${Uri.encodeComponent(search.trim())}'
        : ApiConstants.workshopCommissionsRulesEndpoint;
    final raw = await _apiService.get(path, headers: _auth(token));
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getCommissionRuleServices(
      String token) async {
    final raw = await _apiService.get(
      ApiConstants.workshopCommissionsRuleServicesEndpoint,
      headers: _auth(token),
    );
    List? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list = raw['services'] as List? ?? raw['data'] as List?;
    }
    return (list ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createCommissionRule(
    String token,
    Map<String, dynamic> body,
  ) async {
    final raw = await _apiService.post(
      ApiConstants.workshopCommissionsRulesEndpoint,
      body,
      headers: _auth(token),
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<Map<String, dynamic>> updateCommissionRule(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async {
    final raw = await _apiService.patch(
      ApiConstants.workshopCommissionRuleEndpoint(id),
      body,
      headers: _auth(token),
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<void> deleteCommissionRule(String token, String id) async {
    await _apiService.delete(
      ApiConstants.workshopCommissionRuleEndpoint(id),
      headers: _auth(token),
    );
  }

  Future<Map<String, dynamic>> postCommissionsPayout(
    String token, {
    required List<String> commissionLineIds,
    required String payoutAccountId,
    String? notes,
  }) async {
    final raw = await _apiService.post(
      ApiConstants.workshopCommissionsPayoutEndpoint,
      {
        'commissionLineIds': commissionLineIds,
        'payoutAccountId': payoutAccountId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      headers: _auth(token),
    );
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Future<List<Map<String, dynamic>>> getCommissionPayoutAccounts(
    String token, {
    String? branchId,
  }) async {
    final q = <String, String>{
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      if (branchId == null || branchId.isEmpty) 'allBranches': 'true',
    };
    final raw = await _apiService.get(
      '${ApiConstants.workshopCommissionsPayoutAccountsEndpoint}?${_qs(q)}',
      headers: _auth(token),
    );
    List? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list = raw['accounts'] as List? ??
          raw['data'] as List? ??
          raw['items'] as List?;
    }
    return (list ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<dynamic> createPurchaseOrder(Map<String, dynamic> data, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.purchaseOrdersEndpoint,
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

  Future<dynamic> getAccountingTransactions(String token, String type) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.accountingTransactionsEndpoint}?type=$type',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPosMonitoring(
      String token, {
        DateTime? from,
        DateTime? to,
        int? viewerUtcOffsetMinutes,
      }) async {
    try {
      String ymd(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';

      final qp = <String, String>{};
      if (from != null) qp['from'] = ymd(from);
      if (to != null) qp['to'] = ymd(to);
      if (viewerUtcOffsetMinutes != null) {
        qp['viewerUtcOffsetMinutes'] = '$viewerUtcOffsetMinutes';
      }

      if (qp.isEmpty) {
        final response = await _apiService.get(
          ApiConstants.posMonitoringEndpoint,
          headers: {'Authorization': 'Bearer $token'},
        );
        return response;
      }
      return await _apiService.getWithQueryParams(
        ApiConstants.posMonitoringEndpoint,
        qp,
        token,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── Locker Management overview ───────────────────────────────────────────
  // Tuned for weak/slow connections:
  //  • 12s timeout with a single automatic retry (handles one dropped
  //    packet without making the user wait through two full timeouts).
  //  • Short-lived (30s) in-memory cache so rapid tab switches / rebuilds
  //    don't re-hit the network; `forceRefresh` (pull-to-refresh) bypasses it.
  Map<String, dynamic>? _lockerOverviewCache;
  DateTime? _lockerOverviewCachedAt;
  static const Duration _lockerOverviewCacheTtl = Duration(seconds: 30);
  static const Duration _lockerOverviewTimeout = Duration(seconds: 12);

  Future<dynamic> getLockerManagementOverview(
      String token, {
        bool forceRefresh = false,
      }) async {
    if (!forceRefresh &&
        _lockerOverviewCache != null &&
        _lockerOverviewCachedAt != null &&
        DateTime.now().difference(_lockerOverviewCachedAt!) <
            _lockerOverviewCacheTtl) {
      return _lockerOverviewCache;
    }
    try {
      final response = await _getLockerOverviewWithRetry(token);
      if (response is Map<String, dynamic> && response['success'] == true) {
        _lockerOverviewCache = response;
        _lockerOverviewCachedAt = DateTime.now();
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> _getLockerOverviewWithRetry(String token) async {
    Future<dynamic> call() => _apiService.get(
      ApiConstants.lockerManagementOverviewEndpoint,
      headers: {'Authorization': 'Bearer $token'},
    );
    try {
      return await call().timeout(_lockerOverviewTimeout);
    } on TimeoutException {
      return await call().timeout(_lockerOverviewTimeout);
    }
  }

  Future<PettyCashRequestsResponse> getPettyCashRequests(
      String token, {
        String? status,
        String? branchId,
        String? queue,
        int limit = 20,
        int offset = 0,
      }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;
      if (queue != null && queue.isNotEmpty) params['queue'] = queue;

      final response = await _apiService.getWithQueryParams(
        ApiConstants.workshopPettyCashRequestsEndpoint,
        params,
        token,
      );
      return PettyCashRequestsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<PettyCashRequestsResponse> getPettyCashHistory(
      String token, {
        String? status,
        String? branchId,
        int limit = 50,
        int offset = 0,
      }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;

      final response = await _apiService.getWithQueryParams(
        ApiConstants.workshopPettyCashHistoryEndpoint,
        params,
        token,
      );
      return PettyCashRequestsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /employee-expense/workshop-petty-cash?branchId=
  Future<List<Map<String, dynamic>>> getWorkshopPettyCashWallets(
      String token, {
        String? branchId,
      }) async {
    try {
      final params = <String, String>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        '/employee-expense/workshop-petty-cash',
        params,
        token,
      );
      final list = (response is Map ? response['wallets'] : null) ?? const [];
      return (list is List ? list : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// GET /employee-expense/workshop?limit=&branchId=
  Future<List<Map<String, dynamic>>> getWorkshopExpenseRequests(
      String token, {
        String? branchId,
        String? status,
        int limit = 100,
        int offset = 0,
      }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final response = await _apiService.getWithQueryParams(
        '/employee-expense/workshop',
        params,
        token,
      );
      final list = (response is Map ? response['items'] : null) ?? const [];
      return (list is List ? list : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// GET /employee-expense/issuance-targets
  Future<List<Map<String, dynamic>>> getExpenseIssuanceTargets(
      String token,
      ) async {
    try {
      final response = await _apiService.getWithQueryParams(
        '/employee-expense/issuance-targets',
        const <String, String>{},
        token,
      );
      final list = (response is Map ? response['users'] : null) ?? const [];
      return (list is List ? list : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// POST /employee-expense/issue
  Future<Map<String, dynamic>> issuePettyCash(
      String token, {
        required String userId,
        required String branchId,
        required double amount,
        required String payFromAccountId,
        String? description,
      }) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'branchId': branchId,
        'amount': amount,
        'payFromAccountId': payFromAccountId,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      };
      final response = await _apiService.post(
        '/employee-expense/issue',
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response is Map<String, dynamic>) return response;
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-accounting/lookups/cash-bank (same as web Issue modal)
  Future<List<Map<String, dynamic>>> getWorkshopAccountingCashBankAccounts(
      String token, {
        String? branchId,
      }) async {
    try {
      final params = <String, String>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-accounting/lookups/cash-bank',
        params,
        token,
      );
      final list = (response is Map ? response['accounts'] : null) ??
          (response is Map ? response['items'] : null) ??
          const [];
      return (list is List ? list : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/sales-returns
  /// [status] is the backend value directly ('pending' | 'completed' | 'rejected') — pass
  /// null/empty to fetch all statuses. [dateFrom]/[dateTo] are 'yyyy-MM-ddTHH:mm' strings.
  Future<WorkshopSalesReturnsResponse> getSalesReturns(
      String token, {
        String? status,
        String? branchId,
        String? dateFrom,
        String? dateTo,
        int limit = 100,
        int offset = 0,
      }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (branchId != null && branchId.isNotEmpty) params['branchId'] = branchId;
      if (dateFrom != null && dateFrom.isNotEmpty) params['dateFrom'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) params['dateTo'] = dateTo;

      final response = await _apiService.getWithQueryParams(
        ApiConstants.salesReturnsEndpoint,
        params,
        token,
      );
      return WorkshopSalesReturnsResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/affiliated-purchase-returns
  Future<AffiliatedPurchaseReturnsResponse> getAffiliatedPurchaseReturns(
      String token, {
        String? status,
        String? branchId,
      }) async {
    try {
      final params = <String, String>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        ApiConstants.affiliatedPurchaseReturnsEndpoint,
        params,
        token,
      );
      return AffiliatedPurchaseReturnsResponse.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/affiliated-purchase-returns/:id/approve
  Future<bool> approveAffiliatedPurchaseReturn(
      String token, String returnId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.affiliatedPurchaseReturnApproveEndpoint(returnId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }


  /// GET /workshop-staff/discounts
  /// Returns: WorkshopDiscountsResponse (summary + invoices list).
  Future<WorkshopDiscountsResponse> getDiscounts(
    String token, {
    String? dateFrom,
    String? dateTo,
    String? branchId,
    String? departmentId,
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      final params = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
      };
      if (dateFrom != null && dateFrom.isNotEmpty) {
        params['dateFrom'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        params['dateTo'] = dateTo;
      }
      if (branchId != null && branchId.isNotEmpty) {
        params['branchId'] = branchId;
      }
      if (departmentId != null && departmentId.isNotEmpty) {
        params['departmentId'] = departmentId;
      }

      final response = await _apiService.getWithQueryParams(
        ApiConstants.discountsEndpoint, // '/workshop-staff/discounts'
        params,
        token,
      );
      return WorkshopDiscountsResponse.fromJson(
          response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> approvePettyCashRequest(String token, String requestId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.workshopPettyCashApproveEndpoint(requestId),
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rejectPettyCashRequest(String token, String requestId, String rejectionReason) async {
    try {
      final response = await _apiService.post(
        ApiConstants.workshopPettyCashRejectEndpoint(requestId),
        {'rejectionReason': rejectionReason},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  // Promo Codes
  Future<dynamic> updatePromoCode(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.workshopPromoCodeByIdEndpoint(id),
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

  Future<dynamic> deletePromoCode(String token, String id) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.workshopPromoCodeByIdEndpoint(id),
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

  // Products
  Future<dynamic> updateProduct(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '/workshop-staff/product/$id',
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

  Future<dynamic> deleteProduct(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '/workshop-staff/product/$id',
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

  // Services
  Future<dynamic> updateService(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '/workshop-staff/service/$id',
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

  Future<dynamic> deleteService(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '/workshop-staff/service/$id',
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

  // Categories
  Future<dynamic> updateCategory(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.editCategoryEndpoint(id),
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

  Future<dynamic> updateCorporateAccount(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.editCorporateAccountEndpoint(id),
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

  Future<dynamic> deleteCategory(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.categoriesEndpoint}/$id',
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

  // Sub-Categories
  Future<dynamic> updateSubCategory(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '${ApiConstants.createSubCategoryEndpoint}/$id',
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

  Future<dynamic> deleteSubCategory(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.createSubCategoryEndpoint}/$id',
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

  // Employees
  Future<dynamic> updateTechnician(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '/workshop-staff/technician/$id',
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

  Future<dynamic> deleteTechnician(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '/workshop-staff/technician/$id',
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

  Future<dynamic> updateCashier(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '/workshop-staff/cashier/$id',
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

  Future<dynamic> deleteCashier(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '/workshop-staff/cashier/$id',
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

  // Branches
  Future<dynamic> updateBranch(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '/workshop-staff/branch/$id',
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

  Future<dynamic> deleteBranch(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.deleteBranchEndpoint}/$id',
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

  // Departments
  Future<dynamic> updateDepartment(String token, String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        '${ApiConstants.deleteDepartmentEndpoint}/$id',
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

  Future<dynamic> deleteDepartment(String token, String id) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.deleteDepartmentEndpoint}/$id',
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

  Future<dynamic> getMobileDashboard(
      String token, {
        String? branchId,
        DateTime? startDate,
        DateTime? endDate,
        int technicianLimit = 5,
        int lowStockLimit = 5,
      }) async {
    try {
      final params = <String, String>{
        'technicianLimit': technicianLimit.toString(),
        'lowStockLimit': lowStockLimit.toString(),
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        ..._reportsDateParams(startDate: startDate, endDate: endDate),
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/mobile-dashboard',
        params,
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getSupplierSalesInvoices(
      String token, {
        String? branchId,
        int limit = 1,
        int offset = 0,
      }) async {
    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/supplier-sales-invoices',
        params,
        token,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/admin-wallet-approvals?status=pending
  Future<AdminWalletApprovalsResponse> getAdminWalletApprovals(
      String token, {
        String? status,
        String? branchId,
      }) async {
    try {
      final params = <String, String>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        ApiConstants.adminWalletApprovalsEndpoint,
        params,
        token,
      );
      return AdminWalletApprovalsResponse.fromJson(
          response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/supplier-sales-invoices/:id/approve
  Future<bool> approveSupplierSalesInvoice(
      String token, String invoiceId) async {
    try {
      final response = await _apiService.post(
        '/workshop-staff/supplier-sales-invoices/$invoiceId/approve',
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/supplier-sales-invoices/:id/reject
  Future<bool> rejectSupplierSalesInvoice(
      String token, String invoiceId, String rejectionReason) async {
    try {
      final response = await _apiService.post(
        '/workshop-staff/supplier-sales-invoices/$invoiceId/reject',
        {'rejectionReason': rejectionReason},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/cash-bank/accounts?status=active
  Future<List<Map<String, dynamic>>> getCashBankAccounts(
      String token, {
        String? branchId,
        String status = 'active',
      }) async {
    try {
      final params = <String, String>{
        if (status.isNotEmpty) 'status': status,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/cash-bank/accounts',
        params,
        token,
      );
      final list = (response is Map ? response['accounts'] : null) ??
          (response is Map ? response['data'] : null);
      final accounts = list is List ? list : const [];
      return accounts
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// GET /workshop-staff/admin-wallet-approvals/budget-accounts
  Future<List<Map<String, dynamic>>> getAdminWalletBudgetAccounts(
      String token, {
        String? branchId,
      }) async {
    try {
      final params = <String, String>{
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/admin-wallet-approvals/budget-accounts',
        params,
        token,
      );
      final list = (response is Map ? response['accounts'] : null) ?? const [];
      return (list is List ? list : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/admin-wallet-approvals/:kind/:requestId/approve
  Future<bool> approveAdminWalletRequest(
      String token, {
        required String kind,
        required String requestId,
        Map<String, dynamic> body = const {},
      }) async {
    try {
      final response = await _apiService.post(
        '/workshop-staff/admin-wallet-approvals/$kind/$requestId/approve',
        body,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/admin-wallet-approvals/:kind/:requestId/reject
  Future<bool> rejectAdminWalletRequest(
      String token, {
        required String kind,
        required String requestId,
        required String rejectionReason,
      }) async {
    try {
      final response = await _apiService.post(
        '/workshop-staff/admin-wallet-approvals/$kind/$requestId/reject',
        {'rejectionReason': rejectionReason},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/sales-returns/{id}/approve
  Future<bool> approveSalesReturn(String token, String returnId) async {
    try {
      final response = await _apiService.post(
        '/workshop-staff/sales-returns/$returnId/approve',
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  /// POST /workshop-staff/sales-returns/{id}/reject
  Future<bool> rejectSalesReturn(
      String token, String returnId, String rejectionReason) async {
    try {
      final response = await _apiService.post(
        '/workshop-staff/sales-returns/$returnId/reject',
        {'rejectionReason': rejectionReason},
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response['success'] == true;
    } catch (e) {
      rethrow;
    }
  }

  Future<ActiveTechniciansResponse> getActiveTechnicians(
      String token, {
        String? branchId,
      }) async {
    try {
      final params = <String, String>{
        'isActive': 'true',
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };
      final response = await _apiService.getWithQueryParams(
        '/workshop-staff/technicians',
        params,
        token,
      );
      return ActiveTechniciansResponse.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ─── Workshop Profile ──────────────────────────────────────────────────────

  Future<dynamic> getWorkshopProfile(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.workshopProfileEndpoint,
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

  Future<dynamic> updateWorkshopProfile(
      String token, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch(
        ApiConstants.workshopProfileEndpoint,
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

  // ── Purchase Invoices ──────────────────────────────────────────────────────

  /// GET /workshop-suppliers/local/purchase-invoices
  /// Returns the `invoices` list from the local purchase invoices response.
  Future<List<Map<String, dynamic>>> getLocalPurchaseInvoices(
      String token, {
        int limit = 100,
        int offset = 0,
        String? branchId,
      }) async {
    try {
      final raw = await _apiService.get(
        ApiConstants.localPurchaseInvoicesEndpoint(
          limit: limit,
          offset: offset,
          branchId: branchId,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ) as Map<String, dynamic>;
      return _unwrapPurchaseInvoiceList(raw);
    } catch (e) {
      // Non-fatal — web also swallows local PI failures so affiliated rows still show.
      debugPrint('[OwnerRepository] getLocalPurchaseInvoices error: $e');
      return [];
    }
  }

  /// GET /workshop-staff/supplier-purchase-invoices
  /// Returns the `invoices` list from the supplier purchase invoices response.
  Future<List<Map<String, dynamic>>> getSupplierPurchaseInvoices(
      String token, {
        int limit = 100,
        int offset = 0,
        String? branchId,
      }) async {
    try {
      final raw = await _apiService.get(
        ApiConstants.supplierPurchaseInvoicesEndpoint(
          limit: limit,
          offset: offset,
          branchId: branchId,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ) as Map<String, dynamic>;
      return _unwrapPurchaseInvoiceList(raw);
    } catch (e) {
      rethrow;
    }
  }

  /// Match web `unwrapWorkshopSupplierPurchaseInvoiceList`.
  List<Map<String, dynamic>> _unwrapPurchaseInvoiceList(
      Map<String, dynamic> raw) {
    const keys = [
      'invoices',
      'purchaseInvoices',
      'purchase_invoices',
      'data',
      'items',
      'rows',
      'results',
    ];
    for (final k in keys) {
      final v = raw[k];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final nested = raw['data'];
      if (nested is Map && nested[k] is List) {
        return (nested[k] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    if (raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  // ── Supplier last purchase prices ─────────────────────────────────────────
  // GET /workshop-staff/suppliers/{supplierId}/last-purchase-prices?branchId=X
  // Fetched when user selects a vendor in the New Invoice form — gives the
  // "Last from supplier" price hint on each line item.
  Future<List<Map<String, dynamic>>> getSupplierLastPurchasePrices(
      String token, {
        required String supplierId,
        required String branchId,
      }) async {
    final raw = await _apiService.get(
      '/workshop-staff/suppliers/$supplierId/last-purchase-prices?branchId=$branchId',
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ) as Map<String, dynamic>;
    return ((raw['prices'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  // ── Supplier UOM rules ────────────────────────────────────────────────────
  // GET /workshop-staff/suppliers/{supplierId}/product-uom-rules?branchId=X
  // Fetched alongside last-purchase-prices — tells us warehouseUnit,
  // workshopUnit and conversionFactor for each product from this supplier.
  Future<List<Map<String, dynamic>>> getSupplierUomRules(
      String token, {
        required String supplierId,
        required String branchId,
      }) async {
    final raw = await _apiService.get(
      '/workshop-staff/suppliers/$supplierId/product-uom-rules?branchId=$branchId',
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ) as Map<String, dynamic>;
    return ((raw['rules'] as List?) ?? []).cast<Map<String, dynamic>>();
  }

  // ── Local (non-affiliated) suppliers for vendor dropdowns ─────────────────
  // GET /workshop-suppliers/local?limit=500&offset=0
  // Merged with affiliated suppliers in the ViewModel — no duplication.
  Future<List<Supplier>> getLocalSuppliers(String token, {int limit = 500}) async {
    try {
      final raw = await _apiService.get(
        ApiConstants.suppliersLocalEndpoint(limit: limit),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ) as Map<String, dynamic>;
      final list = (raw['suppliers'] as List?) ?? [];
      return list
          .map((j) => Supplier.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Non-fatal — return empty so the form still works with affiliated suppliers.
      debugPrint('[OwnerRepository] getLocalSuppliers error: $e');
      return [];
    }
  }

  // ── Supplier sales invoices for the Price Report tab ──────────────────────
  // GET /workshop-staff/supplier-sales-invoices?limit=100&offset=0
  // Same JSON shape as supplier purchase invoices — parsed identically.
  Future<List<Map<String, dynamic>>> getSupplierSalesInvoicesForReport(
      String token, {
        int limit = 100,
        int offset = 0,
        String? branchId,
      }) async {
    try {
      final raw = await _apiService.get(
        ApiConstants.supplierSalesInvoicesEndpoint(
          limit: limit,
          offset: offset,
          branchId: branchId,
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ) as Map<String, dynamic>;
      return ((raw['invoices'] as List?) ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      // Non-fatal — empty list keeps the rest of init running.
      debugPrint('[OwnerRepository] getSupplierSalesInvoicesForReport error: $e');
      return [];
    }
  }

  // ── Create supplier purchase invoice ──────────────────────────────────────
  // POST /workshop-staff/supplier-purchase-invoices
  // Returns the created purchaseInvoice wrapped in CreatePurchaseInvoiceResponse.
  Future<CreatePurchaseInvoiceResponse> createSupplierPurchaseInvoice(
      String token,
      Map<String, dynamic> payload,
      ) async {
    final raw = await _apiService.post(
      ApiConstants.createSupplierPurchaseInvoiceEndpoint,
      payload,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    ) as Map<String, dynamic>;
    return CreatePurchaseInvoiceResponse.fromJson(raw);
  }

  // ─── Inventory Adjustments ────────────────────────────────────────────────
  // GET /workshop-catalog/branches/{branchId}/products/{productId}/inventory-adjustments
  //     ?limit=0&offset=0&workshopId={workshopId}
  // Response: { success, data: { storedOpeningQty, currentQtyOnHand, isInfiniteQty, entries: [...] } }
  Future<dynamic> getInventoryAdjustments({
    required String token,
    required String branchId,
    required String productId,
    required String workshopId,
    int limit = 0,
    int offset = 0,
  }) async {
    try {
      final endpoint =
          '/workshop-catalog/branches/$branchId/products/$productId/inventory-adjustments'
          '?limit=$limit&offset=$offset&workshopId=$workshopId';
      final response = await _apiService.get(
        endpoint,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST /workshop-catalog/branches/{branchId}/products/{productId}/inventory-adjustments
  //      ?workshopId={workshopId}
  // Body: { newQty, reason, previousQty }
  // Response: { success, data: { logId, branchId, productId, previousQty, newQty, delta, reason, ... } }
  Future<dynamic> createInventoryAdjustment({
    required String token,
    required String branchId,
    required String productId,
    required String workshopId,
    required int previousQty,
    required int newQty,
    required String reason,
    String? note,
  }) async {
    try {
      final endpoint =
          '/workshop-catalog/branches/$branchId/products/$productId/inventory-adjustments'
          '?workshopId=$workshopId';
      final body = <String, dynamic>{
        'newQty': newQty,
        'reason': reason,
        'previousQty': previousQty,
        if (note != null && note.isNotEmpty) 'note': note,
      };
      final response = await _apiService.post(
        endpoint,
        body,
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

  // PATCH /workshop-catalog/branches/{branchId}/products/{productId}?workshopId={workshopId}
  // Used for:
  //   - criticalStockPoint: { "criticalStockPoint": 5 }
  //   - UOM rule:           { "warehouseUnit": "Box", "workshopUnit": "Liter", "conversionFactor": 12 }
  // Response: { success, data: { branchId, productId, ...updated fields } }
  Future<dynamic> patchBranchProduct({
    required String token,
    required String branchId,
    required String productId,
    required String workshopId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final endpoint =
          '/workshop-catalog/branches/$branchId/products/$productId'
          '?workshopId=$workshopId';
      final response = await _apiService.patch(
        endpoint,
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
}

// ─────────────────────────────────────────────────────────────────────────────

class CatalogRepository {
  final _api = BaseApiService();

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<BranchesResponse> getBranches(String token) async {
    final raw = await _api.get(
      ApiConstants.getBranchesEndpoint,
      headers: _authHeaders(token),
    );
    return BranchesResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<DepartmentsResponse> getCatalogDepartments(String token) async {
    final raw = await _api.get(
      ApiConstants.catalogDepartmentsEndpoint,
      headers: _authHeaders(token),
    );
    return DepartmentsResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<CategoriesResponse> getCatalogCategories(String token) async {
    final raw = await _api.get(
      ApiConstants.catalogCategoriesEndpoint,
      headers: _authHeaders(token),
    );
    return CategoriesResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<ProductsResponse> getCatalogProducts(
      String token, {
        bool allBranches = true,
        String? branchId,
      }) async {
    String endpoint = ApiConstants.productsEndpoint;
    if (branchId != null && branchId.isNotEmpty) {
      endpoint += '?branchId=$branchId';
    } else if (allBranches) {
      endpoint += '?allBranches=true';
    }
    final raw = await _api.get(endpoint, headers: _authHeaders(token));
    return ProductsResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<ServicesResponse> getCatalogServices(
      String token, {
        bool allBranches = true,
        String? branchId,
      }) async {
    String endpoint = '/workshop-catalog/my/services';
    if (branchId != null && branchId.isNotEmpty) {
      endpoint += '?branchId=$branchId';
    } else if (allBranches) {
      endpoint += '?allBranches=true';
    }
    final raw = await _api.get(endpoint, headers: _authHeaders(token));
    return ServicesResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<ProductUnitsResponse> getProductUnits(String token) async {
    final raw = await _api.get(
      ApiConstants.productUnitsEndpoint,
      headers: _authHeaders(token),
    );
    return ProductUnitsResponse.fromJson(raw as Map<String, dynamic>);
  }

  Future<dynamic> removeFromBranch(
      String token, {
        required String branchId,
        required String type,
        required String itemId,
      }) async {
    final raw = await _api.post(
      '${ApiConstants.branchCatalogEndpoint(branchId)}/remove',
      {'type': type, 'id': itemId},
      headers: _authHeaders(token),
    );
    return raw;
  }

  // ─── Toggle department active/inactive ────────────────────────────────────
  // PATCH /workshop-catalog/departments/{id}/active
  // Body: { "isActive": true | false }
  // Cascades to categories, products, services automatically.
  Future<ToggleDepartmentActiveResponse> toggleDepartmentActive(
      String token, {
        required String departmentId,
        required bool isActive,
      }) async {
    final raw = await _api.patch(
      '/workshop-catalog/departments/$departmentId/active',
      {'isActive': isActive},
      headers: _authHeaders(token),
    );
    return ToggleDepartmentActiveResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Create department ────────────────────────────────────────────────────
  // POST /workshop-staff/department/create
  // Body: { "name": "...", "isActive": true }
  Future<CreateDepartmentResponse> createDepartment2(
      String token, {
        required String name,
        bool isActive = true,
        String? branchId,
      }) async {
    final raw = await _api.post(
      '/workshop-staff/department/create',
      {
        'name': name,
        'isActive': isActive,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      },
      headers: _authHeaders(token),
    );
    return CreateDepartmentResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Create category ──────────────────────────────────────────────────────
  // POST /workshop-staff/category/create
  // Body: { "name": "...", "type": "product"|"service", "departmentId": "1", "isActive": true }
  Future<CreateCategoryResponse> createCatalogCategory(
      String token, {
        required String name,
        required String type,
        required String departmentId,
        bool isActive = true,
      }) async {
    final raw = await _api.post(
      '/workshop-staff/category/create',
      {
        'name': name,
        'type': type,
        'departmentId': departmentId,
        'isActive': isActive,
      },
      headers: _authHeaders(token),
    );
    return CreateCategoryResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Create product ───────────────────────────────────────────────────────
  // POST /workshop-staff/product/create
  // ⚠️ unit MUST be from GET /workshop-staff/product-units — 400 otherwise.
  Future<CreateProductResponse> createCatalogProduct(
      String token,
      CreateProductRequest request,
      ) async {
    final raw = await _api.post(
      '/workshop-staff/product/create',
      request.toJson(),
      headers: _authHeaders(token),
    );
    return CreateProductResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Remove workshop product adoption (all branches) ─────────────────────
  // DELETE /workshop-staff/workshop-products/{productId}  — catalog product id
  // Same as admin web "Remove from workshop".
  Future<DeleteProductResponse> removeWorkshopProduct(
    String token,
    String productId,
  ) async {
    final raw = await _api.delete(
      '/workshop-staff/workshop-products/$productId',
      headers: _authHeaders(token),
    );
    return DeleteProductResponse.fromJson(raw as Map<String, dynamic>);
  }

  /// POST /workshop-staff/workshop-products/bulk-remove
  Future<DeleteProductResponse> removeWorkshopProductsBulk(
    String token,
    List<String> productIds,
  ) async {
    final raw = await _api.post(
      '/workshop-staff/workshop-products/bulk-remove',
      {'productIds': productIds},
      headers: _authHeaders(token),
    );
    return DeleteProductResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Remove workshop service adoption (all branches) ─────────────────────
  // DELETE /workshop-staff/workshop-services/{serviceId}
  Future<DeleteProductResponse> removeWorkshopService(
    String token,
    String serviceId,
  ) async {
    final raw = await _api.delete(
      '/workshop-staff/workshop-services/$serviceId',
      headers: _authHeaders(token),
    );
    return DeleteProductResponse.fromJson(raw as Map<String, dynamic>);
  }

  /// POST /workshop-staff/workshop-services/bulk-remove
  Future<DeleteProductResponse> removeWorkshopServicesBulk(
    String token,
    List<String> serviceIds,
  ) async {
    final raw = await _api.post(
      '/workshop-staff/workshop-services/bulk-remove',
      {'serviceIds': serviceIds},
      headers: _authHeaders(token),
    );
    return DeleteProductResponse.fromJson(raw as Map<String, dynamic>);
  }

  @Deprecated('Use removeWorkshopProduct — same endpoint, catalog product id')
  Future<DeleteProductResponse> deleteWorkshopProduct(
    String token,
    String workshopProductId,
  ) =>
      removeWorkshopProduct(token, workshopProductId);

  // ─── Master catalog — departments ─────────────────────────────────────────
  // GET /workshop-catalog/catalog/departments?listScope=master
  // Returns all platform departments; inWorkshop=true means already in this workshop.
  Future<MasterDepartmentsResponse> getMasterDepartments(String token) async {
    final raw = await _api.get(
      '/workshop-catalog/catalog/departments?listScope=master',
      headers: _authHeaders(token),
    );
    return MasterDepartmentsResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Master catalog — categories ──────────────────────────────────────────
  // GET /workshop-catalog/catalog/categories?departmentId={id}&type=product&listScope=master
  Future<MasterCategoriesResponse> getMasterCategories(
      String token, {
        required String departmentId,
        String type = 'product',
      }) async {
    final raw = await _api.get(
      '/workshop-catalog/catalog/categories?departmentId=$departmentId&type=$type&listScope=master',
      headers: _authHeaders(token),
    );
    return MasterCategoriesResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Submit product catalog request ──────────────────────────────────────
  // POST /workshop-staff/catalog/product-request  ← correct path
  // ⚠️ /workshop-catalog/catalog/product-requests → 404 (wrong path)
  Future<CatalogProductRequestResponse> submitProductRequest(
      String token,
      CatalogProductRequest request,
      ) async {
    final raw = await _api.post(
      '/workshop-staff/catalog/product-request',
      request.toJson(),
      headers: _authHeaders(token),
    );
    return CatalogProductRequestResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Create service ───────────────────────────────────────────────────────
  // POST /workshop-staff/product/create  (same endpoint as products)
  // Backend distinguishes via the `type` field — always "service" here.
  // Payload: { workshopId, branchId, name, departmentId, categoryId?, unit,
  //   purchasePrice, salePrice, openingQty, minPriceCorporate,
  //   maxPriceCorporate, criticalStockPoint, kmTypeValue,
  //   allowDecimalQty, type:"service", isActive }
  Future<CreateServiceResponse> createCatalogService(
      String token,
      CreateServiceRequest request,
      ) async {
    final raw = await _api.post(
      ApiConstants.createServiceEndpoint,
      request.toJson(),
      headers: _authHeaders(token),
    );
    return CreateServiceResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ─── Master Catalog raw-list helpers (used by MasterCatalogViewModel) ────
  //
  // These return List<Map<String,dynamic>> so the ViewModel can convert them
  // directly into its own UI models without depending on typed response classes.

  /// GET /workshop-staff/branches
  /// Returns the raw branches array. Each item has at minimum: id, name.
  Future<List<Map<String, dynamic>>> fetchBranchesList(String token) async {
    final raw = await _api.get(
      ApiConstants.getBranchesEndpoint,
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return ((raw['branches'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// GET /workshop-catalog/catalog/departments?listScope=master
  /// Each item: { id, name, isActive, inWorkshop }
  /// inWorkshop=true means the department is already adopted into this workshop.
  Future<List<Map<String, dynamic>>> fetchMasterDeptsList(String token) async {
    final raw = await _api.get(
      '/workshop-catalog/catalog/departments?listScope=master',
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return ((raw['departments'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  /// GET /workshop-catalog/catalog/categories?listScope=master
  /// Returns ALL categories with no dept/type filter.
  /// Each item: { id, name, type, departmentId, departmentName, inWorkshop }
  /// Client-side filtering in the ViewModel avoids extra round-trips when the
  /// user changes the dept/type dropdowns.
  Future<List<Map<String, dynamic>>> fetchAllMasterCategoriesList(
      String token) async {
    final raw = await _api.get(
      '/workshop-catalog/catalog/categories?listScope=master',
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return ((raw['categories'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  // ─── owner_repository.dart — ADD these 4 methods inside CatalogRepository ────
// Paste them right before the final closing brace `}` of CatalogRepository
// (currently after fetchAllMasterCategoriesList, around line 1686).

  // ─── Master Catalog — products (all pages) ────────────────────────────────
  //
  // Fetches page 1 first, then batches remaining pages (5 at a time) until a
  // short page is received. All pages are merged into one flat list.
  //
  // Endpoints: GET /workshop-catalog/catalog/products
  //   ?page=N&pageSize=50&size=50&limit=50&offset=<(N-1)*50>&listScope=master
  Future<List<Map<String, dynamic>>> fetchAllMasterProductsList(
      String token) async {
    const int pageSize = 50;

    final firstRaw = await _api.get(
      '/workshop-catalog/catalog/products'
          '?page=1&pageSize=$pageSize&size=$pageSize'
          '&limit=$pageSize&offset=0&listScope=master',
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;

    final firstPage = ((firstRaw['products'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    if (firstPage.length < pageSize) return firstPage;

    final allPages = <Map<String, dynamic>>[...firstPage];
    int currentPage = 2;

    while (true) {
      const int batchSize = 5;
      final futures = List.generate(batchSize, (i) {
        final page = currentPage + i;
        final offset = (page - 1) * pageSize;
        return _api.get(
          '/workshop-catalog/catalog/products'
              '?page=$page&pageSize=$pageSize&size=$pageSize'
              '&limit=$pageSize&offset=$offset&listScope=master',
          headers: _authHeaders(token),
        );
      });

      final results = await Future.wait(futures);
      bool reachedEnd = false;

      for (final raw in results) {
        final page =
        (((raw as Map<String, dynamic>)['products'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        allPages.addAll(page);
        if (page.length < pageSize) {
          reachedEnd = true;
          break;
        }
      }

      if (reachedEnd) break;
      currentPage += batchSize;
    }

    return allPages;
  }

  // ─── My products — already-added IDs ─────────────────────────────────────
  //
  // GET /workshop-catalog/my/products?isActive=true
  // Returns a Set<String> of master-catalog product IDs already in this workshop,
  // used to mark isAddedToCurrentBranch on the master list.
  Future<Set<String>> fetchMyProductIds(String token) async {
    final raw = await _api.get(
      ApiConstants.masterMyProductsEndpoint,
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return ((raw['products'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map((p) => p['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // ─── Master Catalog — services (all pages) ────────────────────────────────
  //
  // Same batched-pagination strategy as fetchAllMasterProductsList.
  //
  // Endpoints: GET /workshop-catalog/catalog/services
  //   ?page=N&pageSize=50&size=50&limit=50&offset=<(N-1)*50>&listScope=master
  Future<List<Map<String, dynamic>>> fetchAllMasterServicesList(
      String token) async {
    const int pageSize = 50;

    final firstRaw = await _api.get(
      '/workshop-catalog/catalog/services'
          '?page=1&pageSize=$pageSize&size=$pageSize'
          '&limit=$pageSize&offset=0&listScope=master',
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;

    final firstPage = ((firstRaw['services'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    if (firstPage.length < pageSize) return firstPage;

    final allPages = <Map<String, dynamic>>[...firstPage];
    int currentPage = 2;

    while (true) {
      const int batchSize = 5;
      final futures = List.generate(batchSize, (i) {
        final page = currentPage + i;
        final offset = (page - 1) * pageSize;
        return _api.get(
          '/workshop-catalog/catalog/services'
              '?page=$page&pageSize=$pageSize&size=$pageSize'
              '&limit=$pageSize&offset=$offset&listScope=master',
          headers: _authHeaders(token),
        );
      });

      final results = await Future.wait(futures);
      bool reachedEnd = false;

      for (final raw in results) {
        final page =
        (((raw as Map<String, dynamic>)['services'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
        allPages.addAll(page);
        if (page.length < pageSize) {
          reachedEnd = true;
          break;
        }
      }

      if (reachedEnd) break;
      currentPage += batchSize;
    }

    return allPages;
  }

  // ─── My services — already-added IDs ─────────────────────────────────────
  //
  // GET /workshop-catalog/my/services?isActive=true
  // Returns a Set<String> of master-catalog service IDs already in this workshop.
  Future<Set<String>> fetchMyServiceIds(String token) async {
    final raw = await _api.get(
      ApiConstants.masterMyServicesEndpoint,
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return ((raw['services'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map((s) => s['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  // ─── Preview product dependencies ────────────────────────────────────────
  // POST /workshop-catalog/products/preview-dependencies
  // Body:  { "productIds": ["651", ...] }
  // Response: { "success": true, "missing": { "departments": [...], "categories": [...] } }
  Future<Map<String, dynamic>> previewProductDependencies(
      String token, {
        required List<String> productIds,
      }) async {
    final raw = await _api.post(
      '/workshop-catalog/products/preview-dependencies',
      {'productIds': productIds},
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return raw;
  }

  // ─── Add products to branches ─────────────────────────────────────────────
  // POST /workshop-catalog/branches/products
  // Body:  { "items": [{ "productId": "651", "openingQty": 0, "criticalStockPoint": 3 }],
  //           "branchIds": ["13"] }
  // Response: { "success": true, "added": { departments, categories, products, services },
  //             "skipped": [...] }
  Future<Map<String, dynamic>> addProductsToBranches(
      String token, {
        required List<Map<String, dynamic>> items, // [{productId, openingQty, criticalStockPoint}]
        required List<String> branchIds,
      }) async {
    final raw = await _api.post(
      '/workshop-catalog/branches/products',
      {'items': items, 'branchIds': branchIds},
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return raw;
  }

  // ─── Preview service dependencies ────────────────────────────────────────
  // POST /workshop-catalog/services/preview-dependencies
  // Body:  { "serviceIds": ["76", "75"] }
  // Response: { "success": true, "missing": { "departments": [...], "categories": [...] } }
  Future<Map<String, dynamic>> previewServiceDependencies(
      String token, {
        required List<String> serviceIds,
      }) async {
    final raw = await _api.post(
      '/workshop-catalog/services/preview-dependencies',
      {'serviceIds': serviceIds},
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return raw;
  }

  // ─── Add services to branches ─────────────────────────────────────────────
  // POST /workshop-catalog/branches/services
  // Body:  { "items": [{ "serviceId": "76" }, { "serviceId": "75" }],
  //           "branchIds": ["13"] }
  // Response: { "success": true, "added": { departments, categories, products, services },
  //             "skipped": [...] }
  Future<Map<String, dynamic>> addServicesToBranches(
      String token, {
        required List<String> serviceIds,
        required List<String> branchIds,
      }) async {
    final items = serviceIds.map((id) => {'serviceId': id}).toList();
    final raw = await _api.post(
      ApiConstants.masterAddServicesToBranchesEndpoint,
      {'items': items, 'branchIds': branchIds},
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return raw;
  }

  // ─── Add departments to branches ──────────────────────────────────────────
  // POST /workshop-catalog/branches/departments
  // payload: {
  //   "departmentIds": ["3","4"],
  //   "categorySelections": [
  //     { "departmentId": "3", "categoryIds": "all" },
  //     { "departmentId": "4", "categoryIds": ["38"] }
  //   ],
  //   "branchIds": ["13"]
  // }
  Future<Map<String, dynamic>> addDepartmentsToBranches(
      String token, {
        required List<String> departmentIds,
        required List<Map<String, dynamic>> categorySelections,
        required List<String> branchIds,
      }) async {
    final raw = await _api.post(
      ApiConstants.masterAddDepartmentsToBranchesEndpoint,
      {
        'departmentIds': departmentIds,
        'categorySelections': categorySelections,
        'branchIds': branchIds,
      },
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return raw;
  }

  // ─── Add categories to branches ───────────────────────────────────────────
  // POST /workshop-catalog/branches/categories
  // payload: { "categoryIds": ["34"], "branchIds": ["13"] }
  Future<Map<String, dynamic>> addCategoriesToBranches(
      String token, {
        required List<String> categoryIds,
        required List<String> branchIds,
      }) async {
    final raw = await _api.post(
      ApiConstants.masterAddCategoriesToBranchesEndpoint,
      {
        'categoryIds': categoryIds,
        'branchIds': branchIds,
      },
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return raw;
  }

  // ─── Fetch categories per department (for dept sheet live picker) ──────────
  // GET /workshop-catalog/catalog/categories?departmentId=3&listScope=master
  Future<List<Map<String, dynamic>>> fetchCategoriesByDept(
      String token, {
        required String departmentId,
      }) async {
    final raw = await _api.get(
      '/workshop-catalog/catalog/categories?departmentId=$departmentId&listScope=master',
      headers: _authHeaders(token),
    ) as Map<String, dynamic>;
    return ((raw['categories'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Affiliated Suppliers
// ─────────────────────────────────────────────────────────────────────────────

class AffiliatedSuppliersRepository {
  final _api = BaseApiService();

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  // GET /workshop-suppliers/affiliated?branchId=
  // Returns: { success, total, suppliers: [ { serial, id, supplierId,
  //   supplierName, mobile, email, registrationType, branchId, branchName,
  //   openingBalance, openingBalanceDate, isActive, finalBalance, createdAt } ] }
  Future<AffiliatedSuppliersResponse> getAffiliatedSuppliers(
    String token, {
    String? branchId,
  }) async {
    final qs = (branchId != null && branchId.isNotEmpty)
        ? '?branchId=$branchId'
        : '';
    final raw = await _api.get(
      '${ApiConstants.affiliatedSuppliersEndpoint}$qs',
      headers: _authHeaders(token),
    );
    return AffiliatedSuppliersResponse.fromJson(raw as Map<String, dynamic>);
  }

  // GET /workshop-suppliers/affiliated/{supplierId}/ledger?from=yyyy-MM-dd&to=yyyy-MM-dd
  // NOTE: uses `supplierId` (the underlying supplier id), not the affiliation
  // link `id`.
  // Returns: { success, header: {...}, openingBalance, rows: [...], totals: {...} }
  Future<AffiliatedLedgerResponse> getAffiliatedSupplierLedger(
      String token, {
        required String supplierId,
        required String from,
        required String to,
      }) async {
    final endpoint = ApiConstants.affiliatedSupplierLedgerEndpoint(
      supplierId,
      from: from,
      to: to,
    );
    final raw = await _api.get(endpoint, headers: _authHeaders(token));
    return AffiliatedLedgerResponse.fromJson(raw as Map<String, dynamic>);
  }

  // PATCH /workshop-suppliers/affiliated/{id}
  // NOTE: uses the affiliation link `id`, not the underlying `supplierId`.
  // Body: { "isActive": true | false }
  // Returns: { success, id, isActive, branchId }
  Future<ToggleAffiliatedSupplierActiveResponse>
  toggleAffiliatedSupplierActive(
      String token, {
        required String id,
        required bool isActive,
      }) async {
    final raw = await _api.patch(
      ApiConstants.affiliatedSupplierActiveEndpoint(id),
      {'isActive': isActive},
      headers: _authHeaders(token),
    );
    return ToggleAffiliatedSupplierActiveResponse.fromJson(
        raw as Map<String, dynamic>);
  }

  // GET /workshop-suppliers/affiliated/available?limit=...&offset=...
  // Registered suppliers not yet (necessarily) linked to this workshop — the
  // picker list for "Add new supplier". Each item carries isLinkedToWorkshop
  // so already-linked suppliers can be shown as non-selectable.
  // Returns: { success, total, limit, offset, suppliers: [ { id, name,
  //   mobile, email, vatId, crNumber, contactPerson, registrationType,
  //   isActive, isLinkedToWorkshop } ] }
  Future<AvailableAffiliatedSuppliersResponse> getAvailableAffiliatedSuppliers(
      String token, {
        int limit = 500,
        int offset = 0,
      }) async {
    final raw = await _api.get(
      '/workshop-suppliers/affiliated/available?limit=$limit&offset=$offset',
      headers: _authHeaders(token),
    );
    return AvailableAffiliatedSuppliersResponse.fromJson(
        raw as Map<String, dynamic>);
  }

  // POST /workshop-suppliers/affiliated
  // Body: { branchId, items: [ { supplierId, openingBalance, openingBalanceDate } ] }
  // Returns: { success, message, linkedCount, linked: [...] }
  Future<CreateAffiliatedSuppliersResponse> createAffiliatedSuppliers(
      String token, {
        required String branchId,
        required List<Map<String, dynamic>> items,
      }) async {
    final raw = await _api.post(
      ApiConstants.affiliatedSuppliersEndpoint,
      {
        'branchId': branchId,
        'items': items,
      },
      headers: _authHeaders(token),
    );
    return CreateAffiliatedSuppliersResponse.fromJson(
        raw as Map<String, dynamic>);
  }
}


class NonAffiliatedSuppliersRepository {
  final BaseApiService _api = BaseApiService();

  static const Duration _timeout = Duration(seconds: 12);

  // ── tiny in-memory cache (per app session, keyed by branch) ───────────────
  NonAffiliatedSuppliersResponse? _cachedList;
  DateTime? _cachedAt;
  String? _cachedBranchId;
  static const _cacheTtl = Duration(minutes: 2);

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<T> _withRetry<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      // one quick retry — handles a single dropped packet on weak signal
      return await call().timeout(_timeout);
    }
  }

  void _invalidateCache() {
    _cachedList = null;
    _cachedAt = null;
    _cachedBranchId = null;
  }

  // ── GET /workshop-suppliers/local?branchId= ──────────────────────────────
  Future<NonAffiliatedSuppliersResponse> getSuppliers(
    String token, {
    String? branchId,
    bool forceRefresh = false,
  }) async {
    final scopedBranch =
        (branchId != null && branchId.isNotEmpty) ? branchId : null;
    if (!forceRefresh &&
        _cachedList != null &&
        _cachedAt != null &&
        _cachedBranchId == scopedBranch &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cachedList!;
    }
    final qs = scopedBranch != null ? '?branchId=$scopedBranch' : '';
    final raw = await _withRetry(
      () => _api.get(
        '${ApiConstants.nonAffiliatedSuppliersEndpoint}$qs',
        headers: _authHeaders(token),
      ),
    );
    final parsed =
        NonAffiliatedSuppliersResponse.fromJson(raw as Map<String, dynamic>);
    _cachedList = parsed;
    _cachedAt = DateTime.now();
    _cachedBranchId = scopedBranch;
    return parsed;
  }

  // ── GET /workshop-suppliers/local/{id}/ledger?from&to ────────────────────
  Future<NonAffiliatedLedgerResponse> getLedger(
      String token, {
        required String supplierId,
        required String from,
        required String to,
      }) async {
    final raw = await _withRetry(
          () => _api.get(
        ApiConstants.nonAffiliatedSupplierLedgerEndpoint(
          supplierId,
          from: from,
          to: to,
        ),
        headers: _authHeaders(token),
      ),
    );
    return NonAffiliatedLedgerResponse.fromJson(raw as Map<String, dynamic>);
  }

  // ── POST /workshop-suppliers/local ───────────────────────────────────────
  // Body: { name, phone, email, vatId, contactPerson, branchId,
  //         openingBalance, openingBalanceDate }
  Future<CreateNonAffiliatedSupplierResponse> createSupplier(
      String token, {
        required String name,
        String? phone,
        String? email,
        String? vatId,
        String? crNumber,
        String? contactPerson,
        String? address,
        String? branchId,
        double openingBalance = 0,
        String? openingBalanceDate,
      }) async {
    final body = <String, dynamic>{
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (vatId != null && vatId.isNotEmpty) 'vatId': vatId,
      if (crNumber != null && crNumber.isNotEmpty) 'crNumber': crNumber,
      if (contactPerson != null && contactPerson.isNotEmpty)
        'contactPerson': contactPerson,
      if (address != null && address.isNotEmpty) 'address': address,
      if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      'openingBalance': openingBalance,
      if (openingBalanceDate != null) 'openingBalanceDate': openingBalanceDate,
    };
    final raw = await _withRetry(
          () => _api.post(
        ApiConstants.nonAffiliatedSuppliersEndpoint,
        body,
        headers: _authHeaders(token),
      ),
    );
    _invalidateCache();
    return CreateNonAffiliatedSupplierResponse.fromJson(
        raw as Map<String, dynamic>);
  }

  // ── PATCH /workshop-suppliers/local/{id} — edit info ─────────────────────
  // Body: { name, phone, email, address, vatId, crNumber, contactPerson, branchId }
  Future<UpdateNonAffiliatedSupplierResponse> updateSupplierInfo(
      String token, {
        required String id,
        required String name,
        String? phone,
        String? email,
        String? address,
        String? vatId,
        String? crNumber,
        String? contactPerson,
        String? branchId,
      }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone ?? '',
      'email': email ?? '',
      'address': address ?? '',
      'vatId': vatId ?? '',
      'crNumber': crNumber ?? '',
      'contactPerson': contactPerson ?? '',
      if (branchId != null) 'branchId': branchId,
    };
    final raw = await _withRetry(
          () => _api.patch(
        ApiConstants.nonAffiliatedSupplierByIdEndpoint(id),
        body,
        headers: _authHeaders(token),
      ),
    );
    _invalidateCache();
    return UpdateNonAffiliatedSupplierResponse.fromJson(
        raw as Map<String, dynamic>);
  }

  // ── PATCH /workshop-suppliers/local/{id} — toggle active ─────────────────
  // Body: { isActive }
  Future<UpdateNonAffiliatedSupplierResponse> toggleActive(
      String token, {
        required String id,
        required bool isActive,
      }) async {
    final raw = await _withRetry(
          () => _api.patch(
        ApiConstants.nonAffiliatedSupplierByIdEndpoint(id),
        {'isActive': isActive},
        headers: _authHeaders(token),
      ),
    );
    _invalidateCache();
    return UpdateNonAffiliatedSupplierResponse.fromJson(
        raw as Map<String, dynamic>);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models — Create Service
// Mirrors CreateProductRequest/Response but forces type = 'service'.
// Defined here (not in workshop_owner_models.dart) to keep all catalog-repo
// additions in one place.
// ─────────────────────────────────────────────────────────────────────────────

class CreateServiceRequest {
  final String workshopId;
  final String branchId;
  final String name;
  final String departmentId;
  final String? categoryId;
  final String unit;
  final double purchasePrice;
  final double salePrice;
  final int openingQty;
  final double minPriceCorporate;
  final double maxPriceCorporate;
  final int criticalStockPoint;
  final double kmTypeValue;
  final bool allowDecimalQty;
  final bool isActive;

  const CreateServiceRequest({
    required this.workshopId,
    required this.branchId,
    required this.name,
    required this.departmentId,
    this.categoryId,
    required this.unit,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.openingQty = 0,
    this.minPriceCorporate = 0,
    this.maxPriceCorporate = 0,
    this.criticalStockPoint = 0,
    this.kmTypeValue = 0,
    this.allowDecimalQty = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'workshopId': workshopId,
    'branchId': branchId,
    'name': name,
    'departmentId': departmentId,
    if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
    'unit': unit,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'openingQty': openingQty,
    'minPriceCorporate': minPriceCorporate,
    'maxPriceCorporate': maxPriceCorporate,
    'criticalStockPoint': criticalStockPoint,
    'kmTypeValue': kmTypeValue,
    'allowDecimalQty': allowDecimalQty,
    'type': 'service', // always service — never overrideable
    'isActive': isActive,
  };
}

class CreatedServiceItem {
  final String id;
  final String name;
  final String unit;
  final String departmentId;
  final String? categoryId;
  final double purchasePrice;
  final double salePrice;
  final double salePriceBeforeVat;
  final int openingQty;
  final int criticalStockPoint;
  final double kmTypeValue;
  final bool allowDecimalQty;
  final double minPriceCorporate;
  final double maxPriceCorporate;
  final bool isActive;

  const CreatedServiceItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.departmentId,
    this.categoryId,
    required this.purchasePrice,
    required this.salePrice,
    required this.salePriceBeforeVat,
    required this.openingQty,
    required this.criticalStockPoint,
    required this.kmTypeValue,
    required this.allowDecimalQty,
    required this.minPriceCorporate,
    required this.maxPriceCorporate,
    required this.isActive,
  });

  factory CreatedServiceItem.fromJson(Map<String, dynamic> j) =>
      CreatedServiceItem(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        unit: j['unit']?.toString() ?? '',
        departmentId: j['departmentId']?.toString() ?? '',
        categoryId: j['categoryId']?.toString(),
        purchasePrice: (j['purchasePrice'] as num?)?.toDouble() ?? 0,
        salePrice: (j['salePrice'] as num?)?.toDouble() ?? 0,
        salePriceBeforeVat: (j['salePriceBeforeVat'] as num?)?.toDouble() ?? 0,
        openingQty: (j['openingQty'] as num?)?.toInt() ?? 0,
        criticalStockPoint: (j['criticalStockPoint'] as num?)?.toInt() ?? 0,
        kmTypeValue: (j['kmTypeValue'] as num?)?.toDouble() ?? 0,
        allowDecimalQty: j['allowDecimalQty'] as bool? ?? false,
        minPriceCorporate: (j['minPriceCorporate'] as num?)?.toDouble() ?? 0,
        maxPriceCorporate: (j['maxPriceCorporate'] as num?)?.toDouble() ?? 0,
        isActive: j['isActive'] as bool? ?? true,
      );
}

class CreateServiceResponse {
  final bool success;
  final String message;
  final CreatedServiceItem? service;

  const CreateServiceResponse({
    required this.success,
    required this.message,
    this.service,
  });

  factory CreateServiceResponse.fromJson(Map<String, dynamic> j) =>
      CreateServiceResponse(
        success: j['success'] as bool? ?? false,
        message: j['message']?.toString() ?? '',
        // API returns created item under "product" key (same endpoint as products)
        service: j['product'] != null
            ? CreatedServiceItem.fromJson(j['product'] as Map<String, dynamic>)
            : null,
      );
}


// =============================================================================
// Models — Create Supplier Purchase Invoice
// =============================================================================

class CreatedInvoiceSummary {
  final String id;
  final String invoiceNumber;
  final String status;
  final String issueDate;
  final String dueDate;
  final String branchId;
  final String supplierId;
  final String supplierName;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final double balance;

  const CreatedInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    required this.branchId,
    required this.supplierId,
    required this.supplierName,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    required this.balance,
  });

  factory CreatedInvoiceSummary.fromJson(Map<String, dynamic> j) {
    final supplier = j['supplier'] as Map<String, dynamic>? ?? {};
    return CreatedInvoiceSummary(
      id:            j['id']?.toString() ?? '',
      invoiceNumber: j['invoiceNumber']?.toString() ?? '',
      status:        j['status']?.toString() ?? 'pending',
      issueDate:     j['issueDate']?.toString() ?? '',
      dueDate:       j['dueDate']?.toString() ?? '',
      branchId:      j['branchId']?.toString() ?? j['branch_id']?.toString() ?? '',
      supplierId:    j['supplierId']?.toString() ?? '',
      supplierName:  supplier['name']?.toString() ?? '',
      subtotal:      _d(j['subtotal']),
      taxAmount:     _d(j['taxAmount']),
      grandTotal:    _d(j['grandTotal']),
      balance:       _d(j['balance']),
    );
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class CreatePurchaseInvoiceResponse {
  final bool success;
  final CreatedInvoiceSummary? invoice;
  final bool autoApplied;

  const CreatePurchaseInvoiceResponse({
    required this.success,
    this.invoice,
    this.autoApplied = false,
  });

  factory CreatePurchaseInvoiceResponse.fromJson(Map<String, dynamic> j) =>
      CreatePurchaseInvoiceResponse(
        success:     j['success'] as bool? ?? false,
        // API returns full invoice under "purchaseInvoice" key
        invoice:     j['purchaseInvoice'] != null
            ? CreatedInvoiceSummary.fromJson(
            j['purchaseInvoice'] as Map<String, dynamic>)
            : null,
        autoApplied: j['autoApplied'] as bool? ?? false,
      );
}
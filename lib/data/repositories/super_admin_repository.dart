import '../../models/super_admin_branches_api_model.dart';
import '../../models/super_admin_users_api_model.dart';
import '../../models/super_admin_products_api_model.dart';
import '../../models/super_admin_departments_api_model.dart';
import '../../models/super_admin_corporate_customers_api_model.dart';
import '../network/api_constants.dart';
import '../network/base_api_service.dart';

class SuperAdminRepository {
  final BaseApiService _apiService = BaseApiService();

  Future<SuperAdminBranchesResponse> getBranches(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.superAdminBranchesEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return SuperAdminBranchesResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<SuperAdminUsersResponse> getUsers(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.superAdminUsersEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return SuperAdminUsersResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<SuperAdminProductsResponse> getProducts(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.superAdminProductsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return SuperAdminProductsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<SuperAdminDepartmentsResponse> getDepartments(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.superAdminDepartmentsEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return SuperAdminDepartmentsResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<SuperAdminCorporateCustomersResponse> getCorporateClients(String token) async {
    try {
      final response = await _apiService.get(
        ApiConstants.superAdminCorporateCustomersEndpoint,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return SuperAdminCorporateCustomersResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}

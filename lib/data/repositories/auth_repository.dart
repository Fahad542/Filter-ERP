import '../network/api_constants.dart';
import '../network/base_api_service.dart';
import '../../models/auth_response_model.dart';

class AuthRepository {
  final BaseApiService _apiService = BaseApiService();


  Future<AuthResponse> _postLogin(
    String endpoint,
    String email,
    String password,
  ) {
    return BaseApiService.runWithoutUnauthorizedLogout(() async {
      final response = await _apiService.post(
        endpoint,
        {
          'email': email,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response);
    });
  }

  Future<AuthResponse> login(String email, String password) {
    return _postLogin(ApiConstants.loginEndpoint, email, password);
  }



  Future<dynamic> cashierLogout(String token) async {
    final response = await _apiService.post(
      ApiConstants.cashierLogoutEndpoint,
      const <String, dynamic>{},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<AuthResponse> lockerLogin(String email, String password) {
    return _postLogin(ApiConstants.lockerLoginEndpoint, email, password);
  }

  Future<AuthResponse> adminLogin(String email, String password) {
    return _postLogin(ApiConstants.adminLoginEndpoint, email, password);
  }

  Future<AuthResponse> superAdminLogin(String email, String password) {
    return _postLogin(ApiConstants.superAdminLoginEndpoint, email, password);
  }

  Future<AuthResponse> registerWorkshopOwner({
    required String name,
    required String email,
    required String password,
    required String ownerName,
    required String mobile,
    required String taxId,
    required String address,
    required double gpsLat,
    required double gpsLng,
  }) async {
    return BaseApiService.runWithoutUnauthorizedLogout(() async {
      final response = await _apiService.post(
        ApiConstants.adminRegisterEndpoint,
        {
          'name': name,
          'email': email,
          'password': password,
          'ownerName': ownerName,
          'mobile': mobile,
          'taxId': taxId,
          'address': address,
          'gpsLat': gpsLat,
          'gpsLng': gpsLng,
        },
      );
      return AuthResponse.fromJson(response);
    });
  }

  Future<AuthResponse> technicianLogin(String email, String password) {
    return _postLogin(ApiConstants.technicianLoginEndpoint, email, password);
  }

  /// Supplier portal login — body uses [mobileOrEmail] (email or phone).
  Future<AuthResponse> supplierLogin(String mobileOrEmail, String password) {
    return BaseApiService.runWithoutUnauthorizedLogout(() async {
      final response = await _apiService.post(
        ApiConstants.supplierLoginEndpoint,
        {
          'mobileOrEmail': mobileOrEmail,
          'password': password,
        },
      );
      return AuthResponse.fromJson(response);
    });
  }

  Future<dynamic> openSession(String email, String password, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.openSessionEndpoint,
        {
          'email': email,
          'password': password,
          'clientOpenedAt': DateTime.now().toIso8601String(),
        },
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

  Future<dynamic> closeSession(String email, String password, String token) async {
    try {
      final response = await _apiService.post(
        ApiConstants.closeSessionEndpoint,
        {
          'email': email,
          'password': password,
          'clientClosedAt': DateTime.now().toIso8601String(),
        },
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

  Future<dynamic> getCurrentSession(String email, String password, String token) async {
    try {
      final response = await _apiService.getWithBody(
        ApiConstants.currentSessionEndpoint,
        {
          'email': email,
          'password': password,
        },
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

  /// `GET /cashier/session/current` — uses stored credentials when present.
  Future<dynamic> getCurrentSessionAuthorized(
    String token, {
    String? email,
    String? password,
  }) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    return BaseApiService.runWithoutUnauthorizedLogout(
      () => _apiService.get(
        ApiConstants.currentSessionEndpoint,
        headers: headers,
      ),
    );
  }
}

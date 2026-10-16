import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../utils/api_logger.dart';
import 'api_constants.dart';

class BaseApiService {
  static Future<void> Function()? _onUnauthorized;
  static bool _isHandlingUnauthorized = false;
  static bool _suppressUnauthorizedHandler = false;

  static void setUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  static Future<T> runWithoutUnauthorizedLogout<T>(
    Future<T> Function() action,
  ) async {
    _suppressUnauthorizedHandler = true;
    try {
      return await action();
    } finally {
      _suppressUnauthorizedHandler = false;
    }
  }

  void _debugLogRequest({
    required String method,
    required String url,
    dynamic body,
  }) {
    ApiLogger.request(method, url, body: body);
  }

  void _debugLogResponse(http.Response response, {String? method}) {
    final url = response.request?.url.toString() ?? '';
    ApiLogger.response(
      response.statusCode,
      url,
      method: method ?? response.request?.method,
      body: response.body,
    );
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      _debugLogRequest(method: 'GET', url: url);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _returnResponse(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  Future<dynamic> getWithQueryParams(String endpoint, Map<String, String> queryParams, String token) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint').replace(queryParameters: queryParams);
      _debugLogRequest(method: 'GET', url: uri.toString());
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return _returnResponse(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  Future<dynamic> getWithBody(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      _debugLogRequest(method: 'GET', url: url, body: data);

      final request = http.Request('GET', Uri.parse(url));
      if (headers != null) {
        request.headers.addAll(headers);
      } else {
        request.headers['Content-Type'] = 'application/json';
      }
      request.body = jsonEncode(data);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _returnResponse(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  Future<dynamic> postMultipart(
      String endpoint,
      Map<String, String> fields,
      List<http.MultipartFile> files,
      String token,
      ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      _debugLogRequest(
        method: 'POST Multipart',
        url: uri.toString(),
        body: {
          'fields': fields,
          'files': files
              .map((f) => '${f.field}: ${f.filename ?? 'file'} (${f.length} bytes)')
              .toList(),
        },
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields.addAll(fields);
      request.files.addAll(files);
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _returnResponse(response, method: 'POST Multipart');
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      _debugLogRequest(method: 'POST', url: url, body: data);
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      return _returnResponse(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      _debugLogRequest(method: 'PATCH', url: url, body: data);
      final response = await http.patch(
        Uri.parse(url),
        body: jsonEncode(data),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      return _returnResponse(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      _debugLogRequest(method: 'DELETE', url: url);
      final response = await http.delete(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );
      return _returnResponse(response);
    } catch (e) {
      if (e is SocketException || e.toString().contains('SocketException')) {
        throw FetchDataException('No Internet connection');
      }
      rethrow;
    }
  }

  dynamic _returnResponse(http.Response response, {String? method}) {
    _debugLogResponse(response, method: method);

    String errorMessage = response.body;
    try {
      final json = jsonDecode(response.body);
      if (json['message'] != null) {
        errorMessage = json['message'];
      }
    } catch (_) {

    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw BadRequestException(errorMessage);
      case 401:
        _triggerUnauthorizedHandler();
        throw UnauthorisedException(errorMessage);
      case 403:
        throw UnauthorisedException(errorMessage);
      case 500:
      default:
        throw FetchDataException(errorMessage);
    }
  }

  void _triggerUnauthorizedHandler() {
    if (_suppressUnauthorizedHandler) return;
    if (_isHandlingUnauthorized) return;
    final handler = _onUnauthorized;
    if (handler == null) return;

    _isHandlingUnauthorized = true;
    unawaited(
      handler().whenComplete(() {
        _isHandlingUnauthorized = false;
      }),
    );
  }
}

class AppException implements Exception {
  final String? _message;
  final String? _prefix;

  AppException([this._message, this._prefix]);

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
      : super(message, "Error During Communication: ");
}

class BadRequestException extends AppException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends AppException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, "Invalid Input: ");
}
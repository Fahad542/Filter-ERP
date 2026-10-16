import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/network/api_constants.dart';

class PaymentIntentException implements Exception {
  final String message;
  const PaymentIntentException(this.message);

  @override
  String toString() => message;
}

class PaymentIntentRecord {
  final String intentId;
  final String? paymentNo;
  final String amount;
  final String status;

  const PaymentIntentRecord({
    required this.intentId,
    this.paymentNo,
    required this.amount,
    required this.status,
  });
}

abstract final class PaymentIntentsService {
  static String? _cachedNearPayMethodId;

  static Map<String, String> _authHeaders(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _unwrapRoot(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const PaymentIntentException('Invalid payment API response');
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return decoded;
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message = decoded['message']?.toString();
        if (message != null && message.trim().isNotEmpty) return message;
        final error = decoded['error']?.toString();
        if (error != null && error.trim().isNotEmpty) return error;
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }

  static Future<String> resolveNearPayMethodId({required String token}) async {
    if (_cachedNearPayMethodId != null) return _cachedNearPayMethodId!;

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.paymentMethodsEndpoint}',
    );
    final response = await http
        .get(uri, headers: _authHeaders(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentIntentException(
        _errorMessage(response, 'Could not load payment methods'),
      );
    }

    final root = jsonDecode(response.body);
    final data = root is Map<String, dynamic> ? root['data'] : null;
    final methods = data is List
        ? data
        : (data is Map<String, dynamic> && data['data'] is List
            ? data['data']
            : null);

    if (methods is! List) {
      throw const PaymentIntentException('Payment methods list missing in response');
    }

    for (final item in methods) {
      if (item is! Map) continue;
      final provider = item['provider_code']?.toString().toUpperCase();
      final code = item['code']?.toString().toUpperCase();
      final active = item['is_active'] == true;
      if (!active) continue;
      if (provider == 'NEARPAY' || code == 'SOFTPOS' || code == 'CARD_IN_APP') {
        final id = item['id']?.toString();
        if (id != null && id.isNotEmpty) {
          _cachedNearPayMethodId = id;
          return id;
        }
      }
    }

    throw const PaymentIntentException(
      'No active NearPay SoftPOS payment method configured on server',
    );
  }

  static Future<PaymentIntentRecord> createPosCardIntent({
    required String token,
    required double amount,
    required String orderId,
    String? externalReference,
    String? payerReference,
    String? payeeReference,
  }) async {
    final methodId = await resolveNearPayMethodId(token: token);
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.paymentIntentsEndpoint}',
    );

    final body = <String, dynamic>{
      'amount': amount.toStringAsFixed(2),
      'currency': 'SAR',
      'payment_method_id': methodId,
      'module': 'pos',
      'entity_type': 'order',
      'entity_id': orderId,
      if (externalReference != null && externalReference.isNotEmpty)
        'external_reference': externalReference,
      if (payerReference != null && payerReference.isNotEmpty)
        'payer_reference': payerReference,
      if (payeeReference != null && payeeReference.isNotEmpty)
        'payee_reference': payeeReference,
      'metadata': {
        'source': 'cashier_pos',
        'order_id': orderId,
      },
    };

    final response = await http
        .post(uri, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentIntentException(
        _errorMessage(response, 'Create payment intent failed'),
      );
    }

    final decoded = jsonDecode(response.body);
    final data = _unwrapRoot(decoded);
    final appPayload = data['app_payload'];
    final payment = data['payment'];

    String? intentId;
    if (appPayload is Map) {
      intentId = appPayload['intentUUID']?.toString() ??
          appPayload['intent_uuid']?.toString();
    }
    if ((intentId == null || intentId.isEmpty) && payment is Map) {
      intentId = payment['provider_intent_id']?.toString();
    }

    if (intentId == null || intentId.isEmpty) {
      throw const PaymentIntentException('Payment intent id missing in response');
    }

    final amountStr = payment is Map
        ? payment['amount']?.toString() ?? amount.toStringAsFixed(2)
        : amount.toStringAsFixed(2);
    final status = payment is Map
        ? payment['status']?.toString() ?? 'REQUIRES_ACTION'
        : 'REQUIRES_ACTION';
    final paymentNo =
        payment is Map ? payment['payment_no']?.toString() : null;

    return PaymentIntentRecord(
      intentId: intentId,
      paymentNo: paymentNo,
      amount: amountStr,
      status: status,
    );
  }
}

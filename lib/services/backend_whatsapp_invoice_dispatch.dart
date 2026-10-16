import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/network/api_constants.dart';
import '../models/create_invoice_model.dart';
import '../utils/api_logger.dart';
import '../utils/invoice_maintenance_checklist.dart';
import 'session_service.dart';

/// Thin Flutter client for the backend WhatsApp invoice send endpoint:
///
/// ```
/// POST {baseUrl}/cashier/invoice/{invoiceId}/whatsapp-send
/// Authorization: Bearer <cashier JWT>
/// { "paymentMethodText": "Cash", "maintenanceChecks": [true,…] }
/// ```
///
/// The backend builds the bilingual A4 PDF, hosts it, and calls Bevatel. We
/// expect a fast `202 Accepted` here — the actual WhatsApp send runs
/// asynchronously server-side so the cashier UI never freezes.
abstract final class BackendWhatsAppInvoiceDispatch {
  BackendWhatsAppInvoiceDispatch._();

  /// Cashier role's JWT, written by `SessionService.saveSession`. Returns
  /// `null` when the cashier is logged out (caller surfaces an error toast).
  static Future<String?> _cashierJwt() async {
    final token = await SessionService().getToken(role: 'cashier');
    final t = token?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Send the invoice on WhatsApp by hitting the backend endpoint. Returns
  /// when the backend acknowledges (`202`). Throws on auth / network errors.
  static Future<void> send({
    required Invoice invoice,
    required String paymentMethodText,
    List<bool>? maintenanceChecks,
  }) async {
    final jwt = await _cashierJwt();
    if (jwt == null) {
      throw StateError(
        'Cashier is not signed in — cannot dispatch WhatsApp invoice via backend.',
      );
    }
    final id = invoice.id.trim();
    if (id.isEmpty) {
      throw StateError('Invoice has no id — cannot dispatch WhatsApp send.');
    }

    final base = _trimRightSlashes(ApiConstants.baseUrl);
    final uri = Uri.parse('$base/cashier/invoice/$id/whatsapp-send');

    final body = <String, dynamic>{
      'paymentMethodText': paymentMethodText,
      if (maintenanceChecks != null &&
          maintenanceChecks.length == InvoiceMaintenanceChecklist.rows.length &&
          InvoiceMaintenanceChecklist.hasAnyChecked(maintenanceChecks))
        'maintenanceChecks': maintenanceChecks,
    };

    ApiLogger.request('POST', uri.toString(), body: body);

    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    ApiLogger.response(res.statusCode, uri.toString(), method: 'POST', body: res.body);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException(
        'WhatsApp backend dispatch failed (HTTP ${res.statusCode}): '
        '${res.body.length > 240 ? '${res.body.substring(0, 240)}…' : res.body}',
      );
    }
  }

  static String _trimRightSlashes(String s) {
    var v = s;
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}

/// Lightweight HTTP exception so callers can `catch` the failure without
/// importing `dart:io` (the `http` package returns plain `Exception`).
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}

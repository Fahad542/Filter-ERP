import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Prints HTTP URLs, request bodies, and response bodies to the debug console.
abstract final class ApiLogger {
  // ignore: unused_field
  static const int _maxLogChars = 100000;

  static void request(String method, String url, {Object? body}) {
    if (kReleaseMode) return;
    debugPrint('[API] → $method $url');
    // Request/response bodies are intentionally suppressed so the terminal
    // only shows API URLs (focus mode). To re-enable, uncomment the line
    // below (and the matching one in [response]).
    // _logPayload('[API]   request body:', body);
  }

  static void response(
    int statusCode,
    String url, {
    String? method,
    Object? body,
  }) {
    if (kReleaseMode) return;
    // Response URL + body are intentionally suppressed so the terminal only
    // shows the outgoing API request URLs (focus mode). To re-enable, uncomment
    // both lines below.
    // final m = method == null ? '' : '$method ';
    // debugPrint('[API] ← $statusCode $m$url');
    // _logPayload('[API]   response body:', body);
  }

  static void socket(String action, String url) {
    if (kReleaseMode) return;
    debugPrint('[API] SOCKET $action $url');
  }

  /// Logged after successful login (debug builds only).
  static void authToken(String role, String token) {
    if (kReleaseMode) return;
    debugPrint('[AUTH] $role token: $token');
  }

  // ignore: unused_element
  static void _logPayload(String label, Object? body) {
    if (body == null) return;
    final text = _formatPayload(body);
    if (text.isEmpty) return;
    _printLong(label, text);
  }

  // ignore: unused_element
  static String _formatPayload(Object body) {
    if (body is Uint8List) {
      return '<binary ${body.length} bytes>';
    }
    if (body is List<int>) {
      return '<binary ${body.length} bytes>';
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) return body;
      try {
        final decoded = jsonDecode(trimmed);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return body;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  // ignore: unused_element
  static void _printLong(String label, String text) {
    var payload = text;
    if (payload.length > _maxLogChars) {
      payload =
          '${payload.substring(0, _maxLogChars)}\n… [truncated, ${text.length} chars total]';
    }
    debugPrint(label);
    const chunkSize = 800;
    for (var i = 0; i < payload.length; i += chunkSize) {
      final end =
          i + chunkSize < payload.length ? i + chunkSize : payload.length;
      debugPrint(payload.substring(i, end));
    }
  }
}

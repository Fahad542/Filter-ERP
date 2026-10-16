import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'realtime_service.dart';
import 'softpos_local_ip.dart';
import 'softpos_protocol.dart';
import 'softpos_settings.dart';
import 'softpos_terminals_api.dart';

class SoftPosBridgeException implements Exception {
  final String message;
  const SoftPosBridgeException(this.message);

  @override
  String toString() => message;
}

class _SoftPosActiveSession {
  final String requestId;
  final String softPosHost;
  final int softPosPort;
  final double amount;
  final Completer<SoftPosPaymentResult> completer;
  final Future<void> Function() cleanup;
  final bool viaSocket;

  const _SoftPosActiveSession({
    required this.requestId,
    required this.softPosHost,
    required this.softPosPort,
    required this.amount,
    required this.completer,
    required this.cleanup,
    this.viaSocket = false,
  });
}

/// Sends card payments to SoftPOS via backend Socket.IO (preferred) or LAN.
abstract final class SoftPosBridge {
  static const _paymentTimeout = Duration(minutes: 3);
  static _SoftPosActiveSession? _active;

  /// Stops an in-flight SoftPOS payment from the POS waiting dialog.
  static Future<void> cancelActivePayment() async {
    final session = _active;
    if (session == null) return;

    try {
      if (session.viaSocket) {
        await SoftPosTerminalsApi().cancelPaymentRequest(
          session.requestId,
          message: 'Cancelled from POS',
        );
      } else {
        final uri = Uri.parse(
          'http://${session.softPosHost}:${session.softPosPort}/cancel',
        );
        await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'requestId': session.requestId}),
            )
            .timeout(const Duration(seconds: 8));
      }
    } catch (_) {
      // SoftPOS unreachable — still cancel locally below.
    }

    if (!session.completer.isCompleted) {
      session.completer.complete(
        SoftPosPaymentResult(
          requestId: session.requestId,
          status: SoftPosProtocol.statusCancelled,
          amount: session.amount,
          message: 'Cancelled from POS',
          processedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    await session.cleanup();
    if (identical(_active, session)) {
      _active = null;
    }
  }

  static String newRequestId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(999999)}';
  }

  static Future<bool> ping({
    required String host,
    required int port,
    int attempts = 3,
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (await _pingOnce(host: host, port: port)) return true;
      if (i < attempts - 1) {
        await Future<void>.delayed(Duration(milliseconds: 350 * (i + 1)));
      }
    }
    return false;
  }

  static Future<bool> _pingOnce({
    required String host,
    required int port,
  }) async {
    HttpClient? client;
    try {
      final uri = Uri.parse('http://$host:$port/health');
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(uri);
      final resp = await req.close().timeout(const Duration(seconds: 8));
      final body = await utf8.decoder.bind(resp).join();
      if (resp.statusCode != 200) return false;
      final decoded = jsonDecode(body);
      return decoded is Map && decoded['ok'] == true;
    } catch (_) {
      return false;
    } finally {
      client?.close(force: true);
    }
  }

  /// True when bound SoftPOS handset reported presence recently (socket/LAN).
  static Future<bool> isBoundDeviceOnline() async {
    try {
      final binding = await SoftPosTerminalsApi().getBinding();
      return binding?.online == true;
    } catch (_) {
      return false;
    }
  }

  /// SoftPOS is triggered only for Tap to Pay (not Card).
  static bool isSoftPosPaymentMethod(String? raw) {
    final method = (raw ?? '').toString().trim().toLowerCase();
    if (method.isEmpty) return false;
    final compact = method.replaceAll(RegExp(r'[\s_\-]'), '');
    return compact.contains('taptopay') ||
        compact == 'softpos' ||
        compact == 'nearpay' ||
        (method.contains('tap') && method.contains('pay'));
  }

  static double softPosAmountFromSplits(List<Map<String, dynamic>> splits) {
    var sum = 0.0;
    for (final s in splits) {
      if (isSoftPosPaymentMethod(s['method']?.toString())) {
        sum += (s['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return sum;
  }

  /// Deprecated name — SoftPOS follows Tap to Pay splits only.
  static double cardAmountFromSplits(List<Map<String, dynamic>> splits) =>
      softPosAmountFromSplits(splits);

  static bool splitsIncludeSoftPos(List<Map<String, dynamic>>? splits) {
    if (splits == null || splits.isEmpty) return false;
    return splits.any((s) => isSoftPosPaymentMethod(s['method']?.toString()));
  }

  /// Deprecated name — SoftPOS follows Tap to Pay splits only.
  static bool splitsIncludeCard(List<Map<String, dynamic>>? splits) =>
      splitsIncludeSoftPos(splits);

  /// Preferred path: POST cashier payment-request → SoftPOS socket → result event.
  static Future<SoftPosPaymentResult> requestPaymentViaSocket({
    required SoftPosPaymentRequest request,
  }) async {
    final completer = Completer<SoftPosPaymentResult>();
    Timer? timeoutTimer;
    Timer? pollTimer;
    late void Function(Map<String, dynamic>) onUpdate;
    final realtime = RealtimeService();
    final api = SoftPosTerminalsApi();

    Future<void> cleanup() async {
      timeoutTimer?.cancel();
      pollTimer?.cancel();
      realtime.off(RealtimeService.eventCashierSoftPosPaymentUpdated, onUpdate);
      if (identical(_active?.completer, completer)) {
        _active = null;
      }
    }

    onUpdate = (payload) {
      final id = payload['requestId']?.toString();
      if (id != request.requestId) return;
      final status = payload['status']?.toString() ?? '';
      if (status == 'pending') return;
      if (completer.isCompleted) return;
      completer.complete(
        SoftPosPaymentResult(
          requestId: request.requestId,
          status: status.isEmpty ? SoftPosProtocol.statusDeclined : status,
          amount: (payload['amount'] is num)
              ? (payload['amount'] as num).toDouble()
              : request.amount,
          authCode: payload['authCode']?.toString(),
          message: payload['message']?.toString(),
          processedAt: payload['updatedAt']?.toString() ??
              DateTime.now().toIso8601String(),
        ),
      );
    };

    try {
      realtime.on(RealtimeService.eventCashierSoftPosPaymentUpdated, onUpdate);

      await api.createPaymentRequest({
        'requestId': request.requestId,
        'amount': request.amount,
        'currency': request.currency,
        'orderId': request.orderId,
        if (request.orderNo != null) 'orderNo': request.orderNo,
        if (request.customerName != null) 'customerName': request.customerName,
        if (request.customerMobile != null)
          'customerMobile': request.customerMobile,
        if (request.plateNo != null) 'plateNo': request.plateNo,
        if (request.lineSummary != null) 'lineSummary': request.lineSummary,
        'paymentLabel': request.paymentLabel,
        if (request.intentUuid != null && request.intentUuid!.isNotEmpty)
          'intentUuid': request.intentUuid,
      });

      _active = _SoftPosActiveSession(
        requestId: request.requestId,
        softPosHost: 'socket',
        softPosPort: 0,
        amount: request.amount,
        completer: completer,
        cleanup: cleanup,
        viaSocket: true,
      );

      // Fallback poll in case socket event is missed.
      pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (completer.isCompleted) return;
        try {
          final row = await api.getPaymentRequestStatus(request.requestId);
          if (row == null) return;
          final status = row['status']?.toString() ?? '';
          if (status == 'pending' || status.isEmpty) return;
          onUpdate(row);
        } catch (_) {}
      });

      timeoutTimer = Timer(_paymentTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            const SoftPosBridgeException(
              'SoftPOS payment timed out. Check the SoftPOS app.',
            ),
          );
        }
      });

      final result = await completer.future;
      await cleanup();
      return result;
    } catch (e) {
      await cleanup();
      if (e is SoftPosBridgeException) rethrow;
      throw SoftPosBridgeException(
        e is TimeoutException
            ? 'SoftPOS payment timed out. Check the SoftPOS app.'
            : 'SoftPOS socket bridge failed: $e',
      );
    }
  }

  static Future<SoftPosPaymentResult> requestPayment({
    required SoftPosPaymentRequest request,
    required String softPosHost,
    required int softPosPort,
    int callbackPort = SoftPosProtocol.defaultCallbackPort,
  }) async {
    final localIp = await getLocalIpv4();
    if (localIp == null) {
      throw const SoftPosBridgeException(
        'Could not detect this device IP for SoftPOS callback.',
      );
    }

    final completer = Completer<SoftPosPaymentResult>();
    HttpServer? callbackServer;
    Timer? timeoutTimer;

    Future<void> cleanup() async {
      timeoutTimer?.cancel();
      final s = callbackServer;
      callbackServer = null;
      if (s != null) {
        await s.close(force: true);
      }
      if (identical(_active?.completer, completer)) {
        _active = null;
      }
    }

    try {
      callbackServer = await HttpServer.bind(
        InternetAddress.anyIPv4,
        callbackPort,
        shared: true,
      );

      callbackServer!.listen((HttpRequest req) async {
        try {
          if (req.method == 'POST' &&
              req.uri.path == '/softpos/callback') {
            final body = await utf8.decoder.bind(req).join();
            final json = jsonDecode(body) as Map<String, dynamic>;
            final result = SoftPosPaymentResult.fromJson(json);
            // ignore: avoid_print
            print('[SoftPOS bridge] callback received status=${result.status}');
            await _writeJson(req.response, HttpStatus.ok, {'ok': true});
            if (!completer.isCompleted) {
              completer.complete(result);
            }
            return;
          }
          await _writeJson(req.response, HttpStatus.notFound, {'ok': false});
        } catch (e) {
          await _writeJson(
            req.response,
            HttpStatus.internalServerError,
            {'ok': false, 'error': e.toString()},
          );
        }
      });

      final callbackUrl =
          'http://$localIp:$callbackPort/softpos/callback';
      // ignore: avoid_print
      print('[SoftPOS bridge] callback URL for POS device: $callbackUrl');
      final payload = SoftPosPaymentRequest(
        requestId: request.requestId,
        callbackUrl: callbackUrl,
        amount: request.amount,
        currency: request.currency,
        orderId: request.orderId,
        orderNo: request.orderNo,
        customerName: request.customerName,
        customerMobile: request.customerMobile,
        plateNo: request.plateNo,
        lineSummary: request.lineSummary,
        paymentLabel: request.paymentLabel,
        intentUuid: request.intentUuid,
      );

      final payUri = Uri.parse('http://$softPosHost:$softPosPort/pay');
      final resp = await http
          .post(
            payUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 409) {
        throw const SoftPosBridgeException(
          'SoftPOS is busy with another payment. Finish it first.',
        );
      }
      if (resp.statusCode != 200) {
        throw SoftPosBridgeException(
          'SoftPOS rejected request (${resp.statusCode}).',
        );
      }

      _active = _SoftPosActiveSession(
        requestId: request.requestId,
        softPosHost: softPosHost,
        softPosPort: softPosPort,
        amount: request.amount,
        completer: completer,
        cleanup: cleanup,
      );

      timeoutTimer = Timer(_paymentTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            const SoftPosBridgeException(
              'SoftPOS payment timed out. Check the SoftPOS app.',
            ),
          );
        }
      });

      final result = await completer.future;
      await cleanup();
      return result;
    } catch (e) {
      await cleanup();
      if (e is SoftPosBridgeException) rethrow;
      throw SoftPosBridgeException(
        e is TimeoutException
            ? 'SoftPOS device not reachable. Open SoftPOS and check binding.'
            : 'SoftPOS bridge failed: $e',
      );
    }
  }

  /// Runs bridge when enabled and Tap to Pay is in [paymentSplits].
  /// Prefers backend Socket.IO when a SoftPOS device is bound.
  static Future<bool> runIfNeeded({
    required List<Map<String, dynamic>>? paymentSplits,
    required SoftPosPaymentRequest request,
  }) async {
    final settings = await SoftPosSettings.load();
    if (!settings.enabled) return true;
    if (!splitsIncludeSoftPos(paymentSplits)) return true;

    final softPosAmount = softPosAmountFromSplits(paymentSplits!);
    if (softPosAmount <= 0.001) return true;

    final payRequest = SoftPosPaymentRequest(
      requestId: request.requestId,
      callbackUrl: request.callbackUrl,
      amount: softPosAmount,
      currency: request.currency,
      orderId: request.orderId,
      orderNo: request.orderNo,
      customerName: request.customerName,
      customerMobile: request.customerMobile,
      plateNo: request.plateNo,
      lineSummary: request.lineSummary,
      paymentLabel: request.paymentLabel,
      intentUuid: request.intentUuid,
    );

    final deviceId = (settings.deviceId ?? '').trim();
    if (deviceId.isNotEmpty) {
      // ignore: avoid_print
      print('[SoftPOS bridge] socket path deviceId=$deviceId');
      final result = await requestPaymentViaSocket(request: payRequest);
      return result.approved;
    }

    final reachable = await ping(host: settings.host, port: settings.port);
    if (!reachable) {
      throw const SoftPosBridgeException(
        'Cannot reach SoftPOS. Bind a terminal in settings, or open SoftPOS on the same Wi‑Fi.',
      );
    }

    final result = await requestPayment(
      request: payRequest,
      softPosHost: settings.host,
      softPosPort: settings.port,
    );

    return result.approved;
  }

  static Future<void> _writeJson(
    HttpResponse response,
    int status,
    Map<String, dynamic> body,
  ) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}

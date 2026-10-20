import '../data/network/api_constants.dart';
import '../data/network/base_api_service.dart';
import 'session_service.dart';

class SoftPosTerminalItem {
  SoftPosTerminalItem({
    required this.deviceId,
    required this.label,
    required this.online,
    required this.bound,
    this.boundToOther = false,
    this.boundByUserId,
    this.boundByName,
    this.lanHost,
    this.lanPort,
    this.terminalId,
    this.terminalTid,
    this.terminalLabel,
    this.nearpayTerminalId,
    this.lastSeenAt,
  });

  final String deviceId;
  final String label;
  final bool online;
  /// Bound to the current cashier.
  final bool bound;
  /// Bound to a different cashier in this branch (not connectable).
  final bool boundToOther;
  final String? boundByUserId;
  final String? boundByName;
  final String? lanHost;
  final int? lanPort;
  final String? terminalId;
  final String? terminalTid;
  final String? terminalLabel;
  final String? nearpayTerminalId;
  final String? lastSeenAt;

  bool get hasLan => (lanHost ?? '').trim().isNotEmpty;

  factory SoftPosTerminalItem.fromJson(Map<String, dynamic> json) {
    final terminal = json['terminal'];
    final t = terminal is Map
        ? Map<String, dynamic>.from(terminal)
        : <String, dynamic>{};
    final boundByName = (json['boundByName'] ?? '').toString().trim();
    return SoftPosTerminalItem(
      deviceId: (json['deviceId'] ?? '').toString(),
      label: (json['label'] ?? 'SoftPOS').toString(),
      online: json['online'] == true,
      bound: json['bound'] == true,
      boundToOther: json['boundToOther'] == true,
      boundByUserId: json['boundByUserId']?.toString(),
      boundByName: boundByName.isEmpty ? null : boundByName,
      lanHost: json['lanHost']?.toString(),
      lanPort: json['lanPort'] is num
          ? (json['lanPort'] as num).toInt()
          : int.tryParse('${json['lanPort'] ?? ''}'),
      terminalId: t['id']?.toString(),
      terminalTid: t['tid']?.toString(),
      terminalLabel: t['label']?.toString(),
      nearpayTerminalId: t['nearpayTerminalId']?.toString(),
      lastSeenAt: json['lastSeenAt']?.toString(),
    );
  }
}

class SoftPosTerminalsApi {
  SoftPosTerminalsApi({
    BaseApiService? api,
    SessionService? session,
  })  : _api = api ?? BaseApiService(),
        _session = session ?? SessionService();

  final BaseApiService _api;
  final SessionService _session;

  Future<Map<String, String>> _headers() async {
    final token = await _session.getToken(role: 'cashier');
    if (token == null || token.isEmpty) {
      throw Exception('Not signed in as cashier');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<({String? boundDeviceId, List<SoftPosTerminalItem> items})>
      listTerminals() async {
    final raw = await _api.get(
      ApiConstants.cashierSoftPosTerminalsEndpoint,
      headers: await _headers(),
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final list = <SoftPosTerminalItem>[];
    final items = map['items'];
    if (items is List) {
      for (final row in items) {
        if (row is Map) {
          list.add(
            SoftPosTerminalItem.fromJson(Map<String, dynamic>.from(row)),
          );
        }
      }
    }
    return (
      boundDeviceId: map['boundDeviceId']?.toString(),
      items: list,
    );
  }

  Future<SoftPosTerminalItem?> getBinding() async {
    final raw = await _api.get(
      ApiConstants.cashierSoftPosBindingEndpoint,
      headers: await _headers(),
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    if (map['bound'] != true) return null;
    final device = map['device'];
    if (device is! Map) return null;
    return SoftPosTerminalItem.fromJson(
      Map<String, dynamic>.from(device)..['bound'] = true,
    );
  }

  Future<SoftPosTerminalItem> bind(String deviceId) async {
    final raw = await _api.patch(
      ApiConstants.cashierSoftPosBindingEndpoint,
      {'deviceId': deviceId},
      headers: await _headers(),
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final device = map['device'];
    if (device is! Map) {
      throw Exception('Bind succeeded but terminal payload missing');
    }
    return SoftPosTerminalItem.fromJson(
      Map<String, dynamic>.from(device)..['bound'] = true,
    );
  }

  Future<void> unbind() async {
    await _api.delete(
      ApiConstants.cashierSoftPosBindingEndpoint,
      headers: await _headers(),
    );
  }

  Future<Map<String, dynamic>> createPaymentRequest(
    Map<String, dynamic> body,
  ) async {
    final raw = await _api.post(
      ApiConstants.cashierSoftPosPaymentRequestEndpoint,
      body,
      headers: await _headers(),
    );
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
  }

  Future<void> cancelPaymentRequest(String requestId, {String? message}) async {
    await _api.post(
      ApiConstants.cashierSoftPosPaymentCancelEndpoint,
      {
        'requestId': requestId,
        if (message != null && message.isNotEmpty) 'message': message,
      },
      headers: await _headers(),
    );
  }

  Future<Map<String, dynamic>?> getPaymentRequestStatus(String requestId) async {
    final raw = await _api.get(
      ApiConstants.cashierSoftPosPaymentRequestStatusEndpoint(requestId),
      headers: await _headers(),
    );
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    if (map['found'] != true) return null;
    final request = map['request'];
    if (request is Map) return Map<String, dynamic>.from(request);
    return null;
  }
}

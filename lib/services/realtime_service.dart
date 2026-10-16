import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../data/network/api_constants.dart';
import '../utils/api_logger.dart';

typedef RealtimeEventCallback = void Function(Map<String, dynamic> payload);

/// Shared socket so cashier VMs (e.g. [PosViewModel], broadcast list) get the same connection.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService _instance = RealtimeService._();
  factory RealtimeService() => _instance;

  static const String _namespace = '/realtime';
  static const String _socketPath = '/socket.io';

  static const String eventCashierTechniciansUpdated = 'cashier.technicians.updated';
  static const String eventTechnicianProfileUpdated = 'technician.profile.updated';
  static const String eventCashierOrdersUpdated = 'cashier.orders.updated';
  static const String eventTechnicianOrdersUpdated = 'technician.assigned-orders.updated';
  static const String eventTechnicianBroadcastCreated = 'technician.broadcast.created';
  static const String eventTechnicianBroadcastClosed = 'technician.broadcast.closed';
  static const String eventCashierBroadcastUpdated = 'cashier.broadcast.updated';
  static const String eventCorporateWalkInOrderUpdated = 'corporate.walk-in-order.updated';
  static const String eventCashierCorporateWalkInApproved = 'cashier.corporate-walk-in.approved';
  static const String eventCashierCorporateWalkInRejected = 'cashier.corporate-walk-in.rejected';
  static const String eventWorkshopPettyCashUpdated = 'workshop.petty-cash.updated';
  static const String eventCashierPettyCashUpdated = 'cashier.petty-cash.updated';
  static const String eventCashierSessionForceClosed = 'cashier.session.force-closed';
  static const String eventCashierAiOrderUnbilled = 'cashier.ai-order.unbilled';
  static const String eventCashierAiOrderMatched = 'cashier.ai-order.matched';
  static const String eventCashierSoftPosAccessUpdated =
      'cashier.softpos.access.updated';
  static const String eventCashierSoftPosPaymentUpdated =
      'cashier.softpos.payment.updated';

  static const String eventPlatformChatMessage = 'platform-chat.message';
  static const String eventPlatformChatConversationUpdated =
      'platform-chat.conversation.updated';
  static const String eventPlatformChatConversationCreated =
      'platform-chat.conversation.created';
  static const String eventPlatformChatReceiptUpdated =
      'platform-chat.receipt.updated';
  static const String eventPlatformChatTyping = 'platform-chat.typing';

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _authToken;

  bool get isConnected => _isConnected;
  String? get authToken => _authToken;

  final Map<String, List<RealtimeEventCallback>> _listeners = {};
  final List<void Function()> _connectListeners = [];

  void addConnectListener(void Function() listener) {
    if (!_connectListeners.contains(listener)) {
      _connectListeners.add(listener);
    }
  }

  void removeConnectListener(void Function() listener) {
    _connectListeners.remove(listener);
  }

  void _notifyConnectListeners() {
    for (final listener in List<void Function()>.from(_connectListeners)) {
      listener();
    }
  }

  void connect(String token) {
    if (_socket != null) {
      if (_authToken == token && _isConnected) return;
      reconnect(token);
      return;
    }
    _openSocket(token);
  }

  /// Drop the old socket (e.g. after force-logout) and connect with a fresh token.
  void reconnect(String token) {
    disconnectSocket();
    _openSocket(token);
  }

  void _openSocket(String token) {
    _authToken = token;
    final socketUrl = '${ApiConstants.baseUrl}$_namespace';
    ApiLogger.socket('CONNECT', '$socketUrl (path: $_socketPath)');

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(_socketPath)
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _notifyConnectListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
    });

    _socket!.onError((err) {});

    _socket!.on(eventCashierTechniciansUpdated, (data) {
      _emit(eventCashierTechniciansUpdated, _toMap(data));
    });

    _socket!.on(eventTechnicianProfileUpdated, (data) {
      _emit(eventTechnicianProfileUpdated, _toMap(data));
    });

    _socket!.on(eventCashierOrdersUpdated, (data) {
      _emit(eventCashierOrdersUpdated, _toMap(data));
    });

    _socket!.on(eventTechnicianOrdersUpdated, (data) {
      _emit(eventTechnicianOrdersUpdated, _toMap(data));
    });

    _socket!.on(eventTechnicianBroadcastCreated, (data) {
      _emit(eventTechnicianBroadcastCreated, _toMap(data));
    });

    _socket!.on(eventTechnicianBroadcastClosed, (data) {
      _emit(eventTechnicianBroadcastClosed, _toMap(data));
    });

    _socket!.on(eventCashierBroadcastUpdated, (data) {
      _emit(eventCashierBroadcastUpdated, _toMap(data));
    });

    _socket!.on(eventCorporateWalkInOrderUpdated, (data) {
      _emit(eventCorporateWalkInOrderUpdated, _toMap(data));
    });

    _socket!.on(eventCashierCorporateWalkInApproved, (data) {
      _emit(eventCashierCorporateWalkInApproved, _toMap(data));
    });

    _socket!.on(eventCashierCorporateWalkInRejected, (data) {
      _emit(eventCashierCorporateWalkInRejected, _toMap(data));
    });

    _socket!.on(eventWorkshopPettyCashUpdated, (data) {
      _emit(eventWorkshopPettyCashUpdated, _toMap(data));
    });

    _socket!.on(eventCashierPettyCashUpdated, (data) {
      _emit(eventCashierPettyCashUpdated, _toMap(data));
    });

    _socket!.on(eventCashierSessionForceClosed, (data) {
      final map = _toMap(data);
      ApiLogger.socket('EVENT', eventCashierSessionForceClosed);
      if (kDebugMode && map.isNotEmpty) {
        debugPrint('[API] SOCKET payload: $map');
      }
      _emit(eventCashierSessionForceClosed, map);
    });

    _socket!.on(eventCashierAiOrderUnbilled, (data) {
      _emit(eventCashierAiOrderUnbilled, _toMap(data));
    });
    _socket!.on(eventCashierAiOrderMatched, (data) {
      _emit(eventCashierAiOrderMatched, _toMap(data));
    });

    _socket!.on(eventCashierSoftPosAccessUpdated, (data) {
      _emit(eventCashierSoftPosAccessUpdated, _toMap(data));
    });

    _socket!.on(eventCashierSoftPosPaymentUpdated, (data) {
      _emit(eventCashierSoftPosPaymentUpdated, _toMap(data));
    });

    _socket!.on(eventPlatformChatMessage, (data) {
      _emit(eventPlatformChatMessage, _toMap(data));
    });
    _socket!.on(eventPlatformChatConversationUpdated, (data) {
      _emit(eventPlatformChatConversationUpdated, _toMap(data));
    });
    _socket!.on(eventPlatformChatConversationCreated, (data) {
      _emit(eventPlatformChatConversationCreated, _toMap(data));
    });
    _socket!.on(eventPlatformChatReceiptUpdated, (data) {
      _emit(eventPlatformChatReceiptUpdated, _toMap(data));
    });
    _socket!.on(eventPlatformChatTyping, (data) {
      _emit(eventPlatformChatTyping, _toMap(data));
    });

    _socket!.connect();
  }

  /// Closes the socket only — keeps registered [on] listeners (e.g. in [PosViewModel]).
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _authToken = null;
  }

  void disconnect() {
    disconnectSocket();
    _listeners.clear();
  }

  void on(String event, RealtimeEventCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, RealtimeEventCallback callback) {
    _listeners[event]?.remove(callback);
  }

  void _emit(String event, Map<String, dynamic> payload) {
    final callbacks = _listeners[event];
    if (callbacks != null) {
      for (final cb in List.of(callbacks)) {
        cb(payload);
      }
    }
  }

  void joinPlatformChatConversation(String conversationId) {
    _socket?.emit('platform-chat.join', {
      'conversationId': conversationId,
    });
  }

  void emitPlatformChatTyping(String conversationId, {bool typing = true}) {
    _socket?.emit('platform-chat.typing', {
      'conversationId': conversationId,
      'typing': typing,
    });
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}

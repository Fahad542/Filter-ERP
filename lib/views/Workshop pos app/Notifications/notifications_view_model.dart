import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/ai_orders_repository.dart';
import '../../../models/cashier_ai_order_model.dart';
import '../../../services/locker_translation_mixin.dart';
import '../../../services/realtime_service.dart';
import '../../../services/session_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isRead;
  final String? type;
  final String? entityType;
  final String? entityId;
  final String? aiOrderId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    this.isRead = false,
    this.type,
    this.entityType,
    this.entityId,
    this.aiOrderId,
  });

  bool get isAiOrder =>
      type == 'workshop_cashier_ai_vehicle_unbilled' ||
      entityType == 'ai_order' ||
      (aiOrderId != null && aiOrderId!.isNotEmpty);

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    IconData? icon,
    bool? isRead,
    String? type,
    String? entityType,
    String? entityId,
    String? aiOrderId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      aiOrderId: aiOrderId ?? this.aiOrderId,
    );
  }
}

class NotificationsViewModel extends ChangeNotifier with TranslatableMixin {
  NotificationsViewModel({
    required this.repository,
    required this.sessionService,
  }) {
    _realtime.on(RealtimeService.eventCashierAiOrderUnbilled, _onSocket);
    _realtime.on(RealtimeService.eventCashierAiOrderMatched, _onSocket);
  }

  final AiOrdersRepository repository;
  final SessionService sessionService;
  final RealtimeService _realtime = RealtimeService();

  List<NotificationModel> _notifications = const [];
  bool isLoading = false;
  String? errorMessage;
  int unreadCount = 0;
  Timer? _socketDebounce;
  Future<void>? _fetchInFlight;

  List<NotificationModel> get notifications => _notifications;

  void bindSettingsViewModel(Listenable settingsViewModel) {
    bindLocaleRetranslation(settingsViewModel, retranslate);
  }

  void _onSocket(Map<String, dynamic> _) {
    _socketDebounce?.cancel();
    _socketDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchInbox(silent: true);
    });
  }

  Future<void> retranslate() async {
    // API titles/bodies are already localized server-side when available.
    notifyListeners();
  }

  Future<void> fetchInbox({bool silent = false}) {
    if (_fetchInFlight != null) return _fetchInFlight!;
    _fetchInFlight =
        _fetchImpl(silent: silent).whenComplete(() => _fetchInFlight = null);
    return _fetchInFlight!;
  }

  Future<void> _fetchImpl({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final token = await sessionService.getToken(role: 'cashier');
      if (token == null) {
        errorMessage = 'Session expired';
        return;
      }
      final result = await repository.listInbox(token, limit: 100);
      _notifications = result.items.map(_mapItem).toList(growable: false);
      unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      if (!silent) errorMessage = e.toString();
      if (kDebugMode) debugPrint('[Notifications] inbox error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  NotificationModel _mapItem(WorkshopNotificationItem item) {
    return NotificationModel(
      id: item.id,
      title: item.title,
      message: item.body,
      time: _formatTime(item.createdAt),
      icon: item.isAiUnbilled
          ? Icons.videocam_outlined
          : Icons.notifications_outlined,
      isRead: !item.isUnread,
      type: item.type,
      entityType: item.entityType,
      entityId: item.entityId,
      aiOrderId: item.aiOrderId,
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      return DateFormat('hh:mm a').format(local);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('dd MMM yyyy').format(local);
  }

  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    final token = await sessionService.getToken(role: 'cashier');
    if (token == null) return;
    for (final n in unread) {
      try {
        await repository.markNotificationRead(token, n.id);
      } catch (_) {}
    }
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList(growable: false);
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> markRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final token = await sessionService.getToken(role: 'cashier');
    if (token == null) return;
    try {
      await repository.markNotificationRead(token, notification.id);
    } catch (_) {}
    _notifications = _notifications
        .map((n) => n.id == notification.id ? n.copyWith(isRead: true) : n)
        .toList(growable: false);
    unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> clearAll() async {
    final token = await sessionService.getToken(role: 'cashier');
    if (token == null) return;
    await repository.clearAllNotifications(token);
    _notifications = const [];
    unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketDebounce?.cancel();
    _realtime.off(RealtimeService.eventCashierAiOrderUnbilled, _onSocket);
    _realtime.off(RealtimeService.eventCashierAiOrderMatched, _onSocket);
    unbindLocaleRetranslation();
    super.dispose();
  }
}

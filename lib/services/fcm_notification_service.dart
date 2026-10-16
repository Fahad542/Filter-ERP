import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FCM channel id — must match AndroidManifest default channel + backend android.notification.channelId.
const String kFcmAndroidChannelId = 'filter_high_importance_channel';
const String kFcmAndroidChannelName = 'Filter Notifications';

/// Handles FCM in foreground, background, and terminated (killed) states.
class FcmNotificationService {
  FcmNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      await _initLocalNotifications();
      await _requestPermissions();

      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);

      // iOS: show banner/sound when a notification payload arrives in foreground.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _logToken(messaging);

      messaging.onTokenRefresh.listen((newToken) {
        _printToken('FCM TOKEN (refreshed)', newToken);
      });

      // Foreground — FCM does not show a system tray notification on Android without this.
      FirebaseMessaging.onMessage.listen((message) {
        unawaited(showFromRemoteMessage(message));
      });

      // App opened from background via notification tap.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // App opened from killed state via notification tap.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleNotificationTap(initial);
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('FCM init failed: $e');
      debugPrint('$st');
    }
  }

  /// Called from the background isolate before showing a notification.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _initLocalNotifications();
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );

    const channel = AndroidNotificationChannel(
      kFcmAndroidChannelId,
      kFcmAndroidChannelName,
      description: 'Job broadcasts, order updates, and alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  /// Show a tray notification for [message] when the OS has not already done so.
  static Future<void> showFromRemoteMessage(
    RemoteMessage message, {
    bool fromBackgroundIsolate = false,
  }) async {
    final title = _titleFor(message);
    final body = _bodyFor(message);
    if (title.isEmpty && body.isEmpty) return;

    // Background/killed + notification payload: Android system already displays it.
    if (fromBackgroundIsolate && message.notification != null) {
      debugPrint('FCM background (system notification): $title');
      return;
    }

    final id = _notificationId(message);
    final androidDetails = AndroidNotificationDetails(
      kFcmAndroidChannelId,
      kFcmAndroidChannelName,
      channelDescription: 'Job broadcasts, order updates, and alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: title.isNotEmpty ? title : body,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications.show(
      id: id,
      title: title.isNotEmpty ? title : kFcmAndroidChannelName,
      body: body.isNotEmpty ? body : title,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );

    debugPrint(
      'FCM notification shown (${fromBackgroundIsolate ? 'background' : 'foreground'}): $title',
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    developer.log(
      'Notification opened: ${message.data}',
      name: 'Firebase',
    );
    debugPrint('FCM notification opened: ${message.data}');
  }

  static String _titleFor(RemoteMessage message) {
    final n = message.notification;
    if (n?.title != null && n!.title!.trim().isNotEmpty) {
      return n.title!.trim();
    }
    final data = message.data;
    return (data['title'] ?? data['departmentName'] ?? '').toString().trim();
  }

  static String _bodyFor(RemoteMessage message) {
    final n = message.notification;
    if (n?.body != null && n!.body!.trim().isNotEmpty) {
      return n.body!.trim();
    }
    final data = message.data;
    final parts = <String>[
      if ((data['departmentName'] ?? '').toString().trim().isNotEmpty)
        data['departmentName'].toString().trim(),
      if ((data['jobId'] ?? '').toString().trim().isNotEmpty)
        'Job #${data['jobId']}',
      if ((data['customerName'] ?? '').toString().trim().isNotEmpty)
        data['customerName'].toString().trim(),
      if ((data['vehiclePlate'] ?? '').toString().trim().isNotEmpty)
        data['vehiclePlate'].toString().trim(),
    ];
    if (parts.isNotEmpty) return parts.join(' • ');
    return (data['body'] ?? data['message'] ?? '').toString().trim();
  }

  static int _notificationId(RemoteMessage message) {
    final key = message.messageId ??
        message.data['broadcastId'] ??
        message.data['jobId'] ??
        message.hashCode.toString();
    return key.hashCode.abs() % 2147483647;
  }

  static Future<void> _logToken(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('FCM TOKEN: (null or empty)');
      return;
    }
    _printToken('FCM TOKEN', token.trim());
  }

  static void _printToken(String label, String token) {
    developer.log('$label: $token', name: 'Firebase');
    debugPrint('══════════════════════════════════════');
    debugPrint('$label: $token');
    debugPrint('══════════════════════════════════════');
  }
}

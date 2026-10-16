import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'fcm_notification_service.dart';

/// Top-level handler required by Firebase for background / terminated data messages.
@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FcmNotificationService.ensureInitialized();
  await FcmNotificationService.showFromRemoteMessage(
    message,
    fromBackgroundIsolate: true,
  );
}

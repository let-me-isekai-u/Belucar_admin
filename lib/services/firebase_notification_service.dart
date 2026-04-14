import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNoti =
  FlutterLocalNotificationsPlugin();

  /// Background / terminated
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('[BG] Message: ${message.messageId}');
  }

  /// ⚠️ GỌI 1 LẦN ở main()
  static Future<void> init() async {
    // 1. Xin quyền
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('❌ Notification permission denied');
      return;
    }

    debugPrint('✅ Notification permission granted');

    // 2. Foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Local notification (iOS)
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNoti.initialize(
      const InitializationSettings(iOS: iosInit),
    );

    // 4. Listen message
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
  }

  /// 🔑 Login dùng hàm này
  static Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('📩 FCM TOKEN: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Get FCM token error: $e');
      return null;
    }
  }

  /// (OPTIONAL) Token refresh – dùng sau này nếu cần
  static void listenTokenRefresh({
    required Future<String?> Function() getAccessToken,
    required Future<void> Function(String token) onNewToken,
  }) {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM token refreshed: $newToken');
      await onNewToken(newToken);
    });
  }

  static void _onMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNoti.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static void _onMessageOpened(RemoteMessage message) {
    debugPrint(
        '📩 Opened from notification: ${message.notification?.title}');
  }
}

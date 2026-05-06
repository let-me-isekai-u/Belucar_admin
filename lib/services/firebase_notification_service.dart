import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  static bool _isFirebaseReady = false;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> configure() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseReady = true;
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('Firebase init skipped: ${_firebaseErrorMessage(e)}');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await init();
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('[BG] Firebase init skipped: ${_firebaseErrorMessage(e)}');
      return;
    }

    debugPrint('[BG] Message: ${message.messageId}');
  }

  static Future<void> init() async {
    if (!_isFirebaseReady) {
      debugPrint('Notification service skipped: Firebase is not configured.');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('Notification permission denied');
      return;
    }

    debugPrint('Notification permission granted');

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      await messaging.subscribeToTopic('admin');
      debugPrint('Subscribed to topic: admin');
    } catch (e) {
      debugPrint('Subscribe topic error: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
  }

  static Future<String?> getDeviceToken() async {
    if (!_isFirebaseReady) {
      debugPrint('FCM token skipped: Firebase is not configured.');
      return null;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM token: $token');
      return token;
    } catch (e) {
      debugPrint('Get FCM token error: $e');
      return null;
    }
  }

  static void listenTokenRefresh({
    required Future<String?> Function() getAccessToken,
    required Future<void> Function(String token) onNewToken,
  }) {
    if (!_isFirebaseReady) {
      debugPrint('FCM token refresh skipped: Firebase is not configured.');
      return;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      await onNewToken(newToken);
    });
  }

  static void _onMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'admin',
          'Admin notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static void _onMessageOpened(RemoteMessage message) {
    debugPrint('Opened from notification: ${message.notification?.title}');
  }

  static String _firebaseErrorMessage(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// Background handler — wajib top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'bank_sampah_channel',
    'Bank Sampah Notifikasi',
    description: 'Notifikasi setoran, penukaran, dan info Bank Sampah.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    // Skip FCM untuk platform web
    if (kIsWeb) return;

    // 1. Minta izin — dibungkus try-catch agar tidak hang
    try {
      final settings = await _fcm
          .requestPermission(
            alert:       true,
            badge:       true,
            sound:       true,
            provisional: false,
          )
          .timeout(const Duration(seconds: 5));

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Izin ditolak user.');
        return;
      }
    } catch (e) {
      // Timeout atau error permission — lanjut saja, notif tidak fatal
      debugPrint('FCM permission error (non-fatal): $e');
    }

    // 2. Setup local notifications
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit     = DarwinInitializationSettings();
      await _localNotif.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _onNotifTapped,
      );

      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    } catch (e) {
      debugPrint('FCM local notif setup error (non-fatal): $e');
    }

    // 3. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Foreground handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 5. Tap dari background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotifOpened);

    // 6. Tap dari terminated
    try {
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) _onNotifOpened(initialMessage);
    } catch (e) {
      debugPrint('FCM getInitialMessage error (non-fatal): $e');
    }

    // 7. Kirim token ke Laravel — non-blocking
    _sendTokenToServer();

    // 8. Auto refresh token
    _fcm.onTokenRefresh.listen(_updateTokenOnServer);
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> _sendTokenToServer() async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;
      debugPrint('FCM Token OK: ${token.substring(0, 20)}...');
      await ApiClient.instance.post(
        '/update-fcm-token',
        data: {'fcm_token': token},
      );
    } catch (e) {
      debugPrint('FCM send token error (non-fatal): $e');
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      await ApiClient.instance.post(
        '/update-fcm-token',
        data: {'fcm_token': token},
      );
    } catch (e) {
      debugPrint('FCM update token error (non-fatal): $e');
    }
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  static void _onForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority:   Priority.high,
          icon:       '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  static void _onNotifOpened(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null) return;
    _navigateTo(route);
  }

  static void _onNotifTapped(NotificationResponse response) {
    final route = response.payload;
    if (route == null) return;
    _navigateTo(route);
  }

  /// Navigasi ke route menggunakan navigatorKey dari api_client.dart
  static void _navigateTo(String route) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushNamed(route);
  }
}
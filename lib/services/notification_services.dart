import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/env_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static late AndroidNotificationChannel _channel;
  static bool _isInitialized = false;

  static String get _backendUrl => EnvConfig.notificationBackendUrl;
  static String? get _apiKey => EnvConfig.notificationBackendUrl;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      _channel = const AndroidNotificationChannel(
        'chat_channel',
        'Chat Notifications',
        description: 'Notifications for chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        throw Exception('NotificationService initialization failed: $e');
      }
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null && !kIsWeb) {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          notification.body ?? '',
          contentTitle: notification.title,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'New Message',
        notification.body ?? '',
        details,
        payload: jsonEncode(message.data),
      );
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _processNotificationData(message.data);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _processNotificationData(data);
      } catch (e) {
        if (kDebugMode) {
          rethrow;
        }
      }
    }
  }

  static void _processNotificationData(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'message':
        break;
      case 'friend_request':
        break;
      case 'request_accepted':
        break;
      default:
        break;
    }
  }

  static Future<void> _handleTokenRefresh(String token) async {
    await updateTokenInFirestore(token);
  }

  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await updateTokenInFirestore(token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateTokenInFirestore(String token) async {}

  static Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      if (_backendUrl.isEmpty) {
        return false;
      }

      final headers = <String, String>{'Content-Type': 'application/json'};

      if (_apiKey != null) {
        headers['x-api-key'] = _apiKey!;
      }

      final payload = {
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
      };

      final response = await http.post(
        Uri.parse('$_backendUrl/send-notification'),
        headers: headers,
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, int>> sendBatchNotifications({
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      if (_backendUrl.isEmpty) {
        return {'successCount': 0, 'failureCount': notifications.length};
      }

      final headers = <String, String>{'Content-Type': 'application/json'};

      if (_apiKey != null) {
        headers['x-api-key'] = _apiKey!;
      }

      final payload = {'notifications': notifications};

      final response = await http.post(
        Uri.parse('$_backendUrl/send-notifications-batch'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'successCount': result['successCount'],
          'failureCount': result['failureCount'],
        };
      } else {
        return {'successCount': 0, 'failureCount': notifications.length};
      }
    } catch (e) {
      return {'successCount': 0, 'failureCount': notifications.length};
    }
  }

  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        rethrow;
      }
    }
  }

  static Future<RemoteMessage?> getInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message != null) {
        _processNotificationData(message.data);
      }
      return message;
    } catch (e) {
      return null;
    }
  }
}

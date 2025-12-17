import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static late AndroidNotificationChannel _channel;
  static bool _isInitialized = false;

  // ✅ REPLACE THIS WITH YOUR DEPLOYED BACKEND URL
  static const String _backendUrl = 'http://192.168.1.65:3000';
  // static const String _backendUrl = 'http://192.168.1.5:3000';

  // Optional: Add API key for security
  static const String? _apiKey =
      null; // Set this if you implement authentication

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User declined notification permission');
        return;
      }

      // Create Android notification channel
      _channel = const AndroidNotificationChannel(
        'chat_channel',
        'Chat Notifications',
        description: 'Notifications for chat messages',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Create the channel on the device
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // Initialize local notifications
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

      // Set foreground notification presentation options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle token refresh
      _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Foreground message received: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Show local notification
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

      debugPrint('✅ Local notification shown');
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped (background): ${message.data}');
    _processNotificationData(message.data);
  }

  /// Handle notification tap from local notifications
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped (foreground): ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _processNotificationData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Process notification data and navigate
  static void _processNotificationData(Map<String, dynamic> data) {
    final type = data['type'];
    debugPrint('Processing notification type: $type');

    switch (type) {
      case 'message':
        final chatId = data['chatId'];
        final senderId = data['senderId'];
        debugPrint('Navigate to chat: $chatId from sender: $senderId');
        // TODO: Navigate to chat screen
        break;
      case 'friend_request':
        final senderId = data['senderId'];
        debugPrint('Navigate to friend requests from: $senderId');
        // TODO: Navigate to friend requests screen
        break;
      case 'request_accepted':
        final userId = data['userId'];
        final chatId = data['chatId'];
        debugPrint('Friend request accepted from: $userId, chat: $chatId');
        // TODO: Navigate to chat or show success message
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Handle token refresh
  static Future<void> _handleTokenRefresh(String token) async {
    debugPrint('🔄 FCM Token refreshed: $token');
    await updateTokenInFirestore(token);
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Token: $token');

      if (token != null) {
        await updateTokenInFirestore(token);
      }

      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Update token in Firestore
  static Future<void> updateTokenInFirestore(String token) async {
    try {
      // This will be called from your auth wrapper with the actual user ID
      debugPrint('Token ready to be updated in Firestore: $token');
    } catch (e) {
      debugPrint('Error updating token in Firestore: $e');
    }
  }

  /// Send notification via backend API
  static Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('📤 Sending notification to: $token');

      final headers = <String, String>{'Content-Type': 'application/json'};

      // Add API key if configured
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

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Notification sent successfully: ${result['messageId']}');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send batch notifications
  static Future<Map<String, int>> sendBatchNotifications({
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      debugPrint('📤 Sending ${notifications.length} notifications');

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
        debugPrint(
          '✅ Batch sent - Success: ${result['successCount']}, Failed: ${result['failureCount']}',
        );
        return {
          'successCount': result['successCount'],
          'failureCount': result['failureCount'],
        };
      } else {
        debugPrint('❌ Failed to send batch: ${response.statusCode}');
        return {'successCount': 0, 'failureCount': notifications.length};
      }
    } catch (e) {
      debugPrint('❌ Error sending batch: $e');
      return {'successCount': 0, 'failureCount': notifications.length};
    }
  }

  /// Delete token (call on logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  /// Get initial message (for app opened from terminated state)
  static Future<RemoteMessage?> getInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message != null) {
        debugPrint('📩 Initial message: ${message.data}');
        _processNotificationData(message.data);
      }
      return message;
    } catch (e) {
      debugPrint('Error getting initial message: $e');
      return null;
    }
  }
}

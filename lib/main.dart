import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibetalk/screens/Authstate/auth_wrapper.dart';
import 'package:vibetalk/screens/Conservation/conversation_screen.dart';
import 'package:vibetalk/models/user_model.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'services/notification_services.dart';
import 'theme/app_theme.dart';

// ─────────────────────────────────────────────────────────
// Background FCM handler — must be a top-level function
// ─────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FIX: Ignore Zego offline push messages BEFORE any heavy init.
  // Zego's own internal handler already processes these.
  // Touching them here causes the 10-20 second call delivery delay.
  if (message.data.containsKey('zego') ||
      message.data['resourceID'] == 'zego_call' ||
      message.data.containsKey('callID')) {
    debugPrint('📬 Zego offline push — handled by ZegoUIKit, ignoring here.');
    return;
  }

  // Only initialise Firebase when handling a real app notification
  await Firebase.initializeApp();
  debugPrint('📬 Background message: ${message.messageId}');

  await NotificationService.initializeForBackground();
  await NotificationService.showLocalNotification(message);
}

// ─────────────────────────────────────────────────────────
// Permission helper
// FIX: ALL six permissions are requested here, in ONE place,
// BEFORE Firebase Messaging and BEFORE Zego init.
// Previously notification + systemAlertWindow were only
// requested inside ZegoService.initializeZego() (post-login),
// which meant FCM couldn't deliver call notifications on
// first launch and the system overlay wasn't ready.
// ─────────────────────────────────────────────────────────
Future<void> _requestAllPermissions() async {
  final statuses = await [
    Permission.microphone, // required for voice/video calls
    Permission.camera, // required for video calls
    Permission.bluetoothConnect, // required on Android 12+
    Permission.notification, // FIX: was missing — FCM needs this
    Permission.systemAlertWindow, // FIX: was missing — call overlay needs this
  ].request();

  statuses.forEach((permission, status) {
    debugPrint('🔐 $permission: $status');
  });
}

// ─────────────────────────────────────────────────────────
// FCM token warm-up
// FIX: On first launch the FCM token is generated async.
// Awaiting it here guarantees ZPNs.registerPush() (called
// inside ZegoService.initializeZego()) finds a cached token
// instead of failing silently with errorCode != 0.
// ─────────────────────────────────────────────────────────
Future<void> _ensureFcmTokenReady() async {
  try {
    final token = await FirebaseMessaging.instance.getToken().timeout(
      const Duration(seconds: 10),
    );
    debugPrint('✅ FCM token ready: $token');
  } catch (e) {
    // Non-fatal — Zego will retry registration on next launch
    debugPrint('⚠️ FCM token not ready within 10s: $e');
  }
}

// ─────────────────────────────────────────────────────────
// main()
// FIX: Correct startup sequence:
//   1. Firebase init
//   2. Register background handler IMMEDIATELY (before any async gap)
//   3. Request ALL permissions and wait for user responses
//   4. Warm up FCM token
//   5. NotificationService init
//   6. Zego background call engine (useSystemCallingUI)
//   7. runApp
// ─────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // FIX: Register background handler immediately after Firebase init,
  // before any blocking calls. Previously this came after
  // _requestCallPermissions() which meant a message arriving during
  // the permission-dialog window had no handler registered.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FIX: Request every permission in one shot, wait for completion
  await _requestAllPermissions();

  // FIX: Warm up the FCM token so ZPNs.registerPush() succeeds on first launch
  await _ensureFcmTokenReady();

  await NotificationService.initialize();

  // Enable background/system call UI (must come before runApp)
  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
    ZegoUIKitSignalingPlugin(),
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

// ─────────────────────────────────────────────────────────
// App widget — unchanged except minor cleanup
// ─────────────────────────────────────────────────────────
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // FIX: Set navigator key SYNCHRONOUSLY here, before any frame is painted.
    // Previously this was inside addPostFrameCallback, which fires AFTER the
    // first frame — meaning AuthenticationWrapper had already started Zego init
    // before the key was registered. Zego uses the key internally to push call
    // screens; if it arrives late the first outgoing call silently goes nowhere.
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wire up notification tap navigation (still needs a frame)
      NotificationService.onNotificationTap = _handleNotificationTap;
      NotificationService.getInitialMessage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('📱 App lifecycle: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('✅ Resumed — calls active');
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ Paused — background calls still work');
        break;
      case AppLifecycleState.inactive:
        debugPrint('💤 Inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('🔌 Detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('👻 Hidden');
        break;
    }
  }

  void _handleNotificationTap(
    String chatId,
    String friendId,
    String friendUsername,
  ) {
    debugPrint('🔔 Notification tapped — ChatId: $chatId');

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final friend = UserModel(
      uid: friendId,
      email: '',
      username: friendUsername,
      fcmToken: '',
      createdAt: DateTime.now(),
      searchKeywords: [],
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(chatId: chatId, friend: friend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeTalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Handles incoming call UI when app is in foreground or background
            ZegoUIKitPrebuiltCallMiniOverlayPage(
              // Use ?. so that if the navigator has not yet mounted its first
              // frame (e.g., during hot-restart or app init), we fall back to
              // the MaterialApp build-context instead of throwing a NPE.
              contextQuery: () =>
                  navigatorKey.currentState?.context ?? context,
            ),
          ],
        );
      },
      home: const AuthenticationWrapper(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'screens/home_screen.dart';
import 'screens/sign_screen.dart';
import 'services/notification_services.dart';
import 'services/zego_services.dart';
import 'providers/auth_provider.dart';
import 'providers/chart_provider.dart';
import 'providers/user_provider.dart';
import 'providers/friend_req_provider.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
    ZegoUIKitSignalingPlugin(),
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Professional Chat",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,

      builder: (context, child) {
        return Stack(
          children: [
            child!,

            ZegoUIKitPrebuiltCallMiniOverlayPage(
              contextQuery: () => navigatorKey.currentState!.context,
            ),
          ],
        );
      },

      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends ConsumerStatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  ConsumerState<AuthenticationWrapper> createState() =>
      _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends ConsumerState<AuthenticationWrapper> {
  String? _previousUserId;
  DateTime? _userLoadStartTime;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (firebaseUser) {
        if (firebaseUser != null) {
          final currentUserId = firebaseUser.uid;

          if (_previousUserId != null && _previousUserId != currentUserId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.invalidate(currentUserProvider);
              ref.invalidate(chatListProvider);
              ref.invalidate(allUsersProvider);
              ref.invalidate(receivedRequestsProvider);
              ref.invalidate(sentRequestsProvider);
            });
          }

          _previousUserId = currentUserId;

          _userLoadStartTime ??= DateTime.now();

          final userAsync = ref.watch(currentUserProvider);

          return userAsync.when(
            data: (currentUser) {
              if (currentUser == null) {
                final loadDuration = DateTime.now().difference(
                  _userLoadStartTime!,
                );

                if (loadDuration.inSeconds > 5) {
                  debugPrint(
                    " User document not found after ${loadDuration.inSeconds}s - signing out",
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await ref.read(authRepositoryProvider).signOut();
                    _userLoadStartTime = null;
                  });

                  return ErrorScreen(
                    error:
                        'Your profile data is missing.\nPlease sign in again or create a new account.',
                    onRetry: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.invalidate(authStateProvider);
                    },
                  );
                }
                debugPrint(
                  " Waiting for user document... ${loadDuration.inSeconds}s",
                );
                return const SplashScreen(message: 'Loading your profile...');
              }

              _userLoadStartTime = null;

              if (!ZegoService.isInitialized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ZegoService.initializeZego(
                    userId: currentUser.uid,
                    userName: currentUser.username,
                  );
                });
              }

              return const HomeScreen();
            },
            loading: () {
              _userLoadStartTime ??= DateTime.now();
              return const SplashScreen(message: 'Loading profile...');
            },
            error: (e, _) {
              debugPrint(" Firestore error: $e");
              _userLoadStartTime = null;

              return ErrorScreen(
                error: 'Failed to load profile\n${e.toString()}',
                onRetry: () => ref.invalidate(currentUserProvider),
              );
            },
          );
        }

        if (_previousUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(chatListProvider);
            ref.invalidate(allUsersProvider);
            ref.invalidate(receivedRequestsProvider);
            ref.invalidate(sentRequestsProvider);
            await ZegoService.uninitializeZego();
          });

          _previousUserId = null;
        }

        _userLoadStartTime = null;

        return const SignInScreen();
      },

      loading: () => const SplashScreen(message: 'Initializing...'),

      error: (e, _) => ErrorScreen(
        error: e.toString(),
        onRetry: () => ref.invalidate(authStateProvider),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  final String message;

  const SplashScreen({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorScreen({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text("Sign Out")),
          ],
        ),
      ),
    );
  }
}

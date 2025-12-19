import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_chart/providers/auth_provider.dart';
import 'package:new_chart/providers/chart_provider.dart';
import 'package:new_chart/providers/friend_req_provider.dart';
import 'package:new_chart/providers/user_provider.dart';
import 'package:new_chart/screens/Authstate/error_screen.dart';
import 'package:new_chart/screens/home_screen.dart';
import 'package:new_chart/screens/sign_screen.dart';
import 'package:new_chart/screens/splash_screen.dart';
import 'package:new_chart/services/zego_services.dart';

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

// lib/providers/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  return ref.watch(userRepositoryProvider).getUserStream(uid);
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield [];
    return;
  }

  final userRepository = ref.read(userRepositoryProvider);

  await for (final users in userRepository.getAllUsers(currentUser.uid)) {
    final filteredUsers = <UserModel>[];
    for (final user in users) {
      final isBlocked = await userRepository.isUserBlocked(
        currentUser.uid,
        user.uid,
      );
      if (!isBlocked) {
        filteredUsers.add(user);
      }
    }
    yield filteredUsers;
  }
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final filteredUsersProvider = StreamProvider<List<UserModel>>((ref) async* {
  final query = ref.watch(searchQueryProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    yield [];
    return;
  }

  final userRepository = ref.read(userRepositoryProvider);

  Stream<List<UserModel>> userStream;
  if (query.isEmpty) {
    userStream = userRepository.getAllUsers(currentUser.uid);
  } else {
    userStream = userRepository.searchUsers(query, currentUser.uid);
  }

  await for (final users in userStream) {
    // Filter out blocked users
    final filteredUsers = <UserModel>[];
    for (final user in users) {
      final isBlocked = await userRepository.isUserBlocked(
        currentUser.uid,
        user.uid,
      );
      if (!isBlocked) {
        filteredUsers.add(user);
      }
    }
    yield filteredUsers;
  }
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import '../models/user_model.dart';
import 'auth_provider.dart';

final userStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  return ref.watch(userRepositoryProvider).getUserStream(uid);
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  return ref.watch(userRepositoryProvider).getAllUsers(currentUser.uid);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) return Stream.value([]);

  if (query.isEmpty) {
    return ref.watch(userRepositoryProvider).getAllUsers(currentUser.uid);
  }

  return ref.watch(userRepositoryProvider).searchUsers(query, currentUser.uid);
});

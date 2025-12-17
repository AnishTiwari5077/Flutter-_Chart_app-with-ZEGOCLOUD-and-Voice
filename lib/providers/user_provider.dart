import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import '../models/user_model.dart';
import 'auth_provider.dart';

// ✅ REMOVED: Duplicate userRepositoryProvider (already in auth_provider.dart)
// Use the one from auth_provider instead

// ✅ User Stream Provider (for specific user by UID)
final userStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  return ref.watch(userRepositoryProvider).getUserStream(uid);
});

// ✅ All Users Provider (excluding current user)
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  return ref.watch(userRepositoryProvider).getAllUsers(currentUser.uid);
});

// ✅ Search Query State Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// ✅ Filtered Users Provider (based on search query)
final filteredUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) return Stream.value([]);

  if (query.isEmpty) {
    return ref.watch(userRepositoryProvider).getAllUsers(currentUser.uid);
  }

  return ref.watch(userRepositoryProvider).searchUsers(query, currentUser.uid);
});

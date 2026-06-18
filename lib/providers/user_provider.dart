import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

import 'auth_provider.dart';

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
  final blockedIds = Set<String>.from(currentUser.blockedUsers);

  try {
    await for (final users in userRepository.getAllUsers(currentUser.uid)) {
      final stillAuthenticated = ref.read(currentUserProvider).value;
      if (stillAuthenticated == null) {
        yield [];
        return;
      }
      // Filter locally — zero extra Firestore reads
      yield users.where((u) => !blockedIds.contains(u.uid)).toList();
    }
  } catch (e) {
    yield [];
  }
});

// Search query state — uses NotifierProvider (recommended Riverpod v2 pattern).
// Exposes explicit set() / clear() methods instead of raw .state mutation.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);


final filteredUsersProvider = StreamProvider<List<UserModel>>((ref) async* {
  final query = ref.watch(searchQueryProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    yield [];
    return;
  }

  final userRepository = ref.read(userRepositoryProvider);
  final blockedIds = Set<String>.from(currentUser.blockedUsers);

  try {
    final Stream<List<UserModel>> userStream = query.isEmpty
        ? userRepository.getAllUsers(currentUser.uid)
        : userRepository.searchUsers(query, currentUser.uid);

    await for (final users in userStream) {
      final stillAuthenticated = ref.read(currentUserProvider).value;
      if (stillAuthenticated == null) {
        yield [];
        return;
      }
      // Filter locally — zero extra Firestore reads
      yield users.where((u) => !blockedIds.contains(u.uid)).toList();
    }
  } catch (e) {
    yield [];
  }
});

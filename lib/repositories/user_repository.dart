import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromMap(doc.data()!);
        } catch (e) {
          // print('Error parsing UserModel: $e');
          return null;
        }
      }
      return null;
    });
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return UserModel.fromMap(doc.data());
                } catch (e) {
                  //  print('Error parsing user ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<UserModel>()
              .toList();
        });
  }

  Stream<List<UserModel>> searchUsers(String query, String currentUserId) {
    if (query.isEmpty) {
      return getAllUsers(currentUserId);
    }

    return _firestore
        .collection('users')
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return UserModel.fromMap(doc.data());
                } catch (e) {
                  //    print('Error parsing user ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<UserModel>()
              .where((user) => user.uid != currentUserId)
              .toList();
        });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUsername(String uid, String username) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'username': username,
        'searchKeywords': UserModel.generateSearchKeywords(username),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAvatar(String uid, String avatarUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': avatarUrl,
      });
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// ---------------- SIGN IN ----------------
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final fcmToken = await _messaging.getToken() ?? '';

        // ✅ Update online status
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'isOnline': true,
          'fcmToken': fcmToken,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// ---------------- SIGN UP ----------------
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? avatarUrl,
  }) async {
    try {
      print('🔐 Step 1: Creating Firebase Auth user...');

      // ✅ Step 1: Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('✅ Firebase Auth user created: ${credential.user!.uid}');
        print('📝 Step 2: Creating Firestore document...');

        final fcmToken = await _messaging.getToken() ?? '';

        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          username: username,
          avatarUrl: avatarUrl,
          isOnline: true,
          lastSeen: DateTime.now(),
          fcmToken: fcmToken,
          createdAt: DateTime.now(),
          searchKeywords: UserModel.generateSearchKeywords(username),
        );

        // ✅ Step 2: Create Firestore document
        // Using set() ensures the document is created
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toMap());

        print('✅ Firestore document created');
        print('🔍 Step 3: Verifying document...');

        // ✅ Step 3: Verify the document was written successfully
        // This ensures the document exists before returning
        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!doc.exists) {
          throw Exception('Failed to create user document in Firestore');
        }

        print('✅ Document verified. Sign up complete!');
      }

      return credential;
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// ---------------- SIGN OUT ----------------
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        // ✅ Update online status before signing out
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'isOnline': false,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }

      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// ------------- STATUS UPDATE -------------
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'isOnline': isOnline,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String fcmToken;
  final DateTime createdAt;
  final List<String> searchKeywords;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    required this.fcmToken,
    required this.createdAt,
    required this.searchKeywords,
  });

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'searchKeywords': searchKeywords,
    };
  }

  /// Create from Firestore Map - Handles multiple date formats
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: _parseDateTime(map['lastSeen']),
      fcmToken: map['fcmToken'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      searchKeywords: _parseSearchKeywords(map['searchKeywords']),
    );
  }

  /// Parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      // If it's a Firestore Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }

      // If it's milliseconds since epoch (int)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      // If it's a double (sometimes Firebase returns this)
      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }

      // If it's a String (ISO format)
      if (value is String) {
        return DateTime.parse(value);
      }

      return null;
    } catch (e) {
      print('Error parsing DateTime from $value: $e');
      return null;
    }
  }

  /// Parse search keywords safely
  static List<String> _parseSearchKeywords(dynamic value) {
    if (value == null) return [];

    try {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error parsing searchKeywords: $e');
      return [];
    }
  }

  /// Copy with method
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    DateTime? createdAt,
    List<String>? searchKeywords,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  /// Generate search keywords for username
  static List<String> generateSearchKeywords(String username) {
    List<String> keywords = [];
    String temp = "";
    for (int i = 0; i < username.length; i++) {
      temp = temp + username[i].toLowerCase();
      keywords.add(temp);
    }
    return keywords;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, email: $email, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

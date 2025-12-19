class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime timestamp;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      status: map['status'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

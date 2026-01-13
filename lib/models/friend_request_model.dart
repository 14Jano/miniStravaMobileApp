import 'user_model.dart';

class FriendRequest {
  final int id;
  final int senderId;
  final User sender;
  final String status;
  final String createdAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.sender,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      sender: User.fromJson(json['sender'] ?? {}),
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
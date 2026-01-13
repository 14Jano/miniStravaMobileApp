import 'feed_model.dart';

class Comment {
  final int id;
  final String content;
  final FeedUser user;
  final String createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.user,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    String formatDate(String? isoDate) {
      if (isoDate == null || isoDate.length < 16) return "Teraz";
      return isoDate.replaceAll('T', ' ').substring(0, 16);
    }

    return Comment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      user: FeedUser.fromJson(json['user'] ?? {}),
      createdAt: formatDate(json['created_at']),
    );
  }
}
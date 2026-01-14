class FeedUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  FeedUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  factory FeedUser.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return FeedUser(
      id: parseInt(json['id']), 
      firstName: json['first_name'] ?? 'Użytkownik',
      lastName: json['last_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class FeedItem {
  final int id;
  final FeedUser user;
  final String title;
  final String type;
  final String startTime;
  final double distanceKm;
  final String duration;
  final int kudosCount;
  final int commentsCount;
  final bool likedByMe;

  FeedItem({
    required this.id,
    required this.user,
    required this.title,
    required this.type,
    required this.startTime,
    required this.distanceKm,
    required this.duration,
    required this.kudosCount,
    required this.commentsCount,
    required this.likedByMe,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    String formatDuration(int seconds) {
      final int minutes = (seconds / 60).floor();
      final int remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }

    String formatDate(String? isoDate) {
      if (isoDate == null || isoDate.length < 10) return "Nieznana data";
      return isoDate.replaceAll('T', ' ').substring(0, 16);
    }

    return FeedItem(
      id: json['id'] ?? 0,
      user: FeedUser.fromJson(json['user'] ?? {}),
      title: json['title'] ?? 'Bez tytułu',
      type: json['type'] ?? 'activity',
      startTime: formatDate(json['start_time']),
      distanceKm: (json['distance_km'] ?? 0).toDouble(), 
      duration: formatDuration(json['duration_seconds'] ?? 0),
      kudosCount: json['kudos_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      likedByMe: json['liked_by_me'] ?? false,
    );
  }
}
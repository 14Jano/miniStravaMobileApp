class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? gender;
  final DateTime? birthDate;
  final int? weightKg;
  final int? heightCm;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.gender,
    this.birthDate,
    this.weightKg,
    this.heightCm,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    int? parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return User(
      id: parseInt(json['id']),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gender: json['gender']?.toString(),
      birthDate: json['birth_date'] != null 
          ? DateTime.tryParse(json['birth_date'].toString()) 
          : null,
      weightKg: parseIntNullable(json['weight_kg']),
      heightCm: parseIntNullable(json['height_cm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().substring(0, 10),
      'weight_kg': weightKg,
      'height_cm': heightCm,
    };
  }
}

class UserStats {
  final String period;
  final int workouts;
  final double distanceKm;
  final int durationSeconds;
  final double? avgSpeedKmh;

  UserStats({
    required this.period,
    required this.workouts,
    required this.distanceKm,
    required this.durationSeconds,
    this.avgSpeedKmh,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return UserStats(
      period: json['period'] ?? '',
      workouts: parseInt(json['workouts']),
      distanceKm: parseDouble(json['distance_km']),
      durationSeconds: parseInt(json['duration_seconds']),
      avgSpeedKmh: json['avg_speed_kmh'] != null ? parseDouble(json['avg_speed_kmh']) : null,
    );
  }
}
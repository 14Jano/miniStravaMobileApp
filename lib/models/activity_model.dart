import 'package:latlong2/latlong.dart';

class Activity {
  final int id;
  final String title;
  final String type;
  
  final DateTime startTime; 
  final DateTime endTime;
  final int durationSeconds;
  final double distanceMeters;
  
  final List<LatLng> routePoints;

  Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.routePoints,
  });

  String get formattedDate => startTime.toString().substring(0, 16).replaceAll('T', ' ');
  
  String get formattedDuration {
    final int minutes = (durationSeconds / 60).floor();
    final int remainingSeconds = durationSeconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  double get distanceKm => distanceMeters / 1000;

  factory Activity.fromJson(Map<String, dynamic> json) {
    List<LatLng> parseRoute(List<dynamic>? routeJson) {
      if (routeJson == null) return [];
      return routeJson.map((point) {
        final lat = (point['lat'] is num) ? (point['lat'] as num).toDouble() : double.parse(point['lat'].toString());
        final lng = (point['lng'] is num) ? (point['lng'] as num).toDouble() : double.parse(point['lng'].toString());
        return LatLng(lat, lng);
      }).toList();
    }

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

    double meters = parseDouble(json['distance_meters']);
    if (meters == 0 && json['distance_km'] != null) {
      meters = parseDouble(json['distance_km']) * 1000;
    }

    return Activity(
      id: parseInt(json['id']),
      title: json['title'] ?? 'Bez tytułu',
      type: json['type'] ?? 'run',
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now(),
      durationSeconds: parseInt(json['duration_seconds']),
      distanceMeters: meters,
      routePoints: parseRoute(json['route']),
    );
  }
}
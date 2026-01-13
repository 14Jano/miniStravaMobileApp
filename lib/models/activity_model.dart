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
  final String? notes;
  final String? photoUrl;

  Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.routePoints,
    this.notes,
    this.photoUrl,
  });

  String get formattedDate => startTime.toString().substring(0, 16).replaceAll('T', ' ');
  
  String get formattedDuration {
    final int hours = durationSeconds ~/ 3600;
    final int minutes = (durationSeconds % 3600) ~/ 60;
    final int remainingSeconds = durationSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  double get distanceKm => distanceMeters / 1000;

  String get formattedPace {
    if (distanceMeters == 0) return '-:--';
    
    final double distKm = distanceMeters / 1000;
    final double totalMinutes = (durationSeconds / 60);
    
    final double paceDecimal = totalMinutes / distKm;
    
    if (paceDecimal > 60) return ">60:00 /km";

    final int minutes = paceDecimal.floor();
    final int seconds = ((paceDecimal - minutes) * 60).round();
    
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    List<LatLng> parseRoute(dynamic routeData) {
      if (routeData == null) return [];
      if (routeData is List) {
        return routeData.map((point) {
          if (point is Map<String, dynamic>) {
            final lat = (point['lat'] is num) ? (point['lat'] as num).toDouble() : double.tryParse(point['lat'].toString()) ?? 0.0;
            final lng = (point['lng'] is num) ? (point['lng'] as num).toDouble() : double.tryParse(point['lng'].toString()) ?? 0.0;
            return LatLng(lat, lng);
          }
          return const LatLng(0, 0);
        }).toList();
      }
      return [];
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

    String? parsePhotoUrl(dynamic url) {
      if (url == null) return null;
      String path = url.toString();
      if (path.isEmpty) return null;
      
      if (path.startsWith('http')) {
        return path;
      }
      
      const String baseUrl = 'https://strava.host358482.xce.pl';
      
      if (path.startsWith('/')) {
        return '$baseUrl$path';
      }
      
      return '$baseUrl/$path';
    }

    return Activity(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? 'Bez tytułu',
      type: json['type']?.toString() ?? 'run',
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time']?.toString() ?? '') ?? DateTime.now(),
      durationSeconds: parseInt(json['duration_seconds']),
      distanceMeters: meters,
      routePoints: parseRoute(json['route']),
      notes: json['notes']?.toString(),
      photoUrl: parsePhotoUrl(json['photo_url']),
    );
  }
}
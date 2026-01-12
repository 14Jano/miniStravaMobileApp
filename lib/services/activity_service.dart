import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/activity_model.dart';

class ActivityService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api';
  final _storage = const FlutterSecureStorage();

  Future<List<Activity>> getActivities() async {
    final token = await _storage.read(key: 'auth_token');
    
    final url = Uri.parse('$_baseUrl/activities');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        if (body.containsKey('data')) {
          final List<dynamic> data = body['data'];
          return data.map((json) => Activity.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        print('Błąd pobierania: ${response.statusCode} ${response.body}');
        throw Exception('Nie udało się pobrać treningów');
      }
    } catch (e) {
      print('Błąd serwisu: $e');
      rethrow;
    }
  }

  Future<bool> createActivity({
    required String title,
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required double distanceMeters,
    required List<LatLng> routePoints,
    String? notes,
    File? imageFile,
  }) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities');
    
    final routeJson = routePoints.map((point) => {
      'lat': point.latitude,
      'lng': point.longitude,
    }).toList();

    try {
      if (imageFile == null) {
        // --- Wersja bez zdjęcia (zwykły JSON) ---
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'type': type,
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'duration_seconds': durationSeconds,
            'distance_meters': distanceMeters,
            'route': routeJson,
            'notes': notes,
          }),
        );
        return (response.statusCode == 200 || response.statusCode == 201);

      } else {
        // --- Wersja ze zdjęciem (Multipart) ---
        var request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';
        
        request.fields['title'] = title;
        request.fields['type'] = type;
        request.fields['start_time'] = startTime.toIso8601String();
        request.fields['end_time'] = endTime.toIso8601String();
        request.fields['duration_seconds'] = durationSeconds.toString();
        request.fields['distance_meters'] = distanceMeters.toString();
        if (notes != null) request.fields['notes'] = notes;
        
        // Ważne: Przesyłamy tablicę route jako string JSON,
        // backend musi to obsłużyć (zdekodować) lub przyjąć w takiej formie.
        request.fields['route'] = jsonEncode(routeJson);

        request.files.add(await http.MultipartFile.fromPath(
          'photo', // Nazwa pola pliku (może wymagać zmiany na 'image' lub 'file' w zależności od API)
          imageFile.path,
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Trening ze zdjęciem zapisany!');
          return true;
        } else {
          print('Błąd uploadu: ${response.body}');
          return false;
        }
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return false;
    }
  }

  Future<Activity?> getActivityDetails(int id) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$id');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        
        if (body is Map<String, dynamic> && body.containsKey('data')) {
           return Activity.fromJson(body['data']);
        } else {
           return Activity.fromJson(body);
        }
      } else {
        print('Błąd pobierania szczegółów: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return null;
    }
  }

  Future<bool> updateActivity(Activity activity) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/${activity.id}');

   
    final routeJson = activity.routePoints.map((point) => {
      'lat': point.latitude,
      'lng': point.longitude,
    }).toList();

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': activity.title,
          'type': activity.type,
          'start_time': activity.startTime.toIso8601String().substring(0, 19),
          'end_time': activity.endTime.toIso8601String().substring(0, 19),
          'duration_seconds': activity.durationSeconds,
          'distance_meters': activity.distanceMeters,
          'route': routeJson,
          'photo_url': "",
          'gpx_path': "",
        }),
      );

      if (response.statusCode == 200) {
        print('Trening zaktualizowany!');
        return true;
      } else {
        print('Błąd aktualizacji: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return false;
    }
  }

  Future<bool> deleteActivity(int id) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$id');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Trening usunięty!');
        return true;
      } else {
        print('Błąd usuwania: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return false;
    }
  }

  Future<String?> exportGpx(int id) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$id/export.gpx');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        print('Brak trasy do wyeksportowania (404)');
        return null;
      } else {
        print('Błąd eksportu: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return null;
    }
  }
}
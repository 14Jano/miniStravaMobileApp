import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/activity_model.dart';

class ActivityService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api';
  final _storage = const FlutterSecureStorage();
  static const String _pendingFile = 'pending_activities.json';

  Future<List<Activity>> getActivities() async {
    final token = await _storage.read(key: 'auth_token');
    final isOffline = await _storage.read(key: 'is_offline') == 'true';
    
    List<Activity> serverActivities = [];
    List<Activity> localActivities = await _getLocalPendingAsActivities();

    if (!isOffline) {
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
            serverActivities = data.map((json) => Activity.fromJson(json)).toList();
          }
        }
      } catch (e) {
        print('Błąd pobierania z serwera: $e');
      }
    }

    return [...localActivities, ...serverActivities];
  }

  Future<List<Activity>> _getLocalPendingAsActivities() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_pendingFile');
      
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      List<dynamic> pendingList = jsonDecode(content);
      List<Activity> activities = [];

      for (var item in pendingList) {
        final List<dynamic> routeData = item['route'];
        final List<LatLng> route = routeData.map((p) => LatLng(p['lat'], p['lng'])).toList();
        
        activities.add(Activity(
          id: -1 * DateTime.parse(item['start_time']).millisecondsSinceEpoch, 
          title: item['title'] ?? 'Lokalna aktywność',
          type: item['type'] ?? 'run',
          startTime: DateTime.parse(item['start_time']),
          endTime: DateTime.parse(item['end_time']),
          durationSeconds: item['duration_seconds'],
          distanceMeters: (item['distance_meters'] as num).toDouble(),
          routePoints: route,
          notes: item['notes'],
          photoUrl: item['image_path'], 
        ));
      }
      return activities.reversed.toList();
    } catch (e) {
      print('Błąd odczytu lokalnych aktywności: $e');
      return [];
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
    final isOffline = await _storage.read(key: 'is_offline') == 'true';
    
    if (isOffline) {
      await _savePendingActivity(
        title: title,
        type: type,
        startTime: startTime,
        endTime: endTime,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        routePoints: routePoints,
        notes: notes,
        imagePath: imageFile?.path,
      );
      return true;
    }

    final url = Uri.parse('$_baseUrl/activities');
    final routeJson = routePoints.map((point) => {
      'lat': point.latitude,
      'lng': point.longitude,
    }).toList();

    try {
      if (imageFile == null) {
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
            'distance_meters': distanceMeters.toInt(),
            'route': routeJson,
            'notes': notes,
          }),
        );
        return (response.statusCode == 200 || response.statusCode == 201);

      } else {
        var request = http.MultipartRequest('POST', url);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
        
        request.fields['title'] = title;
        request.fields['type'] = type;
        request.fields['start_time'] = startTime.toIso8601String();
        request.fields['end_time'] = endTime.toIso8601String();
        request.fields['duration_seconds'] = durationSeconds.toString();
        request.fields['distance_meters'] = distanceMeters.toInt().toString();
        if (notes != null) request.fields['notes'] = notes;
        
        for (int i = 0; i < routePoints.length; i++) {
          request.fields['route[$i][lat]'] = routePoints[i].latitude.toString();
          request.fields['route[$i][lng]'] = routePoints[i].longitude.toString();
        }

        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        return (response.statusCode == 200 || response.statusCode == 201);
      }
    } catch (e) {
      await _savePendingActivity(
        title: title,
        type: type,
        startTime: startTime,
        endTime: endTime,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        routePoints: routePoints,
        notes: notes,
        imagePath: imageFile?.path,
      );
      return true;
    }
  }

  Future<void> _savePendingActivity({
    required String title,
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required double distanceMeters,
    required List<LatLng> routePoints,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_pendingFile');
      
      List<dynamic> pendingList = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          pendingList = jsonDecode(content);
        }
      }

      String? savedImagePath;
      if (imagePath != null) {
        final sourceFile = File(imagePath);
        final newPath = '${directory.path}/offline_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await sourceFile.copy(newPath);
        savedImagePath = newPath;
      }

      final activityMap = {
        'title': title,
        'type': type,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'route': routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'notes': notes,
        'image_path': savedImagePath,
      };

      pendingList.add(activityMap);
      await file.writeAsString(jsonEncode(pendingList));
    } catch (e) {
      print('Błąd zapisu offline: $e');
    }
  }

  Future<int> syncPendingActivities() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_pendingFile');

      if (!await file.exists()) return 0;

      final content = await file.readAsString();
      if (content.isEmpty) return 0;

      List<dynamic> pendingList = jsonDecode(content);
      List<dynamic> failedList = [];
      int syncedCount = 0;

      for (var item in pendingList) {
        final List<dynamic> routeData = item['route'];
        final List<LatLng> route = routeData.map((p) => LatLng(p['lat'], p['lng'])).toList();
        
        File? imageFile;
        if (item['image_path'] != null) {
          final f = File(item['image_path']);
          if (await f.exists()) imageFile = f;
        }

        bool success = await _uploadActivity(
          title: item['title'],
          type: item['type'],
          startTime: DateTime.parse(item['start_time']),
          endTime: DateTime.parse(item['end_time']),
          durationSeconds: item['duration_seconds'],
          distanceMeters: item['distance_meters'],
          routePoints: route,
          notes: item['notes'],
          imageFile: imageFile,
        );

        if (success) {
          syncedCount++;
          if (imageFile != null) {
            try { await imageFile.delete(); } catch (_) {}
          }
        } else {
          failedList.add(item);
        }
      }

      if (failedList.isEmpty) {
        await file.delete();
      } else {
        await file.writeAsString(jsonEncode(failedList));
      }

      return syncedCount;
    } catch (e) {
      print('Błąd synchronizacji: $e');
      return 0;
    }
  }

  Future<bool> _uploadActivity({
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
    
    try {
      if (imageFile == null) {
        final routeJson = routePoints.map((point) => {
          'lat': point.latitude,
          'lng': point.longitude,
        }).toList();

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
            'distance_meters': distanceMeters.toInt(),
            'route': routeJson,
            'notes': notes,
          }),
        );
        return (response.statusCode == 200 || response.statusCode == 201);
      } else {
        var request = http.MultipartRequest('POST', url);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
        
        request.fields['title'] = title;
        request.fields['type'] = type;
        request.fields['start_time'] = startTime.toIso8601String();
        request.fields['end_time'] = endTime.toIso8601String();
        request.fields['duration_seconds'] = durationSeconds.toString();
        request.fields['distance_meters'] = distanceMeters.toInt().toString();
        if (notes != null) request.fields['notes'] = notes;
        
        for (int i = 0; i < routePoints.length; i++) {
          request.fields['route[$i][lat]'] = routePoints[i].latitude.toString();
          request.fields['route[$i][lng]'] = routePoints[i].longitude.toString();
        }

        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        return (response.statusCode == 200 || response.statusCode == 201);
      }
    } catch (e) {
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
        return null;
      }
    } catch (e) {
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
          'start_time': activity.startTime.toIso8601String(),
          'end_time': activity.endTime.toIso8601String(),
          'duration_seconds': activity.durationSeconds,
          'distance_meters': activity.distanceMeters.toInt(),
          'route': routeJson,
          'notes': activity.notes, 
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
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

      return (response.statusCode == 200 || response.statusCode == 204);
    } catch (e) {
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
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
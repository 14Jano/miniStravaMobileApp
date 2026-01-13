import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class UserService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api';
  final _storage = const FlutterSecureStorage();

  Future<User?> getUserProfile() async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/profile');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile(User user, {File? avatarFile}) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/profile');

    try {
      final request = http.MultipartRequest('POST', url);
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';

      request.fields['first_name'] = user.firstName;
      request.fields['last_name'] = user.lastName;
      
      if (user.gender != null) request.fields['gender'] = user.gender!;
      if (user.birthDate != null) {
        request.fields['birth_date'] = user.birthDate!.toIso8601String().split('T')[0];
      }
      if (user.weightKg != null) request.fields['weight_kg'] = user.weightKg.toString();
      if (user.heightCm != null) request.fields['height_cm'] = user.heightCm.toString();
      if (user.bio != null) request.fields['bio'] = user.bio!;

      if (avatarFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<UserStats?> getUserStats({String period = 'week'}) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/stats/me?period=$period');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return UserStats.fromJson(body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
import 'dart:convert';
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
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map<String, dynamic> && body.containsKey('data') 
            ? body['data'] 
            : body;
            
        return User.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserProfile(User user) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/profile');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<UserStats?> getUserStats({String period = 'month'}) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/stats/me').replace(queryParameters: {
      'period': period,
    });

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return UserStats.fromJson(body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
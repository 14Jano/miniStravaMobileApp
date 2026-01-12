import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class SocialService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api';
  final _storage = const FlutterSecureStorage();

  Future<List<User>> getFriends() async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/friends');

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
        if (body['data'] != null) {
          final List<dynamic> data = body['data'];
          return data.map((json) => User.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> getFriendRequests() async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/friends/requests');

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
        if (body is Map<String, dynamic> && body['data'] != null) {
           final List<dynamic> data = body['data'];
           return data.map((json) => User.fromJson(json)).toList();
        } else if (body is List) {
           return body.map((json) => User.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<User>> searchUsers(String query) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/users?search=$query');

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
        if (body['data'] != null) {
          final List<dynamic> data = body['data'];
          return data.map((json) => User.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendInvite(int userId) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/friends/invite');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> acceptInvite(int userId) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/friends/$userId/accept');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectInvite(int userId) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/friends/$userId/reject');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/feed_model.dart';
import '../models/comment_model.dart';

class FeedService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api';
  final _storage = const FlutterSecureStorage();

  Future<List<FeedItem>> getFeed() async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/feed');

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
          return data.map((json) => FeedItem.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        print('Błąd feedu: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Błąd połączenia (feed): $e');
      throw e;
    }
  }

  Future<bool> giveKudos(int activityId) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$activityId/kudos');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Błąd dawania kudo: $e');
      return false;
    }
  }

  Future<bool> removeKudos(int activityId) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$activityId/kudos');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Błąd usuwania kudo: $e');
      return false;
    }
  }

  Future<List<Comment>> getComments(int activityId) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$activityId/comments');

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
          return data.map((json) => Comment.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        print('Błąd pobierania komentarzy: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Błąd połączenia (komentarze): $e');
      return [];
    }
  }

  Future<bool> addComment(int activityId, String content) async {
    final token = await _storage.read(key: 'auth_token');
    final url = Uri.parse('$_baseUrl/activities/$activityId/comments');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': content,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Błąd dodawania komentarza: $e');
      return false;
    }
  }
}
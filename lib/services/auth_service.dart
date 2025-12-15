import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api/';

  final _storage = const FlutterSecureStorage();

  Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Rejestracja udana: ${response.body}');
        return true;
      } else {
        print('Błąd rejestracji: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        String token = data['token'];

        await _storage.write(key: 'auth_token', value: token);
        
        print('Zalogowano! Token: $token');
        return true;
      } else {
        print('Błąd logowania: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    final url = Uri.parse('$_baseUrl/auth/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        print('Link resetujący wysłany.');
        return true;
      } else {
        print('Błąd resetowania: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}
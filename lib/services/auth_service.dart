import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'https://strava.host358482.xce.pl/api';

  final _storage = const FlutterSecureStorage();

  Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    print('Rejestracja - wysyłam do: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstname,
          'last_name': lastname,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

print('Rejestracja Status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        print('Rejestracja udana: ${response.body}');
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
           await _storage.write(key: 'auth_token', value: data['token']);
        }
        
        return true;
      } else {
        print('Błąd rejestracji: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia (register): $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    print('Logowanie - wysyłam do: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Logowanie Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('Odpowiedź serwera: $data');

        if (data['token'] != null) {
          String token = data['token'];
          await _storage.write(key: 'auth_token', value: token);
          print('Zalogowano pomyślnie. Token zapisany.');
          return true;
        } else {
          print('Błąd: Serwer nie zwrócił pola "token"!');
          return false;
        }

      } else {
        print('Błąd logowania: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Błąd połączenia (login): $e');
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
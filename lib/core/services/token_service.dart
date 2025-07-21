// lib/core/services/token_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print("[TokenService] Токен сохранен в SharedPreferences.");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    // print("[TokenService] Токен запрошен из SharedPreferences. Наличие: ${token != null}");
    return token;
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print("[TokenService] Токен удален из SharedPreferences.");
  }
}
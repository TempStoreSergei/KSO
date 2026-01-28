// lib/core/services/token_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const _legacyTokenKey = 'auth_token';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenTypeKey = 'token_type';
  static const _userRoleKey = 'user_role';

  /// Сохраняет access token (JWT).
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
    debugPrint("[TokenService] Access token сохранен в SharedPreferences.");
  }

  /// Получает access token (JWT).
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    if (token != null && token.isNotEmpty) return token;

    // Миграция со старого ключа, если он есть.
    final legacy = prefs.getString(_legacyTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_accessTokenKey, legacy);
      await prefs.remove(_legacyTokenKey);
      return legacy;
    }

    return null;
  }

  /// Удаляет access token.
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_legacyTokenKey);
    debugPrint("[TokenService] Access token удален из SharedPreferences.");
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
    debugPrint("[TokenService] Refresh token сохранен в SharedPreferences.");
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> deleteRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
    debugPrint("[TokenService] Refresh token удален из SharedPreferences.");
  }

  Future<void> saveTokenType(String tokenType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenTypeKey, tokenType);
  }

  Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenType = prefs.getString(_tokenTypeKey);
    return (tokenType == null || tokenType.isEmpty) ? null : tokenType;
  }

  Future<void> deleteTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenTypeKey);
  }

  /// Удаляет только токены (без роли).
  Future<void> clearTokens() async {
    await deleteToken();
    await deleteRefreshToken();
    await deleteTokenType();
  }

  /// Сохраняет роль пользователя
  Future<void> saveUserRole(String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, userRole);
    debugPrint("[TokenService] Роль пользователя сохранена: $userRole");
  }

  /// Получает роль пользователя
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString(_userRoleKey);
    return userRole;
  }

  /// Удаляет роль пользователя
  Future<void> deleteUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    debugPrint("[TokenService] Роль пользователя удалена из SharedPreferences.");
  }

  /// Полный logout на стороне клиента: удаляет access/refresh и роль.
  Future<void> clearAuth() async {
    await clearTokens();
    await deleteUserRole();
  }
}

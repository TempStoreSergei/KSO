// ============================================
// lib/data/repositories/admin_auth_repository_impl.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/token_service.dart';
import 'package:motel/domain/repositories/admin_auth_repository.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final TokenService _tokenService = TokenService();

  @override
  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        body: {'username': username, 'password': password},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      final responseMap = response as Map<String, dynamic>;

      final accessToken = responseMap['access_token'] as String?;
      final refreshToken = responseMap['refresh_token'] as String?;
      final tokenType = responseMap['token_type'] as String?;

      // Возможны оба варианта поля роли, поддерживаем оба.
      final userRole = responseMap['userRole'] as String? ?? responseMap['role'] as String?;
      final detail = responseMap['detail'] as String?;

      if (accessToken != null && accessToken.isNotEmpty) {
        await _tokenService.saveToken(accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _tokenService.saveRefreshToken(refreshToken);
      }
      if (tokenType != null && tokenType.isNotEmpty) {
        await _tokenService.saveTokenType(tokenType);
      }
      if (userRole != null && userRole.isNotEmpty) {
        await _tokenService.saveUserRole(userRole);
      }

      return LoginResponse(
        success: true,
        userRole: userRole,
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenType: tokenType,
        detail: detail,
      );
    } catch (e) {
      return LoginResponse(success: false);
    }
  }
}

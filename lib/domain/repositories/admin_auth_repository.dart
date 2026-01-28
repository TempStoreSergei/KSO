// ============================================
// lib/domain/repositories/admin_auth_repository.dart
// ============================================

/// Модель ответа при авторизации
class LoginResponse {
  final bool success;
  final String? userRole;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final String? detail;

  LoginResponse({
    required this.success,
    this.userRole,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.detail,
  });
}

abstract class AdminAuthRepository {
  Future<LoginResponse> login(String username, String password);
}

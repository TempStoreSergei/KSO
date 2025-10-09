// ============================================
// lib/domain/repositories/admin_auth_repository.dart
// ============================================

abstract class AdminAuthRepository {
  Future<bool> login(String username, String password);
}

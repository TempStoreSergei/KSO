// lib/domain/repositories/admin_auth_repository.dart

abstract class AdminAuthRepository {
  /// Аутентифицирует администратора по паролю.
  /// Возвращает true в случае успеха, иначе false.
  Future<bool> login(String password); // <-- Убрали username
}
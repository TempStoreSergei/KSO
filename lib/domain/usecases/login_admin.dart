// lib/domain/usecases/login_admin.dart

import '../repositories/admin_auth_repository.dart';

class LoginAdmin {
  final AdminAuthRepository repository;

  LoginAdmin(this.repository);

  /// Выполняет вход администратора.
  Future<bool> call(String password) { // <-- Убрали username
    // Валидация осталась, но только для пароля
    if (password.isEmpty) {
      return Future.value(false);
    }
    return repository.login(password);
  }
}
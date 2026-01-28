// ============================================
// lib/domain/usecases/login_admin.dart
// ============================================

import 'package:motel/domain/repositories/admin_auth_repository.dart';

class LoginAdmin {
  final AdminAuthRepository repository;

  LoginAdmin(this.repository);

  Future<LoginResponse> call(String username, String password) async {
    return await repository.login(username, password);
  }
}
// ============================================
// lib/data/repositories/admin_auth_repository_impl.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/repositories/admin_auth_repository.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  @override
  Future<bool> login(String username, String password) async {
    try {
      await ApiClient.instance.post(
        '/auth/login',
        body: {'username': username, 'password': password},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
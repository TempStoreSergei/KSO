// ============================================
// lib/data/repositories/admin_auth_repository_impl.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/permissions_service.dart';
import 'package:motel/domain/repositories/admin_auth_repository.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final PermissionsService _permissionsService = PermissionsService();

  @override
  Future<bool> login(String username, String password) async {
    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        body: {'username': username, 'password': password},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      // Сохраняем роль пользователя
      if (response['userRole'] != null) {
        await _permissionsService.setUserRole(response['userRole']);
        // Загружаем права доступа
        await _permissionsService.loadPermissions();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
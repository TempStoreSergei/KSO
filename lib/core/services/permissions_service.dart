import 'package:motel/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления правами доступа пользователя
class PermissionsService {
  static const String _userRoleKey = 'user_role';

  String? _userRole;
  Map<String, List<String>>? _permissions;

  /// Получить роль текущего пользователя
  Future<String?> getUserRole() async {
    if (_userRole != null) return _userRole;

    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString(_userRoleKey);
    return _userRole;
  }

  /// Сохранить роль пользователя
  Future<void> setUserRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  /// Очистить роль пользователя (при выходе)
  Future<void> clearUserRole() async {
    _userRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
  }

  /// Загрузить права доступа с сервера
  Future<void> loadPermissions() async {
    try {
      final response = await ApiClient.instance.get('/system/permissions');
      if (response['roles'] != null) {
        _permissions = {};
        final roles = response['roles'] as Map<String, dynamic>;
        roles.forEach((role, permissions) {
          _permissions![role] = List<String>.from(permissions as List);
        });
      }
    } catch (e) {
      print('Ошибка загрузки прав доступа: $e');
      // Если не удалось загрузить, используем пустые права
      _permissions = {};
    }
  }

  /// Проверить, есть ли у пользователя право на выполнение действия
  Future<bool> hasPermission(String endpoint) async {
    final role = await getUserRole();

    // Если роль не определена, проверяем только public права
    if (role == null) {
      return _hasPublicPermission(endpoint);
    }

    // Если права еще не загружены, загружаем
    if (_permissions == null) {
      await loadPermissions();
    }

    // Проверяем права для роли пользователя
    final rolePermissions = _permissions?[role] ?? [];

    // Также проверяем public права (доступны всем)
    final publicPermissions = _permissions?['public'] ?? [];

    return rolePermissions.contains(endpoint) || publicPermissions.contains(endpoint);
  }

  /// Проверить, есть ли публичный доступ к endpoint
  bool _hasPublicPermission(String endpoint) {
    final publicPermissions = _permissions?['public'] ?? [];
    return publicPermissions.contains(endpoint);
  }

  /// Получить читаемое название роли
  String getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'operator':
        return 'Оператор';
      default:
        return 'Гость';
    }
  }
}

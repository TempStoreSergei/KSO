// lib/domain/models/permissions_model.dart

/// Модель прав доступа системы
class PermissionsModel {
  final Map<String, List<String>> roles;
  final List<String> publicPermissions;

  PermissionsModel({
    required this.roles,
    required this.publicPermissions,
  });

  /// Создание модели из JSON
  factory PermissionsModel.fromJson(Map<String, dynamic> json) {
    final rolesData = json['roles'] as Map<String, dynamic>? ?? {};
    final roles = rolesData.map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );

    final publicPermissions = json['public'] as List<dynamic>? ?? [];

    return PermissionsModel(
      roles: roles,
      publicPermissions: List<String>.from(publicPermissions),
    );
  }

  /// Преобразование модели в JSON
  Map<String, dynamic> toJson() {
    return {
      'roles': roles,
      'public': publicPermissions,
    };
  }

  /// Проверяет, имеет ли роль определенное право
  bool hasPermission(String role, String permission) {
    // Сначала проверяем публичные права
    if (publicPermissions.contains(permission)) {
      return true;
    }

    // Затем проверяем права роли
    final rolePermissions = roles[role];
    if (rolePermissions == null) {
      return false;
    }

    return rolePermissions.contains(permission);
  }

  /// Получает все права для определенной роли (включая публичные)
  List<String> getPermissionsForRole(String role) {
    final rolePermissions = roles[role] ?? [];
    return [...publicPermissions, ...rolePermissions];
  }
}

// lib/presentation/helpers/permission_builder.dart

import 'package:flutter/cupertino.dart';
import 'package:motel/core/services/permissions_service.dart';
import 'package:motel/core/services/token_service.dart';

/// Виджет для условного отображения UI на основе прав доступа
class PermissionBuilder extends StatefulWidget {
  /// Требуемое право доступа
  final String permission;

  /// Виджет, который отображается если есть право
  final Widget child;

  /// Виджет, который отображается если нет права (опционально)
  final Widget? fallback;

  const PermissionBuilder({
    required this.permission,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  State<PermissionBuilder> createState() => _PermissionBuilderState();
}

class _PermissionBuilderState extends State<PermissionBuilder> {
  final _tokenService = TokenService();
  final _permissionsService = PermissionsService();

  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _tokenService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  bool get _hasPermission {
    return _permissionsService.hasPermission(_userRole, widget.permission);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasPermission) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Виджет для отображения UI если пользователь имеет ЛЮБОЕ из указанных прав
class PermissionBuilderAny extends StatefulWidget {
  /// Список прав, любое из которых позволит отобразить виджет
  final List<String> permissions;

  /// Виджет, который отображается если есть хотя бы одно право
  final Widget child;

  /// Виджет, который отображается если нет ни одного права (опционально)
  final Widget? fallback;

  const PermissionBuilderAny({
    required this.permissions,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  State<PermissionBuilderAny> createState() => _PermissionBuilderAnyState();
}

class _PermissionBuilderAnyState extends State<PermissionBuilderAny> {
  final _tokenService = TokenService();
  final _permissionsService = PermissionsService();

  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _tokenService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  bool get _hasAnyPermission {
    return widget.permissions.any(
      (permission) => _permissionsService.hasPermission(_userRole, permission),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasAnyPermission) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Виджет для отображения UI если пользователь имеет ВСЕ указанные права
class PermissionBuilderAll extends StatefulWidget {
  /// Список прав, все из которых необходимы для отображения виджета
  final List<String> permissions;

  /// Виджет, который отображается если есть все права
  final Widget child;

  /// Виджет, который отображается если нет всех прав (опционально)
  final Widget? fallback;

  const PermissionBuilderAll({
    required this.permissions,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  State<PermissionBuilderAll> createState() => _PermissionBuilderAllState();
}

class _PermissionBuilderAllState extends State<PermissionBuilderAll> {
  final _tokenService = TokenService();
  final _permissionsService = PermissionsService();

  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _tokenService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  bool get _hasAllPermissions {
    return widget.permissions.every(
      (permission) => _permissionsService.hasPermission(_userRole, permission),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasAllPermissions) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Mixin для упрощения проверки прав в StatefulWidget
mixin PermissionCheckMixin<T extends StatefulWidget> on State<T> {
  final _tokenService = TokenService();
  final _permissionsService = PermissionsService();

  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRoleForPermissions();
  }

  Future<void> _loadUserRoleForPermissions() async {
    final role = await _tokenService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  /// Проверяет, имеет ли пользователь указанное право
  bool hasPermission(String permission) {
    return _permissionsService.hasPermission(_userRole, permission);
  }

  /// Проверяет, имеет ли пользователь любое из указанных прав
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((p) => hasPermission(p));
  }

  /// Проверяет, имеет ли пользователь все указанные права
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((p) => hasPermission(p));
  }

  /// Получает роль пользователя
  String? get userRole => _userRole;
}

import 'package:flutter/cupertino.dart';
import 'package:motel/core/services/permissions_service.dart';
import 'package:motel/core/services/token_service.dart';

/// Виджет который отображает дочерний виджет только если есть права доступа
class PermissionWidget extends StatefulWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  State<PermissionWidget> createState() => _PermissionWidgetState();
}

class _PermissionWidgetState extends State<PermissionWidget> {
  final PermissionsService _permissionsService = PermissionsService();
  final TokenService _tokenService = TokenService();
  bool? _hasPermission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final role = await _tokenService.getUserRole();
    final hasPermission = _permissionsService.hasPermission(role, widget.permission);
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_hasPermission == true) {
      return widget.child;
    }

    return widget.fallback ?? const SizedBox.shrink();
  }
}

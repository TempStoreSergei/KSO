import 'package:flutter/cupertino.dart';
import 'package:motel/core/services/permissions_service.dart';

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
  bool? _hasPermission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _permissionsService.hasPermission(widget.permission);
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

// lib/presentation/helpers/permission_protected_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/helpers/permission_builder.dart';

/// Wrapper для экранов, требующих проверки прав
/// Автоматически показывает сообщение "Нет доступа" если у пользователя нет нужных прав
class PermissionProtectedScreen extends StatefulWidget {
  final List<String> requiredPermissions;
  final Widget child;
  final String title;
  final bool requireAll; // true = нужны ВСЕ права, false = нужно хотя бы ОДНО право

  const PermissionProtectedScreen({
    required this.requiredPermissions,
    required this.child,
    this.title = 'Настройки',
    this.requireAll = false, // по умолчанию достаточно одного права
    super.key,
  });

  @override
  State<PermissionProtectedScreen> createState() => _PermissionProtectedScreenState();
}

class _PermissionProtectedScreenState extends State<PermissionProtectedScreen>
    with PermissionCheckMixin {

  @override
  Widget build(BuildContext context) {
    // Проверяем права
    final bool hasAccess = widget.requireAll
        ? hasAllPermissions(widget.requiredPermissions)
        : hasAnyPermission(widget.requiredPermissions);

    if (!hasAccess) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.lock_shield,
                size: 80,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 24),
              const Text(
                'Нет доступа',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'У вас нет прав для доступа к этой функции',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton(
                child: const Text('Назад'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    // Если есть доступ, показываем дочерний виджет
    return widget.child;
  }
}

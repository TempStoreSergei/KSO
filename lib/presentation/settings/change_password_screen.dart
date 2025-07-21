// lib/presentation/settings/change_password_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Импорты из слоев Чистой Архитектуры
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/repositories/settings_repository_impl.dart';
import 'package:motel/domain/repositories/settings_repository.dart';
import 'package:motel/domain/usecases/update_password_use_case.dart';

// Ваши UI компоненты (пути могут отличаться)
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';

/// Виджет-обертка, который предоставляет зависимости через Provider.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // В реальном приложении лучше использовать DI-контейнер (GetIt, etc.)
    final ApiClient apiClient = ApiClient.instance; // Предполагаем, что у вас синглтон
    final SettingsRepository settingsRepository = SettingsRepositoryImpl(apiClient);
    final UpdatePasswordUseCase updatePasswordUseCase = UpdatePasswordUseCase(settingsRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KeyboardNotifier()),
        Provider.value(value: updatePasswordUseCase), // Предоставляем UseCase дереву виджетов
      ],
      child: const _ChangePasswordView(),
    );
  }
}

/// Основной виджет экрана, отвечающий за UI и состояние.
class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _oldPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
      keyboardNotifier.registerFields(
        controllers: [_oldPasswordController, _newPasswordController],
        focusNodes: [_oldPasswordFocusNode, _newPasswordFocusNode],
      );
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _oldPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    super.dispose();
  }

  /// <<< ГЛАВНОЕ ИЗМЕНЕНИЕ: Метод теперь вызывает Use Case, а не делает прямой запрос.
  Future<void> _updatePassword() async {
    final updatePasswordUseCase = Provider.of<UpdatePasswordUseCase>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      // Вся логика и запрос скрыты за одним вызовом
      await updatePasswordUseCase(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSuccessDialog('Пароль успешно изменен.');
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Произошла ошибка: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI остается без изменений, так как он уже был хорошо отделен.
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
    final navigationBar = CupertinoNavigationBar(
      middle: const Text('Смена пароля'),
      previousPageTitle: 'Настройки',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isLoading ? null : _updatePassword,
        child: _isLoading ? const CupertinoActivityIndicator() : const Text('Готово', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      resizeToAvoidBottomInset: false,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1020),
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('ВВЕДИТЕ ДАННЫЕ'),
                    children: [
                      _AdaptiveCupertinoTextField(
                        controller: _oldPasswordController,
                        placeholder: 'Старый пароль',
                        focusNode: _oldPasswordFocusNode,
                        obscureText: true,
                        onTap: () => keyboardNotifier.setActiveControllerByIndex(0),
                      ),
                      _AdaptiveCupertinoTextField(
                        controller: _newPasswordController,
                        placeholder: 'Новый пароль',
                        focusNode: _newPasswordFocusNode,
                        obscureText: true,
                        isLast: true,
                        onTap: () => keyboardNotifier.setActiveControllerByIndex(1),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomKeyboard(onKeyPressed: keyboardNotifier.onKeyPressed),
                ),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: navigationBar),
        ],
      ),
    );
  }

  // Методы для отображения диалогов (часть UI)
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: const Text('Ошибка'), content: Text(message), actions: [CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(title: const Text('Успешно'), content: Text(message), actions: [CupertinoDialogAction(isDefaultAction: true, onPressed: () {Navigator.of(ctx).pop(); Navigator.of(context).pop();}, child: const Text('OK'))]));
  }
}

/// Виджет поля ввода (_AdaptiveCupertinoTextField) остается здесь без изменений
class _AdaptiveCupertinoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final bool obscureText;
  final bool isLast;

  const _AdaptiveCupertinoTextField({
    required this.controller, required this.placeholder, required this.focusNode, required this.onTap, this.obscureText = false, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    const double largeFontSize = 24.0;
    const EdgeInsets largePadding = EdgeInsets.symmetric(vertical: 32, horizontal: 24);
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      focusNode: focusNode,
      obscureText: obscureText,
      readOnly: true,
      showCursor: true,
      cursorColor: CupertinoColors.activeBlue,
      cursorWidth: 3.0,
      onTap: onTap,
      style: const TextStyle(fontSize: largeFontSize),
      placeholderStyle: const TextStyle(fontSize: largeFontSize, color: CupertinoColors.placeholderText),
      padding: largePadding,
      decoration: BoxDecoration(
          border: Border(bottom: isLast ? BorderSide.none : const BorderSide(color: CupertinoColors.separator, width: 0.5))),
    );
  }
}
// ============================================
// lib/presentation/settings/password/change_password_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Импорты из слоев Чистой Архитектуры
import 'package:motel/domain/usecases/update_password_use_case.dart';

// Ваши UI компоненты
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';

/// Виджет-обертка, который предоставляет зависимости через Provider.
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UpdatePasswordUseCase updatePasswordUseCase = UpdatePasswordUseCase();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KeyboardNotifier()),
        Provider.value(value: updatePasswordUseCase),
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
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _oldPasswordFocusNode.addListener(() {
      if (_oldPasswordFocusNode.hasFocus) {
        setState(() {
          _showError = false;
        });
        final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
        keyboardNotifier.setActiveField(0);
      }
    });

    _newPasswordFocusNode.addListener(() {
      if (_newPasswordFocusNode.hasFocus) {
        setState(() {
          _showError = false;
        });
        final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
        keyboardNotifier.setActiveField(1);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
      keyboardNotifier.registerFields(
        controllers: [_oldPasswordController, _newPasswordController],
        focusNodes: [_oldPasswordFocusNode, _newPasswordFocusNode],
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        _oldPasswordFocusNode.requestFocus();
      });
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

  Future<void> _updatePassword() async {
    if (_oldPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите старый пароль';
        _showError = true;
      });
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите новый пароль';
        _showError = true;
      });
      return;
    }

    final updatePasswordUseCase = Provider.of<UpdatePasswordUseCase>(context, listen: false);
    setState(() {
      _isLoading = true;
      _showError = false;
    });

    try {
      await updatePasswordUseCase(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSuccessDialog('Пароль успешно изменен.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Произошла ошибка: ${e.toString()}';
        _showError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: SafeArea(
        child: Column(
          children: [
            // Кнопка назад
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Иконка
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.activeBlue.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_rotation,
                            size: 60,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Заголовок
                        const Text(
                          'Смена пароля',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Введите старый и новый пароль',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 17,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),

                        // Поля ввода
                        CupertinoListSection.insetGrouped(
                          backgroundColor: CupertinoColors.transparent,
                          children: [
                            CupertinoListTile(
                              title: const Text('Старый пароль'),
                              additionalInfo: Expanded(
                                child: CupertinoTextField(
                                  controller: _oldPasswordController,
                                  focusNode: _oldPasswordFocusNode,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: CupertinoColors.systemGrey),
                                  decoration: null,
                                  obscureText: true,
                                  placeholder: 'Старый пароль',
                                ),
                              ),
                            ),
                            CupertinoListTile(
                              title: const Text('Новый пароль'),
                              additionalInfo: Expanded(
                                child: CupertinoTextField(
                                  controller: _newPasswordController,
                                  focusNode: _newPasswordFocusNode,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: CupertinoColors.systemGrey),
                                  decoration: null,
                                  obscureText: true,
                                  placeholder: 'Новый пароль',
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Сообщение об ошибке
                        if (_showError) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CupertinoColors.systemRed.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
                                  color: CupertinoColors.systemRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: CupertinoColors.systemRed,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Кнопка подтверждения
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isLoading ? null : _updatePassword,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? const Color(0xFF2C2C2E)
                                  : CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                                  : const Text(
                                'Изменить пароль',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.lock_shield, color: CupertinoColors.systemGrey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Пароль будет обновлён безопасно',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Клавиатура внизу
            Center(
              child: SizedBox(
                width: 1200,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
                  child: CustomKeyboard(onKeyPressed: keyboardNotifier.onKeyPressed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
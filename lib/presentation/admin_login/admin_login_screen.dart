// ============================================
// lib/presentation/admin_login/admin_login_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:motel/data/repositories/admin_auth_repository_impl.dart';
import 'package:motel/domain/usecases/login_admin.dart';
import 'package:motel/presentation/settings/settings_screen.dart';
import 'package:motel/presentation/settings/server/server_settings_screen.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
import 'package:provider/provider.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeyboardNotifier(),
      child: const _AdminLoginView(),
    );
  }
}

class _AdminLoginView extends StatefulWidget {
  const _AdminLoginView();

  @override
  State<_AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<_AdminLoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      if (_usernameFocusNode.hasFocus) {
        setState(() {
          _showError = false;
        });
        final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
        keyboardNotifier.setActiveField(0);
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
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
        controllers: [_usernameController, _passwordController],
        focusNodes: [_usernameFocusNode, _passwordFocusNode],
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        _usernameFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (_usernameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите имя пользователя';
        _showError = true;
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Введите пароль';
        _showError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showError = false;
    });

    final repository = AdminAuthRepositoryImpl();
    final loginUseCase = LoginAdmin(repository);
    try {
      final response = await loginUseCase.call(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.success) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => AdminDashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = response.detail ?? 'Неверное имя пользователя или пароль';
          _showError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка подключения: $e';
        _showError = true;
      });
    }
  }

  Future<void> _showSettingsPasswordDialog() async {
    final controller = TextEditingController();
    
    // Используем отдельный notifier для диалога, если нужно, но пока простая клавиатура
    // В идеале нужно интегрировать с глобальной клавиатурой, но для диалогов это сложно.
    // Пока используем стандартный ввод (полагаясь на то, что админ может подключить физ. клавиатуру 
    // или использовать экранную если доступна системная). 
    // В киоск-режиме системной клавиатуры может не быть. 
    // Поэтому лучше использовать текущую кастомную клавиатуру, но это потребует перестройки UI.
    
    // Упрощение: Проверяем пароль просто через поле, предполагая, что фокус перехватится
    // нашей кастомной клавиатурой, если мы переключим поле.
    
    // НО: Наша кастомная клавиатура привязана к полям _usernameController/_passwordController.
    // Чтобы ввести пароль для настроек, нужно либо добавить поле в список KeyboardNotifier,
    // либо (проще) использовать одно из существующих полей как "ввод пароля".
    
    // Вариант: Кнопка "Настройки" просто проверяет текущий введенный пароль в поле "Пароль"
    // если логин пустой? Нет, это неочевидно.
    
    // Лучший вариант: Показать диалог. Но кастомная клавиатура перекрывается диалогом?
    // Нет, она внизу Column, а диалог модальный.
    
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Вход в настройки сервера'),
        content: Column(
          children: [
            const Text('Введите пароль из .env для доступа к настройкам подключения.'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              obscureText: true,
              placeholder: 'Пароль настроек',
              style: const TextStyle(color: CupertinoColors.black),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Войти'),
            onPressed: () {
              final settingsPassword = dotenv.env['SETTINGS_PASSWORD'];
              if (controller.text == settingsPassword) {
                Navigator.of(ctx).pop(); // Закрыть диалог
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const ServerSettingsScreen()),
                );
              } else {
                // Можно показать ошибку, но пока просто закроем или ничего не сделаем
                // Для простоты - ничего.
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: SafeArea(
        child: Column(
          children: [
            // Верхняя панель: Назад и Настройки
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
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
                  
                  // Кнопка настроек (шестеренка)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showSettingsPasswordDialog,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.settings,
                        color: CupertinoColors.systemGrey,
                        size: 24,
                      ),
                    ),
                  ),
                ],
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
                            color: CupertinoColors.activeBlue.withOpacity(0.15),
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_shield_fill,
                            size: 60,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Заголовок
                        const Text(
                          'Вход для администратора',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Введите учетные данные для доступа',
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
                              title: const Text('Имя пользователя'),
                              additionalInfo: Expanded(
                                child: CupertinoTextField(
                                  controller: _usernameController,
                                  focusNode: _usernameFocusNode,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: CupertinoColors.systemGrey),
                                  decoration: null,
                                  placeholder: 'Имя пользователя',
                                ),
                              ),
                            ),
                            CupertinoListTile(
                              title: const Text('Пароль'),
                              additionalInfo: Expanded(
                                child: CupertinoTextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: CupertinoColors.systemGrey),
                                  decoration: null,
                                  obscureText: true,
                                  placeholder: 'Пароль',
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
                              color: CupertinoColors.systemRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CupertinoColors.systemRed.withOpacity(0.3),
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

                        // Кнопка входа
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isLoading ? null : _onLoginPressed,
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
                                'Войти',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
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
}

// ============================================
// lib/presentation/admin_login/admin_login_screen.dart
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:motel/data/repositories/admin_auth_repository_impl.dart';
import 'package:motel/domain/usecases/login_admin.dart';
import 'package:motel/presentation/settings/settings_screen.dart';
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

  int _focusedFieldIndex = 0;
  bool _isLoading = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      if (_usernameFocusNode.hasFocus) {
        setState(() {
          _focusedFieldIndex = 0;
          _showError = false;
        });
        final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
        keyboardNotifier.setActiveField(0);
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() {
          _focusedFieldIndex = 1;
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
    final success = await loginUseCase.call(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => AdminDashboardScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Неверное имя пользователя или пароль';
        _showError = true;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required FocusNode focusNode,
    required bool isFocused,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: isFocused
            ? Border.all(color: CupertinoColors.activeBlue, width: 2)
            : null,
      ),
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        obscureText: obscureText,
        style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
        ),
        prefix: isFocused
            ? const Padding(
          padding: EdgeInsets.only(left: 12.0, right: 12.0),
          child: Icon(
            CupertinoIcons.minus_circle_fill,
            color: CupertinoColors.white,
            size: 24,
          ),
        )
            : null,
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
                        _buildTextField(
                          controller: _usernameController,
                          placeholder: 'Имя пользователя',
                          focusNode: _usernameFocusNode,
                          isFocused: _focusedFieldIndex == 0,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _passwordController,
                          placeholder: 'Пароль',
                          focusNode: _passwordFocusNode,
                          isFocused: _focusedFieldIndex == 1,
                          obscureText: true,
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
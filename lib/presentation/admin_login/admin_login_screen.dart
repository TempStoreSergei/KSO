import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/data/repositories/admin_auth_repository_impl.dart';
import 'package:motel/domain/usecases/login_admin.dart';
import 'package:motel/presentation/admin_dashboard/admin_dashboard_screen.dart';
import 'package:motel/presentation/guest_info/custom_keyboard.dart';
import 'package:motel/presentation/guest_info/focusable_textfield.dart';
import 'package:motel/presentation/guest_info/keyboard_notifier.dart';
import 'package:motel/presentation/helpers/adaptive_text.dart';
import 'package:motel/presentation/helpers/glassmorphic_container.dart';
import 'package:motel/presentation/helpers/app_background.dart';
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
  State<_AdminLoginView> createState() => __AdminLoginViewState();
}

class __AdminLoginViewState extends State<_AdminLoginView> {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showError = false;
  String _errorMessage = 'Пароль указан неверно';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);
      keyboardNotifier.registerFields(
        controllers: [_passwordController],
        focusNodes: [_passwordFocusNode],
      );
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
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
    final success = await loginUseCase.call(_passwordController.text);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => const SettingsScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Пароль указан неверно';
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = Provider.of<KeyboardNotifier>(context, listen: false);

    final loginButton = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isLoading ? null : _onLoginPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _showError ? Colors.white : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: _isLoading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showError
                ? Text(_errorMessage, key: ValueKey(_errorMessage), textAlign: TextAlign.center, style: TextStyle(fontSize: scaleText(context, 16), fontWeight: FontWeight.bold, color: CupertinoColors.systemRed))
                : Text('Войти', key: const ValueKey('login'), textAlign: TextAlign.center, style: TextStyle(fontSize: scaleText(context, 20), fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );

    final backButton = GlassmorphicContainer(
      child: CupertinoButton(
        padding: const EdgeInsets.all(10),
        onPressed: () => Navigator.of(context).pop(),
        child: const Icon(CupertinoIcons.back, color: Colors.white, size: 35),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1020),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    backButton,
                    const Spacer(),
                    Text('Вход для администратора', style: TextStyle(color: Colors.white, fontSize: scaleText(context, 32), fontWeight: FontWeight.bold, shadows: const [Shadow(blurRadius: 10)])),
                    const Spacer(),
                    Opacity(opacity: 0, child: backButton),
                  ],
                ),
                const SizedBox(height: 30),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: FocusableTextField(
                          controller: _passwordController,
                          placeholder: 'Пароль администратора',
                          controllerIndex: 0,
                          focusNode: _passwordFocusNode,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: loginButton),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                CustomKeyboard(onKeyPressed: keyboardNotifier.onKeyPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
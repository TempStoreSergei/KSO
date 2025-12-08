import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'cubit/telegram_cubit.dart';
import 'cubit/telegram_state.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TelegramSettingsScreen extends StatelessWidget {
  const TelegramSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TelegramCubit(ApiClient.instance),
      child: const _TelegramSettingsView(),
    );
  }
}

class _TelegramSettingsView extends StatefulWidget {
  const _TelegramSettingsView();

  @override
  State<_TelegramSettingsView> createState() => _TelegramSettingsViewState();
}

class _TelegramSettingsViewState extends State<_TelegramSettingsView> {
  final _tokenController = TextEditingController(text: '1234567890:ABCDEFGHIJKLMONPQRSTUVWXYZ12367890');
  final _chatIdController = TextEditingController();
  final _tokenFocusNode = FocusNode();
  final _chatIdFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _tokenFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdController.dispose();
    _tokenFocusNode.dispose();
    _chatIdFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: BlocConsumer<TelegramCubit, TelegramState>(
          listener: (context, state) {
            if (state is TelegramSuccess) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Успех'),
                  content: Text(state.message),
                  actions: [
                    CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              );
            } else if (state is TelegramError) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Ошибка'),
                  content: Text(state.message),
                  actions: [
                    CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              );
            }
          },
          builder: (context, state) {
            // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Добавлен виджет Center ---
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: SvgPicture.string(
                          '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-telegram" viewBox="0 0 16 16"> <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0ZM8.287 5.906q-1.168.486-4.666 2.01a.567.567 0 0 0-.595.442c-.03.243.275.339.69.47l.175.055c.408.133.958.288 1.243.294q.39.01.868-.32 3.269-2.206 3.374-2.23c.05-.012.12-.026.166.016s.042.12.037.141c-.03.129-1.227 1.241-1.846 1.817-.193.18-.33.307-.358.336a8.07 8.07 0 0 1-.188.186c-.38.366-.664.64.015 1.088.327.216.589.393.85.571.284.194.568.387.936.629q.14.092.27.187c.331.236.63.448.997.414.214-.02.435-.22.547-.82.265-1.417.786-4.486.906-5.751a1.4 1.4 0 0 0-.013-.315.34.34 0 0 0-.114-.217.53.53 0 0 0-.31-.093c-.3.005-.763.166-2.984 1.09Z"/> </svg>',
                          colorFilter: const ColorFilter.mode(CupertinoColors.activeBlue, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Настройки Telegram Бота',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CupertinoListSection.insetGrouped(
                        backgroundColor: CupertinoColors.transparent,
                        header: const Text('Учетные данные'),
                        footer: const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Для ввода данных требуется физическая клавиатура.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        children: <Widget>[
                          CupertinoListTile(
                            title: const Text('Токен'),
                            additionalInfo: Expanded(
                              child: CupertinoTextField(
                                controller: _tokenController,
                                focusNode: _tokenFocusNode,
                                textAlign: TextAlign.end,
                                style: const TextStyle(color: CupertinoColors.systemGrey),
                                decoration: null,
                              ),
                            ),
                            trailing: CupertinoButton(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: const Text('Проверить'),
                              onPressed: () => context.read<TelegramCubit>().checkToken(_tokenController.text),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: state is TelegramTokenVerified
                                  ? CupertinoListTile(
                                key: const ValueKey('chatId'),
                                title: const Text('ID чата'),
                                additionalInfo: Expanded(
                                  child: CupertinoTextField(
                                    controller: _chatIdController,
                                    focusNode: _chatIdFocusNode,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(color: CupertinoColors.systemGrey),
                                    decoration: null,
                                  ),
                                ),
                              )
                                  : const SizedBox.shrink(key: ValueKey('empty')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CupertinoListSection.insetGrouped(
                        header: const Text('Инструкция'),
                        children: const [
                          CupertinoListTile(title: Text('1. Создайте бота в Telegram'), subtitle: Text('С помощью @BotFather и получите токен.')),
                          CupertinoListTile(title: Text('2. Найдите своего бота'), subtitle: Text('В Telegram и отправьте ему сообщение.')),
                          CupertinoListTile(title: Text('3. Откройте в браузере'), subtitle: Text('https://api.telegram.org/bot<ваш_токен>/getUpdates')),
                          CupertinoListTile(title: Text('4. Найдите в ответе'), subtitle: Text('chat -> id')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (state is TelegramTokenVerified)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: state is TelegramLoading ? null : () => context.read<TelegramCubit>().startBot(_tokenController.text, _chatIdController.text),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: state is TelegramLoading ? const Color(0xFF2C2C2E) : CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: state is TelegramLoading
                                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                  : const Text('Запустить', style: TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
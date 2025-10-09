import 'package:flutter/cupertino.dart';
import 'package:motel/presentation/screensaver_settings/screensaver_settings_screen.dart';
import 'package:motel/presentation/settings/change_password_screen.dart';
import 'package:motel/presentation/settings/desktop_background_settings_screen.dart';
import 'package:motel/presentation/settings/services_settings_screen.dart';
import 'package:motel/presentation/settings/shift_settings_screen.dart';
import 'package:motel/presentation/settings/bill_acceptor_settings_screen.dart';
import 'package:motel/presentation/settings/bill_dispenser_settings_screen.dart';
import 'package:motel/presentation/settings/acquiring_settings_screen.dart';


class DummyEditScreen extends StatelessWidget {
  final String title;
  const DummyEditScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        previousPageTitle: 'Настройки',
      ),
      child: Center(
        child: Text('Экран редактирования для "$title"'),
      ),
    );
  }
}

// Главный виджет экрана настроек
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Переменная для хранения состояния переключателя
  bool _autoUpdateEnabled = true;

  // Метод для отображения диалога подтверждения выхода
  Future<void> _showLogoutConfirmation() async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вам потребуется снова войти, чтобы получить доступ к приложению.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Выйти'),
            onPressed: () {
              // Здесь должна быть ваша логика выхода из аккаунта
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  // Вспомогательный виджет для создания красивой навигационной строки
  Widget _buildNavigationTile({
    required String label,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
  }) {
    return CupertinoListTile(
      title: Text(label),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 20),
      ),
      trailing: const CupertinoListTileChevron(),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Стандартный фон для сгруппированных списков в iOS
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Настройки'),
          ),

          // Группируем все секции
          SliverMainAxisGroup(
            slivers: [
              // БЛОК 1: ОБОРУДОВАНИЕ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ОБОРУДОВАНИЕ'),
                  children: [
                    _buildNavigationTile(
                      label: 'Заставка',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (context) => const ScreensaverSettingsScreen()),
                        );
                      },
                      icon: CupertinoIcons.photo_on_rectangle,
                      iconColor: CupertinoColors.systemGrey,
                    ),
                    _buildNavigationTile(
                      label: 'Фискальный накопитель',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const DummyEditScreen(title: 'Фискальный накопитель'))),
                      icon: CupertinoIcons.doc_text,
                      iconColor: CupertinoColors.systemGreen,
                    ),
                    _buildNavigationTile(
                      label: 'Эквайринг',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const AcquiringSettingsScreen())),
                      icon: CupertinoIcons.creditcard,
                      iconColor: CupertinoColors.systemOrange,
                    ),
                    _buildNavigationTile(
                      label: 'Диспенсер купюр',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const BillDispenserSettingsScreen())),
                      icon: CupertinoIcons.arrow_up_circle,
                      iconColor: CupertinoColors.systemTeal,
                    ),
                    _buildNavigationTile(
                      label: 'Купюроприемник',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const BillAcceptorSettingsScreen())),
                      icon: CupertinoIcons.money_dollar_circle,
                      iconColor: CupertinoColors.systemPurple,
                    ),
                  ],
                ),
              ),

              // БЛОК 2: СМЕНЫ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('СМЕНЫ'),
                  children: [
                    _buildNavigationTile(
                      label: 'Управление сменами',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ShiftSettingsScreen())),
                      icon: CupertinoIcons.clock_fill,
                      iconColor: CupertinoColors.systemIndigo,
                    ),
                  ],
                ),
              ),

              // БЛОК 4: БЕЗОПАСНОСТЬ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('БЕЗОПАСНОСТЬ'),
                  children: [
                    _buildNavigationTile(
                      label: 'Сменить пароль',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      },
                      icon: CupertinoIcons.lock_fill,
                      iconColor: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),

              // БЛОК 5: УВЕДОМЛЕНИЯ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('УВЕДОМЛЕНИЯ'),
                  footer: const Text('Настройте уведомления о состоянии купюроприемника и других событиях.'),
                  children: [
                    _buildNavigationTile(
                      label: 'Telegram',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const DummyEditScreen(title: 'Telegram'))),
                      icon: CupertinoIcons.paperplane_fill,
                      iconColor: const Color(0xFF2AABEE),
                    ),
                  ],
                ),
              ),

              // БЛОК 6: ПРИЛОЖЕНИЕ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ПРИЛОЖЕНИЕ'),
                  children: [
                    CupertinoListTile(
                      title: const Text('Автообновление контента'),
                      leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(CupertinoIcons.arrow_2_circlepath, color: CupertinoColors.white, size: 20)
                      ),
                      trailing: CupertinoSwitch(
                        value: _autoUpdateEnabled,
                        onChanged: (newValue) => setState(() => _autoUpdateEnabled = newValue),
                      ),
                    ),
                    _buildNavigationTile(
                      label: 'О приложении',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const DummyEditScreen(title: 'О приложении'))),
                      icon: CupertinoIcons.info_circle_fill,
                      iconColor: CupertinoColors.systemGreen,
                    ),
                  ],
                ),
              ),

              // БЛОК 7: ВЫХОД ИЗ АККАУНТА
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  children: [
                    CupertinoListTile(
                      title: const Text(
                        'Выйти из аккаунта',
                        style: TextStyle(color: CupertinoColors.systemRed),
                      ),
                      onTap: _showLogoutConfirmation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
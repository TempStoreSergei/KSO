import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/permissions_service.dart';
import 'package:motel/core/constants/permissions_mapping.dart';
import 'package:motel/presentation/settings/telegram/telegram_settings_screen.dart';
import 'package:motel/presentation/settings/about/about_screen.dart';
import 'package:motel/presentation/settings/screensaver/screensaver_settings_screen.dart';
import 'package:motel/presentation/settings/password/change_password_screen.dart';
import 'package:motel/presentation/settings/services/services_settings_screen.dart';
import 'package:motel/presentation/settings/fines/fines_settings_screen.dart';
import 'package:motel/presentation/settings/transactions/transactions_screen.dart';
import 'package:motel/presentation/settings/shift/shift_settings_screen.dart';
import 'package:motel/presentation/settings/bill_acceptor/bill_acceptor_settings_screen.dart';
import 'package:motel/presentation/settings/bill_dispenser/bill_dispenser_settings_screen.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_settings_screen.dart';
import 'package:motel/presentation/settings/room_prices/room_prices_settings_screen.dart';
import 'package:motel/presentation/settings/tax/tax_settings_screen.dart';
import 'package:motel/presentation/settings/server/server_settings_screen.dart';

// Главный виджет экрана настроек
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final PermissionsService _permissionsService = PermissionsService();
  String? _userRole;
  Map<String, bool> _permissions = {};
  bool _isLoadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadPermissions();
  }

  Future<void> _loadUserRole() async {
    final role = await _permissionsService.getUserRole();
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  Future<void> _loadPermissions() async {
    // Загружаем все необходимые права
    final permissions = {
      'screensaver': await _permissionsService.hasPermission(PermissionsMapping.screensaver),
      'acquiring': await _permissionsService.hasPermission(PermissionsMapping.acquiring),
      'billDispenser': await _permissionsService.hasPermission(PermissionsMapping.billDispenser),
      'billAcceptor': await _permissionsService.hasPermission(PermissionsMapping.billAcceptor),
      'shiftManagement': await _permissionsService.hasPermission(PermissionsMapping.shiftManagement),
      'services': await _permissionsService.hasPermission(PermissionsMapping.services),
      'fines': await _permissionsService.hasPermission(PermissionsMapping.fines),
      'roomPrices': await _permissionsService.hasPermission(PermissionsMapping.roomPrices),
      'transactions': await _permissionsService.hasPermission(PermissionsMapping.transactions),
      'taxSettings': await _permissionsService.hasPermission(PermissionsMapping.taxSettings),
      'changePassword': await _permissionsService.hasPermission(PermissionsMapping.changePassword),
      'telegram': await _permissionsService.hasPermission(PermissionsMapping.telegram),
    };

    if (mounted) {
      setState(() {
        _permissions = permissions;
        _isLoadingPermissions = false;
      });
    }
  }

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
            onPressed: () async {
              // Закрываем диалог
              Navigator.of(ctx).pop();

              // Очищаем cookies (выход из аккаунта)
              await ApiClient.instance.logout();

              // Возвращаемся на главный экран (закрываем все экраны настроек)
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  // Методы для построения списков пунктов меню с проверкой прав
  List<Widget> _buildEquipmentItems() {
    if (_isLoadingPermissions) return [];

    final items = <Widget>[];

    if (_permissions['screensaver'] == true) {
      items.add(_buildNavigationTile(
        label: 'Заставка',
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute(builder: (context) => const ScreensaverSettingsScreen()),
        ),
        icon: CupertinoIcons.photo_on_rectangle,
        iconColor: CupertinoColors.systemGrey,
      ));
    }

    if (_permissions['acquiring'] == true) {
      items.add(_buildNavigationTile(
        label: 'Эквайринг',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const AcquiringSettingsScreen())),
        icon: CupertinoIcons.creditcard,
        iconColor: CupertinoColors.systemOrange,
      ));
    }

    if (_permissions['billDispenser'] == true) {
      items.add(_buildNavigationTile(
        label: 'Диспенсер купюр',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const BillDispenserSettingsScreen())),
        icon: CupertinoIcons.arrow_up_circle,
        iconColor: CupertinoColors.systemTeal,
      ));
    }

    if (_permissions['billAcceptor'] == true) {
      items.add(_buildNavigationTile(
        label: 'Купюроприемник',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const BillAcceptorSettingsScreen())),
        icon: CupertinoIcons.money_dollar_circle,
        iconColor: CupertinoColors.systemPurple,
      ));
    }

    return items;
  }

  List<Widget> _buildShiftItems() {
    if (_isLoadingPermissions) return [];

    final items = <Widget>[];

    if (_permissions['shiftManagement'] == true) {
      items.add(_buildNavigationTile(
        label: 'Управление сменами',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ShiftSettingsScreen())),
        icon: CupertinoIcons.clock_fill,
        iconColor: CupertinoColors.systemIndigo,
      ));
    }

    return items;
  }

  List<Widget> _buildServicesItems() {
    if (_isLoadingPermissions) return [];

    final items = <Widget>[];

    if (_permissions['services'] == true) {
      items.add(_buildNavigationTile(
        label: 'Услуги',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ServicesSettingsScreen())),
        icon: CupertinoIcons.square_list,
        iconColor: CupertinoColors.systemBlue,
      ));
    }

    if (_permissions['fines'] == true) {
      items.add(_buildNavigationTile(
        label: 'Штрафы',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const FinesSettingsScreen())),
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        iconColor: CupertinoColors.systemRed,
      ));
    }

    if (_permissions['roomPrices'] == true) {
      items.add(_buildNavigationTile(
        label: 'Цены на жилье',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const RoomPricesSettingsScreen())),
        icon: CupertinoIcons.money_rubl_circle_fill,
        iconColor: CupertinoColors.systemYellow,
      ));
    }

    if (_permissions['transactions'] == true) {
      items.add(_buildNavigationTile(
        label: 'Транзакции',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const TransactionsScreen())),
        icon: CupertinoIcons.doc_text_fill,
        iconColor: CupertinoColors.systemGreen,
      ));
    }

    if (_permissions['taxSettings'] == true) {
      items.add(_buildNavigationTile(
        label: 'Налоговые настройки',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const TaxSettingsScreen())),
        icon: CupertinoIcons.percent,
        iconColor: CupertinoColors.systemPurple,
      ));
    }

    return items;
  }

  List<Widget> _buildSecurityItems() {
    if (_isLoadingPermissions) return [];

    final items = <Widget>[];

    if (_permissions['changePassword'] == true) {
      items.add(_buildNavigationTile(
        label: 'Сменить пароль',
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => const ChangePasswordScreen()),
        ),
        icon: CupertinoIcons.lock_fill,
        iconColor: CupertinoColors.systemGrey,
      ));
    }

    return items;
  }

  List<Widget> _buildNotificationsItems() {
    if (_isLoadingPermissions) return [];

    final items = <Widget>[];

    if (_permissions['telegram'] == true) {
      items.add(_buildNavigationTile(
        label: 'Telegram',
        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const TelegramSettingsScreen())),
        icon: CupertinoIcons.paperplane_fill,
        iconColor: const Color(0xFF2AABEE),
      ));
    }

    return items;
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
            automaticallyImplyLeading: false, // Убираем кнопку "назад"
          ),

          // Группируем все секции
          SliverMainAxisGroup(
            slivers: [
              // БЛОК 0: ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  children: [
                    CupertinoListTile(
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemIndigo,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.person_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text('Роль пользователя'),
                      trailing: Text(
                        _permissionsService.getRoleDisplayName(_userRole),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // БЛОК 1: ОБОРУДОВАНИЕ
              if (_buildEquipmentItems().isNotEmpty)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('ОБОРУДОВАНИЕ'),
                    children: _buildEquipmentItems(),
                  ),
                ),

              // БЛОК 2: СМЕНЫ
              if (_buildShiftItems().isNotEmpty)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('СМЕНЫ'),
                    children: _buildShiftItems(),
                  ),
                ),

              // БЛОК 3: УСЛУГИ И ШТРАФЫ
              if (_buildServicesItems().isNotEmpty)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('УСЛУГИ И ШТРАФЫ'),
                    children: _buildServicesItems(),
                  ),
                ),

              // БЛОК 4: БЕЗОПАСНОСТЬ
              if (_buildSecurityItems().isNotEmpty)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('БЕЗОПАСНОСТЬ'),
                    children: _buildSecurityItems(),
                  ),
                ),

              // БЛОК 5: УВЕДОМЛЕНИЯ
              if (_buildNotificationsItems().isNotEmpty)
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('УВЕДОМЛЕНИЯ'),
                    footer: const Text('Настройте уведомления о состоянии купюроприемника и других событиях.'),
                    children: _buildNotificationsItems(),
                  ),
                ),

              // БЛОК 6: ПРИЛОЖЕНИЕ
              SliverToBoxAdapter(
                child: CupertinoListSection.insetGrouped(
                  header: const Text('ПРИЛОЖЕНИЕ'),
                  children: [
                    _buildNavigationTile(
                      label: 'Настройки сервера',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ServerSettingsScreen())),
                      icon: CupertinoIcons.globe,
                      iconColor: CupertinoColors.systemBlue,
                    ),
                    _buildNavigationTile(
                      label: 'О приложении',
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const AboutScreen())),
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
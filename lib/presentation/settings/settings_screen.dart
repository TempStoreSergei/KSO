import 'package:flutter/cupertino.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/permissions_service.dart';
import 'package:motel/core/services/token_service.dart';
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
import 'package:motel/presentation/settings/operations/operations_screen.dart';

// Главный виджет экрана настроек
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final PermissionsService _permissionsService = PermissionsService();
  final TokenService _tokenService = TokenService();
  
  String? _userRole;
  Map<String, bool> _permissions = {};
  bool _isLoadingPermissions = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadPermissions();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final role = await _tokenService.getUserRole();
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  /// Получить читаемое название роли
  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'operator':
        return 'Оператор';
      default:
        return 'Гость';
    }
  }

  Future<void> _loadPermissions() async {
    await _permissionsService.fetchPermissions();

    final permissions = {
      'screensaver': _permissionsService.hasPermission(_userRole, PermissionsMapping.screensaver),
      'acquiring': _permissionsService.hasPermission(_userRole, PermissionsMapping.acquiring),
      'billDispenser': _permissionsService.hasPermission(_userRole, PermissionsMapping.billDispenser),
      'billAcceptor': _permissionsService.hasPermission(_userRole, PermissionsMapping.billAcceptor),
      'shiftManagement': _permissionsService.hasPermission(_userRole, 'open_shift') ||
                         _permissionsService.hasPermission(_userRole, 'close_shift') ||
                         _permissionsService.hasPermission(_userRole, 'print_x_report') ||
                         _permissionsService.hasPermission(_userRole, 'get_shift_status'),
      'services': _permissionsService.hasPermission(_userRole, PermissionsMapping.services),
      'fines': _permissionsService.hasPermission(_userRole, PermissionsMapping.fines),
      'roomPrices': _permissionsService.hasPermission(_userRole, PermissionsMapping.roomPrices),
      'transactions': _permissionsService.hasPermission(_userRole, PermissionsMapping.transactions),
      'operations': _permissionsService.hasPermission(_userRole, PermissionsMapping.operations),
      'taxSettings': _permissionsService.hasPermission(_userRole, PermissionsMapping.taxSettings),
      'changePassword': _permissionsService.hasPermission(_userRole, PermissionsMapping.changePassword),
      'telegram': _permissionsService.hasPermission(_userRole, PermissionsMapping.telegram),
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

              // Удаляем токены (выход из аккаунта)
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
          
          CupertinoSliverRefreshControl(
             onRefresh: () async {
               await _loadPermissions();
             },
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
                        _getRoleDisplayName(_userRole),
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
                    if (_permissions['operations'] == true)
                      _buildNavigationTile(
                        label: 'Операции',
                        onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const OperationsScreen())),
                        icon: CupertinoIcons.waveform_path_ecg,
                        iconColor: CupertinoColors.systemOrange,
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

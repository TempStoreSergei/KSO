// lib/presentation/settings/shift_settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Импорт API client и исключений
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';

// Модели данных для смен
class ShiftSettings {
  final bool autoShiftsIsEnable;
  final String autoShiftsTimeToOpen;
  final String autoShiftsTimeToClose;

  ShiftSettings({
    required this.autoShiftsIsEnable,
    required this.autoShiftsTimeToOpen,
    required this.autoShiftsTimeToClose,
  });

  factory ShiftSettings.fromJson(Map<String, dynamic> json) {
    final shiftData = json['shiftData'] ?? {};
    return ShiftSettings(
      autoShiftsIsEnable: shiftData['autoShiftIsEnabled'] ?? false,
      autoShiftsTimeToOpen: shiftData['autoShiftsTimeToOpen']?.substring(0, 5) ?? '08:00',
      autoShiftsTimeToClose: shiftData['autoShiftsTimeToClose']?.substring(0, 5) ?? '20:00',
    );
  }
}

// Use Cases для смен
class ShiftUseCases {
  final ApiClient _apiClient;

  ShiftUseCases(this._apiClient);

  Future<ShiftSettings> getShiftSettings() async {
    try {
      // Попробуем получить настройки с сервера
      // Если у вас есть endpoint для получения настроек, замените на него
      final response = await _apiClient.get('/settings/shifts');
      return ShiftSettings.fromJson(response);
    } catch (e) {
      // Если endpoint не существует или произошла ошибка, возвращаем дефолтные значения
      return ShiftSettings(
        autoShiftsIsEnable: false,
        autoShiftsTimeToOpen: '08:00',
        autoShiftsTimeToClose: '20:00',
      );
    }
  }

  Future<void> updateAutoShiftsStatus(bool enabled) async {
    await _apiClient.put(
      '/settings/activate_or_deactivate_auto_shifts_by_time',
      body: {'autoShiftsIsEnable': enabled},
    );
  }

  Future<void> updateShiftTimes(String openTime, String closeTime) async {
    await _apiClient.put(
      '/settings/update_time_auto_shifts',
      body: {
        'autoShiftsTimeToOpen': openTime,
        'autoShiftsTimeToClose': closeTime,
      },
    );
  }

  Future<void> openShift() async {
    await _apiClient.get('/shifts/open_shift');
  }

  Future<void> closeShift() async {
    await _apiClient.get('/shifts/close_shift');
  }
}

/// Виджет-обертка для настроек смен
class ShiftSettingsScreen extends StatelessWidget {
  const ShiftSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ShiftUseCases shiftUseCases = ShiftUseCases(ApiClient.instance);

    return Provider.value(
      value: shiftUseCases,
      child: const _ShiftSettingsView(),
    );
  }
}

/// Основной виджет экрана настроек смен
class _ShiftSettingsView extends StatefulWidget {
  const _ShiftSettingsView();

  @override
  State<_ShiftSettingsView> createState() => _ShiftSettingsViewState();
}

class _ShiftSettingsViewState extends State<_ShiftSettingsView> {
  bool _autoShiftsEnabled = false;
  String _openTime = '08:00';
  String _closeTime = '20:00';
  bool _isLoading = false;

  // Состояние текущей смены
  bool _isShiftOpen = false;
  String? _shiftOpenedAt;
  String? _shiftDuration;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final shiftUseCases = Provider.of<ShiftUseCases>(context, listen: false);
      final response = await shiftUseCases._apiClient.get('/shifts/get_shift_status');
      final shiftData = response['shiftData'] ?? {};

      setState(() {
        _autoShiftsEnabled = shiftData['autoShiftIsEnabled'] ?? false;
        _openTime = shiftData['autoShiftsTimeToOpen']?.substring(0, 5) ?? '08:00';
        _closeTime = shiftData['autoShiftsTimeToClose']?.substring(0, 5) ?? '20:00';
        _isShiftOpen = shiftData['shiftIsOpened'] ?? false;
      });
    } on FetchDataException catch (e) {
      _showErrorDialog('Ошибка сети: ${e.toString()}');
    } on BadRequestException catch (e) {
      _showErrorDialog('Неверный запрос: ${e.toString()}');
    } on UnauthorisedException catch (e) {
      _showErrorDialog('Ошибка авторизации: ${e.toString()}');
    } catch (e) {
      _showErrorDialog('Ошибка загрузки настроек: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutoShifts(bool enabled) async {
    // Если включаем автосмены, проверяем валидность времени
    if (enabled && !_validateShiftTimes()) {
      return; // Не включаем автосмены при невалидном времени
    }

    try {
      final shiftUseCases = Provider.of<ShiftUseCases>(context, listen: false);
      await shiftUseCases.updateAutoShiftsStatus(enabled);
      setState(() => _autoShiftsEnabled = enabled);
      _showSuccessDialog('Настройки сохранены');
    } on FetchDataException catch (e) {
      _showErrorDialog('Ошибка сети: ${e.toString()}');
    } on BadRequestException catch (e) {
      _showErrorDialog('Неверный запрос: ${e.toString()}');
    } on UnauthorisedException catch (e) {
      _showErrorDialog('Ошибка авторизации: ${e.toString()}');
    } catch (e) {
      _showErrorDialog('Ошибка сохранения: ${e.toString()}');
    }
  }

  // Валидация времени смен
  bool _validateShiftTimes() {
    final openTimeParts = _openTime.split(':');
    final closeTimeParts = _closeTime.split(':');

    final openHour = int.parse(openTimeParts[0]);
    final openMinute = int.parse(openTimeParts[1]);
    final closeHour = int.parse(closeTimeParts[0]);
    final closeMinute = int.parse(closeTimeParts[1]);

    final openTotalMinutes = openHour * 60 + openMinute;
    final closeTotalMinutes = closeHour * 60 + closeMinute;

    // Проверяем, что время закрытия больше времени открытия
    if (closeTotalMinutes <= openTotalMinutes) {
      _showErrorDialog('Время закрытия должно быть позже времени открытия');
      return false;
    }

    // Проверяем минимальную длительность смены (1 час = 60 минут)
    final shiftDurationMinutes = closeTotalMinutes - openTotalMinutes;
    if (shiftDurationMinutes < 60) {
      _showErrorDialog('Минимальная продолжительность смены — 1 час');
      return false;
    }

    return true;
  }

  Future<void> _updateTimes() async {
    // Валидируем время перед отправкой на сервер
    if (!_validateShiftTimes()) {
      return;
    }

    try {
      final shiftUseCases = Provider.of<ShiftUseCases>(context, listen: false);
      await shiftUseCases.updateShiftTimes(_openTime, _closeTime);
      _showSuccessDialog('Время смен обновлено');
    } on FetchDataException catch (e) {
      _showErrorDialog('Ошибка сети: ${e.toString()}');
    } on BadRequestException catch (e) {
      _showErrorDialog('Неверный запрос: ${e.toString()}');
    } on UnauthorisedException catch (e) {
      _showErrorDialog('Ошибка авторизации: ${e.toString()}');
    } catch (e) {
      _showErrorDialog('Ошибка обновления времени: ${e.toString()}');
    }
  }

  Future<void> _openShift() async {
    try {
      final shiftUseCases = Provider.of<ShiftUseCases>(context, listen: false);
      await shiftUseCases.openShift();
      _showSuccessDialog('Смена открыта');
      // Обновляем все данные
      await _loadSettings();
    } on FetchDataException catch (e) {
      _showErrorDialog('Ошибка сети: ${e.toString()}');
    } on BadRequestException catch (e) {
      _showErrorDialog('Неверный запрос: ${e.toString()}');
    } on UnauthorisedException catch (e) {
      _showErrorDialog('Ошибка авторизации: ${e.toString()}');
    } catch (e) {
      _showErrorDialog('Ошибка открытия смены: ${e.toString()}');
    }
  }

  Future<void> _closeShift() async {
    try {
      final shiftUseCases = Provider.of<ShiftUseCases>(context, listen: false);
      await shiftUseCases.closeShift();
      _showSuccessDialog('Смена закрыта');
      // Обновляем все данные
      await _loadSettings();
    } on FetchDataException catch (e) {
      _showErrorDialog('Ошибка сети: ${e.toString()}');
    } on BadRequestException catch (e) {
      _showErrorDialog('Неверный запрос: ${e.toString()}');
    } on UnauthorisedException catch (e) {
      _showErrorDialog('Ошибка авторизации: ${e.toString()}');
    } catch (e) {
      _showErrorDialog('Ошибка закрытия смены: ${e.toString()}');
    }
  }

  void _showCloseShiftConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Закрыть смену?'),
        content: const Text('Вы уверены, что хотите закрыть текущую смену?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Закрыть'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _closeShift();
            },
          ),
        ],
      ),
    );
  }

  void _showTimePicker({
    required String title,
    required String currentTime,
    required Function(String) onTimeSelected,
  }) {
    final timeParts = currentTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    String tempTime = currentTime; // Временная переменная для хранения выбранного времени

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: const Border(
                  bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () {
                      Navigator.of(context).pop();

                      // Сохраняем предыдущие значения для возможного отката
                      final previousOpenTime = _openTime;
                      final previousCloseTime = _closeTime;

                      // Применяем новое время
                      onTimeSelected(tempTime);

                      // Проверяем валидность после применения нового времени
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_validateShiftTimes()) {
                          // Если валидация не прошла, возвращаем предыдущие значения
                          setState(() {
                            _openTime = previousOpenTime;
                            _closeTime = previousCloseTime;
                          });
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2024, 1, 1, hour, minute),
                use24hFormat: true,
                onDateTimeChanged: (DateTime dateTime) {
                  tempTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSettingTile({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
          const SizedBox(width: 8),
          const CupertinoListTileChevron(),
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Управление сменами'),
            previousPageTitle: 'Настройки',
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CupertinoActivityIndicator(radius: 20),
                ),
              ),
            )
          else
            SliverMainAxisGroup(
              slivers: [
                // Статус текущей смены
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
                    children: [
                      CupertinoListTile(
                        title: const Text('Статус смены'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isShiftOpen ? CupertinoColors.activeGreen : CupertinoColors.systemGrey4,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _isShiftOpen ? 'Открыта' : 'Закрыта',
                            style: TextStyle(
                              color: _isShiftOpen ? CupertinoColors.white : CupertinoColors.systemGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_isShiftOpen && _shiftOpenedAt != null)
                        CupertinoListTile(
                          title: const Text('Время открытия'),
                          trailing: Text(
                            _shiftOpenedAt!,
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      if (_isShiftOpen && _shiftDuration != null)
                        CupertinoListTile(
                          title: const Text('Продолжительность'),
                          trailing: Text(
                            _shiftDuration!,
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 17,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Автоматические смены
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('АВТОМАТИЧЕСКОЕ УПРАВЛЕНИЕ'),
                    footer: const Text(
                      'При включении автоматического управления смены будут открываться и закрываться в указанное время.',
                    ),
                    children: [
                      CupertinoListTile(
                        title: const Text('Автоматические смены'),
                        trailing: CupertinoSwitch(
                          value: _autoShiftsEnabled,
                          onChanged: _toggleAutoShifts,
                        ),
                      ),
                    ],
                  ),
                ),

                // Настройки времени
                if (_autoShiftsEnabled)
                  SliverToBoxAdapter(
                    child: CupertinoListSection.insetGrouped(
                      header: const Text('ВРЕМЯ СМЕН'),
                      footer: const Text(
                        'Время закрытия должно быть позже времени открытия. Минимальная продолжительность смены — 1 час.',
                      ),
                      children: [
                        _buildTimeSettingTile(
                          label: 'Время открытия',
                          time: _openTime,
                          onTap: () => _showTimePicker(
                            title: 'Время открытия',
                            currentTime: _openTime,
                            onTimeSelected: (time) => setState(() => _openTime = time),
                          ),
                        ),
                        _buildTimeSettingTile(
                          label: 'Время закрытия',
                          time: _closeTime,
                          onTap: () => _showTimePicker(
                            title: 'Время закрытия',
                            currentTime: _closeTime,
                            onTimeSelected: (time) => setState(() => _closeTime = time),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: _updateTimes,
                              child: const Text(
                                'Сохранить время',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Ручное управление
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('РУЧНОЕ УПРАВЛЕНИЕ'),
                    footer: const Text(
                      'Используйте эти опции для немедленного открытия или закрытия смены.',
                    ),
                    children: [
                      CupertinoListTile(
                        title: Text(
                          _isShiftOpen ? 'Закрыть смену' : 'Открыть смену',
                          style: TextStyle(
                            color: _isShiftOpen
                                ? CupertinoColors.systemRed
                                : CupertinoColors.activeGreen,
                          ),
                        ),
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _isShiftOpen
                                ? CupertinoColors.systemRed
                                : CupertinoColors.activeGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isShiftOpen
                                ? CupertinoIcons.stop_fill
                                : CupertinoIcons.play_fill,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          if (_isShiftOpen) {
                            _showCloseShiftConfirmation();
                          } else {
                            _openShift();
                          }
                        },
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

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
// lib/presentation/settings/bill_dispenser_test_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Импорт API client и исключений
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';

// Модели данных для тестирования выдачи
class DispenserTestRequest {
  final bool upperLvl;
  final int upperLvlAmount;
  final bool lowerLvl;
  final int lowerLvlAmount;

  DispenserTestRequest({
    required this.upperLvl,
    required this.upperLvlAmount,
    required this.lowerLvl,
    required this.lowerLvlAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'upperLvl': upperLvl,
      'upperLvlAmount': upperLvl ? upperLvlAmount : 0,
      'lowerLvl': lowerLvl,
      'lowerLvlAmount': lowerLvl ? lowerLvlAmount : 0,
    };
  }
}

class DispenserTestStatus {
  final String detail;
  final String status;

  DispenserTestStatus({
    required this.detail,
    required this.status,
  });

  factory DispenserTestStatus.fromJson(Map<String, dynamic> json) {
    return DispenserTestStatus(
      detail: json['detail'] ?? '',
      status: json['status'] ?? 'Неизвестно',
    );
  }
}

// Use Cases для тестирования выдачи
class BillDispenserTestUseCases {
  final ApiClient _apiClient;

  BillDispenserTestUseCases(this._apiClient);

  Future<void> startTest(DispenserTestRequest request) async {
    await _apiClient.post(
      '/tests/run_test_returning_change',
      body: request.toJson(),
    );
  }

  Future<DispenserTestStatus> getTestStatus() async {
    final response = await _apiClient.get('/tests/get_status_test_returning_change_');
    return DispenserTestStatus.fromJson(response);
  }

  Future<Map<String, dynamic>> getDispenserStatus() async {
    final response = await _apiClient.get('/settings/get_bill_dispenser_status');
    return response['billDispenserData'] ?? {};
  }
}

/// Экран тестирования диспенсера купюр
class BillDispenserTestScreen extends StatelessWidget {
  const BillDispenserTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillDispenserTestUseCases useCases = BillDispenserTestUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _BillDispenserTestView(),
    );
  }
}

class _BillDispenserTestView extends StatefulWidget {
  const _BillDispenserTestView();

  @override
  State<_BillDispenserTestView> createState() => _BillDispenserTestViewState();
}

class _BillDispenserTestViewState extends State<_BillDispenserTestView> {
  bool _isTesting = false;
  bool _isLoading = false;
  DispenserTestStatus? _currentStatus;

  // Настройки теста
  bool _upperLvlEnabled = true;
  int _upperLvlAmount = 1;
  bool _lowerLvlEnabled = true;
  int _lowerLvlAmount = 1;

  // Данные о состоянии диспенсера
  int _upperBoxCount = 0;
  int _lowerBoxCount = 0;
  int _upperBoxValue = 0;
  int _lowerBoxValue = 0;

  // Таймер для периодического обновления статуса
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadDispenserData();
  }

  @override
  void dispose() {
    _stopStatusUpdates();
    super.dispose();
  }

  Future<void> _loadDispenserData() async {
    try {
      final useCases = Provider.of<BillDispenserTestUseCases>(context, listen: false);
      final data = await useCases.getDispenserStatus();

      setState(() {
        _upperBoxCount = data['upperBoxCount'] ?? 0;
        _lowerBoxCount = data['lowerBoxCount'] ?? 0;
        _upperBoxValue = data['upperBoxValue'] ?? 0;
        _lowerBoxValue = data['lowerBoxValue'] ?? 0;

        // Корректируем выбранные количества если они больше доступных
        if (_upperLvlAmount > _upperBoxCount) {
          _upperLvlAmount = _upperBoxCount.clamp(1, 60);
        }
        if (_lowerLvlAmount > _lowerBoxCount) {
          _lowerLvlAmount = _lowerBoxCount.clamp(1, 60);
        }

        // Отключаем боксы без купюр
        if (_upperBoxCount <= 0) {
          _upperLvlEnabled = false;
        }
        if (_lowerBoxCount <= 0) {
          _lowerLvlEnabled = false;
        }
      });
    } catch (e) {
      // Ошибки загрузки не критичны
    }
  }

  Future<void> _startTest() async {
    // Проверяем, что есть что выдавать
    if (_upperLvlEnabled && _upperLvlAmount > _upperBoxCount) {
      _showErrorDialog('В верхнем боксе недостаточно купюр. Доступно: $_upperBoxCount');
      return;
    }

    if (_lowerLvlEnabled && _lowerLvlAmount > _lowerBoxCount) {
      _showErrorDialog('В нижнем боксе недостаточно купюр. Доступно: $_lowerBoxCount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final useCases = Provider.of<BillDispenserTestUseCases>(context, listen: false);
      final request = DispenserTestRequest(
        upperLvl: _upperLvlEnabled,
        upperLvlAmount: _upperLvlAmount,
        lowerLvl: _lowerLvlEnabled,
        lowerLvlAmount: _lowerLvlAmount,
      );

      await useCases.startTest(request);

      setState(() => _isTesting = true);

      // Сразу проверяем статус после запуска
      await _updateStatus();

      _startStatusUpdates();

    } catch (e) {
      _showErrorDialog('Ошибка запуска теста: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _stopTest() {
    setState(() => _isTesting = false);
    _stopStatusUpdates();
  }

  void _startStatusUpdates() {
    // Обновляем статус каждые 2 секунды
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateStatus();
    });
    // Сразу получаем первый статус
    _updateStatus();
  }

  void _stopStatusUpdates() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> _updateStatus() async {
    if (!_isTesting) return;

    try {
      final useCases = Provider.of<BillDispenserTestUseCases>(context, listen: false);
      final status = await useCases.getTestStatus();

      setState(() => _currentStatus = status);

      // Если статус "Свободен" - тест завершен
      if (status.status == 'Свободен') {
        setState(() => _isTesting = false);
        _stopStatusUpdates();
      }

    } catch (e) {
      // Ошибки статуса не критичны
    }
  }

  void _showAmountPicker({
    required String title,
    required int currentValue,
    required Function(int) onValueChanged,
  }) {
    // Определяем максимальное доступное количество
    final maxAvailable = title.contains('верхний') ? _upperBoxCount : _lowerBoxCount;
    final maxSelectable = maxAvailable.clamp(1, 60);

    if (maxAvailable <= 0) {
      _showErrorDialog('В этом боксе нет купюр для выдачи');
      return;
    }

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
                    '$title (макс: $maxAvailable)',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: (currentValue - 1).clamp(0, maxSelectable - 1),
                ),
                onSelectedItemChanged: (index) {
                  onValueChanged(index + 1);
                },
                children: List.generate(maxSelectable, (index) {
                  return Center(child: Text('${index + 1}'));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('СТАТУС ТЕСТИРОВАНИЯ'),
      children: [
        CupertinoListTile(
          title: const Text('Состояние'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isTesting ? CupertinoColors.activeGreen : CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _isTesting ? 'Активен' : 'Остановлен',
              style: TextStyle(
                color: _isTesting ? CupertinoColors.white : CupertinoColors.systemGrey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Верхний бокс'),
          subtitle: Text('Номинал: $_upperBoxValue руб.'),
          trailing: Text(
            '$_upperBoxCount купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Нижний бокс'),
          subtitle: Text('Номинал: $_lowerBoxValue руб.'),
          trailing: Text(
            '$_lowerBoxCount купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        if (_currentStatus != null) ...[
          CupertinoListTile(
            title: const Text('Статус диспенсера'),
            trailing: Text(
              _currentStatus!.status,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 17,
              ),
            ),
          ),
          if (_currentStatus!.detail.isNotEmpty)
            CupertinoListTile(
              title: const Text('Детали'),
              subtitle: Text(_currentStatus!.detail),
            ),
        ],
      ],
    );
  }

  Widget _buildSettingsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('НАСТРОЙКИ ТЕСТА'),
      footer: const Text('Настройте количество купюр для выдачи из каждого уровня диспенсера.'),
      children: [
        CupertinoListTile(
          title: const Text('Верхний уровень'),
          trailing: CupertinoSwitch(
            value: _upperLvlEnabled,
            onChanged: _isTesting ? null : (value) {
              setState(() => _upperLvlEnabled = value);
            },
          ),
        ),
        if (_upperLvlEnabled)
          CupertinoListTile(
            title: const Text('Количество (верхний)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_upperLvlAmount',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 8),
                const CupertinoListTileChevron(),
              ],
            ),
            onTap: _isTesting ? null : () => _showAmountPicker(
              title: 'Количество (верхний)',
              currentValue: _upperLvlAmount,
              onValueChanged: (value) => setState(() => _upperLvlAmount = value),
            ),
          ),
        CupertinoListTile(
          title: const Text('Нижний уровень'),
          trailing: CupertinoSwitch(
            value: _lowerLvlEnabled,
            onChanged: _isTesting ? null : (value) {
              setState(() => _lowerLvlEnabled = value);
            },
          ),
        ),
        if (_lowerLvlEnabled)
          CupertinoListTile(
            title: const Text('Количество (нижний)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_lowerLvlAmount',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 8),
                const CupertinoListTileChevron(),
              ],
            ),
            onTap: _isTesting ? null : () => _showAmountPicker(
              title: 'Количество (нижний)',
              currentValue: _lowerLvlAmount,
              onValueChanged: (value) => setState(() => _lowerLvlAmount = value),
            ),
          ),
      ],
    );
  }

  Widget _buildControlSection() {
    // Проверяем, что хотя бы один уровень включен
    final canStartTest = (_upperLvlEnabled || _lowerLvlEnabled) && !_isTesting;

    return CupertinoListSection.insetGrouped(
      header: const Text('УПРАВЛЕНИЕ'),
      children: [
        if (!_isTesting) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: canStartTest ? CupertinoColors.activeGreen : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(12),
                onPressed: (_isLoading || !canStartTest) ? null : _startTest,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                  'Запустить тест',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(12),
                onPressed: _stopTest,
                child: const Text(
                  'Остановить тест',
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Тест диспенсера купюр'),
            previousPageTitle: 'Тестирование',
          ),
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _buildStatusSection()),
              SliverToBoxAdapter(child: _buildSettingsSection()),
              SliverToBoxAdapter(child: _buildControlSection()),
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
}
// lib/presentation/settings/bill_dispenser_settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Импорт API client и исключений
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';

// Модели данных для диспенсера купюр
class BillDispenserStatus {
  final int upperBoxValue;
  final int lowerBoxValue;
  final int upperBoxCount;
  final int lowerBoxCount;

  BillDispenserStatus({
    required this.upperBoxValue,
    required this.lowerBoxValue,
    required this.upperBoxCount,
    required this.lowerBoxCount,
  });

  factory BillDispenserStatus.fromJson(Map<String, dynamic> json) {
    final billDispenserData = json['billDispenserData'] ?? {};
    return BillDispenserStatus(
      upperBoxValue: billDispenserData['upperBoxValue'] ?? 0,
      lowerBoxValue: billDispenserData['lowerBoxValue'] ?? 0,
      upperBoxCount: billDispenserData['upperBoxCount'] ?? 0,
      lowerBoxCount: billDispenserData['lowerBoxCount'] ?? 0,
    );
  }
}

// Use Cases для диспенсера купюр
class BillDispenserUseCases {
  final ApiClient _apiClient;

  BillDispenserUseCases(this._apiClient);

  Future<BillDispenserStatus> getStatus() async {
    final response = await _apiClient.get('/settings/get_bill_dispenser_status');
    return BillDispenserStatus.fromJson(response);
  }

  Future<void> setCount(int upperCount, int lowerCount) async {
    await _apiClient.post(
      '/settings/set_bill_dispenser_count',
      body: {
        'upperCount': upperCount,
        'lowerCount': lowerCount,
      },
    );
  }

  Future<void> resetCount() async {
    await _apiClient.get('/settings/reset_bill_dispenser_count');
  }

  Future<void> setLevels(int upperLvl, int lowerLvl) async {
    await _apiClient.post(
      '/settings/set_bill_dispenser_lvl',
      body: {
        'upperLvl': upperLvl,
        'lowerLvl': lowerLvl,
      },
    );
  }
}

/// Основной экран настроек диспенсера купюр
class BillDispenserSettingsScreen extends StatelessWidget {
  const BillDispenserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillDispenserUseCases useCases = BillDispenserUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _BillDispenserSettingsView(),
    );
  }
}

class _BillDispenserSettingsView extends StatefulWidget {
  const _BillDispenserSettingsView();

  @override
  State<_BillDispenserSettingsView> createState() => _BillDispenserSettingsViewState();
}

class _BillDispenserSettingsViewState extends State<_BillDispenserSettingsView> {
  BillDispenserStatus? _status;
  bool _isLoading = false;

  // Временные значения для настройки
  int _newUpperBoxCount = 0;
  int _newLowerBoxCount = 0;
  int _newUpperBoxValue = 0;
  int _newLowerBoxValue = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final useCases = Provider.of<BillDispenserUseCases>(context, listen: false);
      final status = await useCases.getStatus();

      setState(() {
        _status = status;
        _newUpperBoxCount = status.upperBoxCount;
        _newLowerBoxCount = status.lowerBoxCount;
        _newUpperBoxValue = status.upperBoxValue;
        _newLowerBoxValue = status.lowerBoxValue;
      });
    } catch (e) {
      _showErrorDialog('Ошибка загрузки данных: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCount() async {
    try {
      final useCases = Provider.of<BillDispenserUseCases>(context, listen: false);
      // Отправляем только количество добавляемых купюр, а не общее количество
      final addUpperCount = _newUpperBoxCount - (_status?.upperBoxCount ?? 0);
      final addLowerCount = _newLowerBoxCount - (_status?.lowerBoxCount ?? 0);

      await useCases.setCount(addUpperCount, addLowerCount);
      _showSuccessDialog('Количество купюр обновлено');
      await _loadData(); // Перезагружаем данные и правильно инициализируем переменные
    } catch (e) {
      _showErrorDialog('Ошибка обновления количества: ${e.toString()}');
    }
  }

  Future<void> _updateLevels() async {
    try {
      final useCases = Provider.of<BillDispenserUseCases>(context, listen: false);
      await useCases.setLevels(_newUpperBoxValue, _newLowerBoxValue);
      await _loadData();
      _showSuccessDialog('Номиналы обновлены');
    } catch (e) {
      _showErrorDialog('Ошибка обновления номиналов: ${e.toString()}');
    }
  }

  Future<void> _resetCount() async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Сброс счетчика'),
        content: const Text('Вы уверены, что хотите сбросить счетчик купюр в диспенсере?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Сбросить'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final useCases = Provider.of<BillDispenserUseCases>(context, listen: false);
                await useCases.resetCount();
                await _loadData();
                _showSuccessDialog('Счетчик сброшен');
              } catch (e) {
                _showErrorDialog('Ошибка сброса: ${e.toString()}');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCountPicker({
    required String title,
    required int currentValue,
    required Function(int) onValueChanged,
  }) {
    if (title.contains('Номинал')) {
      // Для номиналов - стандартные номиналы рублей
      final values = [10, 50, 100, 200, 500, 1000, 2000, 5000];
      final initialIndex = values.indexOf(currentValue) != -1 ? values.indexOf(currentValue) : 0;

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
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (index) {
                    onValueChanged(values[index]);
                  },
                  children: values.map((value) {
                    return Center(child: Text('$value руб.'));
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Для количества - добавляемые купюры от 1 до (1000 - текущее количество)
      int currentCount = 0;
      if (title.contains('Верхний')) {
        currentCount = _status?.upperBoxCount ?? 0;
      } else {
        currentCount = _status?.lowerBoxCount ?? 0;
      }

      final maxAdd = (1000 - currentCount).clamp(1, 1000);
      final addValues = List.generate(maxAdd, (index) => index + 1);

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
                      'Добавить купюр',
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
                    initialItem: 0,
                  ),
                  onSelectedItemChanged: (index) {
                    onValueChanged(currentCount + addValues[index]);
                  },
                  children: addValues.map((value) {
                    return Center(child: Text('+$value (итого: ${currentCount + value})'));
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatusSection() {
    if (_status == null) return Container();

    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Верхний бокс'),
          subtitle: Text('Номинал: ${_status!.upperBoxValue} руб.'),
          trailing: Text(
            '${_status!.upperBoxCount} купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Нижний бокс'),
          subtitle: Text('Номинал: ${_status!.lowerBoxValue} руб.'),
          trailing: Text(
            '${_status!.lowerBoxCount} купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountSettingsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('ДОБАВЛЕНИЕ КУПЮР'),
      footer: const Text('Добавьте купюры в каждый бокс диспенсера. Максимальная вместимость: 1000 купюр.'),
      children: [
        CupertinoListTile(
          title: const Text('Верхний бокс'),
          subtitle: Text('Текущее: ${_status?.upperBoxCount ?? 0} / 1000'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${_newUpperBoxCount - (_status?.upperBoxCount ?? 0)}',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              const CupertinoListTileChevron(),
            ],
          ),
          onTap: () => _showCountPicker(
            title: 'Верхний бокс',
            currentValue: _newUpperBoxCount,
            onValueChanged: (value) => setState(() => _newUpperBoxCount = value),
          ),
        ),
        CupertinoListTile(
          title: const Text('Нижний бокс'),
          subtitle: Text('Текущее: ${_status?.lowerBoxCount ?? 0} / 1000'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${_newLowerBoxCount - (_status?.lowerBoxCount ?? 0)}',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              const CupertinoListTileChevron(),
            ],
          ),
          onTap: () => _showCountPicker(
            title: 'Нижний бокс',
            currentValue: _newLowerBoxCount,
            onValueChanged: (value) => setState(() => _newLowerBoxCount = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: (_newUpperBoxCount > (_status?.upperBoxCount ?? 0) || _newLowerBoxCount > (_status?.lowerBoxCount ?? 0))
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(12),
              onPressed: (_newUpperBoxCount > (_status?.upperBoxCount ?? 0) || _newLowerBoxCount > (_status?.lowerBoxCount ?? 0))
                  ? _updateCount
                  : null,
              child: const Text(
                'Добавить купюры',
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
    );
  }

  Widget _buildLevelSettingsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('НАСТРОЙКА НОМИНАЛОВ'),
      footer: const Text('Установите номиналы купюр для каждого бокса диспенсера.'),
      children: [
        CupertinoListTile(
          title: const Text('Верхний бокс'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_newUpperBoxValue',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              const CupertinoListTileChevron(),
            ],
          ),
          onTap: () => _showCountPicker(
            title: 'Номинал верхнего бокса',
            currentValue: _newUpperBoxValue,
            onValueChanged: (value) => setState(() => _newUpperBoxValue = value),
          ),
        ),
        CupertinoListTile(
          title: const Text('Нижний бокс'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_newLowerBoxValue',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              const CupertinoListTileChevron(),
            ],
          ),
          onTap: () => _showCountPicker(
            title: 'Номинал нижнего бокса',
            currentValue: _newLowerBoxValue,
            onValueChanged: (value) => setState(() => _newLowerBoxValue = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
              onPressed: _updateLevels,
              child: const Text(
                'Обновить номиналы',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Диспенсер купюр'),
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
                // Текущее состояние
                SliverToBoxAdapter(
                  child: _buildStatusSection(),
                ),

                // Настройка количества
                SliverToBoxAdapter(
                  child: _buildCountSettingsSection(),
                ),

                // Настройка номиналов
                SliverToBoxAdapter(
                  child: _buildLevelSettingsSection(),
                ),

                // Действия
                SliverToBoxAdapter(
                  child: CupertinoListSection.insetGrouped(
                    header: const Text('ДЕЙСТВИЯ'),
                    children: [
                      CupertinoListTile(
                        title: const Text(
                          'Сбросить счетчик',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.restart,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                        trailing: const CupertinoListTileChevron(),
                        onTap: _resetCount,
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
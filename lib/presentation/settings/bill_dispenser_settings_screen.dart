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
    return BillDispenserStatus(
      upperBoxValue: json['upperBoxValue'] ?? 0,
      lowerBoxValue: json['lowerBoxValue'] ?? 0,
      upperBoxCount: json['upperBoxCount'] ?? 0,
      lowerBoxCount: json['lowerBoxCount'] ?? 0,
    );
  }
}

// Use Cases для диспенсера купюр
class BillDispenserUseCases {
  final ApiClient _apiClient;

  BillDispenserUseCases(this._apiClient);

  Future<BillDispenserStatus> getStatus() async {
    final response = await _apiClient.get('/cash_system/bill_dispenser/status');
    return BillDispenserStatus.fromJson(response);
  }

  Future<void> setCount(int upperCount, int lowerCount) async {
    await _apiClient.post(
      '/cash_system/bill_dispenser/add_bill_count',
      body: {
        'upperCount': upperCount,
        'lowerCount': lowerCount,
      },
    );
  }

  Future<void> resetCount() async {
    await _apiClient.get('/cash_system/bill_dispenser/reset_bill_count');
  }

  Future<void> setLevels(int upperLvl, int lowerLvl) async {
    await _apiClient.post(
      '/cash_system/bill_dispenser/set_nominal',
      body: {
        'upperLvl': upperLvl * 100,
        'lowerLvl': lowerLvl * 100,
      },
    );
  }

  Future<void> testDispenser() async {
    await _apiClient.post(
      '/cash_system/bill_dispenser/test_bill_dispenser',
      body: {
        'upperLvl': true,
        'upperLvlAmount': 1,
        'lowerLvl': true,
        'lowerLvlAmount': 1,
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

enum TestStatus {
  inactive,
  upperBox,
  lowerBox,
  complete,
}

class _BillDispenserSettingsViewState extends State<_BillDispenserSettingsView> {
  BillDispenserStatus? _status;
  bool _isLoading = false;
  TestStatus _testStatus = TestStatus.inactive;

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
      print('Decoded message: $status');
      setState(() {
        _status = status;
        _newUpperBoxCount = status.upperBoxCount;
        _newLowerBoxCount = status.lowerBoxCount;
        _newUpperBoxValue = status.upperBoxValue ~/ 100;
        _newLowerBoxValue = status.lowerBoxValue ~/ 100;
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

  Future<void> _testDispenser() async {
    // Проверяем наличие купюр
    if ((_status?.upperBoxCount ?? 0) < 1 || (_status?.lowerBoxCount ?? 0) < 1) {
      _showErrorDialog('Недостаточно купюр в диспенсере для теста.\nТребуется минимум 1 купюра в каждом боксе.');
      return;
    }

    // Анимация смены статусов
    setState(() => _testStatus = TestStatus.upperBox);
    await Future.delayed(const Duration(seconds: 20));

    if (!mounted) return;
    setState(() => _testStatus = TestStatus.lowerBox);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _testStatus = TestStatus.complete);
    await Future.delayed(const Duration(seconds: 2));

    try {
      final useCases = Provider.of<BillDispenserUseCases>(context, listen: false);
      await useCases.testDispenser();
      _showSuccessDialog('Тест выдачи завершен.\nВыдано: 1 купюра из верхнего бокса и 1 из нижнего.');
      await _loadData();
    } catch (e) {
      _showErrorDialog('Ошибка запуска теста: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _testStatus = TestStatus.inactive);
      }
    }
  }

  Future<void> _resetCount() async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Инкассация'),
        content: const Text('Вы уверены, что хотите выполнить инкассацию и сбросить счетчик купюр в диспенсере?'),
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
                _showSuccessDialog('Инкассация выполнена');
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

  String _getTestStatusText() {
    switch (_testStatus) {
      case TestStatus.inactive:
        final canTest = (_status?.upperBoxCount ?? 0) >= 1 && (_status?.lowerBoxCount ?? 0) >= 1;
        return canTest ? '' : 'Недостаточно купюр';
      case TestStatus.upperBox:
        return 'Верхний бокс';
      case TestStatus.lowerBox:
        return 'Нижний бокс';
      case TestStatus.complete:
        return 'Готово';
    }
  }

  Widget? _getTestStatusWidget() {
    if (_testStatus != TestStatus.inactive) {
      return _buildStatusTag(
        _getTestStatusText(),
        _getTestStatusColor().withOpacity(0.15),
        _getTestStatusColor(),
      );
    }

    final canTest = (_status?.upperBoxCount ?? 0) >= 1 && (_status?.lowerBoxCount ?? 0) >= 1;
    if (!canTest) {
      return _buildStatusTag(
        'Недостаточно купюр',
        CupertinoColors.systemGrey5,
        CupertinoColors.systemGrey,
      );
    }

    return const CupertinoListTileChevron();
  }

  Color _getTestStatusColor() {
    switch (_testStatus) {
      case TestStatus.inactive:
        return CupertinoColors.systemGrey;
      case TestStatus.upperBox:
      case TestStatus.lowerBox:
        return CupertinoColors.systemOrange;
      case TestStatus.complete:
        return CupertinoColors.systemGreen;
    }
  }

  Widget _buildStatusSection() {
    if (_status == null) return Container();

    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Верхний бокс'),
          subtitle: Text('Номинал: ${_status!.upperBoxValue ~/ 100} руб.'),
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
          subtitle: Text('Номинал: ${_status!.lowerBoxValue ~/ 100} руб.'),
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

  Widget _buildInfoFooter(String text, Color barColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: null,
            constraints: const BoxConstraints(minHeight: 28),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCountSettingsSection() {
    final hasChanges = _newUpperBoxCount > (_status?.upperBoxCount ?? 0) ||
        _newLowerBoxCount > (_status?.lowerBoxCount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ДОБАВЛЕНИЕ КУПЮР'),
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
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hasChanges ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: Text(
                'Добавить купюры',
                style: TextStyle(
                  color: hasChanges ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              trailing: hasChanges
                  ? const CupertinoListTileChevron()
                  : _buildStatusTag(
                'Нет изменений',
                CupertinoColors.systemGrey5,
                CupertinoColors.systemGrey,
              ),
              onTap: hasChanges ? _updateCount : null,
            ),
          ],
        ),
        _buildInfoFooter(
          'Добавьте купюры в каждый бокс диспенсера. Максимальная вместимость: 1000 купюр.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  Widget _buildLevelSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('НАСТРОЙКА НОМИНАЛОВ'),
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
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Обновить номиналы',
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _updateLevels,
            ),
          ],
        ),
        _buildInfoFooter(
          'Установите номиналы купюр для каждого бокса диспенсера.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    final canTest = (_status?.upperBoxCount ?? 0) >= 1 &&
        (_status?.lowerBoxCount ?? 0) >= 1 &&
        _testStatus == TestStatus.inactive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ТЕСТИРОВАНИЕ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: canTest ? CupertinoColors.activeGreen : CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _testStatus != TestStatus.inactive
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white, radius: 10)
                    : const Icon(
                  CupertinoIcons.play_fill,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ),
              title: Text(
                'Тест выдачи',
                style: TextStyle(
                  color: canTest ? CupertinoColors.activeGreen : CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),
              trailing: _getTestStatusWidget(),
              onTap: canTest ? _testDispenser : null,
            ),
          ],
        ),
        _buildInfoFooter(
          'Запустите тест выдачи: будет выдана 1 купюра из верхнего бокса и 1 из нижнего.',
          CupertinoColors.activeGreen,
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

                // Тестирование
                SliverToBoxAdapter(
                  child: _buildTestSection(),
                ),

                // Действия
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoListSection.insetGrouped(
                        header: const Text('ДЕЙСТВИЯ'),
                        children: [
                          CupertinoListTile(
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.money_dollar_circle,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Инкассация',
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 17,
                              ),
                            ),
                            trailing: const CupertinoListTileChevron(),
                            onTap: _resetCount,
                          ),
                        ],
                      ),
                      _buildInfoFooter(
                        'Выполните инкассацию и сбросьте счетчик купюр после изъятия денег из диспенсера.',
                        CupertinoColors.systemRed,
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
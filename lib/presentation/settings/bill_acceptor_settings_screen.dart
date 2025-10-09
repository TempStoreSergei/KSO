// lib/presentation/settings/bill_acceptor_settings_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';
import 'package:motel/core/services/websocket_service.dart';

class CashSystemStatus {
  final int maxBillCount;
  final int currentBillCount;
  final double fillPercentage;

  CashSystemStatus({
    required this.maxBillCount,
    required this.currentBillCount,
    required this.fillPercentage,
  });

  factory CashSystemStatus.fromJson(Map<String, dynamic> json) {
    final maxCount = json['maxBillCount'] ?? 0;
    final currentCount = json['billCount'] ?? 0;

    return CashSystemStatus(
      maxBillCount: maxCount,
      currentBillCount: currentCount,
      fillPercentage: maxCount > 0 ? (currentCount / maxCount * 100) : 0,
    );
  }
}

class TestEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  TestEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

class BillAcceptorUseCases {
  final ApiClient _apiClient;

  BillAcceptorUseCases(this._apiClient);

  Future<CashSystemStatus> getStatus() async {
    final response = await _apiClient.get('/cash_system/bill_acceptor/status');
    return CashSystemStatus.fromJson(response);
  }

  Future<void> updateMaxCount(int value) async {
    await _apiClient.get(
      '/cash_system/bill_acceptor/set_max_bill_count',
      params: {'value': value},
    );
  }

  Future<void> resetCount() async {
    await _apiClient.get('/cash_system/bill_acceptor/reset_bill_count');
  }

  Future<void> startTest(int amount) async {
    await _apiClient.post(
      '/cash_system/bill_acceptor/test_bill_accept',
      body: {'amount': amount * 100},
    );
  }

  Future<void> stopTest() async {
    await _apiClient.get('/cash_system/stop_accepting_payment');
  }
}

class BillAcceptorSettingsScreen extends StatelessWidget {
  const BillAcceptorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillAcceptorUseCases useCases = BillAcceptorUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _BillAcceptorSettingsView(),
    );
  }
}

class _BillAcceptorSettingsView extends StatefulWidget {
  const _BillAcceptorSettingsView();

  @override
  State<_BillAcceptorSettingsView> createState() => _BillAcceptorSettingsViewState();
}

enum TestingStatus {
  inactive,
  active,
  completed,
}

class _BillAcceptorSettingsViewState extends State<_BillAcceptorSettingsView>
    with SingleTickerProviderStateMixin {
  CashSystemStatus? _status;
  bool _isLoading = false;
  int _customMaxCount = 0;
  int _testAmount = 100;
  TestingStatus _testingStatus = TestingStatus.inactive;
  int _collectedAmount = 0;
  List<TestEvent> _events = [];
  late AnimationController _animationController;

  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadData();

    _messageSubscription = _wsService.messageStream.listen(_handleWebSocketMessage);
  }


  @override
  void dispose() {
    _messageSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
      final status = await useCases.getStatus();

      setState(() {
        _status = status;
        _customMaxCount = status.maxBillCount;
      });
    } catch (e) {
      _showErrorDialog('Ошибка загрузки данных: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMaxCount() async {
    if (_customMaxCount <= 0) {
      _showErrorDialog('Значение должно быть больше 0');
      return;
    }

    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
      await useCases.updateMaxCount(_customMaxCount);
      await _loadData();
      _showSuccessDialog('Лимит обновлен');
    } catch (e) {
      _showErrorDialog('Ошибка обновления лимита: ${e.toString()}');
    }
  }

  Future<void> _resetCount() async {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Инкассация'),
        content: const Text('Вы уверены, что хотите произвести инкассацию? Счетчик будет сброшен в ноль.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Инкассировать'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
                await useCases.resetCount();
                await _loadData();
                _showSuccessDialog('Инкассация выполнена');
              } catch (e) {
                _showErrorDialog('Ошибка инкассации: ${e.toString()}');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startTest() async {
    setState(() => _isLoading = true);

    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
      await useCases.startTest(_testAmount);

      setState(() {
        _testingStatus = TestingStatus.active;
        _events.clear();
        _collectedAmount = 0;
      });

      await Future.delayed(const Duration(milliseconds: 500));


      await _wsService.connect();

      _addEvent('info', {'message': 'Тест запущен на сумму $_testAmount руб.'});
    } on BadRequestException {
      _showInkassationDialog();
    } catch (e) {
      _showErrorDialog('Ошибка запуска теста: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stopTest() async {
    try {
      final useCases = Provider.of<BillAcceptorUseCases>(context, listen: false);
      await useCases.stopTest();

      setState(() => _testingStatus = TestingStatus.inactive);

      _wsService.disconnect();

      _addEvent('info', {'message': 'Тест остановлен'});
    } catch (e) {
      _showErrorDialog('Ошибка остановки теста: ${e.toString()}');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final eventType = message['event'];
      final eventData = message['data'];

      if (eventType == 'acceptedBill') {
        final billValue = eventData['bill_value'];
        final collectedAmount = eventData['collected_amount'];

        setState(() => _collectedAmount = collectedAmount ~/ 100);
        _addEvent('acceptedBill', {
          'bill_value': billValue ~/ 100,
          'collected_amount': collectedAmount ~/ 100,
        });
      } else if (eventType == 'successPayment') {
        final collectedAmount = eventData['collected_amount'];
        final change = eventData['change'];

        setState(() {
          _collectedAmount = collectedAmount ~/ 100;
          _testingStatus = TestingStatus.completed;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _testingStatus = TestingStatus.inactive);
          }
        });

        _wsService.disconnect();
        _addEvent('successPayment', {
          'collected_amount': collectedAmount ~/ 100,
          'change': change ~/ 100,
        });
      }
    } catch (e) {
      print('Handler error: $e');
    }
  }

  void _addEvent(String type, Map<String, dynamic> data) {
    setState(() {
      _events.insert(0, TestEvent(
        type: type,
        data: data,
        timestamp: DateTime.now(),
      ));

      if (_events.length > 30) {
        _events = _events.take(30).toList();
      }
    });
  }

  void _showInkassationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Требуется инкассация'),
        content: const Text('Для запуска теста необходимо провести инкассацию купюроприемника.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Инкассировать'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetCount();
            },
          ),
        ],
      ),
    );
  }

  void _showMaxCountPicker() {
    const maxLimit = 1500;

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
                  const Text(
                    'Лимит купюр',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    child: const Text('Готово'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateMaxCount();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: _customMaxCount > 0 ? _customMaxCount - 1 : 0,
                ),
                onSelectedItemChanged: (index) {
                  setState(() => _customMaxCount = index + 1);
                },
                children: List.generate(maxLimit, (index) {
                  return Center(child: Text('${index + 1}'));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestAmountPicker() {
    final amounts = [10, 50, 100, 150, 200, 500, 1000];
    final initialIndex = amounts.indexOf(_testAmount) != -1 ? amounts.indexOf(_testAmount) : 2;

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
                  const Text(
                    'Сумма для теста',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                  setState(() => _testAmount = amounts[index]);
                },
                children: amounts.map((amount) {
                  return Center(child: Text('$amount руб.'));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
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
            constraints: const BoxConstraints(minHeight: 24),
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
                  fontSize: 15,
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

  Widget? _getTestStatusWidget() {
    switch (_testingStatus) {
      case TestingStatus.inactive:
        return const CupertinoListTileChevron();
      case TestingStatus.active:
        return _buildStatusTag(
          'Активен',
          CupertinoColors.systemOrange.withOpacity(0.15),
          CupertinoColors.systemOrange,
        );
      case TestingStatus.completed:
        return _buildStatusTag(
          'Завершен',
          CupertinoColors.systemGreen.withOpacity(0.15),
          CupertinoColors.systemGreen,
        );
    }
  }

  Color _getFillColor(double percentage) {
    if (percentage < 50) return CupertinoColors.activeGreen;
    if (percentage < 80) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Купюроприемник'),
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

                // Настройки лимита
                SliverToBoxAdapter(
                  child: _buildLimitSection(),
                ),

                // Тестирование
                SliverToBoxAdapter(
                  child: _buildTestSection(),
                ),

                // Действия
                SliverToBoxAdapter(
                  child: _buildActionsSection(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_status == null) return Container();

    final fillPercentage = _status!.fillPercentage;
    final currentCount = _status!.currentBillCount;
    final maxCount = _status!.maxBillCount;
    final remainingSpace = maxCount - currentCount;

    return CupertinoListSection.insetGrouped(
      header: const Text('ТЕКУЩЕЕ СОСТОЯНИЕ'),
      children: [
        CupertinoListTile(
          title: const Text('Заполнено'),
          trailing: Text(
            '$currentCount купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Осталось места'),
          trailing: Text(
            '$remainingSpace купюр',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Процент заполнения'),
          trailing: Text(
            '${fillPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: _getFillColor(fillPercentage),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLimitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('НАСТРОЙКА ЛИМИТА'),
          children: [
            CupertinoListTile(
              title: const Text('Максимум купюр'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_customMaxCount',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: _showMaxCountPicker,
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
                  CupertinoIcons.checkmark,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Обновить лимит',
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _updateMaxCount,
            ),
          ],
        ),
        _buildInfoFooter(
          'Установите максимальное количество купюр, которое может принять купюроприемник.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    final canTest = _testingStatus == TestingStatus.inactive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ТЕСТИРОВАНИЕ'),
          children: [
            if (canTest) ...[
              CupertinoListTile(
                title: const Text('Сумма для теста'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_testAmount руб.',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CupertinoListTileChevron(),
                  ],
                ),
                onTap: _showTestAmountPicker,
              ),
            ] else ...[
              CupertinoListTile(
                title: const Text('Собрано'),
                trailing: Text(
                  '$_collectedAmount руб.',
                  style: const TextStyle(
                    color: CupertinoColors.activeGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: canTest
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _testingStatus == TestingStatus.active
                    ? const CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                  radius: 10,
                )
                    : Icon(
                  canTest ? CupertinoIcons.play_fill : CupertinoIcons.stop_fill,
                  color: CupertinoColors.white,
                  size: 18,
                ),
              ),
              title: Text(
                canTest ? 'Запустить тест' : 'Остановить тест',
                style: TextStyle(
                  color: canTest
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                  fontSize: 17,
                ),
              ),
              trailing: _getTestStatusWidget(),
              onTap: canTest ? _startTest : _stopTest,
            ),
            if (_testingStatus != TestingStatus.inactive && _events.isNotEmpty)
              CupertinoListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.list_bullet,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Журнал операций',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusTag(
                      '${_events.length}',
                      CupertinoColors.systemGrey5,
                      CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 8),
                    const CupertinoListTileChevron(),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => TestEventsScreen(events: _events),
                    ),
                  );
                },
              ),
          ],
        ),
        _buildInfoFooter(
          'Запустите тест приема купюр: вносите наличные до достижения заданной суммы.',
          CupertinoColors.activeGreen,
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
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
          'Выполните инкассацию и сбросьте счетчик купюр после изъятия денег из купюроприемника.',
          CupertinoColors.systemRed,
        ),
      ],
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

// Отдельная страница для журнала операций
class TestEventsScreen extends StatelessWidget {
  final List<TestEvent> events;

  const TestEventsScreen({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Журнал операций'),
            previousPageTitle: 'Назад',
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              header: const Text('ВСЕ СОБЫТИЯ'),
              children: events.map((event) {
                IconData? icon;
                Color? iconColor;

                switch (event.type) {
                  case 'acceptedBill':
                    icon = CupertinoIcons.money_dollar_circle_fill;
                    iconColor = CupertinoColors.activeGreen;
                    break;
                  case 'successPayment':
                    icon = CupertinoIcons.checkmark_circle_fill;
                    iconColor = CupertinoColors.activeBlue;
                    break;
                  case 'error':
                    icon = CupertinoIcons.exclamationmark_circle_fill;
                    iconColor = CupertinoColors.systemRed;
                    break;
                  case 'info':
                    icon = CupertinoIcons.info_circle_fill;
                    iconColor = CupertinoColors.systemGrey;
                    break;
                }

                return CupertinoListTile(
                  leading: icon != null
                      ? Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconColor?.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  )
                      : null,
                  title: Text(_getEventTitle(event)),
                  subtitle: Text(_getEventSubtitle(event)),
                  trailing: Text(
                    '${event.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${event.timestamp.minute.toString().padLeft(2, '0')}:'
                        '${event.timestamp.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getEventTitle(TestEvent event) {
    switch (event.type) {
      case 'acceptedBill':
        return 'Принята купюра ${event.data['bill_value']} руб.';
      case 'successPayment':
        return 'Платеж завершен';
      case 'info':
        return 'Информация';
      case 'error':
        return 'Ошибка';
      default:
        return 'Событие ${event.type}';
    }
  }

  String _getEventSubtitle(TestEvent event) {
    switch (event.type) {
      case 'acceptedBill':
        return 'Всего: ${event.data['collected_amount']} руб.';
      case 'successPayment':
        return 'Собрано: ${event.data['collected_amount']} руб., '
            'сдача: ${event.data['change']} руб.';
      case 'info':
      case 'error':
        return event.data['message'] ?? '';
      default:
        return '';
    }
  }
}
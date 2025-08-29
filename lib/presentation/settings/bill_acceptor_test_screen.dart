// lib/presentation/settings/bill_acceptor_test_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';

// Импорт API client и исключений
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';

// WebSocket client
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

// Модели данных для тестирования
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

// Use Cases для тестирования
class BillAcceptorTestUseCases {
  final ApiClient _apiClient;

  BillAcceptorTestUseCases(this._apiClient);

  Future<void> startTest(int amount) async {
    await _apiClient.post(
      '/tests/run_test_accepting_cash',
      body: {'amount': amount},
    );
  }

  Future<void> stopTest() async {
    await _apiClient.get('/payments/stop_accepting_payment');
  }

  Future<void> resetAcceptor() async {
    await _apiClient.get('/settings/reset_bill_acceptor_count');
  }
}

/// Экран тестирования купюроприемника
class BillAcceptorTestScreen extends StatelessWidget {
  const BillAcceptorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BillAcceptorTestUseCases useCases = BillAcceptorTestUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _BillAcceptorTestView(),
    );
  }
}

class _BillAcceptorTestView extends StatefulWidget {
  const _BillAcceptorTestView();

  @override
  State<_BillAcceptorTestView> createState() => _BillAcceptorTestViewState();
}

class _BillAcceptorTestViewState extends State<_BillAcceptorTestView> {
  bool _isTesting = false;
  bool _isLoading = false;
  List<TestEvent> _events = [];
  int _testAmount = 100;
  int _collectedAmount = 0;

  // WebSocket channel
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  @override
  void dispose() {
    _stopWebSocket();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() => _isLoading = true);

    try {
      final useCases = Provider.of<BillAcceptorTestUseCases>(context, listen: false);
      await useCases.startTest(_testAmount);

      setState(() {
        _isTesting = true;
        _events.clear();
        _collectedAmount = 0;
      });

      // Небольшая задержка перед подключением к WebSocket
      await Future.delayed(const Duration(milliseconds: 500));

      _connectWebSocket();
      _addEvent('info', {'message': 'Тест запущен на сумму $_testAmount руб.'});

    } on BadRequestException catch (e) {
      _showInkassationDialog();
    } catch (e) {
      _showErrorDialog('Критическая ошибка: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stopTest() async {
    try {
      final useCases = Provider.of<BillAcceptorTestUseCases>(context, listen: false);
      await useCases.stopTest();

      setState(() => _isTesting = false);
      _stopWebSocket();
      _addEvent('info', {'message': 'Тест остановлен'});

    } catch (e) {
      _showErrorDialog('Ошибка остановки теста: ${e.toString()}');
    }
  }

  Future<void> _performInkassation() async {
    try {
      final useCases = Provider.of<BillAcceptorTestUseCases>(context, listen: false);
      await useCases.resetAcceptor();
      _showSuccessDialog('Инкассация выполнена. Можно запустить тест.');
    } catch (e) {
      _showErrorDialog('Ошибка инкассации: ${e.toString()}');
    }
  }

  void _connectWebSocket() {
    try {
      final wsUrl = 'ws://192.168.0.99:8000/websockets/test_run_accepting_cash';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.ready.then((_) {
        _addEvent('info', {'message': 'WebSocket подключен'});
      }).catchError((error) {
        _addEvent('error', {'message': 'Ошибка готовности WebSocket: $error'});
      });

      _subscription = _channel!.stream.listen(
            (data) {
          try {
            Map<String, dynamic> message;
            if (data is String) {
              message = jsonDecode(data);
            } else if (data is Map) {
              message = Map<String, dynamic>.from(data);
            } else {
              return;
            }

            _handleWebSocketMessage(message);
          } catch (e) {
            _addEvent('error', {'message': 'Ошибка парсинга: $e'});
          }
        },
        onError: (error) {
          _addEvent('error', {'message': 'Ошибка WebSocket: $error'});
        },
        onDone: () {
          _addEvent('info', {'message': 'WebSocket соединение закрыто'});
        },
        cancelOnError: false,
      );

    } catch (e) {
      _addEvent('error', {'message': 'Не удалось подключиться к WebSocket: $e'});
    }
  }

  void _stopWebSocket() {
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _subscription = null;
    _channel = null;
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    // Получаем тип события и вложенные данные
    final eventType = message['event'] ?? message['type'] ?? '';

    // Извлекаем данные из вложенного поля data
    final eventData = message['data'] as Map<String, dynamic>? ?? {};

    switch (eventType) {
      case 'acceptedBill':
        final billValue = eventData['bill_value'] ?? 0;
        final collectedAmount = eventData['collected_amount'] ?? 0;

        setState(() => _collectedAmount = collectedAmount);
        _addEvent('acceptedBill', {
          'bill_value': billValue,
          'collected_amount': collectedAmount,
        });
        break;

      case 'successPayment':
        final collectedAmount = eventData['collected_amount'] ?? 0;
        final change = eventData['change'] ?? 0;

        setState(() {
          _collectedAmount = collectedAmount;
          _isTesting = false;
        });
        _stopWebSocket();
        _addEvent('successPayment', {
          'collected_amount': collectedAmount,
          'change': change,
        });
        break;

      case 'error':
        _addEvent('error', {'message': message['detail'] ?? 'Неизвестная ошибка'});
        break;
    }
  }

  void _addEvent(String type, Map<String, dynamic> data) {
    setState(() {
      _events.insert(0, TestEvent(
        type: type,
        data: data,
        timestamp: DateTime.now(),
      ));

      // Ограничиваем количество событий
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
            child: const Text('Провести инкассацию'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _performInkassation();
            },
          ),
        ],
      ),
    );
  }

  void _showAmountPicker() {
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
          title: const Text('Сумма теста'),
          trailing: Text(
            '$_testAmount руб.',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
            ),
          ),
        ),
        if (_isTesting)
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
    );
  }

  Widget _buildControlSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('УПРАВЛЕНИЕ'),
      children: [
        if (!_isTesting) ...[
          CupertinoListTile(
            title: const Text('Сумма для тестирования'),
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
            onTap: _showAmountPicker,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.activeGreen,
                borderRadius: BorderRadius.circular(12),
                onPressed: _isLoading ? null : _startTest,
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

  Widget _buildEventsSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('СОБЫТИЯ'),
      children: _events.isEmpty
          ? [
        const CupertinoListTile(
          title: Text(
            'События будут отображаться здесь',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      ]
          : _events.take(15).map((event) {
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
              ? Icon(icon, color: iconColor, size: 24)
              : null,
          title: Text(_getEventTitle(event)),
          subtitle: Text(_getEventSubtitle(event)),
          trailing: Text(
            '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
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
        return 'Всего собрано: ${event.data['collected_amount']} руб.';
      case 'successPayment':
        return 'Собрано: ${event.data['collected_amount']} руб., сдача: ${event.data['change']} руб.';
      case 'info':
      case 'error':
        return event.data['message'] ?? '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Тест купюроприемника'),
            previousPageTitle: 'Купюроприемник',
          ),
          SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _buildStatusSection()),
              SliverToBoxAdapter(child: _buildControlSection()),
              SliverToBoxAdapter(child: _buildEventsSection()),
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
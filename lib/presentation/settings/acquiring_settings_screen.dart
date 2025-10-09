import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:motel/core/api/api_client.dart';

// Модели данных для эквайринга
class AcquiringResponse {
  final bool status;
  final String detail;
  final Map<String, dynamic>? data;

  AcquiringResponse({
    required this.status,
    required this.detail,
    this.data,
  });

  factory AcquiringResponse.fromJson(Map<String, dynamic> json) {
    return AcquiringResponse(
      status: json['status'] ?? false,
      detail: json['detail'] ?? '',
      data: json['data'],
    );
  }
}

// Use Cases для эквайринга
class AcquiringUseCases {
  final ApiClient _apiClient;

  AcquiringUseCases(this._apiClient);

  // Автоматическая проверка подключения (сначала новый метод, потом старый)
  Future<AcquiringResponse> checkConnection() async {
    try {
      final response = await _apiClient.get('/acquiring/check_connect');
      final result = AcquiringResponse.fromJson(response);
      if (result.status) {
        return result;
      }
    } catch (e) {
      // Если новый метод не сработал, пробуем старый
    }

    // Пробуем старый метод
    final response = await _apiClient.get('/acquiring/check_connect_old');
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> startPayment() async {
    final response = await _apiClient.get('/acquiring/start_payment', params: {'amount': '100'});
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> refundPayment() async {
    final response = await _apiClient.get('/acquiring/refund_payment',  params: {'amount': '100'});
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> receiptReport() async {
    final response = await _apiClient.get('/acquiring/receipt_report');
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> cancelPayment() async {
    final response = await _apiClient.get('/acquiring/cancel_payment');
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> openMenu() async {
    final response = await _apiClient.get('/acquiring/open_menu');
    return AcquiringResponse.fromJson(response);
  }
}

/// Основной экран настроек эквайринга
class AcquiringSettingsScreen extends StatelessWidget {
  const AcquiringSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AcquiringUseCases useCases = AcquiringUseCases(ApiClient.instance);

    return Provider.value(
      value: useCases,
      child: const _AcquiringSettingsView(),
    );
  }
}

class _AcquiringSettingsView extends StatefulWidget {
  const _AcquiringSettingsView();

  @override
  State<_AcquiringSettingsView> createState() => _AcquiringSettingsViewState();
}

class _AcquiringSettingsViewState extends State<_AcquiringSettingsView> {
  bool _isConnected = false;
  bool _isCheckingConnection = false;
  String _connectionMethod = '';
  String _lastActionResult = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
      _connectionMethod = '';
    });

    try {
      final useCases = Provider.of<AcquiringUseCases>(context, listen: false);
      final response = await useCases.checkConnection();

      setState(() {
        _isConnected = response.status;
        _connectionMethod = response.detail;
        _isCheckingConnection = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionMethod = 'Ошибка подключения';
        _isCheckingConnection = false;
      });
    }
  }

  Future<void> _startPayment() async {
    await _executeAction(
      'Запуск платежа',
          () async {
        final useCases = Provider.of<AcquiringUseCases>(context, listen: false);
        return await useCases.startPayment();
      },
    );
  }

  Future<void> _refundPayment() async {
    await _executeAction(
      'Возврат платежа',
          () async {
        final useCases = Provider.of<AcquiringUseCases>(context, listen: false);
        return await useCases.refundPayment();
      },
    );
  }

  Future<void> _receiptReport() async {
    await _executeAction(
      'Отчет о чеках',
          () async {
        final useCases = Provider.of<AcquiringUseCases>(context, listen: false);
        return await useCases.receiptReport();
      },
    );
  }

  Future<void> _cancelPayment() async {
    await _executeAction(
      'Отмена платежа',
          () async {
        final useCases = Provider.of<AcquiringUseCases>(context, listen: false);
        return await useCases.cancelPayment();
      },
    );
  }

  Future<void> _openMenu() async {
    await _executeAction(
      'Открыть меню',
          () async {
        final useCases = Provider.of<AcquiringUseCases>(context, listen: false);
        return await useCases.openMenu();
      },
    );
  }

  Future<void> _executeAction(String actionName, Future<AcquiringResponse> Function() action) async {
    try {
      final response = await action();

      setState(() {
        _lastActionResult = response.detail;
      });

      if (response.status) {
        _showSuccessDialog('$actionName выполнен успешно', response.detail);
      } else {
        _showErrorDialog('$actionName не выполнен', response.detail);
      }
    } catch (e) {
      _showErrorDialog('Ошибка выполнения', e.toString());
    }
  }

  Widget _buildStatusSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('СТАТУС ПОДКЛЮЧЕНИЯ'),
      children: [
        CupertinoListTile(
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _isConnected
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isConnected ? CupertinoIcons.checkmark : CupertinoIcons.xmark,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          title: Text(
            _isConnected ? 'Подключено' : 'Не подключено',
            style: TextStyle(
              color: _isConnected
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.systemRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: _connectionMethod.isNotEmpty
              ? Text(_connectionMethod)
              : null,
          trailing: _isCheckingConnection
              ? const CupertinoActivityIndicator(radius: 10)
              : CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _checkConnection,
            child: const Icon(
              CupertinoIcons.refresh,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ОПЕРАЦИИ С ПЛАТЕЖАМИ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Запустить платеж',
                style: TextStyle(
                  color: CupertinoColors.activeGreen,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _isConnected ? _startPayment : null,
            ),
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.arrow_counterclockwise,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Возврат платежа',
                style: TextStyle(
                  color: CupertinoColors.systemOrange,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _isConnected ? _refundPayment : null,
            ),
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.xmark_circle,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Отменить платеж',
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _isConnected ? _cancelPayment : null,
            ),
          ],
        ),
        _buildInfoFooter(
          'Управление платежными операциями через терминал эквайринга.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('ОТЧЕТЫ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Отчет о чеках',
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _isConnected ? _receiptReport : null,
            ),
          ],
        ),
        _buildInfoFooter(
          'Получение отчетов о проведенных операциях.',
          CupertinoColors.activeBlue,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('НАСТРОЙКИ'),
          children: [
            CupertinoListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.settings,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Открыть меню терминала',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: _isConnected ? _openMenu : null,
            ),
          ],
        ),
        _buildInfoFooter(
          'Открыть меню настроек на терминале эквайринга.',
          CupertinoColors.systemGrey,
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Эквайринг'),
            previousPageTitle: 'Настройки',
          ),
          SliverMainAxisGroup(
            slivers: [
              // Статус подключения
              SliverToBoxAdapter(
                child: _buildStatusSection(),
              ),

              // Операции с платежами
              SliverToBoxAdapter(
                child: _buildPaymentActionsSection(),
              ),

              // Отчеты
              SliverToBoxAdapter(
                child: _buildReportsSection(),
              ),

              // Настройки
              SliverToBoxAdapter(
                child: _buildSettingsSection(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
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

  void _showSuccessDialog(String title, String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
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
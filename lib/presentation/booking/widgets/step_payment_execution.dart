import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/websocket_service.dart';
import 'package:motel/core/services/tax_settings_service.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/save_transaction_usecase.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StepPaymentExecution extends StatefulWidget {
  final BookingData data;
  final String paymentMethod;
  final int totalPrice;
  final WebSocketService webSocketService;
  final VoidCallback onPaymentComplete;
  final VoidCallback onPaymentError;
  final VoidCallback onPaymentTimeout;
  final VoidCallback? onCancel;
  final void Function(String message, Future<bool> Function() retryPrint)? onHardwareError;

  const StepPaymentExecution({
    super.key,
    required this.data,
    required this.paymentMethod,
    required this.totalPrice,
    required this.webSocketService,
    required this.onPaymentComplete,
    required this.onPaymentError,
    required this.onPaymentTimeout,
    this.onCancel,
    this.onHardwareError,
  });

  @override
  State<StepPaymentExecution> createState() => _StepPaymentExecutionState();
}

class _StepPaymentExecutionState extends State<StepPaymentExecution> {
  Timer? _paymentTimer;
  late int _remainingSeconds;
  late int _totalSeconds;
  StreamSubscription? _socketSubscription;
  int _collectedAmount = 0; // Собранная сумма в копейках
  bool _isCancelling = false;
  bool _isDeviceReady = false;

  @override
  void initState() {
    super.initState();
    widget.webSocketService.connect();
    _totalSeconds = widget.paymentMethod == 'Наличные' ? 300 : 120;
    _remainingSeconds = _totalSeconds;
    _listenToPaymentEvents();
    _startPayment();
  }

  Future<void> _startPayment() async {
    try {
      if (widget.paymentMethod == 'Наличные') {
        await ApiClient.instance.get(
          '/cash_system/start_accepting_payment',
          params: {'amount': widget.totalPrice},
        );
      } else if (widget.paymentMethod == 'Карта') {
        await ApiClient.instance.get(
          '/acquiring/start_payment',
          params: {'amount': widget.totalPrice},
        );
      }
      // Устройство ответило — запускаем таймер
      if (mounted) {
        setState(() => _isDeviceReady = true);
        _startPaymentTimer();
      }
    } catch (e) {
      print('Ошибка запуска оплаты: $e');
      if (widget.onHardwareError != null) {
        widget.onHardwareError!('Оборудование не отвечает: $e', () async => false);
      } else {
        widget.onPaymentError();
      }
    }
  }

  Future<void> _cancelPayment() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    try {
      if (widget.paymentMethod == 'Наличные') {
        await ApiClient.instance.get('/cash_system/stop_accepting_payment');
      }
      _paymentTimer?.cancel();
      _socketSubscription?.cancel();
      if (mounted) {
        widget.onCancel?.call();
      }
    } catch (e) {
      print('Ошибка отмены оплаты: $e');
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  void _listenToPaymentEvents() {
    _socketSubscription = widget.webSocketService.messageStream.listen((message) {
      print('DEBUG: WebSocket message received: $message');
      final eventType = message['event'];
      final eventData = message['data'];

      if (eventType == 'acceptedBill') {
        print('DEBUG: acceptedBill event, collected_amount: ${eventData?['collected_amount']}');
        // Обновление собранной суммы для наличных
        if (mounted && eventData != null && eventData['collected_amount'] != null) {
          setState(() {
            _collectedAmount = eventData['collected_amount'] as int;
          });
        }
      } else if (eventType == 'successPayment') {
        print('DEBUG: successPayment event received');
        _handleSuccessfulPayment();
      } else if (eventType == 'errorPayment') {
        print('DEBUG: errorPayment event received');
        widget.onPaymentError();
      }
    });
  }

  Future<void> _handleSuccessfulPayment() async {
    print('DEBUG: _handleSuccessfulPayment called');
    try {
      final isCheckPrinted = await _printCheck();
      print('DEBUG: isCheckPrinted = $isCheckPrinted');
      if (isCheckPrinted) {
        final useCase = SaveTransactionUseCase(ApiClient.instance);
        print('DEBUG: Calling SaveTransactionUseCase');
        await useCase.call(widget.data);
        print('DEBUG: Transaction saved, calling onPaymentComplete');
        widget.onPaymentComplete();
      } else {
        print('DEBUG: Check printing failed');
        // Сохраняем транзакцию даже если чек не напечатался
        try {
          final useCase = SaveTransactionUseCase(ApiClient.instance);
          await useCase.call(widget.data);
        } catch (_) {}
        if (widget.onHardwareError != null) {
          widget.onHardwareError!('Не удалось напечатать чек. Обратитесь к администратору.', _printCheck);
        } else {
          widget.onPaymentError();
        }
      }
    } catch (e) {
      print('DEBUG: Error in _handleSuccessfulPayment: $e');
      // Сохраняем транзакцию даже при ошибке оборудования
      try {
        final useCase = SaveTransactionUseCase(ApiClient.instance);
        await useCase.call(widget.data);
      } catch (_) {}
      if (widget.onHardwareError != null) {
        widget.onHardwareError!('Ошибка оборудования: $e', _printCheck);
      } else {
        widget.onPaymentError();
      }
    }
  }

  Future<bool> _printCheck() async {
    final items = widget.data.selectedItems.map((item) {
      return {
        "name": item.name,
        "price": item.price,
        "quantity": item.quantity,
        "tax": item.tax,
        "objectType": 4, // Всегда 4
      };
    }).toList();

    // Если услуги не выбраны (пустой список), добавляем услугу по умолчанию
    if (items.isEmpty && widget.data.selectedCategory == BookingCategory.accommodation) {
      // Получаем налоговую ставку из настроек
      final defaultTax = await TaxSettingsService.getDefaultAccommodationTax();

      items.add({
        "name": "Предоставление койко-мест для временного размещения",
        "price": widget.totalPrice,
        "quantity": 1,
        "tax": defaultTax,
        "objectType": 4,
      });
    }

    final checkData = {
      "items": items,
      "paymentType": _getPaymentTypeCode(widget.paymentMethod),
      "summ": widget.totalPrice,
    };

    return await ApiClient.instance.printCheck(checkData);
  }

  int _getPaymentTypeCode(String paymentMethod) {
    switch (paymentMethod) {
      case 'Карта':
        return 1;
      case 'Наличные':
        return 0;
      default:
        return 1; // СБП or other
    }
  }

  void _startPaymentTimer() {
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _paymentTimer?.cancel();
          widget.onPaymentTimeout();
        }
      });
    });
  }

  @override
  void dispose() {
    _paymentTimer?.cancel();
    _socketSubscription?.cancel();
    super.dispose();
  }

  String _getFormattedTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progressValue => _remainingSeconds / _totalSeconds;

  Color get _progressColor {
    if (_remainingSeconds > 60) {
      return CupertinoColors.systemGreen;
    } else if (_remainingSeconds > 30) {
      return CupertinoColors.systemOrange;
    } else {
      return CupertinoColors.systemRed;
    }
  }

  IconData _getPaymentIcon() {
    switch (widget.paymentMethod) {
      case 'СБП':
        return CupertinoIcons.qrcode;
      case 'Карта':
        return CupertinoIcons.creditcard_fill;
      case 'Наличные':
        return CupertinoIcons.money_dollar_circle_fill;
      default:
        return CupertinoIcons.money_dollar;
    }
  }

  String _getPaymentTitle() {
    switch (widget.paymentMethod) {
      case 'СБП':
        return 'Оплата через СБП';
      case 'Карта':
        return 'Оплата картой';
      case 'Наличные':
        return 'Оплата наличными';
      default:
        return 'Выполнение оплаты';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeviceReady) {
      return StepContainer(
        icon: _getPaymentIcon(),
        title: _getPaymentTitle(),
        subtitle: 'Сумма к оплате: ${widget.totalPrice ~/ 100} ₽',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            const CupertinoActivityIndicator(radius: 20),
            const SizedBox(height: 24),
            const Text(
              'Подключение к оборудованию...',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Пожалуйста, подождите',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(height: 32),
              _buildCancelButton(),
            ],
          ],
        ),
      );
    }

    return StepContainer(
      icon: _getPaymentIcon(),
      title: _getPaymentTitle(),
      subtitle: 'Сумма к оплате: ${widget.totalPrice ~/ 100} ₽',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimerSection(),
          const SizedBox(height: 24),
          _buildPaymentContent(),
          if (widget.onCancel != null) ...[
            const SizedBox(height: 24),
            _buildCancelButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isCancelling ? null : _cancelPayment,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemRed.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: _isCancelling
              ? const CupertinoActivityIndicator()
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.chevron_back, color: CupertinoColors.systemRed, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Отменить оплату',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Время на оплату:',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 15,
                ),
              ),
              Text(
                _getFormattedTime(),
                style: TextStyle(
                  color: _progressColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 8,
              backgroundColor: const Color(0xFF2C2C2E),
              valueColor: AlwaysStoppedAnimation(_progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    switch (widget.paymentMethod) {
      case 'СБП':
        return _buildSBPContent();
      case 'Карта':
        return _buildCardContent();
      case 'Наличные':
        return _buildCashContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSBPContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.activeBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: 'sbp://pay?amount=${widget.totalPrice}&purpose=hotel_booking',
            version: QrVersions.auto,
            size: 220,
            backgroundColor: CupertinoColors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Отсканируйте QR-код',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'в приложении вашего банка',
          style: TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardContent() {
    return Column(
      children: [
        const SizedBox(height: 32),
        const Text(
          'Приложите карту к терминалу',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Следуйте инструкциям на экране терминала',
          style: TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCashContent() {
    final remainingAmount = widget.totalPrice - _collectedAmount;
    final changeAmount = _collectedAmount > widget.totalPrice ? _collectedAmount - widget.totalPrice : 0;

    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.money_dollar_circle_fill,
            color: CupertinoColors.systemGreen,
            size: 70,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Внесите купюры',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Собранная сумма
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Собрано:',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_collectedAmount ~/ 100} ₽',
                    style: const TextStyle(
                      color: CupertinoColors.systemGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Осталось:',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${remainingAmount > 0 ? remainingAmount ~/ 100 : 0} ₽',
                    style: TextStyle(
                      color: remainingAmount > 0 ? CupertinoColors.systemOrange : CupertinoColors.systemGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (changeAmount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Сдача:',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${changeAmount ~/ 100} ₽',
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Вставляйте по одной купюре',
          style: TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
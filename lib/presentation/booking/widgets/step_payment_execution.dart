import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/payment_flow_tracker.dart';
import 'package:motel/core/services/websocket_service.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/payment_hardware_usecase.dart';
import 'package:motel/domain/usecases/print_booking_check_usecase.dart';
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
  static const int _cashPaymentSeconds = 300;
  static const int _nonCashPaymentSeconds = 120;
  static const int _partialPaymentDecisionSeconds = 120;
  static const int _cashPaymentExtensionSeconds = 300;

  Timer? _paymentTimer;
  late int _remainingSeconds;
  late int _totalSeconds;
  StreamSubscription? _socketSubscription;
  int _collectedAmount = 0; // Собранная сумма в копейках
  int? _partialPaymentPromptRemainingSeconds;
  bool _isCancelling = false;
  bool _isTimingOut = false;
  bool _hasHandledSuccessfulPayment = false;
  bool _hasExtendedPartialPayment = false;
  bool _isPartialPaymentDialogOpen = false;
  bool _isDeviceReady = false;
  late final PaymentHardwareUseCase _paymentHardware;
  late final PrintBookingCheckUseCase _printBookingCheck;
  late final SaveTransactionUseCase _saveTransaction;
  late final PaymentFlowTracker _tracker;

  @override
  void initState() {
    super.initState();
    _paymentHardware = PaymentHardwareUseCase(ApiClient.instance);
    _printBookingCheck = PrintBookingCheckUseCase(ApiClient.instance);
    _saveTransaction = SaveTransactionUseCase(ApiClient.instance);
    _tracker = PaymentFlowTracker()
      ..start(
        paymentMethod: widget.paymentMethod,
        amount: widget.totalPrice,
      );
    widget.webSocketService.connect();
    _totalSeconds = widget.paymentMethod == 'Наличные' ? _cashPaymentSeconds : _nonCashPaymentSeconds;
    _remainingSeconds = _totalSeconds;
    _listenToPaymentEvents();
    _startPayment();
  }

  Future<void> _startPayment() async {
    try {
      _tracker.mark('payment_start_requested');
      if (_isCashPayment) {
        await _paymentHardware.startCashPayment(amount: widget.totalPrice);
      } else if (_isCardPayment) {
        await _paymentHardware.startCardPayment(amount: widget.totalPrice);
      }
      if (mounted) {
        _tracker.mark('device_ready');
        setState(() => _isDeviceReady = true);
        _startPaymentTimer();
      }
    } catch (e) {
      _tracker.finish('hardware_start_failed', data: {'error': e.toString()});
      if (widget.onHardwareError != null) {
        widget.onHardwareError!('Оборудование не отвечает: $e', () async => false);
      } else {
        widget.onPaymentError();
      }
    }
  }

  Future<void> _cancelPayment() async {
    if (_isCancelling) return;
    _tracker.mark('cancel_requested', data: {'collectedAmount': _collectedAmount});
    setState(() => _isCancelling = true);
    try {
      if (_isCashPayment) {
        await _stopCashAcceptance(reason: 'cancel');
        final canLeavePayment = await _dispenseInsertedCashBeforeExit();
        if (!canLeavePayment) {
          if (mounted) {
            setState(() => _isCancelling = false);
          }
          return;
        }
      }
      _paymentTimer?.cancel();
      _socketSubscription?.cancel();
      if (mounted) {
        _tracker.finish('cancelled', data: {'returnedAmount': _collectedAmount});
        widget.onCancel?.call();
      }
    } catch (e) {
      _tracker.mark('cancel_failed', data: {'error': e.toString()});
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  void _listenToPaymentEvents() {
    _socketSubscription = widget.webSocketService.messageStream.listen((message) {
      final eventType = message['event'];
      final eventData = message['data'];

      if (eventType == 'acceptedBill') {
        final collectedAmount = eventData is Map ? _readInt(eventData['collected_amount']) : null;
        if (mounted && collectedAmount != null) {
          _tracker.mark('cash_accepted', data: {'collectedAmount': collectedAmount});
          setState(() {
            _collectedAmount = collectedAmount;
          });
          if (collectedAmount >= widget.totalPrice) {
            _dismissPartialPaymentDialog();
          }
        }
      } else if (eventType == 'successPayment') {
        _tracker.mark('success_payment_event');
        _handleSuccessfulPayment(eventData);
      } else if (eventType == 'errorPayment') {
        _tracker.finish('payment_error_event');
        widget.onPaymentError();
      }
    });
  }

  Future<void> _handleSuccessfulPayment(dynamic eventData) async {
    if (_hasHandledSuccessfulPayment) return;
    _hasHandledSuccessfulPayment = true;
    _paymentTimer?.cancel();
    _dismissPartialPaymentDialog();
    try {
      _syncCollectedAmount(eventData);
      _tracker.mark('print_check_started');
      final isCheckPrinted = await _printCheck();
      if (isCheckPrinted) {
        _tracker.mark('print_check_succeeded');
        await _saveTransactionOrThrow(reason: 'payment_completed');
        _tracker.finish('completed', data: {'collectedAmount': _collectedAmount});
        widget.onPaymentComplete();
      } else {
        _tracker.mark('print_check_failed');
        await _saveTransactionSilently(reason: 'print_check_failed');
        if (widget.onHardwareError != null) {
          widget.onHardwareError!('Не удалось напечатать чек. Обратитесь к администратору.', _printCheck);
        } else {
          widget.onPaymentError();
        }
      }
    } catch (e) {
      _tracker.mark('success_handling_failed', data: {'error': e.toString()});
      await _saveTransactionSilently(reason: 'success_handling_failed');
      if (widget.onHardwareError != null) {
        widget.onHardwareError!('Ошибка оборудования: $e', _printCheck);
      } else {
        widget.onPaymentError();
      }
    }
  }

  void _syncCollectedAmount(dynamic eventData) {
    if (eventData is! Map) return;

    final collectedAmount = _readInt(eventData['collected_amount']);
    if (collectedAmount == null) return;

    _collectedAmount = collectedAmount;
    _tracker.mark('cash_amount_synced', data: {'collectedAmount': collectedAmount});
    if (mounted) {
      setState(() {});
    }
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<bool> _dispenseCashChange(int amount) async {
    if (!_isCashPayment || amount <= 0) return true;

    try {
      _tracker.mark('cash_return_started', data: {'amount': amount});
      await _paymentHardware.dispenseCash(amount: amount);
      _tracker.mark('cash_return_succeeded', data: {'amount': amount});
      return true;
    } catch (e) {
      _tracker.mark('cash_return_failed', data: {'amount': amount, 'error': e.toString()});
      return false;
    }
  }

  Future<bool> _dispenseInsertedCashBeforeExit() async {
    if (!_isCashPayment || _collectedAmount <= 0) return true;

    while (mounted) {
      final isDispensed = await _dispenseCashChange(_collectedAmount);
      if (isDispensed) return true;

      final retry = await _showDispenseRetryDialog(_collectedAmount);
      if (retry != true) return true;
    }

    return false;
  }

  Future<bool?> _showDispenseRetryDialog(int amount) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ошибка выдачи наличных'),
        content: Text(
          'Не удалось выдать внесённую сумму ${amount ~/ 100} ₽. '
          'Повторите выдачу или обратитесь к администратору.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Повторить'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Продолжить вручную'),
          ),
        ],
      ),
    );
  }

  Future<bool> _printCheck() async {
    return await _printBookingCheck.call(
      data: widget.data,
      paymentMethod: widget.paymentMethod,
      totalPrice: widget.totalPrice,
    );
  }

  Future<void> _saveTransactionSilently({required String reason}) async {
    try {
      await _saveTransactionOrThrow(reason: reason);
    } catch (e) {
      _tracker.mark('transaction_save_failed', data: {'reason': reason, 'error': e.toString()});
    }
  }

  Future<void> _saveTransactionOrThrow({required String reason}) async {
    _tracker.mark('transaction_save_started', data: {'reason': reason});
    await _saveTransaction.call(widget.data);
    _tracker.mark('transaction_save_succeeded', data: {'reason': reason});
  }

  Future<void> _stopCashAcceptance({required String reason}) async {
    try {
      _tracker.mark('cash_acceptance_stop_started', data: {'reason': reason});
      await _paymentHardware.stopCashPayment();
      _tracker.mark('cash_acceptance_stop_succeeded', data: {'reason': reason});
    } catch (e) {
      _tracker.mark('cash_acceptance_stop_failed', data: {'reason': reason, 'error': e.toString()});
      rethrow;
    }
  }

  void _startPaymentTimer() {
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      var shouldHandleTimeout = false;
      var shouldShowPartialPaymentDialog = false;
      var timeoutReason = 'timeout';

      setState(() {
        if (_partialPaymentPromptRemainingSeconds != null) {
          if (_partialPaymentPromptRemainingSeconds! > 0) {
            _partialPaymentPromptRemainingSeconds = _partialPaymentPromptRemainingSeconds! - 1;
          }

          if (_partialPaymentPromptRemainingSeconds == 0 && _hasPartialCashPayment && !_hasExtendedPartialPayment) {
            _paymentTimer?.cancel();
            shouldHandleTimeout = true;
            timeoutReason = 'partial_payment_auto_cancel';
          }
        } else if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds > 0) return;
          _remainingSeconds = 0;

          if (_hasPartialCashPayment && !_hasExtendedPartialPayment) {
            shouldShowPartialPaymentDialog = true;
            return;
          }

          _paymentTimer?.cancel();
          shouldHandleTimeout = true;
        } else {
          _remainingSeconds = 0;

          if (_hasPartialCashPayment && !_hasExtendedPartialPayment) {
            shouldShowPartialPaymentDialog = true;
            return;
          }

          _paymentTimer?.cancel();
          shouldHandleTimeout = true;
        }
      });

      if (shouldHandleTimeout) {
        _dismissPartialPaymentDialog();
        _handlePaymentTimeout(reason: timeoutReason);
      } else if (shouldShowPartialPaymentDialog) {
        _showPartialPaymentExtensionDialog();
      }
    });
  }

  Future<void> _handlePaymentTimeout({String reason = 'timeout'}) async {
    if (_isTimingOut || _isCancelling || _hasHandledSuccessfulPayment) return;
    _isTimingOut = true;
    _tracker.mark('timeout_started', data: {'collectedAmount': _collectedAmount, 'reason': reason});

    if (_isCashPayment) {
      try {
        await _stopCashAcceptance(reason: reason);
        final canLeavePayment = await _dispenseInsertedCashBeforeExit();
        if (!canLeavePayment) {
          if (mounted) {
            setState(() => _isTimingOut = false);
          }
          return;
        }
      } catch (_) {
        // Timeout must not block the user flow if cash acceptance cannot be stopped.
      }
    }

    if (mounted) {
      _tracker.finish(
        'timeout',
        data: {
          'collectedAmount': _collectedAmount,
          'returnedAmount': _isCashPayment ? _collectedAmount : 0,
          'reason': reason,
        },
      );
      widget.onPaymentTimeout();
    }
  }

  bool get _isCashPayment => widget.paymentMethod == 'Наличные';

  bool get _isCardPayment => widget.paymentMethod == 'Карта';

  bool get _hasPartialCashPayment => _isCashPayment && _collectedAmount > 0 && _collectedAmount < widget.totalPrice;

  bool get _isPartialPaymentPromptVisible =>
      _partialPaymentPromptRemainingSeconds != null &&
      _hasPartialCashPayment &&
      !_hasExtendedPartialPayment &&
      !_isCancelling &&
      !_isTimingOut &&
      !_hasHandledSuccessfulPayment;

  void _showPartialPaymentExtensionDialog() {
    if (!mounted ||
        _isPartialPaymentDialogOpen ||
        _partialPaymentPromptRemainingSeconds != null ||
        !_hasPartialCashPayment ||
        _hasExtendedPartialPayment) {
      return;
    }

    setState(() {
      _partialPaymentPromptRemainingSeconds = _partialPaymentDecisionSeconds;
    });
    _isPartialPaymentDialogOpen = true;
    _tracker.mark(
      'partial_payment_prompt_shown',
      data: {
        'collectedAmount': _collectedAmount,
        'totalPrice': widget.totalPrice,
        'remainingSeconds': _remainingSeconds,
      },
    );

    unawaited(
      showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Оплата внесена не полностью'),
          content: const Text('Сумма внесена не полностью. Продлить время приема оплаты?'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Продлить прием оплаты'),
            ),
          ],
        ),
      ).then((shouldExtend) {
        _isPartialPaymentDialogOpen = false;
        if (!mounted || shouldExtend != true) return;
        _extendCashPaymentAcceptance();
      }),
    );
  }

  void _dismissPartialPaymentDialog() {
    if (!_isPartialPaymentDialogOpen || !mounted) return;
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  void _extendCashPaymentAcceptance() {
    if (!_isPartialPaymentPromptVisible) return;

    _tracker.mark(
      'partial_payment_extended',
      data: {
        'collectedAmount': _collectedAmount,
        'totalPrice': widget.totalPrice,
      },
    );
    setState(() {
      _remainingSeconds = _cashPaymentExtensionSeconds;
      _totalSeconds = _cashPaymentExtensionSeconds;
      _partialPaymentPromptRemainingSeconds = null;
      _hasExtendedPartialPayment = true;
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

  double get _progressValue {
    if (_totalSeconds <= 0) return 0;

    final value = _remainingSeconds / _totalSeconds;
    return value.clamp(0.0, 1.0).toDouble();
  }

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

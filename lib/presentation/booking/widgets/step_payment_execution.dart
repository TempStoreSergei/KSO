// ============================================
// lib/presentation/booking/widgets/step_payment_execution.dart
// ============================================

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motel/presentation/booking/widgets/step_container.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StepPaymentExecution extends StatefulWidget {
  final String paymentMethod;
  final int totalPrice;
  final VoidCallback onPaymentComplete;
  final VoidCallback onPaymentTimeout;

  const StepPaymentExecution({
    super.key,
    required this.paymentMethod,
    required this.totalPrice,
    required this.onPaymentComplete,
    required this.onPaymentTimeout,
  });

  @override
  State<StepPaymentExecution> createState() => _StepPaymentExecutionState();
}

class _StepPaymentExecutionState extends State<StepPaymentExecution> {
  Timer? _paymentTimer;
  late int _remainingSeconds;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    // Для наличных - 10 минут (600 секунд), для остальных - 2 минуты (120 секунд)
    _totalSeconds = widget.paymentMethod == 'Наличные' ? 600 : 120;
    _remainingSeconds = _totalSeconds;
    _startPaymentTimer();
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
    return StepContainer(
      icon: _getPaymentIcon(),
      title: _getPaymentTitle(),
      subtitle: 'Сумма к оплате: ${widget.totalPrice} ₽',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Таймер с прогресс-баром
          _buildTimerSection(),

          const SizedBox(height: 24),

          // Контент в зависимости от типа оплаты
          _buildPaymentContent(),

          const SizedBox(height: 24),

          // Кнопка для симуляции успешной оплаты (в проде это уберется)
          _buildTestPaymentButton(),
        ],
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
        // QR код
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
        // Анимированная иконка карты
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.creditcard_fill,
            color: CupertinoColors.activeBlue,
            size: 70,
          ),
        ),
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
    return Column(
      children: [
        // Анимированная иконка купюр
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
        const SizedBox(height: 12),
        Text(
          '${widget.totalPrice} ₽',
          style: const TextStyle(
            color: CupertinoColors.systemGreen,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildTestPaymentButton() {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: CupertinoColors.systemGreen,
      borderRadius: BorderRadius.circular(12),
      onPressed: widget.onPaymentComplete,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.white),
          SizedBox(width: 8),
          Text(
            'Симулировать успешную оплату',
            style: TextStyle(
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// lib/core/services/metrics_service.dart
// ============================================

import 'package:shared_preferences/shared_preferences.dart';

class PaymentMetrics {
  final int successfulPayments;
  final int cardDeclines;
  final double averagePaymentTime; // в секундах

  PaymentMetrics({
    required this.successfulPayments,
    required this.cardDeclines,
    required this.averagePaymentTime,
  });
}

class MetricsService {
  static final MetricsService _instance = MetricsService._internal();
  factory MetricsService() => _instance;
  MetricsService._internal();

  static const String _keySuccessfulPayments = 'metrics_successful_payments';
  static const String _keyCardDeclines = 'metrics_card_declines';
  static const String _keyTotalPaymentTime = 'metrics_total_payment_time';
  static const String _keyPaymentCount = 'metrics_payment_count';

  DateTime? _paymentStartTime;

  /// Начать отслеживание времени платежного сценария
  void startPaymentScenario() {
    _paymentStartTime = DateTime.now();
  }

  /// Зафиксировать успешную оплату
  Future<void> recordSuccessfulPayment() async {
    final prefs = await SharedPreferences.getInstance();

    // Увеличиваем счетчик успешных оплат
    final successCount = (prefs.getInt(_keySuccessfulPayments) ?? 0) + 1;
    await prefs.setInt(_keySuccessfulPayments, successCount);

    // Записываем время платежного сценария
    if (_paymentStartTime != null) {
      final duration = DateTime.now().difference(_paymentStartTime!).inSeconds;
      final totalTime = (prefs.getDouble(_keyTotalPaymentTime) ?? 0.0) + duration;
      final paymentCount = (prefs.getInt(_keyPaymentCount) ?? 0) + 1;

      await prefs.setDouble(_keyTotalPaymentTime, totalTime);
      await prefs.setInt(_keyPaymentCount, paymentCount);

      _paymentStartTime = null;
    }
  }

  /// Зафиксировать отказ по карте
  Future<void> recordCardDecline() async {
    final prefs = await SharedPreferences.getInstance();
    final declineCount = (prefs.getInt(_keyCardDeclines) ?? 0) + 1;
    await prefs.setInt(_keyCardDeclines, declineCount);
  }

  /// Получить текущие метрики
  Future<PaymentMetrics> getMetrics() async {
    final prefs = await SharedPreferences.getInstance();

    final successCount = prefs.getInt(_keySuccessfulPayments) ?? 0;
    final declineCount = prefs.getInt(_keyCardDeclines) ?? 0;
    final totalTime = prefs.getDouble(_keyTotalPaymentTime) ?? 0.0;
    final paymentCount = prefs.getInt(_keyPaymentCount) ?? 0;

    final averageTime = paymentCount > 0 ? totalTime / paymentCount : 0.0;

    return PaymentMetrics(
      successfulPayments: successCount,
      cardDeclines: declineCount,
      averagePaymentTime: averageTime,
    );
  }

  /// Сбросить все метрики (для тестирования или сброса статистики)
  Future<void> resetMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySuccessfulPayments);
    await prefs.remove(_keyCardDeclines);
    await prefs.remove(_keyTotalPaymentTime);
    await prefs.remove(_keyPaymentCount);
  }
}

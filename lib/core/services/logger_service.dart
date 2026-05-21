// lib/core/services/logger_service.dart
import 'package:flutter/foundation.dart';

/// Уровни логирования
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Категории логирования для группировки сообщений
enum LogCategory {
  api,
  payment,
  order,
  websocket,
  shift,
  system,
  ui,
}

/// Структурированный сервис логирования
/// Обеспечивает единообразное логирование с метаданными для отслеживания
class LoggerService {
  LoggerService._privateConstructor();
  static final LoggerService instance = LoggerService._privateConstructor();

  /// Минимальный уровень логирования (можно менять в runtime)
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Установить минимальный уровень логирования
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Форматирует timestamp для логов
  String _formatTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Форматирует сообщение лога
  String _formatMessage({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    final buffer = StringBuffer();
    buffer.write('[${_formatTimestamp()}]');
    buffer.write('[${level.name.toUpperCase()}]');
    buffer.write('[${category.name.toUpperCase()}]');

    if (orderId != null) {
      buffer.write('[ORDER:$orderId]');
    }

    buffer.write(' $message');

    if (metadata != null && metadata.isNotEmpty) {
      buffer.write(' | data: $metadata');
    }

    return buffer.toString();
  }

  /// Основной метод логирования
  void log({
    required LogLevel level,
    required LogCategory category,
    required String message,
    String? orderId,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final formattedMessage = _formatMessage(
      level: level,
      category: category,
      message: message,
      orderId: orderId,
      metadata: metadata,
    );

    debugPrint(formattedMessage);

    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('  StackTrace: $stackTrace');
    }
  }

  /// Debug логирование
  void debug(
    LogCategory category,
    String message, {
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    log(
      level: LogLevel.debug,
      category: category,
      message: message,
      orderId: orderId,
      metadata: metadata,
    );
  }

  /// Info логирование
  void info(
    LogCategory category,
    String message, {
    String? orderId,
    Map<String, dynamic>? metadata,
  }) {
    log(
      level: LogLevel.info,
      category: category,
      message: message,
      orderId: orderId,
      metadata: metadata,
    );
  }

  /// Warning логирование
  void warning(
    LogCategory category,
    String message, {
    String? orderId,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.warning,
      category: category,
      message: message,
      orderId: orderId,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error логирование
  void error(
    LogCategory category,
    String message, {
    String? orderId,
    Map<String, dynamic>? metadata,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: LogLevel.error,
      category: category,
      message: message,
      orderId: orderId,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Специализированные методы для удобства

  /// Логирование API запроса
  void logApiRequest(String method, String path, {Map<String, dynamic>? body}) {
    info(LogCategory.api, 'API Request: $method $path', metadata: body);
  }

  /// Логирование API ответа
  void logApiResponse(String path, int statusCode, {Duration? duration}) {
    info(LogCategory.api, 'API Response: $path', metadata: {
      'statusCode': statusCode,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    });
  }

  /// Логирование ошибки API
  void logApiError(String path, Object error, {StackTrace? stackTrace}) {
    this.error(
      LogCategory.api,
      'API Error: $path',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Логирование события заказа
  void logOrderEvent(String event, String orderId, {Map<String, dynamic>? metadata}) {
    info(LogCategory.order, event, orderId: orderId, metadata: metadata);
  }

  /// Логирование платежного события
  void logPaymentEvent(String event, {String? orderId, Map<String, dynamic>? metadata}) {
    info(LogCategory.payment, event, orderId: orderId, metadata: metadata);
  }
}

/// Глобальный экземпляр логгера для удобного доступа
final logger = LoggerService.instance;
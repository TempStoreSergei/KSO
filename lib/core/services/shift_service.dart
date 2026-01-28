// lib/core/services/shift_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/shift_models.dart';

/// Сервис для управления сменами на кассе
/// Автоматически закрывает смену за 5 минут до конца дня (23:55)
class ShiftService {
  ShiftService._privateConstructor();
  static final ShiftService instance = ShiftService._privateConstructor();

  final ApiClient _apiClient = ApiClient.instance;
  Timer? _checkTimer;
  ShiftStatus? _lastShiftStatus;

  /// Проверяет статус смены при запуске приложения
  /// Если смена истекла (shift_state == 2), автоматически закрывает её
  Future<void> checkAndCloseExpiredShiftOnStartup() async {
    try {
      debugPrint('ShiftService: Проверка истекшей смены при запуске');

      // Получаем статус смены
      final status = await getShiftStatus(silent: true);

      if (status.success && status.data != null && status.data!.isExpired) {
        debugPrint('ShiftService: Обнаружена истекшая смена №${status.data!.shiftNumber}, автоматически закрываем');

        // Закрываем истекшую смену
        final closeResult = await closeShift();

        if (closeResult.success) {
          debugPrint('ShiftService: Истекшая смена успешно закрыта при запуске');
        } else {
          debugPrint('ShiftService: Ошибка закрытия истекшей смены: ${closeResult.message}');
        }
      } else if (status.data != null) {
        debugPrint('ShiftService: Смена в нормальном состоянии: ${status.data!.shiftStateName}');
      }
    } catch (e) {
      debugPrint('ShiftService: Ошибка при проверке истекшей смены: $e');
    }
  }

  /// Запускает умный таймер автоматического закрытия смены
  /// Вычисляет время до 23:55 и создает один таймер на это время
  void startAutoCloseMonitoring() {
    debugPrint('ShiftService: Запуск умного таймера автозакрытия смены');

    // Останавливаем предыдущий таймер если он был
    stopAutoCloseMonitoring();

    // Вычисляем время до автозакрытия
    _scheduleNextAutoClose();
  }

  /// Останавливает мониторинг
  void stopAutoCloseMonitoring() {
    debugPrint('ShiftService: Остановка таймера автозакрытия смены');
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Планирует следующее автоматическое закрытие смены
  /// Берет время из date_time статуса смены и вычитает 5 минут
  Future<void> _scheduleNextAutoClose() async {
    try {
      // Получаем статус смены
      final status = await getShiftStatus(silent: true);

      if (!status.success || status.data == null) {
        debugPrint('ShiftService: Не удалось получить статус смены для планирования');
        // Повторяем через час
        _checkTimer = Timer(const Duration(hours: 1), () => _scheduleNextAutoClose());
        return;
      }

      final now = DateTime.now();

      // Берем время из date_time и вычитаем 5 минут
      final shiftDateTime = status.data!.dateTime;
      var closeTime = shiftDateTime.subtract(const Duration(minutes: 5));

      // Если смена на сегодня, но время уже прошло, берем завтрашний день в то же время
      if (closeTime.isBefore(now)) {
        // Вычисляем время закрытия на завтра
        closeTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          closeTime.hour,
          closeTime.minute,
        );
      }

      // Вычисляем длительность до закрытия
      final duration = closeTime.difference(now);

      debugPrint('ShiftService: Запланировано автозакрытие смены в $closeTime (через ${duration.inHours}ч ${duration.inMinutes % 60}м)');

      // Создаем одноразовый таймер
      _checkTimer = Timer(duration, () async {
        await _performAutoClose();
        // Планируем следующее закрытие
        await _scheduleNextAutoClose();
      });
    } catch (e) {
      debugPrint('ShiftService: Ошибка планирования автозакрытия: $e');
      // Повторяем через час при ошибке
      _checkTimer = Timer(const Duration(hours: 1), () => _scheduleNextAutoClose());
    }
  }

  /// Выполняет автоматическое закрытие смены
  Future<void> _performAutoClose() async {
    try {
      debugPrint('ShiftService: Выполнение автоматического закрытия смены');

      // Получаем статус смены
      final status = await getShiftStatus();

      if (status.success && status.data != null && status.data!.isOpen) {
        debugPrint('ShiftService: Смена №${status.data!.shiftNumber} открыта, закрываем автоматически');

        // Закрываем смену
        final closeResult = await closeShift();

        if (closeResult.success) {
          debugPrint('ShiftService: Смена успешно закрыта автоматически');
        } else {
          debugPrint('ShiftService: Ошибка автоматического закрытия смены: ${closeResult.message}');
        }
      } else if (status.data != null && status.data!.isClosed) {
        debugPrint('ShiftService: Смена уже закрыта');
      }
    } catch (e) {
      debugPrint('ShiftService: Ошибка при автоматическом закрытии смены: $e');
    }
  }

  /// Получает текущий статус смены
  Future<ShiftStatus> getShiftStatus({
    String deviceId = 'default',
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        debugPrint('ShiftService: Получение статуса смены для устройства $deviceId');
      }

      var response = await _apiClient.get(
        '/fiscal/shift/status',
        params: {'device_id': deviceId},
      );

      // Проверяем на ошибку соединения
      if (response['success'] == false &&
          response['message'] != null &&
          response['message'].toString().contains('Соединение не установлено')) {
        debugPrint('ShiftService: Обнаружена ошибка соединения. Попытка переподключения...');
        
        final connectionResult = await _establishConnection(deviceId);
        if (connectionResult) {
          debugPrint('ShiftService: Подключение восстановлено. Повторный запрос статуса...');
          // Повторный запрос
          response = await _apiClient.get(
            '/fiscal/shift/status',
            params: {'device_id': deviceId},
          );
        } else {
          debugPrint('ShiftService: Не удалось восстановить подключение.');
        }
      }

      final status = ShiftStatus.fromJson(response);
      _lastShiftStatus = status;

      if (!silent && status.data != null) {
        debugPrint('ShiftService: Статус смены - ${status.data!.shiftStateName}, номер: ${status.data!.shiftNumber}');
      }

      return status;
    } catch (e) {
      debugPrint('ShiftService: Ошибка получения статуса смены: $e');
      return ShiftStatus(
        success: false,
        message: 'Ошибка получения статуса смены: $e',
      );
    }
  }

  /// Попытка установить соединение с фискальным регистратором
  Future<bool> _establishConnection(String deviceId) async {
    try {
      await _apiClient.post(
        '/fiscal/connection/open?device_id=$deviceId',
        body: {
          "settings": {
            "additionalProp1": {}
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint('ShiftService: Ошибка установки соединения: $e');
      return false;
    }
  }

  /// Открывает новую смену
  Future<ShiftActionResponse> openShift({
    String deviceId = 'default',
  }) async {
    try {
      debugPrint('ShiftService: Открытие смены для устройства $deviceId');

      final response = await _apiClient.post(
        '/fiscal/shift/open',
        body: {'device_id': deviceId},
      );

      final result = ShiftActionResponse.fromJson(response);

      if (result.success) {
        debugPrint('ShiftService: Смена успешно открыта');
        // Обновляем кеш статуса
        await getShiftStatus(deviceId: deviceId, silent: true);
      } else {
        debugPrint('ShiftService: Ошибка открытия смены: ${result.message}');
      }

      return result;
    } catch (e) {
      debugPrint('ShiftService: Ошибка открытия смены: $e');
      return ShiftActionResponse(
        success: false,
        message: 'Ошибка открытия смены: $e',
      );
    }
  }

  /// Закрывает текущую смену
  Future<ShiftActionResponse> closeShift({
    String deviceId = 'default',
  }) async {
    try {
      debugPrint('ShiftService: Закрытие смены для устройства $deviceId');

      final response = await _apiClient.post(
        '/fiscal/shift/close',
        body: {'device_id': deviceId},
      );

      final result = ShiftActionResponse.fromJson(response);

      if (result.success) {
        debugPrint('ShiftService: Смена успешно закрыта');
        // Обновляем кеш статуса
        await getShiftStatus(deviceId: deviceId, silent: true);
      } else {
        debugPrint('ShiftService: Ошибка закрытия смены: ${result.message}');
      }

      return result;
    } catch (e) {
      debugPrint('ShiftService: Ошибка закрытия смены: $e');
      return ShiftActionResponse(
        success: false,
        message: 'Ошибка закрытия смены: $e',
      );
    }
  }

  /// Получает последний известный статус смены из кеша
  ShiftStatus? get lastShiftStatus => _lastShiftStatus;

  /// Проверяет, открыта ли смена
  bool get isShiftOpen => _lastShiftStatus?.data?.isOpen ?? false;

  /// Освобождает ресурсы
  void dispose() {
    stopAutoCloseMonitoring();
  }
}

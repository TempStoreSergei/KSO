// lib/core/services/shift_service.dart
import 'package:flutter/foundation.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/constants/api_endpoints.dart';
import 'package:motel/domain/models/shift_automation_settings.dart';
import 'package:motel/domain/models/shift_models.dart';

/// Сервис для управления сменами на кассе
class ShiftService {
  ShiftService._privateConstructor();
  static final ShiftService instance = ShiftService._privateConstructor();

  final ApiClient _apiClient = ApiClient.instance;
  ShiftStatus? _lastShiftStatus;
  Future<ShiftAutomationSettings> getAutomationSettings() async {
    return refreshAutomationSettings();
  }

  Future<ShiftAutomationSettings> refreshAutomationSettings() async {
    final response = await _apiClient.get(ApiEndpoints.getAutoCloseShift);
    if (response is! Map) {
      throw Exception('Некорректный ответ сервера');
    }

    final payload = _extractAutomationPayload(response);
    final enabled = _asBool(payload['enabled']);
    final openTime =
        _normalizeTime(payload['open_time'] ?? payload['openTime']);
    final closeTime =
        _normalizeTime(payload['close_time'] ?? payload['closeTime']);
    final acquiringResult = _asBool(
      payload['acquiring_result'] ?? payload['acquiringResult'],
      defaultValue: true,
    );

    final lastAttempt = payload['last_attempt_at'] ??
        payload['lastAttemptAt'] ??
        payload['last_automation_attempt_at'];

    return ShiftAutomationSettings(
      openMode: enabled && openTime != null
          ? ShiftOpenMode.byTime
          : ShiftOpenMode.firstReceipt,
      autoOpenTime: openTime,
      autoCloseTime: enabled ? closeTime : null,
      acquiringReceiptReportOnClose: acquiringResult,
      lastAutomationError: payload['last_error']?.toString() ??
          payload['lastAutomationError']?.toString(),
      lastAutomationAttemptAt: lastAttempt == null
          ? null
          : DateTime.tryParse(lastAttempt.toString()),
    );
  }

  Map<String, dynamic> _extractAutomationPayload(Map response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return Map<String, dynamic>.from(response);
  }

  bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return defaultValue;
  }

  String? _normalizeTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  Future<void> saveAutomationSettings(ShiftAutomationSettings settings) async {
    final shouldOpenByTime = settings.shouldOpenByTime;
    final shouldCloseByTime = settings.shouldCloseByTime;
    final body = <String, dynamic>{
      'enabled': shouldOpenByTime || shouldCloseByTime,
      'acquiringResult': settings.acquiringReceiptReportOnClose,
    };

    if (shouldOpenByTime) {
      body['openTime'] = settings.autoOpenTime;
    }

    if (shouldCloseByTime) {
      body['closeTime'] = settings.autoCloseTime;
    }

    await _apiClient.post(
      ApiEndpoints.setAutoCloseShift,
      body: body,
    );
  }

  /// Проверяет статус смены при запуске приложения
  /// Расписание открытия/закрытия контролирует backend.
  Future<void> checkAndCloseExpiredShiftOnStartup() async {
    try {
      debugPrint('ShiftService: Обновление статуса смены при запуске');

      final status = await getShiftStatus(silent: true);
      if (status.data != null) {
        debugPrint(
            'ShiftService: Смена в нормальном состоянии: ${status.data!.shiftStateName}');
      }
    } catch (e) {
      debugPrint('ShiftService: Ошибка при проверке истекшей смены: $e');
    }
  }

  /// Расписание выполняет backend, локальный таймер не используется.
  void startAutoCloseMonitoring() {
    stopAutoCloseMonitoring();
    debugPrint(
        'ShiftService: Локальный таймер смен отключен, работает backend');
  }

  /// Останавливает локальный мониторинг.
  void stopAutoCloseMonitoring() {
    debugPrint('ShiftService: Локальный мониторинг смен не используется');
  }

  Future<ShiftActionResponse> _openShiftForAutomation() async {
    final status = await getShiftStatus(silent: true);
    if (!status.success || status.data == null) {
      return ShiftActionResponse(
        success: false,
        message: status.message.isEmpty
            ? 'Не удалось получить статус смены перед открытием'
            : status.message,
      );
    }

    if (status.data!.isOpen) {
      return ShiftActionResponse(success: true, message: 'Смена уже открыта');
    }

    if (status.data!.isExpired) {
      final closeResult = await closeShift();
      if (!closeResult.success) return closeResult;
    }

    return openShift();
  }

  Future<ShiftActionResponse> openShiftForFirstReceiptIfNeeded() async {
    final settings = await getAutomationSettings();
    if (!settings.shouldOpenOnFirstReceipt) {
      return ShiftActionResponse(
        success: true,
        message: 'Автооткрытие не требуется',
      );
    }

    return _openShiftForAutomation();
  }



  /// Получает текущий статус смены
  Future<ShiftStatus> getShiftStatus({
    String deviceId = 'default',
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        debugPrint(
            'ShiftService: Получение статуса смены для устройства $deviceId');
      }

      final response = await _apiClient.get(
        ApiEndpoints.shiftStatus,
        params: {'device_id': deviceId},
      );

      final status = ShiftStatus.fromJson(response);
      _lastShiftStatus = status;

      if (!silent && status.data != null) {
        debugPrint(
            'ShiftService: Статус смены - ${status.data!.shiftStateName}, номер: ${status.data!.shiftNumber}');
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

  /// Открывает новую смену
  Future<ShiftActionResponse> openShift({
    String deviceId = 'default',
  }) async {
    try {
      debugPrint('ShiftService: Открытие смены для устройства $deviceId');

      final response = await _apiClient.post(
        ApiEndpoints.openShift,
        body: {'device_id': deviceId},
      );

      final result = ShiftActionResponse.fromJson(response);

      if (result.success) {
        debugPrint('ShiftService: Смена успешно открыта');
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
    bool? includeAcquiringReceiptReport,
  }) async {
    try {
      debugPrint('ShiftService: Закрытие смены для устройства $deviceId');

      final shouldMakeAcquiringReport = includeAcquiringReceiptReport ??
          (await getAutomationSettings()).acquiringReceiptReportOnClose;

      if (shouldMakeAcquiringReport) {
        final reportResult = await _makeAcquiringReceiptReport();
        if (!reportResult.success) return reportResult;
      }

      final response = await _apiClient.post(
        ApiEndpoints.closeShift,
        body: {'device_id': deviceId},
      );

      final result = ShiftActionResponse.fromJson(response);

      if (result.success) {
        debugPrint('ShiftService: Смена успешно закрыта');
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

  Future<ShiftActionResponse> _makeAcquiringReceiptReport() async {
    try {
      debugPrint('ShiftService: Выполнение итога по чекам эквайринга');

      final response = await _apiClient.get(ApiEndpoints.receiptReport);
      if (response is Map<String, dynamic>) {
        final status = response['status'];
        if (status == false) {
          return ShiftActionResponse(
            success: false,
            message: response['detail']?.toString() ??
                'Итог по чекам эквайринга не выполнен',
            data: response['data'],
          );
        }

        final data = response['data'];
        final receiptLines =
            data is Map<String, dynamic> ? data['receipt_lst_str'] : null;
        if (receiptLines is List && receiptLines.isNotEmpty) {
          final receiptText = receiptLines
              .map((line) => line.toString().trimRight())
              .join('\n');
          await _apiClient.post(
            '/system/print_via_atol_kkt',
            body: {'text': receiptText},
          );
        }
      }

      return ShiftActionResponse(
        success: true,
        message: 'Итог по чекам эквайринга выполнен',
      );
    } catch (e) {
      return ShiftActionResponse(
        success: false,
        message: 'Ошибка итога по чекам эквайринга: $e',
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

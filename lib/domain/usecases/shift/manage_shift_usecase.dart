// lib/domain/usecases/shift/manage_shift_usecase.dart
import 'package:motel/core/services/logger_service.dart';
import 'package:motel/domain/models/shift_automation_settings.dart';
import 'package:motel/domain/models/shift_models.dart';
import 'package:motel/domain/repositories/shift_repository.dart';

/// UseCase for managing shifts
class ManageShiftUseCase {
  final ShiftRepository _repository;

  ManageShiftUseCase(this._repository);

  /// Get current shift status
  Future<ShiftStatus> getStatus({
    String deviceId = 'default',
    bool silent = false,
  }) {
    logger.debug(LogCategory.shift, 'ManageShiftUseCase: getStatus');
    return _repository.getShiftStatus(deviceId: deviceId, silent: silent);
  }

  /// Get automation settings controlled by backend.
  Future<ShiftAutomationSettings> getAutomationSettings() {
    logger.debug(
      LogCategory.shift,
      'ManageShiftUseCase: getAutomationSettings',
    );
    return _repository.getAutomationSettings();
  }

  /// Save automation settings controlled by backend.
  Future<void> saveAutomationSettings(ShiftAutomationSettings settings) {
    logger.info(
      LogCategory.shift,
      'ManageShiftUseCase: saveAutomationSettings',
    );
    return _repository.saveAutomationSettings(settings);
  }

  /// Open a new shift
  Future<ShiftActionResponse> openShift({String deviceId = 'default'}) {
    logger.info(LogCategory.shift, 'ManageShiftUseCase: openShift');
    return _repository.openShift(deviceId: deviceId);
  }

  /// Close current shift
  Future<ShiftActionResponse> closeShift({
    String deviceId = 'default',
    bool? includeAcquiringReceiptReport,
  }) {
    logger.info(LogCategory.shift, 'ManageShiftUseCase: closeShift');
    return _repository.closeShift(
      deviceId: deviceId,
      includeAcquiringReceiptReport: includeAcquiringReceiptReport,
    );
  }

  /// Open shift before the first receipt if configured.
  Future<ShiftActionResponse> openShiftForFirstReceiptIfNeeded() {
    logger.info(
      LogCategory.shift,
      'ManageShiftUseCase: openShiftForFirstReceiptIfNeeded',
    );
    return _repository.openShiftForFirstReceiptIfNeeded();
  }

  /// Check and close expired shift on startup
  Future<void> checkAndCloseExpiredShift() {
    logger.info(
        LogCategory.shift, 'ManageShiftUseCase: checkAndCloseExpiredShift');
    return _repository.checkAndCloseExpiredShiftOnStartup();
  }

  /// Get last cached shift status
  ShiftStatus? get lastStatus => _repository.lastShiftStatus;

  /// Check if shift is currently open
  bool get isShiftOpen => _repository.isShiftOpen;

  /// Get shift number from last status
  int get shiftNumber => _repository.lastShiftStatus?.data?.shiftNumber ?? 0;

  /// Start auto-close monitoring
  void startAutoCloseMonitoring() {
    _repository.startAutoCloseMonitoring();
  }

  /// Stop auto-close monitoring
  void stopAutoCloseMonitoring() {
    _repository.stopAutoCloseMonitoring();
  }
}

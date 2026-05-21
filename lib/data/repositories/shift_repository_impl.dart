// lib/data/repositories/shift_repository_impl.dart
import 'package:motel/core/services/shift_service.dart';
import 'package:motel/domain/models/shift_automation_settings.dart';
import 'package:motel/domain/models/shift_models.dart';
import 'package:motel/domain/repositories/shift_repository.dart';

/// Implementation of ShiftRepository using ShiftService
class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftService _shiftService;

  ShiftRepositoryImpl({ShiftService? shiftService})
      : _shiftService = shiftService ?? ShiftService.instance;

  @override
  Future<ShiftStatus> getShiftStatus({
    String deviceId = 'default',
    bool silent = false,
  }) {
    return _shiftService.getShiftStatus(deviceId: deviceId, silent: silent);
  }

  @override
  Future<ShiftAutomationSettings> getAutomationSettings() {
    return _shiftService.getAutomationSettings();
  }

  @override
  Future<void> saveAutomationSettings(ShiftAutomationSettings settings) {
    return _shiftService.saveAutomationSettings(settings);
  }

  @override
  Future<ShiftActionResponse> openShift({String deviceId = 'default'}) {
    return _shiftService.openShift(deviceId: deviceId);
  }

  @override
  Future<ShiftActionResponse> closeShift({
    String deviceId = 'default',
    bool? includeAcquiringReceiptReport,
  }) {
    return _shiftService.closeShift(
      deviceId: deviceId,
      includeAcquiringReceiptReport: includeAcquiringReceiptReport,
    );
  }

  @override
  Future<ShiftActionResponse> openShiftForFirstReceiptIfNeeded() {
    return _shiftService.openShiftForFirstReceiptIfNeeded();
  }

  @override
  Future<void> checkAndCloseExpiredShiftOnStartup() {
    return _shiftService.checkAndCloseExpiredShiftOnStartup();
  }

  @override
  void startAutoCloseMonitoring() {
    _shiftService.startAutoCloseMonitoring();
  }

  @override
  void stopAutoCloseMonitoring() {
    _shiftService.stopAutoCloseMonitoring();
  }

  @override
  ShiftStatus? get lastShiftStatus => _shiftService.lastShiftStatus;

  @override
  bool get isShiftOpen => _shiftService.isShiftOpen;

  @override
  void dispose() {
    _shiftService.dispose();
  }
}

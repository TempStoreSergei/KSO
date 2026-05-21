// lib/domain/repositories/shift_repository.dart
import 'package:motel/domain/models/shift_models.dart';
import 'package:motel/domain/models/shift_automation_settings.dart';

/// Repository interface for shift management
abstract class ShiftRepository {
  /// Get shift status
  Future<ShiftStatus> getShiftStatus({
    String deviceId = 'default',
    bool silent = false,
  });

  /// Get backend-driven shift automation settings.
  Future<ShiftAutomationSettings> getAutomationSettings();

  /// Save backend-driven shift automation settings.
  Future<void> saveAutomationSettings(ShiftAutomationSettings settings);

  /// Open a new shift
  Future<ShiftActionResponse> openShift({String deviceId = 'default'});

  /// Close current shift
  Future<ShiftActionResponse> closeShift({
    String deviceId = 'default',
    bool? includeAcquiringReceiptReport,
  });

  /// Open shift before first receipt when automation requires it.
  Future<ShiftActionResponse> openShiftForFirstReceiptIfNeeded();

  /// Check and close expired shift on startup
  Future<void> checkAndCloseExpiredShiftOnStartup();

  /// Start monitoring for auto-close
  void startAutoCloseMonitoring();

  /// Stop monitoring for auto-close
  void stopAutoCloseMonitoring();

  /// Get last cached shift status
  ShiftStatus? get lastShiftStatus;

  /// Check if shift is currently open
  bool get isShiftOpen;

  /// Dispose resources
  void dispose();
}

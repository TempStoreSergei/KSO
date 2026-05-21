// lib/presentation/settings/shift/models/shift_settings.dart

import 'package:motel/domain/models/shift_automation_settings.dart';
import 'package:motel/domain/models/shift_models.dart';

class ShiftSettings {
  final ShiftOpenMode openMode;
  final String? autoShiftsTimeToOpen;
  final String? autoShiftsTimeToClose;
  final bool acquiringReceiptReportOnClose;
  final String? lastAutomationError;
  final DateTime? lastAutomationAttemptAt;
  final bool shiftIsOpened;
  final String? shiftOpenedAt;
  final String? shiftDuration;
  final ShiftData? shiftData; // Полные данные смены

  ShiftSettings({
    this.openMode = ShiftOpenMode.firstReceipt,
    this.autoShiftsTimeToOpen,
    this.autoShiftsTimeToClose,
    this.acquiringReceiptReportOnClose = true,
    this.lastAutomationError,
    this.lastAutomationAttemptAt,
    required this.shiftIsOpened,
    this.shiftOpenedAt,
    this.shiftDuration,
    this.shiftData,
  });

  factory ShiftSettings.fromJson(Map<String, dynamic> json) {
    final shiftData = json['shiftData'] ?? {};
    return ShiftSettings(
      openMode: ShiftOpenModeX.fromStorageValue(shiftData['openMode']),
      autoShiftsTimeToOpen: shiftData['autoShiftsTimeToOpen']?.substring(0, 5),
      autoShiftsTimeToClose:
          shiftData['autoShiftsTimeToClose']?.substring(0, 5),
      acquiringReceiptReportOnClose:
          shiftData['acquiringReceiptReportOnClose'] ?? true,
      shiftIsOpened: shiftData['shiftIsOpened'] ?? false,
      shiftOpenedAt: shiftData['shiftOpenedAt'],
      shiftDuration: shiftData['shiftDuration'],
    );
  }

  ShiftSettings copyWith({
    ShiftOpenMode? openMode,
    String? autoShiftsTimeToOpen,
    bool clearAutoShiftsTimeToOpen = false,
    String? autoShiftsTimeToClose,
    bool clearAutoShiftsTimeToClose = false,
    bool? acquiringReceiptReportOnClose,
    String? lastAutomationError,
    bool clearLastAutomationError = false,
    DateTime? lastAutomationAttemptAt,
    bool? shiftIsOpened,
    String? shiftOpenedAt,
    String? shiftDuration,
    ShiftData? shiftData,
  }) {
    return ShiftSettings(
      openMode: openMode ?? this.openMode,
      autoShiftsTimeToOpen: clearAutoShiftsTimeToOpen
          ? null
          : autoShiftsTimeToOpen ?? this.autoShiftsTimeToOpen,
      autoShiftsTimeToClose: clearAutoShiftsTimeToClose
          ? null
          : autoShiftsTimeToClose ?? this.autoShiftsTimeToClose,
      acquiringReceiptReportOnClose:
          acquiringReceiptReportOnClose ?? this.acquiringReceiptReportOnClose,
      lastAutomationError: clearLastAutomationError
          ? null
          : lastAutomationError ?? this.lastAutomationError,
      lastAutomationAttemptAt:
          lastAutomationAttemptAt ?? this.lastAutomationAttemptAt,
      shiftIsOpened: shiftIsOpened ?? this.shiftIsOpened,
      shiftOpenedAt: shiftOpenedAt ?? this.shiftOpenedAt,
      shiftDuration: shiftDuration ?? this.shiftDuration,
      shiftData: shiftData ?? this.shiftData,
    );
  }

  bool get autoShiftsIsEnable =>
      openMode == ShiftOpenMode.byTime || autoShiftsTimeToClose != null;

  ShiftAutomationSettings get automationSettings => ShiftAutomationSettings(
        openMode: openMode,
        autoOpenTime: autoShiftsTimeToOpen,
        autoCloseTime: autoShiftsTimeToClose,
        acquiringReceiptReportOnClose: acquiringReceiptReportOnClose,
        lastAutomationError: lastAutomationError,
        lastAutomationAttemptAt: lastAutomationAttemptAt,
      );

  factory ShiftSettings.fromAutomation({
    required ShiftAutomationSettings automation,
    required bool shiftIsOpened,
    ShiftData? shiftData,
  }) {
    return ShiftSettings(
      openMode: automation.openMode,
      autoShiftsTimeToOpen: automation.autoOpenTime,
      autoShiftsTimeToClose: automation.autoCloseTime,
      acquiringReceiptReportOnClose: automation.acquiringReceiptReportOnClose,
      lastAutomationError: automation.lastAutomationError,
      lastAutomationAttemptAt: automation.lastAutomationAttemptAt,
      shiftIsOpened: shiftIsOpened,
      shiftData: shiftData,
    );
  }
}

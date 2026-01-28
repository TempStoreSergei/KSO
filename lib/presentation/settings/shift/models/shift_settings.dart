// lib/presentation/settings/shift/models/shift_settings.dart

import 'package:motel/domain/models/shift_models.dart';

class ShiftSettings {
  final bool autoShiftsIsEnable;
  final String autoShiftsTimeToOpen;
  final String autoShiftsTimeToClose;
  final bool shiftIsOpened;
  final String? shiftOpenedAt;
  final String? shiftDuration;
  final ShiftData? shiftData; // Полные данные смены

  ShiftSettings({
    required this.autoShiftsIsEnable,
    required this.autoShiftsTimeToOpen,
    required this.autoShiftsTimeToClose,
    required this.shiftIsOpened,
    this.shiftOpenedAt,
    this.shiftDuration,
    this.shiftData,
  });

  factory ShiftSettings.fromJson(Map<String, dynamic> json) {
    final shiftData = json['shiftData'] ?? {};
    return ShiftSettings(
      autoShiftsIsEnable: shiftData['autoShiftIsEnabled'] ?? false,
      autoShiftsTimeToOpen: shiftData['autoShiftsTimeToOpen']?.substring(0, 5) ?? '08:00',
      autoShiftsTimeToClose: shiftData['autoShiftsTimeToClose']?.substring(0, 5) ?? '20:00',
      shiftIsOpened: shiftData['shiftIsOpened'] ?? false,
      shiftOpenedAt: shiftData['shiftOpenedAt'],
      shiftDuration: shiftData['shiftDuration'],
    );
  }

  ShiftSettings copyWith({
    bool? autoShiftsIsEnable,
    String? autoShiftsTimeToOpen,
    String? autoShiftsTimeToClose,
    bool? shiftIsOpened,
    String? shiftOpenedAt,
    String? shiftDuration,
    ShiftData? shiftData,
  }) {
    return ShiftSettings(
      autoShiftsIsEnable: autoShiftsIsEnable ?? this.autoShiftsIsEnable,
      autoShiftsTimeToOpen: autoShiftsTimeToOpen ?? this.autoShiftsTimeToOpen,
      autoShiftsTimeToClose: autoShiftsTimeToClose ?? this.autoShiftsTimeToClose,
      shiftIsOpened: shiftIsOpened ?? this.shiftIsOpened,
      shiftOpenedAt: shiftOpenedAt ?? this.shiftOpenedAt,
      shiftDuration: shiftDuration ?? this.shiftDuration,
      shiftData: shiftData ?? this.shiftData,
    );
  }
}

// lib/domain/models/shift_models.dart

/// Модель статуса смены
class ShiftStatus {
  final bool success;
  final String message;
  final ShiftData? data;

  ShiftStatus({
    required this.success,
    required this.message,
    this.data,
  });

  factory ShiftStatus.fromJson(Map<String, dynamic> json) {
    // Поддержка ответов без обертки success/data
    if (json.containsKey('shift_state')) {
      return ShiftStatus(
        success: true,
        message: '',
        data: ShiftData.fromJson(json),
      );
    }

    return ShiftStatus(
      success: json['success'] ?? json['status'] ?? false,
      message: json['message'] ?? json['detail'] ?? '',
      data: json['data'] != null ? ShiftData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

/// Данные смены
class ShiftData {
  final int
      shiftState; // 0 - закрыта, 1 - открыта, 2 - истекла (больше 24 часов)
  final String shiftStateName;
  final int shiftNumber;
  final DateTime dateTime;

  ShiftData({
    required this.shiftState,
    required this.shiftStateName,
    required this.shiftNumber,
    required this.dateTime,
  });

  bool get isOpen => shiftState == 1;
  bool get isClosed => shiftState == 0;
  bool get isExpired => shiftState == 2;

  factory ShiftData.fromJson(Map<String, dynamic> json) {
    return ShiftData(
      shiftState: json['shift_state'] ?? json['shiftState'] ?? 0,
      shiftStateName: json['shift_state_name'] ?? json['shiftStateName'] ?? '',
      shiftNumber: json['shift_number'] ?? json['shiftNumber'] ?? 0,
      dateTime: json['date_time'] != null 
          ? DateTime.tryParse(json['date_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shift_state': shiftState,
      'shift_state_name': shiftStateName,
      'shift_number': shiftNumber,
      'date_time': dateTime.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ShiftData(state: $shiftState, name: $shiftStateName, number: $shiftNumber, dateTime: $dateTime)';
  }
}

/// Ответ на открытие/закрытие смены
class ShiftActionResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ShiftActionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ShiftActionResponse.fromJson(Map<String, dynamic> json) {
    return ShiftActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

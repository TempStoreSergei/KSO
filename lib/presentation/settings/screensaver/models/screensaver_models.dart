// ============================================
// lib/presentation/settings/screensaver/models/screensaver_models.dart
// ============================================

/// Модель файла заставки
class ScreensaverFileModel {
  final int id;
  final int order;
  final String fileUrl;
  final bool soundIsEnable;
  final int timeShowImage;
  final String fileType;

  ScreensaverFileModel({
    required this.id,
    required this.order,
    required this.fileUrl,
    required this.soundIsEnable,
    required this.timeShowImage,
    required this.fileType,
  });

  factory ScreensaverFileModel.fromJson(Map<String, dynamic> json) {
    return ScreensaverFileModel(
      id: json['id'] ?? 0,
      order: json['order'] ?? 0,
      fileUrl: json['fileUrl'] ?? '',
      soundIsEnable: json['soundIsEnable'] ?? false,
      timeShowImage: json['timeShowImage'] ?? 200,
      fileType: json['fileType'] ?? '',
    );
  }

  ScreensaverFileModel copyWith({
    int? id,
    int? order,
    String? fileUrl,
    bool? soundIsEnable,
    int? timeShowImage,
    String? fileType,
  }) {
    return ScreensaverFileModel(
      id: id ?? this.id,
      order: order ?? this.order,
      fileUrl: fileUrl ?? this.fileUrl,
      soundIsEnable: soundIsEnable ?? this.soundIsEnable,
      timeShowImage: timeShowImage ?? this.timeShowImage,
      fileType: fileType ?? this.fileType,
    );
  }
}

/// Модель настроек заставки
class ScreensaverSettingsModel {
  final bool isEnable;
  final bool soundIsEnable;
  final int timeShowImage;
  final int idleTime;
  final bool showClock;

  ScreensaverSettingsModel({
    required this.isEnable,
    required this.soundIsEnable,
    required this.timeShowImage,
    required this.idleTime,
    required this.showClock,
  });

  factory ScreensaverSettingsModel.fromJson(Map<String, dynamic> json) {
    return ScreensaverSettingsModel(
      isEnable: json['isEnable'] ?? false,
      soundIsEnable: json['soundIsEnable'] ?? false,
      timeShowImage: json['timeShowImage'] ?? 200,
      idleTime: json['idleTime'] ?? 100,
      showClock: json['showClock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnable': isEnable,
      'soundIsEnable': soundIsEnable,
      'timeShowImage': timeShowImage,
      'idleTime': idleTime,
      'showClock': showClock,
    };
  }

  ScreensaverSettingsModel copyWith({
    bool? isEnable,
    bool? soundIsEnable,
    int? timeShowImage,
    int? idleTime,
    bool? showClock,
  }) {
    return ScreensaverSettingsModel(
      isEnable: isEnable ?? this.isEnable,
      soundIsEnable: soundIsEnable ?? this.soundIsEnable,
      timeShowImage: timeShowImage ?? this.timeShowImage,
      idleTime: idleTime ?? this.idleTime,
      showClock: showClock ?? this.showClock,
    );
  }
}

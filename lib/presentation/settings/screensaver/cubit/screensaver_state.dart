// ============================================
// lib/presentation/settings/screensaver/cubit/screensaver_state.dart
// ============================================

import 'package:motel/presentation/settings/screensaver/models/screensaver_models.dart';

/// Состояние экрана настроек заставки
abstract class ScreensaverState {}

/// Начальное состояние
class ScreensaverInitial extends ScreensaverState {}

/// Загрузка данных
class ScreensaverLoading extends ScreensaverState {}

/// Данные загружены успешно
class ScreensaverLoaded extends ScreensaverState {
  final List<ScreensaverFileModel> files;
  final ScreensaverSettingsModel settings;
  final bool isEditing;

  ScreensaverLoaded({
    required this.files,
    required this.settings,
    this.isEditing = false,
  });

  ScreensaverLoaded copyWith({
    List<ScreensaverFileModel>? files,
    ScreensaverSettingsModel? settings,
    bool? isEditing,
  }) {
    return ScreensaverLoaded(
      files: files ?? this.files,
      settings: settings ?? this.settings,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

/// Ошибка загрузки/сохранения
class ScreensaverError extends ScreensaverState {
  final String message;

  ScreensaverError(this.message);
}

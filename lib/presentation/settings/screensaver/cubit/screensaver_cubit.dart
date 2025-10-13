// ============================================
// lib/presentation/settings/screensaver/cubit/screensaver_cubit.dart
// ============================================

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/settings/screensaver/cubit/screensaver_state.dart';
import 'package:motel/presentation/settings/screensaver/models/screensaver_models.dart';

/// Cubit для управления состоянием настроек заставки
class ScreensaverCubit extends Cubit<ScreensaverState> {
  final ApiClient _apiClient;

  ScreensaverCubit({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance,
        super(ScreensaverInitial());

  /// Загружает данные с сервера
  Future<void> loadData() async {
    emit(ScreensaverLoading());
    try {
      final filesResponse = await _apiClient.get('/screensaver/get_files');
      final filesList = (filesResponse['files'] as List)
          .map((json) => ScreensaverFileModel.fromJson(json))
          .toList();

      // Сортируем по order
      filesList.sort((a, b) => a.order.compareTo(b.order));

      final settingsResponse = await _apiClient.get('/screensaver/get_settings');
      final settings = ScreensaverSettingsModel.fromJson(settingsResponse);

      emit(ScreensaverLoaded(files: filesList, settings: settings));
    } catch (e) {
      emit(ScreensaverError('Ошибка загрузки данных: $e'));
    }
  }

  /// Добавляет новый файл заставки
  Future<void> addFile(XFile pickedFile) async {
    final currentState = state;
    if (currentState is! ScreensaverLoaded) return;

    emit(ScreensaverLoading());
    try {
      final bytes = await pickedFile.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final newOrder = currentState.files.length + 1;

      await _apiClient.post('/screensaver/add_file', body: {
        'order': newOrder,
        'fileBase64': base64String,
        'soundIsEnable': currentState.settings.soundIsEnable,
        'timeShowImage': currentState.settings.timeShowImage,
      });

      await loadData();
    } catch (e) {
      emit(ScreensaverError('Ошибка добавления файла: $e'));
      emit(currentState);
    }
  }

  /// Удаляет файл заставки
  Future<void> deleteFile(int fileId) async {
    final currentState = state;
    if (currentState is! ScreensaverLoaded) return;

    emit(ScreensaverLoading());
    try {
      await _apiClient.delete('/screensaver/delete_file?file_id=$fileId');
      await loadData();
    } catch (e) {
      emit(ScreensaverError('Ошибка удаления файла: $e'));
      emit(currentState);
    }
  }

  /// Сохраняет новый порядок файлов
  Future<void> saveOrder(List<ScreensaverFileModel> reorderedFiles) async {
    final currentState = state;
    if (currentState is! ScreensaverLoaded) return;

    emit(ScreensaverLoading());
    try {
      for (int i = 0; i < reorderedFiles.length; i++) {
        final file = reorderedFiles[i];
        await _apiClient.put('/screensaver/update_file', body: {
          'id': file.id,
          'order': i + 1,
          'soundIsEnable': file.soundIsEnable,
          'timeShowImage': file.timeShowImage,
        });
      }

      await loadData();
    } catch (e) {
      emit(ScreensaverError('Ошибка сохранения порядка: $e'));
      emit(currentState);
    }
  }

  /// Обновляет глобальные настройки заставки
  Future<void> updateSettings(ScreensaverSettingsModel newSettings) async {
    final currentState = state;
    if (currentState is! ScreensaverLoaded) return;

    emit(ScreensaverLoading());
    try {
      await _apiClient.put('/screensaver/update_settings', body: newSettings.toJson());
      await loadData();
    } catch (e) {
      emit(ScreensaverError('Ошибка обновления настроек: $e'));
      emit(currentState);
    }
  }

  /// Обновляет настройки конкретного файла
  Future<void> updateFileSettings(
    ScreensaverFileModel file, {
    bool? soundIsEnable,
    int? timeShowImage,
  }) async {
    final currentState = state;
    if (currentState is! ScreensaverLoaded) return;

    emit(ScreensaverLoading());
    try {
      await _apiClient.put('/screensaver/update_file', body: {
        'id': file.id,
        'order': file.order,
        'fileBase64': '',
        'soundIsEnable': soundIsEnable ?? file.soundIsEnable,
        'timeShowImage': timeShowImage ?? file.timeShowImage,
      });
      await loadData();
    } catch (e) {
      emit(ScreensaverError('Ошибка обновления файла: $e'));
      emit(currentState);
    }
  }

  /// Переключает режим редактирования
  void toggleEditMode() {
    final currentState = state;
    if (currentState is ScreensaverLoaded) {
      emit(currentState.copyWith(isEditing: !currentState.isEditing));
    }
  }

  /// Обновляет список файлов (для reorder)
  void updateFilesList(List<ScreensaverFileModel> newFiles) {
    final currentState = state;
    if (currentState is ScreensaverLoaded) {
      emit(currentState.copyWith(files: newFiles));
    }
  }
}

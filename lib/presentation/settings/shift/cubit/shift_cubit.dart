// lib/presentation/settings/shift/cubit/shift_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_state.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ApiClient _apiClient;

  ShiftCubit(this._apiClient) : super(ShiftInitial());

  Future<void> loadSettings() async {
    emit(ShiftLoading());
    try {
      final response = await _apiClient.get('/shifts/get_shift_status');
      final settings = ShiftSettings.fromJson(response);
      emit(ShiftLoaded(settings));
    } on FetchDataException catch (e) {
      emit(ShiftError('Ошибка сети: ${e.toString()}'));
    } on BadRequestException catch (e) {
      emit(ShiftError('Неверный запрос: ${e.toString()}'));
    } on UnauthorisedException catch (e) {
      emit(ShiftError('Ошибка авторизации: ${e.toString()}'));
    } catch (e) {
      emit(ShiftError('Ошибка загрузки настроек: ${e.toString()}'));
    }
  }

  Future<void> toggleAutoShifts(bool enabled, ShiftSettings currentSettings) async {
    // Если включаем автосмены, проверяем валидность времени
    if (enabled && !_validateShiftTimes(currentSettings.autoShiftsTimeToOpen, currentSettings.autoShiftsTimeToClose)) {
      return; // Не включаем автосмены при невалидном времени
    }

    emit(ShiftUpdating(currentSettings));
    try {
      await _apiClient.put(
        '/settings/activate_or_deactivate_auto_shifts_by_time',
        body: {'autoShiftsIsEnable': enabled},
      );
      final updatedSettings = currentSettings.copyWith(autoShiftsIsEnable: enabled);
      emit(ShiftLoaded(updatedSettings));
    } on FetchDataException catch (e) {
      emit(ShiftError('Ошибка сети: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    } on BadRequestException catch (e) {
      emit(ShiftError('Неверный запрос: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    } on UnauthorisedException catch (e) {
      emit(ShiftError('Ошибка авторизации: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    } catch (e) {
      emit(ShiftError('Ошибка сохранения: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    }
  }

  Future<void> updateShiftTimes(String openTime, String closeTime, ShiftSettings currentSettings) async {
    // Валидируем время перед отправкой на сервер
    if (!_validateShiftTimes(openTime, closeTime)) {
      return;
    }

    emit(ShiftUpdating(currentSettings));
    try {
      await _apiClient.put(
        '/settings/update_time_auto_shifts',
        body: {
          'autoShiftsTimeToOpen': openTime,
          'autoShiftsTimeToClose': closeTime,
        },
      );
      final updatedSettings = currentSettings.copyWith(
        autoShiftsTimeToOpen: openTime,
        autoShiftsTimeToClose: closeTime,
      );
      emit(ShiftLoaded(updatedSettings));
    } on FetchDataException catch (e) {
      emit(ShiftError('Ошибка сети: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    } on BadRequestException catch (e) {
      emit(ShiftError('Неверный запрос: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    } on UnauthorisedException catch (e) {
      emit(ShiftError('Ошибка авторизации: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    } catch (e) {
      emit(ShiftError('Ошибка обновления времени: ${e.toString()}'));
      emit(ShiftLoaded(currentSettings));
    }
  }

  Future<void> openShift() async {
    final currentState = state;
    if (currentState is! ShiftLoaded) return;

    emit(ShiftUpdating(currentState.settings));
    try {
      await _apiClient.get('/shifts/open_shift');
      await loadSettings(); // Обновляем все данные
    } on FetchDataException catch (e) {
      emit(ShiftError('Ошибка сети: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    } on BadRequestException catch (e) {
      emit(ShiftError('Неверный запрос: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    } on UnauthorisedException catch (e) {
      emit(ShiftError('Ошибка авторизации: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    } catch (e) {
      emit(ShiftError('Ошибка открытия смены: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    }
  }

  Future<void> closeShift() async {
    final currentState = state;
    if (currentState is! ShiftLoaded) return;

    emit(ShiftUpdating(currentState.settings));
    try {
      await _apiClient.get('/shifts/close_shift');
      await loadSettings(); // Обновляем все данные
    } on FetchDataException catch (e) {
      emit(ShiftError('Ошибка сети: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    } on BadRequestException catch (e) {
      emit(ShiftError('Неверный запрос: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    } on UnauthorisedException catch (e) {
      emit(ShiftError('Ошибка авторизации: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    } catch (e) {
      emit(ShiftError('Ошибка закрытия смены: ${e.toString()}'));
      emit(ShiftLoaded(currentState.settings));
    }
  }

  bool _validateShiftTimes(String openTime, String closeTime) {
    try {
      final openTimeParts = openTime.split(':');
      final closeTimeParts = closeTime.split(':');

      final openHour = int.parse(openTimeParts[0]);
      final openMinute = int.parse(openTimeParts[1]);
      final closeHour = int.parse(closeTimeParts[0]);
      final closeMinute = int.parse(closeTimeParts[1]);

      final openTotalMinutes = openHour * 60 + openMinute;
      final closeTotalMinutes = closeHour * 60 + closeMinute;

      // Проверяем, что время закрытия больше времени открытия
      if (closeTotalMinutes <= openTotalMinutes) {
        final currentState = state;
        if (currentState is ShiftLoaded) {
          emit(ShiftValidationError(
            'Время закрытия должно быть позже времени открытия',
            currentState.settings,
          ));
        }
        return false;
      }

      // Проверяем минимальную длительность смены (1 час = 60 минут)
      final shiftDurationMinutes = closeTotalMinutes - openTotalMinutes;
      if (shiftDurationMinutes < 60) {
        final currentState = state;
        if (currentState is ShiftLoaded) {
          emit(ShiftValidationError(
            'Минимальная продолжительность смены — 1 час',
            currentState.settings,
          ));
        }
        return false;
      }

      return true;
    } catch (e) {
      final currentState = state;
      if (currentState is ShiftLoaded) {
        emit(ShiftValidationError(
          'Неверный формат времени',
          currentState.settings,
        ));
      }
      return false;
    }
  }

  void updateLocalTime(String openTime, String closeTime, ShiftSettings currentSettings) {
    final updatedSettings = currentSettings.copyWith(
      autoShiftsTimeToOpen: openTime,
      autoShiftsTimeToClose: closeTime,
    );
    emit(ShiftLoaded(updatedSettings));
  }
}

// lib/presentation/settings/shift/cubit/shift_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_exceptions.dart';
import 'package:motel/domain/models/shift_automation_settings.dart';
import 'package:motel/domain/usecases/shift/manage_shift_usecase.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_state.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ManageShiftUseCase _manageShiftUseCase;

  ShiftCubit(this._manageShiftUseCase) : super(ShiftInitial());

  Future<void> loadSettings() async {
    emit(ShiftLoading());
    try {
      emit(ShiftLoaded(await _loadShiftSettings()));
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

  Future<ShiftSettings> _loadShiftSettings() async {
    final automation = await _manageShiftUseCase.getAutomationSettings();
    final shiftStatus = await _manageShiftUseCase.getStatus();

    if (!shiftStatus.success || shiftStatus.data == null) {
      throw Exception(shiftStatus.message);
    }

    return ShiftSettings.fromAutomation(
      automation: automation,
      shiftIsOpened: shiftStatus.data!.isOpen,
      shiftData: shiftStatus.data,
    );
  }

  ShiftSettings? _settingsFromState() {
    final currentState = state;
    if (currentState is ShiftLoaded) return currentState.settings;
    if (currentState is ShiftUpdating) return currentState.settings;
    if (currentState is ShiftValidationError) return currentState.settings;
    return null;
  }

  Future<void> updateOpenMode(ShiftOpenMode mode) async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    final nextMode =
        mode == ShiftOpenMode.disabled ? ShiftOpenMode.firstReceipt : mode;
    final nextSettings = currentSettings.copyWith(
      openMode: nextMode,
      autoShiftsTimeToOpen: nextMode == ShiftOpenMode.byTime
          ? currentSettings.autoShiftsTimeToOpen ?? '08:00'
          : null,
      clearAutoShiftsTimeToOpen: nextMode != ShiftOpenMode.byTime,
    );
    await _saveAutomationSettings(nextSettings);
  }

  Future<void> updateOpenTime(String time) async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    await _saveAutomationSettings(
      currentSettings.copyWith(
        openMode: ShiftOpenMode.byTime,
        autoShiftsTimeToOpen: time,
      ),
    );
  }

  Future<void> updateCloseTime(String time) async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    await _saveAutomationSettings(
      currentSettings.copyWith(autoShiftsTimeToClose: time),
    );
  }

  Future<void> disableAutoClose() async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    await _saveAutomationSettings(
      currentSettings.copyWith(clearAutoShiftsTimeToClose: true),
    );
  }

  Future<void> toggleAcquiringReceiptReportOnClose(bool value) async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    await _saveAutomationSettings(
      currentSettings.copyWith(acquiringReceiptReportOnClose: value),
    );
  }

  Future<void> _saveAutomationSettings(ShiftSettings settings) async {
    emit(ShiftUpdating(settings));
    try {
      await _manageShiftUseCase.saveAutomationSettings(
        settings.automationSettings,
      );
      emit(ShiftLoaded(await _loadShiftSettings()));
    } catch (e) {
      emit(
        ShiftValidationError(
          'Не удалось сохранить настройки смены на сервере: ${e.toString()}',
          settings,
        ),
      );
    }
  }

  Future<void> openShift() async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    emit(ShiftUpdating(currentSettings));
    try {
      final result = await _manageShiftUseCase.openShift();

      if (!result.success) {
        emit(ShiftValidationError(result.message, currentSettings));
        return;
      }

      final updatedSettings = await _loadShiftSettings();
      emit(ShiftLoaded(updatedSettings));
    } on FetchDataException catch (e) {
      emit(ShiftValidationError(
          'Ошибка сети: ${e.toString()}', currentSettings));
    } on BadRequestException catch (e) {
      emit(ShiftValidationError(
          'Неверный запрос: ${e.toString()}', currentSettings));
    } on UnauthorisedException catch (e) {
      emit(ShiftValidationError(
          'Ошибка авторизации: ${e.toString()}', currentSettings));
    } catch (e) {
      emit(ShiftValidationError(
          'Ошибка открытия смены: ${e.toString()}', currentSettings));
    }
  }

  Future<void> closeShift() async {
    final currentSettings = _settingsFromState();
    if (currentSettings == null) return;

    emit(ShiftUpdating(currentSettings));
    try {
      final result = await _manageShiftUseCase.closeShift(
        includeAcquiringReceiptReport:
            currentSettings.acquiringReceiptReportOnClose,
      );

      if (!result.success) {
        emit(ShiftValidationError(result.message, currentSettings));
        return;
      }

      final updatedSettings = await _loadShiftSettings();
      emit(ShiftLoaded(updatedSettings));
    } on FetchDataException catch (e) {
      emit(ShiftValidationError(
          'Ошибка сети: ${e.toString()}', currentSettings));
    } on BadRequestException catch (e) {
      emit(ShiftValidationError(
          'Неверный запрос: ${e.toString()}', currentSettings));
    } on UnauthorisedException catch (e) {
      emit(ShiftValidationError(
          'Ошибка авторизации: ${e.toString()}', currentSettings));
    } catch (e) {
      emit(ShiftValidationError(
          'Ошибка закрытия смены: ${e.toString()}', currentSettings));
    }
  }


}

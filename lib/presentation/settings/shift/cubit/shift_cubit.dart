// lib/presentation/settings/shift/cubit/shift_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';
import 'package:motel/core/services/shift_service.dart';
import 'package:motel/presentation/settings/shift/cubit/shift_state.dart';
import 'package:motel/presentation/settings/shift/models/shift_settings.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftService _shiftService = ShiftService.instance;

  ShiftCubit(ApiClient apiClient) : super(ShiftInitial());

  Future<void> loadSettings() async {
    emit(ShiftLoading());
    try {
      // Используем новый ShiftService для получения статуса
      final shiftStatus = await _shiftService.getShiftStatus();

      if (!shiftStatus.success || shiftStatus.data == null) {
        emit(ShiftError(shiftStatus.message));
        return;
      }

      // Преобразуем в ShiftSettings с полными данными ShiftData
      final settings = ShiftSettings(
        autoShiftsIsEnable: false, // TODO: получать из настроек если нужно
        autoShiftsTimeToOpen: '08:00',
        autoShiftsTimeToClose: '23:55',
        shiftIsOpened: shiftStatus.data!.isOpen,
        shiftData: shiftStatus.data, // Передаем полные данные смены
      );

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

  // Методы toggleAutoShifts и updateShiftTimes удалены, так как этих API нет

  Future<void> openShift() async {
    final currentState = state;
    if (currentState is! ShiftLoaded) return;

    emit(ShiftUpdating(currentState.settings));
    try {
      // Используем ShiftService для открытия смены
      final result = await _shiftService.openShift();

      if (!result.success) {
        emit(ShiftError(result.message));
        emit(ShiftLoaded(currentState.settings));
        return;
      }

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
      // Используем ShiftService для закрытия смены
      final result = await _shiftService.closeShift();

      if (!result.success) {
        emit(ShiftError(result.message));
        emit(ShiftLoaded(currentState.settings));
        return;
      }

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

}

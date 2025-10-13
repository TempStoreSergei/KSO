import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import '../models/bill_dispenser_status.dart';
import '../models/test_status.dart';
import 'bill_dispenser_state.dart';

class BillDispenserCubit extends Cubit<BillDispenserState> {
  final ApiClient _apiClient;

  BillDispenserCubit(this._apiClient) : super(BillDispenserInitial());

  Future<void> loadStatus() async {
    emit(BillDispenserLoading());
    try {
      final response = await _apiClient.get('/cash_system/bill_dispenser/status');
      final status = BillDispenserStatus.fromJson(response);

      emit(BillDispenserLoaded(
        status: status,
        newUpperBoxCount: status.upperBoxCount,
        newLowerBoxCount: status.lowerBoxCount,
        newUpperBoxValue: status.upperBoxValue ~/ 100,
        newLowerBoxValue: status.lowerBoxValue ~/ 100,
      ));
    } catch (e) {
      emit(BillDispenserError('Ошибка загрузки данных: ${e.toString()}'));
    }
  }

  void updateNewUpperBoxCount(int count) {
    if (state is BillDispenserLoaded) {
      final currentState = state as BillDispenserLoaded;
      emit(currentState.copyWith(newUpperBoxCount: count));
    }
  }

  void updateNewLowerBoxCount(int count) {
    if (state is BillDispenserLoaded) {
      final currentState = state as BillDispenserLoaded;
      emit(currentState.copyWith(newLowerBoxCount: count));
    }
  }

  void updateNewUpperBoxValue(int value) {
    if (state is BillDispenserLoaded) {
      final currentState = state as BillDispenserLoaded;
      emit(currentState.copyWith(newUpperBoxValue: value));
    }
  }

  void updateNewLowerBoxValue(int value) {
    if (state is BillDispenserLoaded) {
      final currentState = state as BillDispenserLoaded;
      emit(currentState.copyWith(newLowerBoxValue: value));
    }
  }

  Future<void> updateCount() async {
    if (state is! BillDispenserLoaded) return;

    final currentState = state as BillDispenserLoaded;
    try {
      // Отправляем только количество добавляемых купюр, а не общее количество
      final addUpperCount = currentState.newUpperBoxCount - currentState.status.upperBoxCount;
      final addLowerCount = currentState.newLowerBoxCount - currentState.status.lowerBoxCount;

      await _apiClient.post(
        '/cash_system/bill_dispenser/add_bill_count',
        body: {
          'upperCount': addUpperCount,
          'lowerCount': addLowerCount,
        },
      );

      // Перезагружаем данные
      await loadStatus();

      // Показываем сообщение об успехе
      if (state is BillDispenserLoaded) {
        final newState = state as BillDispenserLoaded;
        emit(BillDispenserSuccess(
          message: 'Количество купюр обновлено',
          status: newState.status,
          newUpperBoxCount: newState.newUpperBoxCount,
          newLowerBoxCount: newState.newLowerBoxCount,
          newUpperBoxValue: newState.newUpperBoxValue,
          newLowerBoxValue: newState.newLowerBoxValue,
        ));
        // Возвращаем loaded state
        emit(newState);
      }
    } catch (e) {
      emit(BillDispenserError('Ошибка обновления количества: ${e.toString()}'));
      // Возвращаем loaded state
      emit(currentState);
    }
  }

  Future<void> updateLevels() async {
    if (state is! BillDispenserLoaded) return;

    final currentState = state as BillDispenserLoaded;
    try {
      await _apiClient.post(
        '/cash_system/bill_dispenser/set_nominal',
        body: {
          'upperLvl': currentState.newUpperBoxValue * 100,
          'lowerLvl': currentState.newLowerBoxValue * 100,
        },
      );

      // Перезагружаем данные
      await loadStatus();

      // Показываем сообщение об успехе
      if (state is BillDispenserLoaded) {
        final newState = state as BillDispenserLoaded;
        emit(BillDispenserSuccess(
          message: 'Номиналы обновлены',
          status: newState.status,
          newUpperBoxCount: newState.newUpperBoxCount,
          newLowerBoxCount: newState.newLowerBoxCount,
          newUpperBoxValue: newState.newUpperBoxValue,
          newLowerBoxValue: newState.newLowerBoxValue,
        ));
        // Возвращаем loaded state
        emit(newState);
      }
    } catch (e) {
      emit(BillDispenserError('Ошибка обновления номиналов: ${e.toString()}'));
      // Возвращаем loaded state
      emit(currentState);
    }
  }

  Future<void> testDispenser() async {
    if (state is! BillDispenserLoaded) return;

    final currentState = state as BillDispenserLoaded;

    // Проверяем наличие купюр
    if (currentState.status.upperBoxCount < 1 || currentState.status.lowerBoxCount < 1) {
      emit(const BillDispenserError('Недостаточно купюр в диспенсере для теста.\nТребуется минимум 1 купюра в каждом боксе.'));
      emit(currentState);
      return;
    }

    // Анимация смены статусов
    emit(currentState.copyWith(testStatus: TestStatus.upperBox));
    await Future.delayed(const Duration(seconds: 20));

    emit(currentState.copyWith(testStatus: TestStatus.lowerBox));
    await Future.delayed(const Duration(seconds: 2));

    emit(currentState.copyWith(testStatus: TestStatus.complete));
    await Future.delayed(const Duration(seconds: 2));

    try {
      await _apiClient.post(
        '/cash_system/bill_dispenser/test_bill_dispenser',
        body: {
          'upperLvl': true,
          'upperLvlAmount': 1,
          'lowerLvl': true,
          'lowerLvlAmount': 1,
        },
      );

      // Перезагружаем данные
      await loadStatus();

      // Показываем сообщение об успехе
      if (state is BillDispenserLoaded) {
        final newState = state as BillDispenserLoaded;
        emit(BillDispenserSuccess(
          message: 'Тест выдачи завершен.\nВыдано: 1 купюра из верхнего бокса и 1 из нижнего.',
          status: newState.status,
          newUpperBoxCount: newState.newUpperBoxCount,
          newLowerBoxCount: newState.newLowerBoxCount,
          newUpperBoxValue: newState.newUpperBoxValue,
          newLowerBoxValue: newState.newLowerBoxValue,
        ));
        // Возвращаем loaded state
        emit(newState);
      }
    } catch (e) {
      emit(BillDispenserError('Ошибка запуска теста: ${e.toString()}'));
      // Возвращаем loaded state с inactive статусом
      emit(currentState.copyWith(testStatus: TestStatus.inactive));
    }
  }

  Future<void> resetCount() async {
    if (state is! BillDispenserLoaded) return;

    final currentState = state as BillDispenserLoaded;
    try {
      await _apiClient.get('/cash_system/bill_dispenser/reset_bill_count');

      // Перезагружаем данные
      await loadStatus();

      // Показываем сообщение об успехе
      if (state is BillDispenserLoaded) {
        final newState = state as BillDispenserLoaded;
        emit(BillDispenserSuccess(
          message: 'Инкассация выполнена',
          status: newState.status,
          newUpperBoxCount: newState.newUpperBoxCount,
          newLowerBoxCount: newState.newLowerBoxCount,
          newUpperBoxValue: newState.newUpperBoxValue,
          newLowerBoxValue: newState.newLowerBoxValue,
        ));
        // Возвращаем loaded state
        emit(newState);
      }
    } catch (e) {
      emit(BillDispenserError('Ошибка сброса: ${e.toString()}'));
      // Возвращаем loaded state
      emit(currentState);
    }
  }
}

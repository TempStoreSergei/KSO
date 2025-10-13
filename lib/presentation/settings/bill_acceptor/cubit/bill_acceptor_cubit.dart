// ============================================
// lib/presentation/settings/bill_acceptor/cubit/bill_acceptor_cubit.dart
// ============================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/api/api_exceptions.dart';
import 'package:motel/core/services/websocket_service.dart';
import 'package:motel/presentation/settings/bill_acceptor/cubit/bill_acceptor_state.dart';
import 'package:motel/presentation/settings/bill_acceptor/models/bill_acceptor_models.dart';

/// Cubit для управления состоянием настроек купюроприемника
class BillAcceptorCubit extends Cubit<BillAcceptorState> {
  final ApiClient _apiClient;
  final WebSocketService _wsService;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  BillAcceptorCubit({
    ApiClient? apiClient,
    WebSocketService? wsService,
  })  : _apiClient = apiClient ?? ApiClient.instance,
        _wsService = wsService ?? WebSocketService(),
        super(BillAcceptorInitial());

  /// Загружает данные с сервера
  Future<void> loadData() async {
    emit(BillAcceptorLoading());
    try {
      final response = await _apiClient.get('/cash_system/bill_acceptor/status');
      final status = CashSystemStatus.fromJson(response);

      emit(BillAcceptorLoaded(
        status: status,
        customMaxCount: status.maxBillCount,
      ));
    } catch (e) {
      emit(BillAcceptorError('Ошибка загрузки данных: ${e.toString()}'));
    }
  }

  /// Обновляет максимальное количество купюр
  Future<void> updateMaxCount(int value) async {
    final currentState = state;
    if (currentState is! BillAcceptorLoaded) return;

    if (value <= 0) {
      emit(BillAcceptorError(
        'Значение должно быть больше 0',
        previousState: currentState,
      ));
      return;
    }

    try {
      await _apiClient.get(
        '/cash_system/bill_acceptor/set_max_bill_count',
        params: {'value': value},
      );
      emit(currentState.copyWith(status: currentState.status.copyWith(maxBillCount: value)));
    } catch (e) {
      emit(BillAcceptorError(
        'Ошибка обновления лимита: ${e.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Сбрасывает счетчик купюр (инкассация)
  Future<void> resetCount() async {
    final currentState = state;
    if (currentState is! BillAcceptorLoaded) return;

    emit(BillAcceptorLoading());
    try {
      await _apiClient.get('/cash_system/bill_acceptor/reset_bill_count');
      await loadData();
    } catch (e) {
      emit(BillAcceptorError(
        'Ошибка инкассации: ${e.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Запускает тест приема купюр
  Future<void> startTest(int amount) async {
    final currentState = state;
    if (currentState is! BillAcceptorLoaded) return;

    emit(BillAcceptorLoading());
    try {
      await _apiClient.post(
        '/cash_system/bill_acceptor/test_bill_accept',
        body: {'amount': amount * 100},
      );

      // Подключаемся к WebSocket
      await Future.delayed(const Duration(milliseconds: 500));
      await _wsService.connect();

      // Подписываемся на сообщения
      _messageSubscription?.cancel();
      _messageSubscription = _wsService.messageStream.listen(_handleWebSocketMessage);

      emit(currentState.copyWith(
        testingStatus: TestingStatus.active,
        collectedAmount: 0,
        events: [
          TestEvent(
            type: 'info',
            data: {'message': 'Тест запущен на сумму $amount руб.'},
            timestamp: DateTime.now(),
          ),
        ],
      ));
    } on BadRequestException {
      emit(BillAcceptorError(
        'INKASSATION_REQUIRED',
        previousState: currentState,
      ));
    } catch (e) {
      emit(BillAcceptorError(
        'Ошибка запуска теста: ${e.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Останавливает тест приема купюр
  Future<void> stopTest() async {
    final currentState = state;
    if (currentState is! BillAcceptorLoaded) return;

    try {
      await _apiClient.get('/cash_system/stop_accepting_payment');

      _wsService.disconnect();
      _messageSubscription?.cancel();

      final updatedEvents = List<TestEvent>.from(currentState.events)
        ..insert(
          0,
          TestEvent(
            type: 'info',
            data: {'message': 'Тест остановлен'},
            timestamp: DateTime.now(),
          ),
        );

      emit(currentState.copyWith(
        testingStatus: TestingStatus.inactive,
        events: updatedEvents,
      ));
    } catch (e) {
      emit(BillAcceptorError(
        'Ошибка остановки теста: ${e.toString()}',
        previousState: currentState,
      ));
    }
  }

  /// Обрабатывает сообщения WebSocket
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    try {
      final currentState = state;
      if (currentState is! BillAcceptorLoaded) return;

      final eventType = message['event'];
      final eventData = message['data'];

      if (eventType == 'acceptedBill') {
        final billValue = eventData['bill_value'];
        final collectedAmount = eventData['collected_amount'];

        final updatedEvents = List<TestEvent>.from(currentState.events)
          ..insert(
            0,
            TestEvent(
              type: 'acceptedBill',
              data: {
                'bill_value': billValue ~/ 100,
                'collected_amount': collectedAmount ~/ 100,
              },
              timestamp: DateTime.now(),
            ),
          );

        // Ограничиваем список событий до 30 элементов
        if (updatedEvents.length > 30) {
          updatedEvents.removeRange(30, updatedEvents.length);
        }

        emit(currentState.copyWith(
          collectedAmount: collectedAmount ~/ 100,
          events: updatedEvents,
        ));
      } else if (eventType == 'successPayment') {
        final collectedAmount = eventData['collected_amount'];
        final change = eventData['change'];

        final updatedEvents = List<TestEvent>.from(currentState.events)
          ..insert(
            0,
            TestEvent(
              type: 'successPayment',
              data: {
                'collected_amount': collectedAmount ~/ 100,
                'change': change ~/ 100,
              },
              timestamp: DateTime.now(),
            ),
          );

        emit(currentState.copyWith(
          collectedAmount: collectedAmount ~/ 100,
          testingStatus: TestingStatus.completed,
          events: updatedEvents,
        ));

        _wsService.disconnect();
        _messageSubscription?.cancel();

        // Автоматически возвращаемся в inactive через 3 секунды
        Future.delayed(const Duration(seconds: 3), () {
          final state = this.state;
          if (state is BillAcceptorLoaded && state.testingStatus == TestingStatus.completed) {
            emit(state.copyWith(testingStatus: TestingStatus.inactive));
          }
        });
      }
    } catch (e) {
      // Handler error - silently ignore
    }
  }

  /// Обновляет пользовательский лимит (локально)
  void updateCustomMaxCount(int value) {
    final currentState = state;
    if (currentState is BillAcceptorLoaded) {
      emit(currentState.copyWith(customMaxCount: value));
    }
  }

  /// Обновляет сумму для теста (локально)
  void updateTestAmount(int amount) {
    final currentState = state;
    if (currentState is BillAcceptorLoaded) {
      emit(currentState.copyWith(testAmount: amount));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}

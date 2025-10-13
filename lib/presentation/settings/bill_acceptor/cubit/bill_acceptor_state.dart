// ============================================
// lib/presentation/settings/bill_acceptor/cubit/bill_acceptor_state.dart
// ============================================

import 'package:motel/presentation/settings/bill_acceptor/models/bill_acceptor_models.dart';

/// Состояние экрана настроек купюроприемника
abstract class BillAcceptorState {}

/// Начальное состояние
class BillAcceptorInitial extends BillAcceptorState {}

/// Загрузка данных
class BillAcceptorLoading extends BillAcceptorState {}

/// Данные загружены успешно
class BillAcceptorLoaded extends BillAcceptorState {
  final CashSystemStatus status;
  final int customMaxCount;
  final int testAmount;
  final TestingStatus testingStatus;
  final int collectedAmount;
  final List<TestEvent> events;

  BillAcceptorLoaded({
    required this.status,
    required this.customMaxCount,
    this.testAmount = 100,
    this.testingStatus = TestingStatus.inactive,
    this.collectedAmount = 0,
    this.events = const [],
  });

  BillAcceptorLoaded copyWith({
    CashSystemStatus? status,
    int? customMaxCount,
    int? testAmount,
    TestingStatus? testingStatus,
    int? collectedAmount,
    List<TestEvent>? events,
  }) {
    return BillAcceptorLoaded(
      status: status ?? this.status,
      customMaxCount: customMaxCount ?? this.customMaxCount,
      testAmount: testAmount ?? this.testAmount,
      testingStatus: testingStatus ?? this.testingStatus,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      events: events ?? this.events,
    );
  }
}

/// Ошибка загрузки/сохранения
class BillAcceptorError extends BillAcceptorState {
  final String message;
  final BillAcceptorLoaded? previousState;

  BillAcceptorError(this.message, {this.previousState});
}

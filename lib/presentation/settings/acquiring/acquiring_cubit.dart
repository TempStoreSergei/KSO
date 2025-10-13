// ============================================
// lib/presentation/settings/acquiring/acquiring_cubit.dart
// ============================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_models.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_use_cases.dart';

/// Cubit для управления состоянием эквайринга
class AcquiringCubit extends Cubit<AcquiringConnectionState> {
  final AcquiringUseCases _useCases;

  AcquiringCubit(this._useCases) : super(AcquiringConnectionState());

  /// Проверить подключение к терминалу
  Future<void> checkConnection() async {
    emit(state.copyWith(isChecking: true, connectionMethod: ''));

    try {
      final response = await _useCases.checkConnection();
      emit(state.copyWith(
        isConnected: response.status,
        connectionMethod: response.detail,
        isChecking: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isConnected: false,
        connectionMethod: 'Ошибка подключения',
        isChecking: false,
      ));
    }
  }

  /// Выполнить действие с терминалом
  Future<AcquiringResponse> executeAction(Future<AcquiringResponse> Function() action) async {
    return await action();
  }
}

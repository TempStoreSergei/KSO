import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'metrics_state.dart';

class MetricsCubit extends Cubit<MetricsState> {
  final ApiClient _apiClient;

  MetricsCubit(this._apiClient) : super(MetricsInitial());

  Future<void> loadMetrics() async {
    try {
      emit(MetricsLoading());
      final metrics = await _apiClient.getMetrics();
      emit(MetricsLoaded(metrics));
    } catch (e) {
      emit(MetricsError(e.toString()));
    }
  }
}

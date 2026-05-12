// ============================================
// lib/domain/usecases/delete_service.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/diagnostic_logger.dart';

class DeleteServiceUseCase {
  final ApiClient _apiClient;

  DeleteServiceUseCase(this._apiClient);

  /// Удалить услугу по ID
  Future<void> execute(int serviceId) async {
    try {
      DiagnosticLogger.info('services', 'delete_started', data: {'serviceId': serviceId});

      await _apiClient.delete('/services/$serviceId');

      DiagnosticLogger.info('services', 'delete_succeeded', data: {'serviceId': serviceId});
    } catch (e) {
      DiagnosticLogger.info('services', 'delete_failed', data: {'serviceId': serviceId, 'error': e.toString()});
      throw Exception('Ошибка при удалении услуги: $e');
    }
  }
}

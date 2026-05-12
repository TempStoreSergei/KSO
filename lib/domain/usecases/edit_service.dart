// ============================================
// lib/domain/usecases/edit_service.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:motel/domain/entities/api_service.dart';

class EditServiceUseCase {
  final ApiClient _apiClient;

  EditServiceUseCase(this._apiClient);

  /// Редактировать существующую услугу
  Future<ApiService> execute({
    required int serviceId,
    required String name,
    required int price,
    required int tax,
  }) async {
    try {
      DiagnosticLogger.info('services', 'edit_started', data: {'serviceId': serviceId});

      final response = await _apiClient.put(
        '/services/$serviceId',
        body: {
          'name': name,
          'price': price,
          'tax': tax,
        },
      );

      DiagnosticLogger.info('services', 'edit_succeeded', data: {'serviceId': serviceId});
      return ApiService.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      DiagnosticLogger.info('services', 'edit_failed', data: {'serviceId': serviceId, 'error': e.toString()});
      throw Exception('Ошибка при редактировании услуги: $e');
    }
  }
}

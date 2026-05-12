// ============================================
// lib/domain/usecases/add_service.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:motel/domain/entities/api_service.dart';

class AddServiceUseCase {
  final ApiClient _apiClient;

  AddServiceUseCase(this._apiClient);

  /// Добавить новую услугу
  Future<ApiService> execute({
    required String name,
    required int price,
    required int tax,
  }) async {
    try {
      DiagnosticLogger.info('services', 'create_started', data: {'name': name, 'price': price, 'tax': tax});

      final response = await _apiClient.post(
        '/services',
        body: {
          'name': name,
          'price': price * 100,
          'tax': tax,
        },
      );

      DiagnosticLogger.info('services', 'create_succeeded', data: {'name': name});
      return ApiService.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      DiagnosticLogger.info('services', 'create_failed', data: {'name': name, 'error': e.toString()});
      throw Exception('Ошибка при создании услуги: $e');
    }
  }
}

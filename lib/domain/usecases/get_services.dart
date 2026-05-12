// ============================================
// lib/domain/usecases/get_services.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:motel/domain/entities/api_service.dart';

class GetServices {
  final ApiClient _apiClient;

  GetServices(this._apiClient);

  Future<List<ApiService>> call() async {
    try {
      DiagnosticLogger.info('services', 'get_started');

      // === ИСПРАВЛЕНИЕ: 'responseData' теперь является Map<String, dynamic>, а не Response ===
      final responseData = await _apiClient.get('/services/get_services');

      // Мы предполагаем, что если запрос не удался (статус не 200), ApiClient выбросит исключение.
      // Поэтому проверка 'if (response.statusCode == 200)' здесь не нужна и является ошибкой.

      // Извлекаем список напрямую из полученной Map.
      final List<dynamic> servicesJson = responseData['services'];

      // Преобразуем каждый JSON-объект в наш класс ApiService
      final List<ApiService> services = servicesJson.map((json) => ApiService.fromJson(json)).toList();

      DiagnosticLogger.info('services', 'get_succeeded', data: {'count': services.length});
      return services;

    } catch (e) {
      DiagnosticLogger.info('services', 'get_failed', data: {'error': e.toString()});
      // Перебрасываем исключение, чтобы FutureBuilder мог его поймать и показать ошибку
      throw Exception('Не удалось загрузить сервисы из-за ошибки: $e');
    }
  }
}

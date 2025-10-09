// ============================================
// lib/domain/usecases/get_services.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/entities/api_service.dart';

class GetServices {
  final ApiClient _apiClient;

  GetServices(this._apiClient);

  Future<List<ApiService>> call() async {
    try {
      print("[GetServices] Выполняю запрос на /guests/get_services...");

      // === ИСПРАВЛЕНИЕ: 'responseData' теперь является Map<String, dynamic>, а не Response ===
      final responseData = await _apiClient.get('/guests/get_services');

      // Мы предполагаем, что если запрос не удался (статус не 200), ApiClient выбросит исключение.
      // Поэтому проверка 'if (response.statusCode == 200)' здесь не нужна и является ошибкой.

      // Извлекаем список напрямую из полученной Map.
      final List<dynamic> servicesJson = responseData['services'];

      // Преобразуем каждый JSON-объект в наш класс ApiService
      final List<ApiService> services = servicesJson.map((json) => ApiService.fromJson(json)).toList();

      print("[GetServices] Успешно загружено и распарсено ${services.length} сервисов.");
      return services;

    } catch (e) {
      print("[GetServices] КРИТИЧЕСКАЯ ОШИБКА: $e");
      // Перебрасываем исключение, чтобы FutureBuilder мог его поймать и показать ошибку
      throw Exception('Не удалось загрузить сервисы из-за ошибки: $e');
    }
  }
}
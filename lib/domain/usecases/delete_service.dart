// ============================================
// lib/domain/usecases/delete_service.dart
// ============================================

import 'package:motel/core/api/api_client.dart';

class DeleteServiceUseCase {
  final ApiClient _apiClient;

  DeleteServiceUseCase(this._apiClient);

  /// Удалить услугу по ID
  Future<void> execute(int serviceId) async {
    try {
      print("[DeleteServiceUseCase] Удаление услуги с ID: $serviceId");

      await _apiClient.delete('/services/$serviceId');

      print("[DeleteServiceUseCase] Услуга успешно удалена");
    } catch (e) {
      print("[DeleteServiceUseCase] Ошибка: $e");
      throw Exception('Ошибка при удалении услуги: $e');
    }
  }
}

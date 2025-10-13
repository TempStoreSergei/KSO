// ============================================
// lib/domain/usecases/edit_service.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
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
      print("[EditServiceUseCase] Редактирование услуги ID: $serviceId");

      final response = await _apiClient.put(
        '/services/$serviceId',
        body: {
          'name': name,
          'price': price,
          'tax': tax,
        },
      );

      print("[EditServiceUseCase] Услуга успешно обновлена");
      return ApiService.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print("[EditServiceUseCase] Ошибка: $e");
      throw Exception('Ошибка при редактировании услуги: $e');
    }
  }
}

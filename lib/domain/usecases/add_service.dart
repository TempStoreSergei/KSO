// ============================================
// lib/domain/usecases/add_service.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
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
      print("[AddServiceUseCase] Создание услуги: $name, цена: $price, налог: $tax");

      final response = await _apiClient.post(
        '/services',
        body: {
          'name': name,
          'price': price * 100,
          'tax': tax,
        },
      );

      print("[AddServiceUseCase] Услуга успешно создана");
      return ApiService.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print("[AddServiceUseCase] Ошибка: $e");
      throw Exception('Ошибка при создании услуги: $e');
    }
  }
}

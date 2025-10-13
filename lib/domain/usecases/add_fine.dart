// ============================================
// lib/domain/usecases/add_fine.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/fine_models.dart';

class AddFineUseCase {
  final ApiClient _apiClient;

  AddFineUseCase(this._apiClient);

  /// Добавить новый штраф
  Future<void> execute(CreateFineRequest request) async {
    try {
      await _apiClient.post(
        '/guests/add_fine',
        body: request.toJson(),
      );
    } catch (e) {
      throw Exception('Ошибка при создании штрафа: $e');
    }
  }
}

// ============================================
// lib/domain/usecases/update_fine.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/fine_models.dart';

class UpdateFineUseCase {
  final ApiClient _apiClient;

  UpdateFineUseCase(this._apiClient);

  /// Обновить существующий штраф
  Future<void> execute(UpdateFineRequest request) async {
    try {
      await _apiClient.put(
        '/fines/update_fine',
        body: request.toJson(),
      );
    } catch (e) {
      throw Exception('Ошибка при обновлении штрафа: $e');
    }
  }
}

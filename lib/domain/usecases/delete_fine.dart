// ============================================
// lib/domain/usecases/delete_fine.dart
// ============================================

import 'package:motel/core/api/api_client.dart';

class DeleteFineUseCase {
  final ApiClient _apiClient;

  DeleteFineUseCase(this._apiClient);

  /// Удалить штраф по ID
  Future<void> execute(int fineId) async {
    try {
      await _apiClient.delete('/guests/delete_fine?fine_id=$fineId');
    } catch (e) {
      throw Exception('Ошибка при удалении штрафа: $e');
    }
  }
}

// ============================================
// lib/domain/usecases/get_fines.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/fine_models.dart';

class GetFinesUseCase {
  final ApiClient _apiClient;

  GetFinesUseCase(this._apiClient);

  /// Получить все штрафы
  Future<List<Fine>> execute() async {
    try {
      final response = await _apiClient.get('/guests/get_fines');

      if (response['fines'] == null) {
        return [];
      }

      final List<dynamic> finesJson = response['fines'] as List<dynamic>;
      return finesJson.map((json) => Fine.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Ошибка при загрузке штрафов: $e');
    }
  }

  /// Получить штрафы по типу
  Future<List<Fine>> getByType(FineType type) async {
    final allFines = await execute();
    return allFines.where((fine) => fine.type == type).toList();
  }
}

// lib/data/repositories/settings_repository_impl.dart

import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:motel/domain/repositories/settings_repository.dart';

/// Конкретная реализация контракта `SettingsRepository`.
/// Она использует ваш `ApiClient` для выполнения сетевых запросов.
class SettingsRepositoryImpl implements SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepositoryImpl(this._apiClient);

  @override
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.put(
        '/settings/update_admin_password',
        body: {
          'oldAdminPassword': oldPassword,
          'newAdminPassword': newPassword,
        },
      );
    } catch (e) {
      // Логируем ошибку и перебрасываем ее выше, чтобы UI мог ее обработать.
      DiagnosticLogger.info('settings', 'update_password_failed', data: {'error': e.toString()});
      rethrow;
    }
  }
}

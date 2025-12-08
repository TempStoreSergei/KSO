// lib/domain/usecases/update_password_use_case.dart

import 'package:motel/core/api/api_client.dart';

/// Use Case инкапсулирует конкретный бизнес-сценарий смены пароля.
class UpdatePasswordUseCase {
  final ApiClient _apiClient;

  UpdatePasswordUseCase({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Выполняет операцию смены пароля.
  /// [oldPassword] - текущий пароль пользователя
  /// [newPassword] - новый пароль
  Future<void> call({
    required String oldPassword,
    required String newPassword,
  }) async {
    // Валидация входных данных
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      throw ArgumentError('Пароли не могут быть пустыми.');
    }

    // Можно добавить дополнительные проверки
    if (newPassword.length < 6) {
      throw ArgumentError('Новый пароль должен содержать минимум 6 символов.');
    }

    // Формируем тело запроса
    final body = {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };

    // Отправляем запрос на сервер
    try {
      await _apiClient.post('/auth/change_password', body: body);
      // Если запрос успешен, метод завершается без исключений
    } catch (e) {
      // Пробрасываем исключение дальше для обработки в UI
      throw Exception('Не удалось изменить пароль: ${e.toString()}');
    }
  }
}
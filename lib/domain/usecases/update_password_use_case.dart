// lib/domain/use_cases/update_password_use_case.dart

import 'package:motel/domain/repositories/settings_repository.dart';

/// Use Case инкапсулирует конкретный бизнес-сценарий.
class UpdatePasswordUseCase {
  final SettingsRepository _repository;

  UpdatePasswordUseCase(this._repository);

  /// Выполняет операцию смены пароля.
  Future<void> call({
    required String oldPassword,
    required String newPassword,
  }) async {
    // Здесь может быть более сложная бизнес-логика (например, проверка длины пароля).
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      throw ArgumentError('Пароли не могут быть пустыми.');
    }

    // Делегируем выполнение репозиторию.
    await _repository.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
// lib/domain/repositories/settings_repository.dart

/// Абстрактный контракт, который определяет, ЧТО можно сделать с настройками.
/// Он не говорит, КАК это делать.
abstract class SettingsRepository {
  /// Обновляет пароль администратора.
  /// Выбрасывает исключение в случае ошибки.
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  });
}
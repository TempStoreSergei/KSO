// lib/domain/usecases/set_screensaver_status.dart
import 'package:motel/domain/repositories/screensaver_repository.dart';

class SetScreensaverStatus {
  final ScreensaverRepository repository;

  SetScreensaverStatus(this.repository);

  /// Вызывает включение или отключение заставки.
  Future<bool> call(bool isEnabled) async {
    return repository.setScreensaverStatus(isEnabled);
  }
}
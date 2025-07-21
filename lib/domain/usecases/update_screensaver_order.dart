// lib/domain/usecases/update_screensaver_order.dart
import 'package:motel/domain/repositories/screensaver_repository.dart';

class UpdateScreensaverOrder {
  final ScreensaverRepository repository;

  UpdateScreensaverOrder(this.repository);

  /// Вызывает обновление порядкового номера для файла.
  Future<bool> call({required String fileID, required int newOrder}) async {
    if (fileID.isEmpty || newOrder < 1) return false;
    return repository.updateFileOrder(fileID, newOrder);
  }
}
import 'package:image_picker/image_picker.dart';
import 'package:motel/domain/entities/desktop_background_entity.dart';

/// Абстрактный контракт для работы с фоном рабочего стола.
abstract class DesktopBackgroundRepository {
  /// Получает информацию о текущем фоне.
  /// Возвращает null, если фон не установлен.
  Future<DesktopBackgroundEntity?> getDesktopBackground();

  /// Загружает новый файл фона.
  Future<bool> addDesktopBackground(XFile file);

  /// Удаляет текущий фон по его ID.
  Future<bool> deleteDesktopBackground(String fileID);
}
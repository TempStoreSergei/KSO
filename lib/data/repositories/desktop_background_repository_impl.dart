import 'package:image_picker/image_picker.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:motel/data/datasources/desktop_background_remote_data_source.dart';
import 'package:motel/domain/entities/desktop_background_entity.dart';
import 'package:motel/domain/repositories/desktop_background_repository.dart';

/// Реализация репозитория, которая обрабатывает ошибки.
class DesktopBackgroundRepositoryImpl implements DesktopBackgroundRepository {
  final DesktopBackgroundRemoteDataSource remoteDataSource;

  DesktopBackgroundRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DesktopBackgroundEntity?> getDesktopBackground() async {
    try {
      // Метод источника данных уже может вернуть null, поэтому просто передаем результат.
      return await remoteDataSource.getDesktopBackground();
    } catch (e) {
      DiagnosticLogger.info('desktop_background', 'get_failed', data: {'error': e.toString()});
      return null;
    }
  }

  @override
  Future<bool> addDesktopBackground(XFile file) async {
    try {
      await remoteDataSource.addDesktopBackground(file);
      return true;
    } catch (e) {
      DiagnosticLogger.info('desktop_background', 'add_failed', data: {'error': e.toString()});
      return false;
    }
  }

  @override
  Future<bool> deleteDesktopBackground(String fileID) async {
    try {
      await remoteDataSource.deleteDesktopBackground(fileID);
      return true;
    } catch (e) {
      DiagnosticLogger.info('desktop_background', 'delete_failed', data: {'fileID': fileID, 'error': e.toString()});
      return false;
    }
  }
}

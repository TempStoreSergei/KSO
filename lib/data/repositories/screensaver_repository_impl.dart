// lib/data/repositories/screensaver_repository_impl.dart
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:motel/domain/entities/screensaver_file.dart';
import 'package:motel/domain/repositories/screensaver_repository.dart';
import 'package:image_picker/image_picker.dart';

class ScreensaverRepositoryImpl implements ScreensaverRepository {
  final ApiClient _apiClient;
  ScreensaverRepositoryImpl(this._apiClient);

  @override
  Future<List<ScreensaverFile>> getScreensaverFiles() async {
    try {
      final response = await _apiClient.get('/screensaver/get_screensaver_files');
      final List<dynamic> filesData = response['filesData'];

      final files = filesData
          .map((data) => ScreensaverFile.fromJson(data))
          .toList();

      files.sort((a, b) => a.fileOrder.compareTo(b.fileOrder));
      return files;

    } catch (e) {
      DiagnosticLogger.info('screensaver', 'get_files_failed', data: {'error': e.toString()});
      rethrow; // Перебрасываем ошибку, чтобы UI мог ее обработать
    }
  }

  @override
  Future<bool> addScreensaverFile(XFile imageFile) async { // <-- ИЗМЕНЕНИЕ ТИПА
    try {
      // Передаем XFile напрямую в ApiClient, который умеет с ним работать
      await _apiClient.multipartPost('/screensaver/add_screensaver_file', imageFile);
      return true;
    } catch (e) {
      DiagnosticLogger.info('screensaver', 'add_file_failed', data: {'fileName': imageFile.name, 'error': e.toString()});
      return false;
    }
  }

  @override
  Future<bool> deleteScreensaverFile(String fileID) async {
    try {
      await _apiClient.delete('/screensaver/delete_screensaver_file', body: {'fileID': fileID});
      return true;
    } catch (e) {
      DiagnosticLogger.info('screensaver', 'delete_file_failed', data: {'fileID': fileID, 'error': e.toString()});
      return false;
    }
  }

  @override
  Future<bool> updateFileOrder(String fileID, int newOrder) async {
    try {
      await _apiClient.put('/screensaver/update_screensaver_file_order', body: {
        'fileID': fileID,
        'file_order': newOrder,
      });
      return true;
    } catch (e) {
      DiagnosticLogger.info('screensaver', 'update_order_failed', data: {'fileID': fileID, 'error': e.toString()});
      return false;
    }
  }

  @override
  Future<bool> setScreensaverStatus(bool isEnabled) async {
    try {
      await _apiClient.put('/screensaver/activate_or_deactivate_screensaver', body: {
        'screensaverIsEnabled': isEnabled,
      });
      return true;
    } catch (e) {
      DiagnosticLogger.info('screensaver', 'set_status_failed', data: {'enabled': isEnabled, 'error': e.toString()});
      return false;
    }
  }
}

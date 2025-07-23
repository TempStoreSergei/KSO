import 'package:image_picker/image_picker.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/models/desktop_background_model.dart';

/// Абстракция для прямых вызовов к API.
abstract class DesktopBackgroundRemoteDataSource {
  Future<DesktopBackgroundModel?> getDesktopBackground();
  Future<void> addDesktopBackground(XFile file);
  Future<void> deleteDesktopBackground(String fileID);
}

/// Реализация, использующая ваш ApiClient.
class DesktopBackgroundRemoteDataSourceImpl implements DesktopBackgroundRemoteDataSource {
  final ApiClient apiClient;

  DesktopBackgroundRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DesktopBackgroundModel?> getDesktopBackground() async {
    final response = await apiClient.get('/desktop_background/get_desktop_background_files');
    // API может вернуть пустые данные. Проверяем наличие ключа 'fileData'.
    if (response.containsKey('fileData') && response['fileData'] != null) {
      return DesktopBackgroundModel.fromJson(response['fileData']);
    }
    return null; // Возвращаем null, если фон не найден.
  }

  @override
  Future<void> addDesktopBackground(XFile file) async {
    // Используем метод для multipart-запросов из вашего ApiClient
    await apiClient.multipartPost('/desktop_background/add_desktop_background_file', file);
  }

  @override
  Future<void> deleteDesktopBackground(String fileID) async {
    await apiClient.delete(
      '/desktop_background/delete_desktop_background_file',
      body: {'fileID': fileID},
    );
  }
}
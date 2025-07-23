import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Сущность, представляющая фон рабочего стола.
class DesktopBackgroundEntity extends Equatable {
  final String fileID;
  final String filePath;

  const DesktopBackgroundEntity({
    required this.fileID,
    required this.filePath,
  });

  /// Вспомогательный геттер для получения полного URL-адреса изображения.
  String get fullUrl {
    final baseUrl = dotenv.env['BASE_URL']!;
    // Убедимся, что путь не начинается со слеша, если он уже есть в baseUrl
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$baseUrl/$path';
  }

  @override
  List<Object?> get props => [fileID, filePath];
}
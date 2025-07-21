// lib/domain/entities/screensaver_file.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Сущность, представляющая один файл заставки.
class ScreensaverFile {
  final String fileID;
  final String filePath; // Относительный путь, который возвращает сервер
  final int fileOrder;

  ScreensaverFile({
    required this.fileID,
    required this.filePath,
    required this.fileOrder,
  });

  /// Фабричный конструктор для создания экземпляра [ScreensaverFile] из JSON-объекта.
  /// Это основной способ преобразования ответа от сервера в наш объект.
  factory ScreensaverFile.fromJson(Map<String, dynamic> json) {
    return ScreensaverFile(
      fileID: json['fileID'] as String,
      filePath: json['filePath'] as String,
      fileOrder: json['fileOrder'] as int,
    );
  }

  /// Удобный геттер для получения полного, абсолютного URL изображения.
  /// Он объединяет базовый URL из .env файла и относительный путь файла.
  String get fullUrl {
    // Получаем базовый URL из переменных окружения
    final baseUrl = dotenv.env['BASE_URL'];

    // Проверка на случай, если BASE_URL не загружен
    if (baseUrl == null) {
      print("КРИТИЧЕСКАЯ ОШИБКА: Переменная BASE_URL не найдена в .env файле.");
      // Возвращаем пустую строку, чтобы избежать падения, но в консоли будет ошибка
      return '';
    }

    // Собираем полный URL
    return "$baseUrl/$filePath";
  }
}
// lib/domain/repositories/screensaver_repository.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // <-- ВАЖНЫЙ ИМПОРТ
import '../entities/screensaver_file.dart';

/// Абстрактный репозиторий (контракт) для управления файлами заставки.
abstract class ScreensaverRepository {
  Future<List<ScreensaverFile>> getScreensaverFiles();

  Future<bool> addScreensaverFile(XFile imageFile);

  Future<bool> deleteScreensaverFile(String fileID);
  Future<bool> updateFileOrder(String fileID, int newOrder);
  Future<bool> setScreensaverStatus(bool isEnabled);
}
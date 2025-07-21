// lib/domain/usecases/get_screensaver_files.dart
import '../entities/screensaver_file.dart';
import '../repositories/screensaver_repository.dart';

class GetScreensaverFiles {
  final ScreensaverRepository repository;

  GetScreensaverFiles(this.repository);

  Future<List<ScreensaverFile>> call() async {
    return await repository.getScreensaverFiles();
  }
}
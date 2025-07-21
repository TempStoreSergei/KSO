// lib/domain/usecases/add_screensaver_file.dart
import 'package:image_picker/image_picker.dart';
import 'package:motel/domain/repositories/screensaver_repository.dart';

class AddScreensaverFile {
  final ScreensaverRepository repository;
  AddScreensaverFile(this.repository);

  Future<bool> call(XFile image) async {
    return repository.addScreensaverFile(image);
  }
}
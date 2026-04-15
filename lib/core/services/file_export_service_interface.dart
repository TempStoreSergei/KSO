import 'dart:typed_data';

abstract class FileExportService {
  Future<bool> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    String? mimeType,
  });
}

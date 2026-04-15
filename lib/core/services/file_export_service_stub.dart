import 'dart:typed_data';

import 'file_export_service_interface.dart';

class UnsupportedFileExportService implements FileExportService {
  @override
  Future<bool> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    String? mimeType,
  }) async {
    return false;
  }
}

FileExportService createFileExportService() => UnsupportedFileExportService();

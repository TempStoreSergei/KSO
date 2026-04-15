import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'file_export_service_interface.dart';

class IoFileExportService implements FileExportService {
  @override
  Future<bool> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    String? mimeType,
  }) async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    );

    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return false;
    }

    final separator = Platform.pathSeparator;
    final normalizedDirectory = selectedDirectory.trim();
    final savePath = normalizedDirectory.endsWith(separator)
        ? '$normalizedDirectory$fileName'
        : '$normalizedDirectory$separator$fileName';

    final file = File(savePath);
    await file.writeAsBytes(bytes);
    return true;
  }
}

FileExportService createFileExportService() => IoFileExportService();

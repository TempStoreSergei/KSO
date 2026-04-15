// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

import 'file_export_service_interface.dart';

class WebFileExportService implements FileExportService {
  @override
  Future<bool> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    String? mimeType,
  }) async {
    final blob = html.Blob(
      [bytes],
      mimeType ?? 'application/octet-stream',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return true;
  }
}

FileExportService createFileExportService() => WebFileExportService();

import 'package:motel/domain/entities/desktop_background_entity.dart';

/// Модель данных, которая умеет парситься из JSON.
class DesktopBackgroundModel extends DesktopBackgroundEntity {
  const DesktopBackgroundModel({
    required super.fileID,
    required super.filePath,
  });

  factory DesktopBackgroundModel.fromJson(Map<String, dynamic> json) {
    return DesktopBackgroundModel(
      fileID: json['fileID'],
      filePath: json['filePath'],
    );
  }
}
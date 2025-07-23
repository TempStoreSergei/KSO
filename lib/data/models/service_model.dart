import 'package:motel/domain/entities/service_entity.dart';

// Модель расширяет Entity, чтобы избежать дублирования полей.
class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.serviceID,
    required super.serviceName,
    required super.servicePrice,
    required super.serviceOneTime,
  });

  // Фабричный конструктор для создания экземпляра из JSON
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceID: json['serviceID'],
      serviceName: json['serviceName'],
      servicePrice: json['servicePrice'],
      serviceOneTime: json['serviceOneTime'],
    );
  }

  // Метод для конвертации в JSON (если понадобится отправлять данные)
  Map<String, dynamic> toJson() {
    return {
      'serviceID': serviceID,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'serviceOneTime': serviceOneTime,
    };
  }
}
import 'package:motel/domain/entities/service_entity.dart';

// Модель расширяет Entity, чтобы избежать дублирования полей.
class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.price,
    required super.tax,
    required super.isCountable,
    required super.isDuration,
    required super.code,
  });

  // Фабричный конструктор для создания экземпляра из JSON
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      tax: json['tax'] as int,
      isCountable: json['isCountable'] as bool,
      isDuration: json['isDuration'] as bool,
      code: json['code'] as String? ?? '',
    );
  }

  // Метод для конвертации в JSON (если понадобится отправлять данные)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'tax': tax,
      'isCountable': isCountable,
      'isDuration': isDuration,
      'code': code,
    };
  }
}
import 'package:equatable/equatable.dart';

// Используем Equatable для простого сравнения объектов
class ServiceEntity extends Equatable {
  final int id;
  final String name;
  final int price;
  final int tax;
  final bool isCountable;
  final bool isDuration;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.tax,
    required this.isCountable,
    required this.isDuration,
  });

  @override
  List<Object?> get props => [id, name, price, tax, isCountable, isDuration];
}
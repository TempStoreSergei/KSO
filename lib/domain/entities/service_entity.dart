import 'package:equatable/equatable.dart';

// Используем Equatable для простого сравнения объектов
class ServiceEntity extends Equatable {
  final String serviceID;
  final String serviceName;
  final int? servicePrice;
  final bool serviceOneTime;

  const ServiceEntity({
    required this.serviceID,
    required this.serviceName,
    this.servicePrice,
    required this.serviceOneTime,
  });

  @override
  List<Object?> get props => [serviceID, serviceName, servicePrice, serviceOneTime];
}
// lib/models/service_model.dart

class Service {
  final String serviceID;
  final String serviceName;
  final int? servicePrice; // Цена может быть null
  final bool serviceOneTime;

  Service({
    required this.serviceID,
    required this.serviceName,
    this.servicePrice,
    required this.serviceOneTime,
  });

  // Фабричный конструктор для создания экземпляра Service из JSON
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      serviceID: json['serviceID'],
      serviceName: json['serviceName'],
      servicePrice: json['servicePrice'],
      serviceOneTime: json['serviceOneTime'],
    );
  }
}
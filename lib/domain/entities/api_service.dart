// ============================================
// lib/domain/entities/api_service.dart
// ============================================

class ApiService {
  final int id;
  final String name;
  final int price;
  final int tax;

  ApiService({
    required this.id,
    required this.name,
    required this.price,
    required this.tax,
  });

  factory ApiService.fromJson(Map<String, dynamic> json) {
    return ApiService(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      tax: json['tax'],
    );
  }
}
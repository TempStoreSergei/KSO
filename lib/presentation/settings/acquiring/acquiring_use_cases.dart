// ============================================
// lib/presentation/settings/acquiring/acquiring_use_cases.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/presentation/settings/acquiring/acquiring_models.dart';

/// Use Cases для работы с эквайрингом
class AcquiringUseCases {
  final ApiClient _apiClient;

  AcquiringUseCases(this._apiClient);

  /// Автоматическая проверка подключения (сначала новый метод, потом старый)
  Future<AcquiringResponse> checkConnection() async {
    try {
      final response = await _apiClient.get('/acquiring/check_connect');
      final result = AcquiringResponse.fromJson(response);
      if (result.status) {
        return result;
      }
    } catch (e) {
      // Если новый метод не сработал, пробуем старый
    }

    // Пробуем старый метод
    final response = await _apiClient.get('/acquiring/check_connect_old');
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> startPayment() async {
    final response = await _apiClient.get('/acquiring/start_payment', params: {'amount': '100'});
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> refundPayment() async {
    final response = await _apiClient.get('/acquiring/refund_payment', params: {'amount': '100'});
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> receiptReport() async {
    final response = await _apiClient.get('/acquiring/receipt_report');
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> cancelPayment() async {
    final response = await _apiClient.get('/acquiring/cancel_payment');
    return AcquiringResponse.fromJson(response);
  }

  Future<AcquiringResponse> openMenu() async {
    final response = await _apiClient.get('/acquiring/open_menu');
    return AcquiringResponse.fromJson(response);
  }
}

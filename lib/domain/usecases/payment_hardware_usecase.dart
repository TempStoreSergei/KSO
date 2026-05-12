import 'package:motel/core/api/api_client.dart';

class PaymentHardwareUseCase {
  PaymentHardwareUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<void> startCashPayment({required int amount}) async {
    await _apiClient.get(
      '/cash_system/start_accepting_payment',
      params: {'amount': amount},
    );
  }

  Future<void> stopCashPayment() async {
    await _apiClient.get('/cash_system/stop_accepting_payment');
  }

  Future<void> dispenseCash({required int amount}) async {
    if (amount <= 0) return;

    await _apiClient.get(
      '/cash_system/dispense_change',
      params: {'amount': amount},
    );
  }

  Future<void> startCardPayment({required int amount}) async {
    await _apiClient.get(
      '/acquiring/start_payment',
      params: {'amount': amount},
    );
  }
}

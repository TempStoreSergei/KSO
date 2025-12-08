  import 'package:motel/core/api/api_client.dart';
  import 'package:motel/domain/entities/transaction.dart';

  class SendTransactionTo1CUseCase {
    final ApiClient _apiClient;

    SendTransactionTo1CUseCase(this._apiClient);

    Future<void> call(Transaction transaction, String clientId) async {
      try {
        // Подготавливаем items из услуг
        final items = transaction.services.map((service) {
          return {
            'code': int.tryParse(service.serviceCode) ?? 0,
            'price': service.price,
            'count': service.count,
          };
        }).toList();

        // Вычисляем общую сумму
        final totalPrice = (transaction.room.totalPrice ?? 0) +
                          transaction.services.fold<int>(0, (sum, s) => sum + s.totalPrice);

        await _apiClient.post(
          '/transactions/send_transaction',
          body: {
            'id': transaction.id,
            'room_number': transaction.room.number,
            'client_id': clientId,
            'items': items,
            'payment_summ': totalPrice,
            'payment_type': transaction.paymentType,
          },
        );
      } catch (e) {
        throw Exception('Не удалось отправить транзакцию в 1С: $e');
      }
    }
  }
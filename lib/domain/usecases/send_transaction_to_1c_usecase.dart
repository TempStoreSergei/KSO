import 'package:motel/core/api/api_client.dart';
  import 'package:motel/domain/entities/transaction.dart';

  class SendTransactionTo1CUseCase {
    final ApiClient _apiClient;

    SendTransactionTo1CUseCase(this._apiClient);

    Future<void> call(Transaction transaction, String clientId) async {
      try {
        // Подготавливаем items из услуг
        final items = <Map<String, dynamic>>[];
        
        // Добавляем услуги
        items.addAll(transaction.services.map((service) {
          return {
            'code': service.serviceCode,
            'price': service.price,
            'count': service.count,
            'name': service.name,
          };
        }));

        // Добавляем штрафы
        items.addAll(transaction.fines.map((fine) {
          return {
            'code': fine.fineCode,
            'price': fine.price,
            'count': fine.count,
            'name': fine.name,
          };
        }));

        await _apiClient.post(
          '/transactions/send_transaction',
          body: {
            'id': transaction.id,
            'room_number': transaction.room.number,
            'client_id': clientId,
            'items': items,
            // Используем итог из ответа API: room.price может быть стоимостью
            // только одних суток проживания.
            'payment_summ': transaction.totalPrice,
            'payment_type': transaction.paymentType,
          },
        );
      } catch (e) {
        throw Exception('Не удалось отправить транзакцию в 1С: $e');
      }
    }
  }

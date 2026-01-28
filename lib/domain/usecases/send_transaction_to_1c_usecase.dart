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

        // Вычисляем общую сумму: Комната + Услуги + Штрафы
        final servicesSum = transaction.services.fold<int>(0, (sum, s) => sum + s.totalPrice);
        final finesSum = transaction.fines.fold<int>(0, (sum, f) => sum + f.totalPrice);
        final roomPrice = transaction.room.totalPrice ?? 0;
        
        // Если это чисто транзакция проживания (без услуг и штрафов), и totalPrice 0,
        // возможно стоит брать price? Но пока оставим totalPrice как основной источник для проживания.
        // Если это транзакция штрафа, roomPrice будет 0, servicesSum 0, finesSum > 0.
        
        final totalPrice = roomPrice + servicesSum + finesSum;

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
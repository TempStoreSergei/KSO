// ============================================
// lib/domain/usecases/save_transaction_usecase.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/models/save_transaction_request.dart';

class SaveTransactionUseCase {
  final ApiClient _apiClient;

  SaveTransactionUseCase(this._apiClient);

  Future<void> call(BookingData bookingData) async {
    // 1. Преобразуем данные из BookingData в модель запроса
    final requestModel = _mapBookingDataToRequest(bookingData);

    // 2. Отправляем POST-запрос с данными в формате JSON
    try {
      print("[SaveTransactionUseCase] Отправляю данные на /guests/save_transaction...");
      print("Тело запроса: ${requestModel.toJson()}");

      await _apiClient.post(
        '/guests/save_transaction',
        body: requestModel.toJson(),
      );

      print("[SaveTransactionUseCase] Данные успешно отправлены.");
    } catch (e) {
      print("[SaveTransactionUseCase] КРИТИЧЕСКАЯ ОШИБКА при отправке данных: $e");
      // Перебрасываем ошибку, чтобы UI мог ее обработать
      throw Exception('Не удалось сохранить бронирование: $e');
    }
  }

  // Вспомогательный метод для маппинга данных
  SaveTransactionRequest _mapBookingDataToRequest(BookingData data) {
    // Собираем массив ID сервисов из выбранных элементов
    final List<int> serviceIds = data.selectedItems
        .map((item) => int.tryParse(item.id) ?? 0)
        .where((id) => id != 0)
        .toList();

    return SaveTransactionRequest(
      guest: GuestInfoRequest(
        firstName: data.firstName ?? '',
        lastName: data.lastName ?? '',
        surname: data.middleName ?? '', // Маппим middleName в surname
      ),
      services: serviceIds,
      // Пытаемся распарсить номер комнаты из строки, если не получается - ставим 0
      roomId: int.tryParse(data.selectedRoom?.name ?? '0') ?? 0,
      // Конвертируем даты в стандартный формат ISO 8601
      checkIn: data.checkInDate.toIso8601String(),
      checkOut: data.checkOutDate.toIso8601String(),
      paymentType: data.paymentMethod ?? 'unknown',
    );
  }
}
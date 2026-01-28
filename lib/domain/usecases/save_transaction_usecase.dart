
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/models/save_transaction_request.dart';
import 'package:motel/presentation/booking/formatters/ru_phone.dart';

class SaveTransactionUseCase {
  final ApiClient _apiClient;

  SaveTransactionUseCase(this._apiClient);

  Future<void> call(BookingData bookingData) async {
    final requestModel = _mapBookingDataToRequest(bookingData);

    try {
      await _apiClient.post(
        '/transactions/save_transaction',
        body: requestModel.toJson(),
      );
    } catch (e) {
      throw Exception('Не удалось сохранить бронирование: $e');
    }
  }

  SaveTransactionRequest _mapBookingDataToRequest(BookingData data) {
    List<Map<String, int>>? services;
    List<Map<String, int>>? fines;

    // Определяем, что мы отправляем - услуги или штрафы
    if (data.selectedCategory == BookingCategory.services ||
        data.selectedCategory == BookingCategory.accommodation) {
      if (data.selectedItems.isNotEmpty) {
        services = data.selectedItems.map((item) {
          final Map<String, int> serviceMap = {
            'id': int.tryParse(item.id) ?? 0,
          };
          if (item.isCountable && item.quantity > 0) {
            serviceMap['count'] = item.quantity;
          }
          if (item.isDuration && item.quantity > 0) {
            serviceMap['duration'] = item.quantity;
          }
          return serviceMap;
        }).toList();
      }
    } else if (data.selectedCategory == BookingCategory.ruleViolationPenalty ||
        data.selectedCategory == BookingCategory.propertyDamagePenalty) {
      if (data.selectedItems.isNotEmpty) {
        fines = data.selectedItems.map((item) {
          final Map<String, int> fineMap = {
            'id': int.tryParse(item.id) ?? 0,
          };
          // Предполагаем, что штрафы тоже могут быть исчисляемыми
          if (item.isCountable && item.quantity > 0) {
            fineMap['count'] = item.quantity;
          }
          return fineMap;
        }).toList();
      }
    }

    // Собираем новый объект room
    final roomInfo = RoomInfoRequest(
      number: data.selectedRoom?.name ?? '0',
      type: data.selectedRoom?.type.toApiString() ?? 'unknown',
      building: int.tryParse(data.selectedRoom?.buildingId ?? '0') ?? 0,
      countDays: data.totalNights,
    );

    return SaveTransactionRequest(
      guest: GuestInfoRequest(
        firstName: data.firstName ?? '',
        lastName: data.lastName ?? '',
        surname: data.middleName ?? '',
        phoneNumber: normalizeRuPhoneDigits(data.phoneNumber ?? '') ?? '',
      ),
      room: roomInfo,
      services: services,
      fines: fines,
      paymentSumm: data.totalPrice,
      paymentType: _convertPaymentType(data.paymentMethod),
    );
  }

  /// Преобразует метод оплаты в формат для сервера
  /// "Наличные" → "Наличные"
  /// "СБП" или "Карта" → "Он-лайн платёж(СБП, Карта)"
  String _convertPaymentType(String? paymentMethod) {
    if (paymentMethod == 'Наличные') {
      return 'Наличные';
    } else if (paymentMethod == 'СБП' || paymentMethod == 'Карта') {
      return 'Он-лайн платёж';
    }
    return 'Наличные'; // По умолчанию
  }
}

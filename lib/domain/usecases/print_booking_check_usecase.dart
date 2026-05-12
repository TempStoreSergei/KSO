import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/tax_settings_service.dart';
import 'package:motel/domain/models/booking_models.dart';

class PrintBookingCheckUseCase {
  PrintBookingCheckUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<bool> call({
    required BookingData data,
    required String paymentMethod,
    required int totalPrice,
  }) async {
    final items = data.selectedItems.map((item) {
      return {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'tax': item.tax,
        'objectType': 4,
      };
    }).toList();

    if (items.isEmpty && data.selectedCategory == BookingCategory.accommodation) {
      final defaultTax = await TaxSettingsService.getDefaultAccommodationTax();

      items.add({
        'name': 'Предоставление койко-мест для временного размещения',
        'price': totalPrice,
        'quantity': 1,
        'tax': defaultTax,
        'objectType': 4,
      });
    }

    final fio = [
      data.lastName ?? '',
      data.firstName ?? '',
      data.middleName ?? '',
    ].where((part) => part.isNotEmpty).join(' ');

    final checkData = {
      'items': items,
      'paymentType': _getPaymentTypeCode(paymentMethod),
      'summ': totalPrice,
      'fio': fio,
      'phoneNumber': data.phoneNumber ?? '',
    };

    return await _apiClient.printCheck(checkData);
  }

  int _getPaymentTypeCode(String paymentMethod) {
    switch (paymentMethod) {
      case 'Карта':
        return 1;
      case 'Наличные':
        return 0;
      default:
        return 1;
    }
  }
}

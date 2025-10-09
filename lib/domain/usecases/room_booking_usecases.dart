// ============================================
// lib/domain/usecases/room_booking_usecases.dart
// ============================================

import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';

class RoomBookingUseCases {
  final ApiClient _apiClient;

  RoomBookingUseCases(this._apiClient);

  Future<void> createBooking({
    required String firstName,
    required String lastName,
    required String middleName,
    required DateTime checkIn,
    required DateTime checkOut,
    String? serviceId,
    required String paymentMethod,
    required BookingType bookingType,
  }) async {
    await _apiClient.post(
      '/bookings/create',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        if (serviceId != null) 'service_id': serviceId,
        'payment_method': paymentMethod,
        'booking_type': bookingType == BookingType.accommodation ? 'accommodation' : 'service_only',
      },
    );
  }

  List<AdditionalService> getAvailableServices() {
    return [
      AdditionalService(
        id: 'breakfast',
        name: 'Завтрак',
        price: 500,
      ),
      AdditionalService(
        id: 'parking',
        name: 'Парковка',
        price: 300,
      ),
      AdditionalService(
        id: 'spa',
        name: 'СПА-услуги',
        price: 1200,
      ),
    ];
  }
}
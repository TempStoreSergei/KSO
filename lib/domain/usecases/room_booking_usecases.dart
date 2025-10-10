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
    required List<BookingItem> selectedItems,
    required BookingCategory category,
    required String paymentMethod,
  }) async {
    await _apiClient.post(
      '/bookings/create',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'selected_items': selectedItems.map((item) => {
          'id': item.id,
          'name': item.name,
          'price': item.price,
        }).toList(),
        'category': _categoryToString(category),
        'payment_method': paymentMethod,
      },
    );
  }

  String _categoryToString(BookingCategory category) {
    switch (category) {
      case BookingCategory.accommodation:
        return 'accommodation';
      case BookingCategory.services:
        return 'services';
      case BookingCategory.ruleViolationPenalty:
        return 'rule_violation_penalty';
      case BookingCategory.propertyDamagePenalty:
        return 'property_damage_penalty';
      case BookingCategory.unknown:
        return 'unknown';
    }
  }
}
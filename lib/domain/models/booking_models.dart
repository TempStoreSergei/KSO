// ============================================
// lib/domain/models/booking_models.dart
// ============================================

import 'package:flutter/foundation.dart';
import 'package:motel/domain/entities/api_service.dart';

// Перечисление всех шагов в процессе бронирования
enum BookingStep {
  roomSelection,
  guestInfo,
  bookingType,
  period,
  service,
  payment,
  confirmation,
  success,
}

// Типы бронирования
enum BookingType {
  unknown,
  accommodation,
  serviceOnly,
}

// === ИЗМЕНЕНИЕ: Упрощенная модель комнаты. Только номер. ===
class Room {
  final String id;
  final String name; // Номер комнаты, например, "101"

  Room({
    required this.id,
    required this.name,
  });
}

// Класс для дополнительной услуги (макет)
class AdditionalService {
  final String id;
  final String name;
  final int price;

  AdditionalService({
    required this.id,
    required this.name,
    required this.price,
  });
}

// Основной класс, хранящий все данные о текущем бронировании
class BookingData {
  Room? selectedRoom;
  BookingType bookingType = BookingType.unknown;
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
  ApiService? selectedService;
  String? lastName;
  String? firstName;
  String? middleName;
  String? paymentMethod;

  int get totalNights {
    if (checkOutDate.isBefore(checkInDate)) return 0;
    final nights = checkOutDate.difference(checkInDate).inDays;
    return nights > 0 ? nights : 1;
  }

  int get totalPrice {
    if (bookingType == BookingType.accommodation && selectedRoom != null) {
      const int pricePerNight = 3000;
      return pricePerNight * totalNights;
    }
    if (bookingType == BookingType.serviceOnly && selectedService != null) {
      return selectedService!.price;
    }
    return 0;
  }
}
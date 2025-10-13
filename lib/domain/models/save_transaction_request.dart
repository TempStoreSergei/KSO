// ============================================
// lib/domain/models/save_transaction_request.dart
// ============================================

// Внутренняя модель для информации о госте
class GuestInfoRequest {
  final String firstName;
  final String lastName;
  final String surname; // Отчество

  GuestInfoRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'surname': surname,
    };
  }
}

// Основная модель для отправки на /guests/save_transaction
// ВАЖНО: guest и room - обязательные поля
// Должно быть либо services, либо fines (или оба)
class SaveTransactionRequest {
  final GuestInfoRequest guest;
  final String room; // Номер комнаты (строка)
  final List<int>? services; // Опциональный список ID услуг
  final List<int>? fines; // Опциональный список ID штрафов
  final String? checkIn; // Опционально для штрафов
  final String? checkOut; // Опционально для штрафов
  final String? paymentType; // Опционально

  SaveTransactionRequest({
    required this.guest,
    required this.room,
    this.services,
    this.fines,
    this.checkIn,
    this.checkOut,
    this.paymentType,
  }) : assert(
          services != null || fines != null,
          'Должен быть указан либо services, либо fines (или оба)',
        );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'guest': guest.toJson(),
      'room': room,
    };

    // Добавляем опциональные поля только если они не null
    if (services != null && services!.isNotEmpty) {
      json['services'] = services;
    }
    if (fines != null && fines!.isNotEmpty) {
      json['fines'] = fines;
    }
    if (checkIn != null) {
      json['checkIn'] = checkIn;
    }
    if (checkOut != null) {
      json['checkOut'] = checkOut;
    }
    if (paymentType != null) {
      json['paymentType'] = paymentType;
    }

    return json;
  }
}
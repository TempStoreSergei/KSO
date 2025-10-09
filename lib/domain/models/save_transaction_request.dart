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
class SaveTransactionRequest {
  final GuestInfoRequest guest;
  final List<int> services;
  final int roomId;
  final String checkIn;
  final String checkOut;
  final String paymentType;

  SaveTransactionRequest({
    required this.guest,
    required this.services,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.paymentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'guest': guest.toJson(),
      'services': services,
      'roomId': roomId,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'paymentType': paymentType,
    };
  }
}
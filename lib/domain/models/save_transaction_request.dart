// Модель для информации о госте
class GuestInfoRequest {
  final String firstName;
  final String lastName;
  final String surname;

  GuestInfoRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'surname': surname,
      };
}

// Модель для информации о комнате
class RoomInfoRequest {
  final String number;
  final String type;
  final int building;
  final int? countDays;

  RoomInfoRequest({
    required this.number,
    required this.type,
    required this.building,
    this.countDays,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'number': number,
      'type': type,
      'building': building,
    };
    // Не добавляем countDays, если он null или 0
    if (countDays != null && countDays! > 0) {
      map['countDays'] = countDays;
    }
    return map;
  }
}

// Основная модель запроса
class SaveTransactionRequest {
  final GuestInfoRequest guest;
  final RoomInfoRequest room;
  final List<Map<String, int>>? services;
  final List<Map<String, int>>? fines;
  final int paymentSumm;
  final String paymentType;

  SaveTransactionRequest({
    required this.guest,
    required this.room,
    required this.paymentSumm,
    required this.paymentType,
    this.services,
    this.fines,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'guest': guest.toJson(),
      'room': room.toJson(),
      'paymentSumm': paymentSumm,
      'paymentType': paymentType,
    };
    if (services != null && services!.isNotEmpty) {
      map['services'] = services;
    }
    if (fines != null && fines!.isNotEmpty) {
      map['fines'] = fines;
    }
    return map;
  }
}

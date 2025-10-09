// ============================================
// lib/domain/entities/transaction.dart
// ============================================

class Transaction {
  final int id;
  final TransactionGuest guest;
  final List<TransactionService> services;
  final TransactionRoom room;
  final DateTime checkIn;
  final DateTime checkOut;
  final String paymentType;

  Transaction({
    required this.id,
    required this.guest,
    required this.services,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.paymentType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      guest: TransactionGuest.fromJson(json['guest']),
      services: (json['services'] as List)
          .map((s) => TransactionService.fromJson(s))
          .toList(),
      room: TransactionRoom.fromJson(json['room']),
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: DateTime.parse(json['checkOut']),
      paymentType: json['paymentType'],
    );
  }
}

class TransactionGuest {
  final int id;
  final String firstName;
  final String lastName;
  final String surname;

  TransactionGuest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
  });

  factory TransactionGuest.fromJson(Map<String, dynamic> json) {
    return TransactionGuest(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      surname: json['surname'] ?? '',
    );
  }
}

class TransactionService {
  final int id;
  final String name;
  final int price;
  final int tax;

  TransactionService({
    required this.id,
    required this.name,
    required this.price,
    required this.tax,
  });

  factory TransactionService.fromJson(Map<String, dynamic> json) {
    return TransactionService(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      tax: json['tax'],
    );
  }
}

class TransactionRoom {
  final int id;
  final String name;

  TransactionRoom({
    required this.id,
    required this.name,
  });

  factory TransactionRoom.fromJson(Map<String, dynamic> json) {
    return TransactionRoom(
      id: json['id'],
      name: json['name'],
    );
  }
}

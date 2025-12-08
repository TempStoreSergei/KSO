// Represents the structure of a single transaction from the API response

class Transaction {
  final int id;
  final TransactionGuest guest;
  final List<TransactionService> services;
  final List<TransactionFine> fines;
  final TransactionRoom room;
  final String paymentType;
  final bool sentTo1c;
  final bool sentSuccessfully;
  final String? errorMessage;

  Transaction({
    required this.id,
    required this.guest,
    required this.services,
    required this.fines,
    required this.room,
    required this.paymentType,
    required this.sentTo1c,
    required this.sentSuccessfully,
    this.errorMessage,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      guest: TransactionGuest.fromJson(json['guest']),
      services: (json['services'] as List)
          .map((s) => TransactionService.fromJson(s))
          .toList(),
      fines: (json['fines'] as List)
          .map((f) => TransactionFine.fromJson(f))
          .toList(),
      room: TransactionRoom.fromJson(json['room']),
      paymentType: json['paymentType'],
      sentTo1c: json['sentTo1c'] ?? false,
      sentSuccessfully: json['sentSuccessfully'] ?? false,
      errorMessage: json['errorMessage'],
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
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      surname: json['surname'] ?? '',
    );
  }
}

class TransactionService {
  final int id;
  final String name;
  final int price;
  final int tax;
  final int count;
  final int? duration; // Can be null
  final String serviceCode;
  final int totalPrice;

  TransactionService({
    required this.id,
    required this.name,
    required this.price,
    required this.tax,
    required this.count,
    this.duration,
    required this.serviceCode,
    required this.totalPrice,
  });

  factory TransactionService.fromJson(Map<String, dynamic> json) {
    return TransactionService(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      tax: json['tax'],
      count: json['count'],
      duration: json['duration'], // Will be null if not present
      serviceCode: json['serviceCode'] ?? '',
      totalPrice: json['totalPrice'],
    );
  }
}

class TransactionFine {
  final int id;
  final int count;

  TransactionFine({required this.id, required this.count});

  factory TransactionFine.fromJson(Map<String, dynamic> json) {
    return TransactionFine(
      id: json['id'],
      count: json['count'],
    );
  }
}

class TransactionRoom {
  final String number;
  final String type;
  final int building;
  final int? countDays; // Can be null
  final int price;
  final int? totalPrice; // Can be null

  TransactionRoom({
    required this.number,
    required this.type,
    required this.building,
    this.countDays,
    required this.price,
    this.totalPrice,
  });

  factory TransactionRoom.fromJson(Map<String, dynamic> json) {
    return TransactionRoom(
      number: json['number'],
      type: json['type'],
      building: json['building'],
      countDays: json['countDays'],
      price: json['price'],
      totalPrice: json['totalPrice'],
    );
  }
}
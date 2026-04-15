// Represents the structure of a single transaction from the API response

class Transaction {
  final int id;
  final TransactionGuest guest;
  final List<TransactionService> services;
  final List<TransactionFine> fines;
  final TransactionRoom room;
  final String paymentType;
  final DateTime? paymentDateTime;
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
    this.paymentDateTime,
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
      paymentDateTime: _parseTransactionDateTime(json),
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
  final String? phoneNumber;

  TransactionGuest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    this.phoneNumber,
  });

  String get fullName {
    return [lastName, firstName, surname]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
  }

  factory TransactionGuest.fromJson(Map<String, dynamic> json) {
    return TransactionGuest(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      surname: json['surname'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }
}

DateTime? _parseTransactionDateTime(Map<String, dynamic> json) {
  const candidateKeys = [
    'paymentDateTime',
    'payment_datetime',
    'paymentDate',
    'payment_date',
    'createdAt',
    'created_at',
    'dateTime',
    'date_time',
    'timestamp',
  ];

  for (final key in candidateKeys) {
    final rawValue = json[key];
    final parsedValue = _parseDateTime(rawValue);
    if (parsedValue != null) {
      return parsedValue;
    }
  }

  return null;
}

DateTime? _parseDateTime(dynamic rawValue) {
  if (rawValue == null) return null;
  if (rawValue is DateTime) return rawValue;
  if (rawValue is String && rawValue.trim().isNotEmpty) {
    return DateTime.tryParse(rawValue.trim());
  }
  if (rawValue is int) {
    final milliseconds = rawValue > 9999999999 ? rawValue : rawValue * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
  return null;
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
  final String name;
  final int price;
  final int totalPrice;
  final int count;
  final String fineCode;

  TransactionFine({
    required this.id,
    required this.name,
    required this.price,
    required this.totalPrice,
    required this.count,
    required this.fineCode,
  });

  factory TransactionFine.fromJson(Map<String, dynamic> json) {
    return TransactionFine(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      totalPrice: json['totalPrice'],
      count: json['count'],
      fineCode: json['fineCode'] ?? '',
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

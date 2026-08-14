// Represents the structure of a single transaction from the API response

class Transaction {
  final int id;
  final TransactionGuest guest;
  final List<TransactionService> services;
  final List<TransactionFine> fines;
  final TransactionRoom room;
  /// Нормализованная итоговая сумма транзакции (в копейках).
  ///
  /// В текущем ответе API стоимость проживания приходит как
  /// `room.totalPrice`, а стоимость дополнительных позиций — в их
  /// `totalPrice`. Если сервер когда-нибудь начнёт присылать корневой
  /// `totalPrice`, он будет использован напрямую.
  final int totalPrice;
  final String paymentType;
  final DateTime? paymentDateTime;
  final String? rrn;
  final int? receiptNumber;
  final bool sentTo1c;
  final bool sentSuccessfully;
  final String? errorMessage;

  Transaction({
    required this.id,
    required this.guest,
    required this.services,
    required this.fines,
    required this.room,
    required this.totalPrice,
    required this.paymentType,
    this.paymentDateTime,
    this.rrn,
    this.receiptNumber,
    required this.sentTo1c,
    required this.sentSuccessfully,
    this.errorMessage,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List? ?? const [])
        .map((s) => TransactionService.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
    final fines = (json['fines'] as List? ?? const [])
        .map((f) => TransactionFine.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList();
    final room = TransactionRoom.fromJson(
      Map<String, dynamic>.from(json['room'] as Map),
    );

    return Transaction(
      id: _asInt(json['id']) ?? 0,
      guest: TransactionGuest.fromJson(
        Map<String, dynamic>.from(json['guest'] as Map),
      ),
      services: services,
      fines: fines,
      room: room,
      totalPrice: _asInt(json['totalPrice']) ??
          _fallbackTransactionTotalPrice(room, services, fines),
      paymentType: json['paymentType']?.toString() ?? '',
      paymentDateTime: _parseTransactionDateTime(json),
      rrn: json['rrn']?.toString(),
      receiptNumber: _asInt(json['receiptNumber']),
      sentTo1c: json['sentTo1c'] ?? false,
      sentSuccessfully: json['sentSuccessfully'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  int get servicesTotalPrice =>
      services.fold<int>(0, (sum, service) => sum + service.totalPrice);

  int get finesTotalPrice =>
      fines.fold<int>(0, (sum, fine) => sum + fine.totalPrice);

  /// Стоимость проживания для отображения отдельной строкой.
  ///
  /// Если `room.totalPrice` отсутствует, берём разницу между нормализованным
  /// итогом и дополнительными позициями. Для чистого проживания старого
  /// ответа последним резервом остаётся `price × countDays`.
  int get roomTotalPrice {
    final roomTotal = room.totalPrice;
    if (roomTotal != null && roomTotal > 0) return roomTotal;

    final derivedRoomTotal = totalPrice - servicesTotalPrice - finesTotalPrice;
    if (derivedRoomTotal > 0) return derivedRoomTotal;

    if (services.isNotEmpty || fines.isNotEmpty) return roomTotal ?? 0;

    final days = room.countDays == null || room.countDays! < 1 ? 1 : room.countDays!;
    return room.price * days;
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return null;
  return int.tryParse(value.toString());
}

int _fallbackTransactionTotalPrice(
  TransactionRoom room,
  List<TransactionService> services,
  List<TransactionFine> fines,
) {
  final days = room.countDays == null || room.countDays! < 1 ? 1 : room.countDays!;
  final hasAdditionalItems = services.isNotEmpty || fines.isNotEmpty;
  final roomTotal = room.totalPrice != null && room.totalPrice! > 0
      ? room.totalPrice!
      : hasAdditionalItems
          ? 0
          : room.price * days;
  final servicesTotal = services.fold<int>(0, (sum, service) => sum + service.totalPrice);
  final finesTotal = fines.fold<int>(0, (sum, fine) => sum + fine.totalPrice);
  return roomTotal + servicesTotal + finesTotal;
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
      id: _asInt(json['id']) ?? 0,
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
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      price: _asInt(json['price']) ?? 0,
      tax: _asInt(json['tax']) ?? 0,
      count: _asInt(json['count']) ?? 0,
      duration: _asInt(json['duration']), // Will be null if not present
      serviceCode: json['serviceCode'] ?? '',
      totalPrice: _asInt(json['totalPrice']) ?? 0,
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
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      price: _asInt(json['price']) ?? 0,
      totalPrice: _asInt(json['totalPrice']) ?? 0,
      count: _asInt(json['count']) ?? 0,
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
      number: json['number']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      building: _asInt(json['building']) ?? 0,
      countDays: _asInt(json['countDays']),
      price: _asInt(json['price']) ?? 0,
      totalPrice: _asInt(json['totalPrice']),
    );
  }
}

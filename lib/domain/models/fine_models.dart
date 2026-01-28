// ============================================
// lib/domain/models/fine_models.dart
// ============================================

/// Enum для типов штрафов
enum FineType {
  violationRules('violationRules'),
  damageToProperty('damageToProperty');

  final String value;
  const FineType(this.value);

  static FineType fromString(String value) {
    switch (value) {
      case 'violationRules':
        return FineType.violationRules;
      case 'damageToProperty':
        return FineType.damageToProperty;
      default:
        throw ArgumentError('Unknown fine type: $value');
    }
  }

  String toReadableString() {
    switch (this) {
      case FineType.violationRules:
        return 'Нарушение правил';
      case FineType.damageToProperty:
        return 'Порча имущества';
    }
  }
}

/// Модель штрафа
class Fine {
  final int id;
  final String name;
  final int price;
  final FineType type;
  final String code;

  Fine({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.code,
  });

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      type: FineType.fromString(json['type'] as String),
      code: json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'type': type.value,
      'code': code,
    };
  }

  Fine copyWith({
    int? id,
    String? name,
    int? price,
    FineType? type,
    String? code,
  }) {
    return Fine(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      type: type ?? this.type,
      code: code ?? this.code,
    );
  }
}

/// Request модель для создания штрафа
class CreateFineRequest {
  final String name;
  final int price;
  final FineType type;
  final String code;

  CreateFineRequest({
    required this.name,
    required this.price,
    required this.type,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'type': type.value,
      'code': code,
    };
  }
}

/// Request модель для обновления штрафа
class UpdateFineRequest {
  final int id;
  final String name;
  final int price;
  final FineType type;
  final String code;

  UpdateFineRequest({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'type': type.value,
      'code': code,
    };
  }
}

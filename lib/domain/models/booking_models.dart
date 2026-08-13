import 'package:motel/data/models/room_model.dart';

// ============================================
// lib/domain/models/booking_models.dart
// ============================================

// Перечисление всех шагов в процессе бронирования
enum BookingStep {
  buildingSelection,
  roomTypeSelection,
  roomSelection,
  guestInfo,
  categorySelection,
  period, // Выбор дат для проживания
  itemSelection,
  payment,
  confirmation,
  paymentExecution, // Выполнение платежа с таймером
  paymentError,
  success,
}

// Категории бронирования
enum BookingCategory {
  unknown,
  accommodation, // Проживание
  services, // Услуги
  ruleViolationPenalty, // Штраф за нарушение правил
  propertyDamagePenalty, // Штраф за порчу имущества
}

// Типы комнат (по количеству мест)
enum RoomType {
  all,
  fourBed,   // 4 места
  sixBed,    // 6 мест
  eightBed,  // 8 мест
}

// Расширение для преобразования RoomType в строку для API
extension RoomTypeExtension on RoomType {
  String toApiString() {
    switch (this) {
      case RoomType.fourBed:
        return 'fourBed';
      case RoomType.sixBed:
        return 'sixBed';
      case RoomType.eightBed:
        return 'eightBed';
      case RoomType.all:
        return 'all';
    }
  }
}

// Модель корпуса
class Building {
  final String id;
  final String name;

  Building({
    required this.id,
    required this.name,
  });
}


// Класс для элемента выбора (услуга, штраф и т.д.)
class BookingItem {
  final String id;
  final String name;
  final int price;
  final int tax; // Налоговая ставка в процентах
  final BookingCategory category;
  final bool isCountable; // Можно задать количество
  final bool isDuration; // Услуга на определенное количество дней
  int quantity; // Количество (для isCountable) или дни (для isDuration)

  BookingItem({
    required this.id,
    required this.name,
    required this.price,
    required this.tax,
    required this.category,
    this.isCountable = false,
    this.isDuration = false,
    this.quantity = 1,
  });

  // Итоговая стоимость с учетом количества/дней
  int get totalPrice => price * quantity;
}

// Основной класс, хранящий все данные о текущем бронировании
class BookingData {
  Building? selectedBuilding;
  RoomType? selectedRoomType;
  Room? selectedRoom;
  BookingCategory selectedCategory = BookingCategory.unknown;
  List<BookingItem> selectedItems = []; // Множественный выбор
  DateTime? checkInDate;
  DateTime? checkOutDate;
  String? lastName;
  String? firstName;
  String? middleName;
  String? phoneNumber;
  String? paymentMethod;
  int? calculatedRoomPrice; // Цена проживания, полученная с сервера

  int get totalNights {
    if (checkInDate == null || checkOutDate == null || checkOutDate!.isBefore(checkInDate!)) return 0;
    final nights = checkOutDate!.difference(checkInDate!).inDays;
    return nights > 0 ? nights : 1;
  }

  bool get hasValidStayPeriod => totalNights > 0 && calculatedRoomPrice != null;

  int get totalPrice {
    if (selectedCategory == BookingCategory.accommodation && selectedRoom != null) {
      // Используем ТОЛЬКО рассчитанную цену с сервера
      int basePrice = calculatedRoomPrice ?? 0;

      // Добавляем цену выбранных услуг с учетом количества
      int itemsPrice = selectedItems.fold(0, (sum, item) => sum + item.totalPrice);
      return basePrice + itemsPrice;
    }

    // Для остальных категорий суммируем цены выбранных элементов с учетом количества
    return selectedItems.fold(0, (sum, item) => sum + item.totalPrice);
  }
}

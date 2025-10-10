// ============================================
// lib/domain/models/booking_models.dart
// ============================================

// Перечисление всех шагов в процессе бронирования
enum BookingStep {
  buildingSelection,
  roomSelection,
  guestInfo,
  categorySelection,
  period, // Выбор дат для проживания
  itemSelection,
  payment,
  confirmation,
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

// Типы комнат
enum RoomType {
  all,
  standard,
  comfort,
  lux,
  suite,
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

// Модель комнаты
class Room {
  final String id;
  final String name; // Номер комнаты, например, "101"
  final String buildingId; // ID корпуса
  final RoomType type; // Тип комнаты

  Room({
    required this.id,
    required this.name,
    required this.buildingId,
    required this.type,
  });
}

// Класс для элемента выбора (услуга, штраф и т.д.)
class BookingItem {
  final String id;
  final String name;
  final int price;
  final BookingCategory category;

  BookingItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });
}

// Основной класс, хранящий все данные о текущем бронировании
class BookingData {
  Building? selectedBuilding;
  Room? selectedRoom;
  BookingCategory selectedCategory = BookingCategory.unknown;
  List<BookingItem> selectedItems = []; // Множественный выбор
  DateTime checkInDate = DateTime.now();
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
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
    if (selectedCategory == BookingCategory.accommodation && selectedRoom != null) {
      const int pricePerNight = 3000;
      int basePrice = pricePerNight * totalNights;

      // Добавляем цену выбранных услуг
      int itemsPrice = selectedItems.fold(0, (sum, item) => sum + item.price);
      return basePrice + itemsPrice;
    }

    // Для остальных категорий просто суммируем цены выбранных элементов
    return selectedItems.fold(0, (sum, item) => sum + item.price);
  }
}
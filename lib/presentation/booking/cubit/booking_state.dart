// ============================================
// lib/presentation/booking/cubit/booking_state.dart
// ============================================

import 'package:motel/domain/models/booking_models.dart';

/// Состояние процесса бронирования
class BookingState {
  final BookingDataState bookingData;
  final int currentStepIndex;
  final bool isBookingSuccessful;

  BookingState({
    BookingDataState? bookingData,
    this.currentStepIndex = 0,
    this.isBookingSuccessful = false,
  }) : bookingData = bookingData ?? BookingDataState();

  /// Текущий шаг бронирования
  BookingStep get currentStep => steps[currentStepIndex];

  /// Список шагов с учетом выбранной категории
  List<BookingStep> get steps {
    final stepList = [
      BookingStep.buildingSelection,
      BookingStep.roomSelection,
      BookingStep.guestInfo,
      BookingStep.categorySelection,
    ];

    if (bookingData.selectedCategory == BookingCategory.accommodation) {
      stepList.add(BookingStep.period);
    } else if (bookingData.selectedCategory == BookingCategory.services ||
        bookingData.selectedCategory == BookingCategory.ruleViolationPenalty ||
        bookingData.selectedCategory == BookingCategory.propertyDamagePenalty) {
      stepList.add(BookingStep.itemSelection);
    }

    stepList.addAll([BookingStep.payment, BookingStep.confirmation, BookingStep.paymentExecution]);

    if (isBookingSuccessful) {
      stepList.add(BookingStep.success);
    }
    return stepList;
  }

  BookingState copyWith({
    BookingDataState? bookingData,
    int? currentStepIndex,
    bool? isBookingSuccessful,
  }) {
    return BookingState(
      bookingData: bookingData ?? this.bookingData,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isBookingSuccessful: isBookingSuccessful ?? this.isBookingSuccessful,
    );
  }
}

/// Wrapper для BookingData с поддержкой copyWith
class BookingDataState {
  final BookingData _data;

  BookingDataState([BookingData? data]) : _data = data ?? BookingData();

  Building? get selectedBuilding => _data.selectedBuilding;
  Room? get selectedRoom => _data.selectedRoom;
  BookingCategory get selectedCategory => _data.selectedCategory;
  List<BookingItem> get selectedItems => _data.selectedItems;
  DateTime get checkInDate => _data.checkInDate;
  DateTime get checkOutDate => _data.checkOutDate;
  String? get lastName => _data.lastName;
  String? get firstName => _data.firstName;
  String? get middleName => _data.middleName;
  String? get paymentMethod => _data.paymentMethod;
  int? get calculatedRoomPrice => _data.calculatedRoomPrice;

  int get totalNights => _data.totalNights;
  int get totalPrice => _data.totalPrice;

  BookingData get data => _data;

  BookingDataState copyWith({
    Building? selectedBuilding,
    Room? selectedRoom,
    BookingCategory? selectedCategory,
    List<BookingItem>? selectedItems,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? lastName,
    String? firstName,
    String? middleName,
    String? paymentMethod,
    int? calculatedRoomPrice,
  }) {
    final newData = BookingData()
      ..selectedBuilding = selectedBuilding ?? _data.selectedBuilding
      ..selectedRoom = selectedRoom ?? _data.selectedRoom
      ..selectedCategory = selectedCategory ?? _data.selectedCategory
      ..selectedItems = selectedItems ?? List.from(_data.selectedItems)
      ..checkInDate = checkInDate ?? _data.checkInDate
      ..checkOutDate = checkOutDate ?? _data.checkOutDate
      ..lastName = lastName ?? _data.lastName
      ..firstName = firstName ?? _data.firstName
      ..middleName = middleName ?? _data.middleName
      ..paymentMethod = paymentMethod ?? _data.paymentMethod
      ..calculatedRoomPrice = calculatedRoomPrice ?? _data.calculatedRoomPrice;

    return BookingDataState(newData);
  }
}

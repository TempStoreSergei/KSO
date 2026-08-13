// ============================================
// lib/presentation/booking/cubit/booking_state.dart
// ============================================

import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/data/models/room_model.dart';

const Object _notProvided = Object();

enum BookingStatus { initial, loading, success, failure, paymentError }

class BookingState {
  final BookingDataState bookingData;
  final int currentStepIndex;
  final BookingStatus status;
  final Map<String, List<Room>> rooms;

  BookingState({
    BookingDataState? bookingData,
    this.currentStepIndex = 0,
    this.status = BookingStatus.initial,
    this.rooms = const {},
  }) : bookingData = bookingData ?? BookingDataState();

  BookingStep get currentStep => steps[currentStepIndex];

  List<BookingStep> get steps {
    final stepList = [
      BookingStep.buildingSelection,
      BookingStep.roomTypeSelection,
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

    stepList.addAll([
      BookingStep.payment,
      BookingStep.confirmation,
      BookingStep.paymentExecution
    ]);

    if (status == BookingStatus.success) {
      stepList.add(BookingStep.success);
    } else if (status == BookingStatus.paymentError) {
      stepList.add(BookingStep.paymentError);
    }

    return stepList;
  }

  BookingState copyWith({
    BookingDataState? bookingData,
    int? currentStepIndex,
    BookingStatus? status,
    Map<String, List<Room>>? rooms,
  }) {
    return BookingState(
      bookingData: bookingData ?? this.bookingData,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
    );
  }
}

/// Wrapper для BookingData с поддержкой copyWith
class BookingDataState {
  final BookingData _data;

  BookingDataState([BookingData? data]) : _data = data ?? BookingData();

  Building? get selectedBuilding => _data.selectedBuilding;
  RoomType? get selectedRoomType => _data.selectedRoomType;
  Room? get selectedRoom => _data.selectedRoom;
  BookingCategory get selectedCategory => _data.selectedCategory;
  List<BookingItem> get selectedItems => _data.selectedItems;
  DateTime? get checkInDate => _data.checkInDate;
  DateTime? get checkOutDate => _data.checkOutDate;
  String? get lastName => _data.lastName;
  String? get firstName => _data.firstName;
  String? get middleName => _data.middleName;
  String? get phoneNumber => _data.phoneNumber;
  String? get paymentMethod => _data.paymentMethod;
  int? get calculatedRoomPrice => _data.calculatedRoomPrice;

  int get totalNights => _data.totalNights;
  int get totalPrice => _data.totalPrice;
  bool get hasValidStayPeriod => _data.hasValidStayPeriod;

  BookingData get data => _data;

  BookingDataState copyWith({
    Building? selectedBuilding,
    RoomType? selectedRoomType,
    Room? selectedRoom,
    BookingCategory? selectedCategory,
    List<BookingItem>? selectedItems,
    Object? checkInDate = _notProvided,
    Object? checkOutDate = _notProvided,
    String? lastName,
    String? firstName,
    String? middleName,
    String? phoneNumber,
    String? paymentMethod,
    Object? calculatedRoomPrice = _notProvided,
    bool forceNullRoom = false,
  }) {
    final newData = BookingData()
      ..selectedBuilding = selectedBuilding ?? _data.selectedBuilding
      ..selectedRoomType = selectedRoomType ?? _data.selectedRoomType
      ..selectedRoom = forceNullRoom ? null : selectedRoom ?? _data.selectedRoom
      ..selectedCategory = selectedCategory ?? _data.selectedCategory
      ..selectedItems = selectedItems ?? List.from(_data.selectedItems)
      ..checkInDate = identical(checkInDate, _notProvided) ? _data.checkInDate : checkInDate as DateTime?
      ..checkOutDate = identical(checkOutDate, _notProvided) ? _data.checkOutDate : checkOutDate as DateTime?
      ..lastName = lastName ?? _data.lastName
      ..firstName = firstName ?? _data.firstName
      ..middleName = middleName ?? _data.middleName
      ..phoneNumber = phoneNumber ?? _data.phoneNumber
      ..paymentMethod = paymentMethod ?? _data.paymentMethod
      ..calculatedRoomPrice = identical(calculatedRoomPrice, _notProvided)
          ? _data.calculatedRoomPrice
          : calculatedRoomPrice as int?;

    return BookingDataState(newData);
  }
}

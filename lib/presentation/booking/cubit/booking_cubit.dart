import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart'; // Импортируем ApiClient
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';
import 'package:motel/domain/usecases/get_rooms.dart';
import 'package:motel/data/models/room_model.dart';
import 'package:motel/core/services/metrics_service.dart';

class BookingCubit extends Cubit<BookingState> {
  final GetRooms _getRooms;
  final MetricsService _metricsService;
  final ApiClient _apiClient = ApiClient.instance; // Получаем инстанс ApiClient

  BookingCubit(this._getRooms, this._metricsService) : super(BookingState());

  Future<void> loadRooms() async {
    emit(state.copyWith(status: BookingStatus.loading));
    try {
      final rooms = await _getRooms();
      emit(state.copyWith(status: BookingStatus.success, rooms: rooms));
    } catch (e) {
      emit(state.copyWith(status: BookingStatus.failure));
    }
  }

  void setBuilding(Building? building) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedBuilding: building),
    ));
    if (building != null) {
      _metricsService.recordBuildingSelection(building.id);
      loadRooms();
    }
  }

  void setRoomType(RoomType roomType) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedRoomType: roomType, forceNullRoom: true),
    ));
  }

  Future<void> setRoom(Room? room) async {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedRoom: room),
    ));
    if (room != null) {
      _metricsService.recordRoomSelection('${room.roomNumber}-${room.bedNumber}');

      // Если уже выбраны даты, сразу рассчитываем цену
      final data = state.bookingData;
      final nights = data.totalNights;
      if (nights > 0) {
        try {
          final price = await _apiClient.calculateRoomPrice(
            roomType: room.type.toApiString(),
            roomBuilding: int.tryParse(room.buildingId) ?? 0,
            countDays: nights,
          );
          setCalculatedRoomPrice(price);
        } catch (e) {
          print('Ошибка при расчете цены: $e');
          setCalculatedRoomPrice(null);
        }
      }
    }
  }

  void setGuestData({String? lastName, String? firstName, String? middleName, String? phoneNumber}) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(
        lastName: lastName,
        firstName: firstName,
        middleName: middleName,
        phoneNumber: phoneNumber,
      ),
    ));
  }

  void setCategory(BookingCategory category) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(
        selectedCategory: category,
        selectedItems: [],
      ),
    ));
  }

  Future<void> setDates(DateTime? checkIn, DateTime? checkOut) async {
    // Сначала обновляем состояние с новыми датами
    final tempState = state.bookingData.copyWith(
      checkInDate: checkIn,
      checkOutDate: checkOut,
    );
    emit(state.copyWith(bookingData: tempState));

    // Проверяем, достаточно ли данных для вызова API
    final data = state.bookingData;
    final room = data.selectedRoom;
    final nights = data.totalNights;

    if (room != null && nights > 0) {
      try {
        final price = await _apiClient.calculateRoomPrice(
          roomType: room.type.toApiString(),
          roomBuilding: int.tryParse(room.buildingId) ?? 0,
          countDays: nights,
        );
        // Обновляем состояние с рассчитанной ценой
        setCalculatedRoomPrice(price);
      } catch (e) {
        print('Ошибка при расчете цены: $e');
        // Можно обработать ошибку, например, сбросить цену
        setCalculatedRoomPrice(null);
      }
    }
  }

  void setSelectedItems(List<BookingItem> items) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedItems: items),
    ));
  }

  void setPaymentMethod(String? method) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(paymentMethod: method),
    ));
  }

  void setCalculatedRoomPrice(int? price) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(calculatedRoomPrice: price),
    ));
  }

  void nextStep() {
    if (state.currentStepIndex < state.steps.length - 1) {
      emit(state.copyWith(currentStepIndex: state.currentStepIndex + 1));
    }
  }

  void previousStep() {
    if (state.currentStepIndex > 0) {
      final currentStep = state.currentStep;
      BookingDataState updatedData = state.bookingData;

      if (currentStep == BookingStep.roomSelection) {
        updatedData = updatedData.copyWith(selectedRoomType: RoomType.all, forceNullRoom: true);
      } else if (currentStep == BookingStep.guestInfo) {
        updatedData = updatedData.copyWith(forceNullRoom: true);
      } else if (currentStep == BookingStep.itemSelection) {
        updatedData = updatedData.copyWith(selectedItems: []);
      } else if (currentStep == BookingStep.categorySelection) {
        updatedData = updatedData.copyWith(
          selectedCategory: BookingCategory.unknown,
          selectedItems: [],
        );
      }

      emit(state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
        bookingData: updatedData,
      ));
    }
  }

  void markBookingSuccessful() {
    final successState = state.copyWith(status: BookingStatus.success);
    final successStepIndex = successState.steps.indexOf(BookingStep.success);

    if (successStepIndex != -1) {
      emit(successState.copyWith(currentStepIndex: successStepIndex));
    } else {
      emit(successState);
    }
  }

  void setPaymentError() {
    final errorState = state.copyWith(status: BookingStatus.paymentError);
    final errorStepIndex = errorState.steps.indexOf(BookingStep.paymentError);

    if (errorStepIndex != -1) {
      emit(errorState.copyWith(currentStepIndex: errorStepIndex));
    } else {
      emit(errorState);
    }
  }

  // Private methods
  bool canProceed() {
    final data = state.bookingData;
    switch (state.currentStep) {

      case BookingStep.buildingSelection:
        return data.selectedBuilding != null;
      case BookingStep.roomTypeSelection:
        return data.selectedRoomType != null && data.selectedRoomType != RoomType.all;
      case BookingStep.roomSelection:
        return data.selectedRoom != null;
      case BookingStep.guestInfo:
        return (data.lastName?.isNotEmpty ?? false) && (data.firstName?.isNotEmpty ?? false);
      case BookingStep.categorySelection:
        return data.selectedCategory != BookingCategory.unknown;
      case BookingStep.period:


        return data.checkInDate != null && data.checkOutDate != null;
      case BookingStep.itemSelection:
        if (data.selectedCategory == BookingCategory.accommodation) {
          return true;
        }
        return data.selectedItems.isNotEmpty;
      case BookingStep.payment:
        return data.paymentMethod != null;
      case BookingStep.confirmation:
        return true;
      case BookingStep.paymentExecution:
        return false;
      case BookingStep.paymentError:
        return false;
      case BookingStep.success:
        return false;
    }
  }
}
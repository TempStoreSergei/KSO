// ============================================
// lib/presentation/booking/cubit/booking_cubit.dart
// ============================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';

/// Cubit для управления состоянием процесса бронирования
class BookingCubit extends Cubit<BookingState> {
  BookingCubit() : super(BookingState());

  /// Устанавливает выбранный корпус
  void setBuilding(Building? building) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedBuilding: building),
    ));
  }

  /// Устанавливает выбранную комнату
  void setRoom(Room? room) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedRoom: room),
    ));
  }

  /// Устанавливает тип комнаты
  void setRoomType(RoomType type) {
    if (state.bookingData.selectedRoom != null) {
      final updatedRoom = Room(
        id: state.bookingData.selectedRoom!.id,
        name: state.bookingData.selectedRoom!.name,
        buildingId: state.bookingData.selectedRoom!.buildingId,
        type: type,
      );
      setRoom(updatedRoom);
    }
  }

  /// Устанавливает данные гостя
  void setGuestData({String? lastName, String? firstName, String? middleName}) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(
        lastName: lastName,
        firstName: firstName,
        middleName: middleName,
      ),
    ));
  }

  /// Устанавливает выбранную категорию
  void setCategory(BookingCategory category) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(
        selectedCategory: category,
        selectedItems: [], // Сбрасываем выбранные элементы
      ),
    ));
  }

  /// Устанавливает даты заезда/выезда
  void setDates(DateTime checkIn, DateTime checkOut) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(
        checkInDate: checkIn,
        checkOutDate: checkOut,
      ),
    ));
  }

  /// Устанавливает выбранные элементы (услуги, штрафы)
  void setSelectedItems(List<BookingItem> items) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(selectedItems: items),
    ));
  }

  /// Устанавливает способ оплаты
  void setPaymentMethod(String? method) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(paymentMethod: method),
    ));
  }

  /// Устанавливает рассчитанную цену проживания
  void setCalculatedRoomPrice(int? price) {
    emit(state.copyWith(
      bookingData: state.bookingData.copyWith(calculatedRoomPrice: price),
    ));
  }

  /// Переходит к следующему шагу
  void nextStep() {
    if (state.currentStepIndex < state.steps.length - 1) {
      emit(state.copyWith(currentStepIndex: state.currentStepIndex + 1));
    }
  }

  /// Возвращается к предыдущему шагу
  void previousStep() {
    if (state.currentStepIndex > 0) {
      // Сбрасываем данные при возврате к определенным шагам
      final currentStep = state.currentStep;

      BookingDataState updatedData = state.bookingData;

      if (currentStep == BookingStep.itemSelection) {
        updatedData = updatedData.copyWith(selectedItems: []);
      } else if (currentStep == BookingStep.categorySelection) {
        updatedData = updatedData.copyWith(
          selectedCategory: BookingCategory.unknown,
          selectedItems: [],
        );
      } else if (currentStep == BookingStep.guestInfo) {
        updatedData = updatedData.copyWith(selectedRoom: null);
      }

      emit(state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
        bookingData: updatedData,
      ));
    }
  }

  /// Помечает бронирование как успешное
  void markBookingSuccessful() {
    emit(state.copyWith(
      isBookingSuccessful: true,
      currentStepIndex: state.currentStepIndex + 1,
    ));
  }

  /// Проверяет, можно ли перейти к следующему шагу
  bool canProceed() {
    final data = state.bookingData;

    switch (state.currentStep) {
      case BookingStep.buildingSelection:
        return data.selectedBuilding != null;
      case BookingStep.roomSelection:
        return data.selectedRoom != null &&
               data.selectedRoom!.type != RoomType.all;
      case BookingStep.guestInfo:
        return (data.lastName?.isNotEmpty ?? false) &&
               (data.firstName?.isNotEmpty ?? false);
      case BookingStep.categorySelection:
        return data.selectedCategory != BookingCategory.unknown;
      case BookingStep.period:
        return true;
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
      case BookingStep.success:
        return false;
    }
  }
}

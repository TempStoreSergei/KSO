import 'package:flutter_test/flutter_test.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/metrics_service.dart';
import 'package:motel/data/models/room_model.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/get_rooms.dart';
import 'package:motel/presentation/booking/cubit/booking_cubit.dart';

void main() {
  test('keeps period and price after payment back and continue', () async {
    final cubit = BookingCubit(
      GetRooms(ApiClient.instance),
      MetricsService(),
    );
    addTearDown(cubit.close);

    final bookingData = cubit.state.bookingData.data
      ..selectedCategory = BookingCategory.accommodation
      ..selectedRoom = Room(
        buildingId: '1',
        roomNumber: '224',
        bedNumber: '1',
        type: RoomType.sixBed,
      )
      ..checkInDate = DateTime(2026, 8, 13)
      ..checkOutDate = DateTime(2026, 8, 20)
      ..calculatedRoomPrice = 420000;

    while (cubit.state.currentStep != BookingStep.payment) {
      cubit.nextStep();
    }

    cubit.previousStep();

    expect(cubit.state.currentStep, BookingStep.period);
    expect(cubit.state.bookingData.checkInDate, DateTime(2026, 8, 13));
    expect(cubit.state.bookingData.checkOutDate, DateTime(2026, 8, 20));
    expect(cubit.state.bookingData.totalNights, 7);
    expect(cubit.state.bookingData.calculatedRoomPrice, 420000);
    expect(cubit.state.bookingData.totalPrice, 420000);
    expect(cubit.canProceed(), isTrue);

    cubit.nextStep();

    expect(cubit.state.currentStep, BookingStep.payment);
    expect(bookingData.totalNights, 7);
    expect(bookingData.totalPrice, 420000);
  });
}

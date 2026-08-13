import 'package:flutter_test/flutter_test.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/presentation/booking/cubit/booking_state.dart';

void main() {
  group('BookingDataState.copyWith', () {
    test('clears checkout and calculated price when a new period starts', () {
      final originalData = BookingData()
        ..selectedCategory = BookingCategory.accommodation
        ..checkInDate = DateTime(2026, 8, 13)
        ..checkOutDate = DateTime(2026, 8, 27)
        ..calculatedRoomPrice = 840000;

      final updatedState = BookingDataState(originalData).copyWith(
        checkInDate: DateTime(2026, 8, 28),
        checkOutDate: null,
        calculatedRoomPrice: null,
      );

      expect(updatedState.checkInDate, DateTime(2026, 8, 28));
      expect(updatedState.checkOutDate, isNull);
      expect(updatedState.calculatedRoomPrice, isNull);
      expect(updatedState.totalNights, 0);
      expect(updatedState.totalPrice, 0);
      expect(updatedState.hasValidStayPeriod, isFalse);
    });

    test('preserves nullable values when they are not supplied', () {
      final originalData = BookingData()
        ..checkInDate = DateTime(2026, 8, 13)
        ..checkOutDate = DateTime(2026, 8, 27)
        ..calculatedRoomPrice = 840000;

      final updatedState = BookingDataState(originalData).copyWith();

      expect(updatedState.checkInDate, DateTime(2026, 8, 13));
      expect(updatedState.checkOutDate, DateTime(2026, 8, 27));
      expect(updatedState.calculatedRoomPrice, 840000);
    });
  });

  group('BookingData.hasValidStayPeriod', () {
    test('requires both a valid date range and a calculated price', () {
      final data = BookingData()
        ..checkInDate = DateTime(2026, 8, 13)
        ..checkOutDate = DateTime(2026, 8, 27);

      expect(data.hasValidStayPeriod, isFalse);

      data.calculatedRoomPrice = 840000;

      expect(data.hasValidStayPeriod, isTrue);

      data.checkInDate = DateTime(2026, 8, 28);

      expect(data.hasValidStayPeriod, isFalse);
    });
  });
}

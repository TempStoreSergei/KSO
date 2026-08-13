import 'package:flutter_test/flutter_test.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'package:motel/domain/usecases/save_transaction_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('blocks accommodation save when countDays would be omitted', () async {
    final bookingData = BookingData()
      ..selectedCategory = BookingCategory.accommodation
      ..checkInDate = DateTime(2026, 8, 28)
      ..checkOutDate = DateTime(2026, 8, 27)
      ..calculatedRoomPrice = 840000;
    final useCase = SaveTransactionUseCase(ApiClient.instance);

    await expectLater(
      useCase.call(bookingData),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('корректного периода'),
        ),
      ),
    );
  });
}

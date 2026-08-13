import 'package:flutter_test/flutter_test.dart';
import 'package:motel/domain/models/save_transaction_request.dart';

void main() {
  group('RoomInfoRequest', () {
    test('includes a positive countDays in JSON', () {
      final request = RoomInfoRequest(
        number: '224-1',
        type: 'sixBed',
        building: 1,
        countDays: 14,
      );

      expect(request.toJson()['countDays'], 14);
    });

    test('omits countDays when it is not applicable', () {
      final request = RoomInfoRequest(
        number: '224-1',
        type: 'sixBed',
        building: 1,
      );

      expect(request.toJson(), isNot(contains('countDays')));
    });
  });
}

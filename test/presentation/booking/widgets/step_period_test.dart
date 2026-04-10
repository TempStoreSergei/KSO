import 'package:flutter_test/flutter_test.dart';
import 'package:motel/presentation/booking/widgets/step_period.dart';

void main() {
  group('calculateStepPeriodMaxSelectableDate', () {
    test('returns a date 31 days ahead instead of the first day of next month', () {
      final maxSelectableDate = calculateStepPeriodMaxSelectableDate(
        DateTime(2026, 4, 10),
      );

      expect(maxSelectableDate, DateTime(2026, 5, 11));
    });
  });
}

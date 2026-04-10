import 'package:flutter_test/flutter_test.dart';
import 'package:motel/domain/models/system_settings.dart';

void main() {
  group('SystemSettings', () {
    test('parses payment methods from system settings response', () {
      final settings = SystemSettings.fromJson({
        'devices': {
          'fiscal': true,
          'scanner': false,
          'cashSystem': true,
          'acquiring': true,
        },
        'sbpPayment': {
          'isEnable': false,
          'qrUrl': 'https://qr.nspk.ru/payment/v1/',
        },
      });

      expect(settings.devices.cashSystem, isTrue);
      expect(settings.devices.acquiring, isTrue);
      expect(settings.sbpPayment.isEnable, isFalse);
      expect(settings.availablePaymentMethods, ['Карта', 'Наличные']);
    });

    test('includes sbp when it is enabled', () {
      final settings = SystemSettings.fromJson({
        'devices': {
          'fiscal': true,
          'scanner': false,
          'cashSystem': false,
          'acquiring': false,
        },
        'sbpPayment': {
          'isEnable': true,
          'qrUrl': 'https://qr.nspk.ru/payment/v1/test',
        },
      });

      expect(settings.availablePaymentMethods, ['СБП']);
    });
  });
}

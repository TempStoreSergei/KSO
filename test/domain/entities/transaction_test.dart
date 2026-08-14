import 'package:flutter_test/flutter_test.dart';
import 'package:motel/domain/entities/transaction.dart';

void main() {
  Map<String, dynamic> transactionJson({
    int? totalPrice,
    int? roomTotalPrice,
  }) {
    return {
      'id': 3621,
      'guest': {
        'id': 42,
        'firstName': 'Станислав',
        'lastName': 'Ясинский',
        'surname': '',
      },
      'room': {
        'number': '224-1',
        'type': 'sixBed',
        'building': 1,
        'countDays': 3,
        'price': 150000,
        'totalPrice': roomTotalPrice,
      },
      'services': <Map<String, dynamic>>[],
      'fines': <Map<String, dynamic>>[],
      'paymentType': 'Он-лайн платёж',
      if (totalPrice != null) 'totalPrice': totalPrice,
    };
  }

  test('supports an optional root totalPrice override', () {
    final transaction = Transaction.fromJson(
      transactionJson(totalPrice: 450000),
    );

    expect(transaction.totalPrice, 450000);
    expect(transaction.roomTotalPrice, 450000);
  });

  test('uses room.totalPrice for a multi-day accommodation transaction', () {
    final transaction = Transaction.fromJson(
      transactionJson(roomTotalPrice: 450000),
    );

    expect(transaction.totalPrice, 450000);
    expect(transaction.roomTotalPrice, 450000);
  });

  test('falls back to all booked days when legacy response has no totalPrice', () {
    final transaction = Transaction.fromJson(transactionJson());

    expect(transaction.totalPrice, 450000);
    expect(transaction.roomTotalPrice, 450000);
    expect(transaction.rrn, isNull);
    expect(transaction.receiptNumber, isNull);
  });

  test('parses optional payment identifiers', () {
    final transaction = Transaction.fromJson({
      ...transactionJson(),
      'rrn': '1234567891234',
      'receiptNumber': 12345,
    });

    expect(transaction.rrn, '1234567891234');
    expect(transaction.receiptNumber, 12345);
  });
}

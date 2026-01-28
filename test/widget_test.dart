import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motel/main.dart';
import 'package:motel/presentation/lock_screen/lock_screen.dart';

void main() {
  testWidgets('MyApp builds and shows LockScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.byType(LockScreen), findsOneWidget);
  });
}

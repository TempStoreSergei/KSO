import 'package:flutter/widgets.dart';

class AppNavigator {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void popToRoot() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
  }
}


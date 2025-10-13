// ============================================
// lib/presentation/booking/managers/inactivity_manager.dart
// ============================================

import 'dart:async';
import 'package:flutter/widgets.dart';

/// Менеджер для управления таймером бездействия
class InactivityManager {
  Timer? _inactivityTimer;
  final Duration inactivityDuration;
  final VoidCallback onTimeout;

  InactivityManager({
    this.inactivityDuration = const Duration(seconds: 60),
    required this.onTimeout,
  });

  /// Запускает таймер бездействия
  void start() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, onTimeout);
  }

  /// Сбрасывает таймер бездействия
  void reset() {
    start();
  }

  /// Останавливает таймер
  void stop() {
    _inactivityTimer?.cancel();
  }

  /// Освобождает ресурсы
  void dispose() {
    _inactivityTimer?.cancel();
  }
}

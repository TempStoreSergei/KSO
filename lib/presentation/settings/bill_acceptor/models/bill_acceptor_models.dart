// ============================================
// lib/presentation/settings/bill_acceptor/models/bill_acceptor_models.dart
// ============================================

/// Модель статуса кассовой системы
class CashSystemStatus {
  final int maxBillCount;
  final int currentBillCount;
  final double fillPercentage;

  CashSystemStatus({
    required this.maxBillCount,
    required this.currentBillCount,
    required this.fillPercentage,
  });

  factory CashSystemStatus.fromJson(Map<String, dynamic> json) {
    final maxCount = json['maxBillCount'] ?? 0;
    final currentCount = json['billCount'] ?? 0;

    return CashSystemStatus(
      maxBillCount: maxCount,
      currentBillCount: currentCount,
      fillPercentage: maxCount > 0 ? (currentCount / maxCount * 100) : 0,
    );
  }

  int get remainingSpace => maxBillCount - currentBillCount;

  CashSystemStatus copyWith({
    int? maxBillCount,
    int? currentBillCount,
    double? fillPercentage,
  }) {
    return CashSystemStatus(
      maxBillCount: maxBillCount ?? this.maxBillCount,
      currentBillCount: currentBillCount ?? this.currentBillCount,
      fillPercentage: fillPercentage ?? this.fillPercentage,
    );
  }
}

/// Модель события теста
class TestEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  TestEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  TestEvent copyWith({
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return TestEvent(
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Статус тестирования
enum TestingStatus {
  inactive,
  active,
  completed,
}

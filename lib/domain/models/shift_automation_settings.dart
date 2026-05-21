enum ShiftOpenMode {
  disabled,
  byTime,
  firstReceipt,
}

extension ShiftOpenModeX on ShiftOpenMode {
  String get storageValue {
    switch (this) {
      case ShiftOpenMode.byTime:
        return 'by_time';
      case ShiftOpenMode.firstReceipt:
        return 'first_receipt';
      case ShiftOpenMode.disabled:
        return 'disabled';
    }
  }

  static ShiftOpenMode fromStorageValue(String? value) {
    switch (value) {
      case 'by_time':
        return ShiftOpenMode.byTime;
      case 'first_receipt':
        return ShiftOpenMode.firstReceipt;
      default:
        return ShiftOpenMode.disabled;
    }
  }
}

class ShiftAutomationSettings {
  final ShiftOpenMode openMode;
  final String? autoOpenTime;
  final String? autoCloseTime;
  final bool acquiringReceiptReportOnClose;
  final String? lastAutomationError;
  final DateTime? lastAutomationAttemptAt;

  const ShiftAutomationSettings({
    this.openMode = ShiftOpenMode.firstReceipt,
    this.autoOpenTime,
    this.autoCloseTime,
    this.acquiringReceiptReportOnClose = true,
    this.lastAutomationError,
    this.lastAutomationAttemptAt,
  });

  bool get shouldOpenByTime =>
      openMode == ShiftOpenMode.byTime && autoOpenTime != null;

  bool get shouldOpenOnFirstReceipt => openMode == ShiftOpenMode.firstReceipt;

  bool get shouldCloseByTime => autoCloseTime != null;

  ShiftAutomationSettings copyWith({
    ShiftOpenMode? openMode,
    String? autoOpenTime,
    bool clearAutoOpenTime = false,
    String? autoCloseTime,
    bool clearAutoCloseTime = false,
    bool? acquiringReceiptReportOnClose,
    String? lastAutomationError,
    bool clearLastAutomationError = false,
    DateTime? lastAutomationAttemptAt,
  }) {
    return ShiftAutomationSettings(
      openMode: openMode ?? this.openMode,
      autoOpenTime:
          clearAutoOpenTime ? null : autoOpenTime ?? this.autoOpenTime,
      autoCloseTime:
          clearAutoCloseTime ? null : autoCloseTime ?? this.autoCloseTime,
      acquiringReceiptReportOnClose:
          acquiringReceiptReportOnClose ?? this.acquiringReceiptReportOnClose,
      lastAutomationError: clearLastAutomationError
          ? null
          : lastAutomationError ?? this.lastAutomationError,
      lastAutomationAttemptAt:
          lastAutomationAttemptAt ?? this.lastAutomationAttemptAt,
    );
  }
}

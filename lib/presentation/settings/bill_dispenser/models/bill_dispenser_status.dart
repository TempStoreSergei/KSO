class BillDispenserStatus {
  final int upperBoxValue;
  final int lowerBoxValue;
  final int upperBoxCount;
  final int lowerBoxCount;

  BillDispenserStatus({
    required this.upperBoxValue,
    required this.lowerBoxValue,
    required this.upperBoxCount,
    required this.lowerBoxCount,
  });

  factory BillDispenserStatus.fromJson(Map<String, dynamic> json) {
    return BillDispenserStatus(
      upperBoxValue: json['upperBoxValue'] ?? 0,
      lowerBoxValue: json['lowerBoxValue'] ?? 0,
      upperBoxCount: json['upperBoxCount'] ?? 0,
      lowerBoxCount: json['lowerBoxCount'] ?? 0,
    );
  }

  BillDispenserStatus copyWith({
    int? upperBoxValue,
    int? lowerBoxValue,
    int? upperBoxCount,
    int? lowerBoxCount,
  }) {
    return BillDispenserStatus(
      upperBoxValue: upperBoxValue ?? this.upperBoxValue,
      lowerBoxValue: lowerBoxValue ?? this.lowerBoxValue,
      upperBoxCount: upperBoxCount ?? this.upperBoxCount,
      lowerBoxCount: lowerBoxCount ?? this.lowerBoxCount,
    );
  }
}

import 'package:equatable/equatable.dart';
import '../models/bill_dispenser_status.dart';
import '../models/test_status.dart';

abstract class BillDispenserState extends Equatable {
  const BillDispenserState();

  @override
  List<Object?> get props => [];
}

class BillDispenserInitial extends BillDispenserState {}

class BillDispenserLoading extends BillDispenserState {}

class BillDispenserLoaded extends BillDispenserState {
  final BillDispenserStatus status;
  final int newUpperBoxCount;
  final int newLowerBoxCount;
  final int newUpperBoxValue;
  final int newLowerBoxValue;
  final TestStatus testStatus;

  const BillDispenserLoaded({
    required this.status,
    required this.newUpperBoxCount,
    required this.newLowerBoxCount,
    required this.newUpperBoxValue,
    required this.newLowerBoxValue,
    this.testStatus = TestStatus.inactive,
  });

  BillDispenserLoaded copyWith({
    BillDispenserStatus? status,
    int? newUpperBoxCount,
    int? newLowerBoxCount,
    int? newUpperBoxValue,
    int? newLowerBoxValue,
    TestStatus? testStatus,
  }) {
    return BillDispenserLoaded(
      status: status ?? this.status,
      newUpperBoxCount: newUpperBoxCount ?? this.newUpperBoxCount,
      newLowerBoxCount: newLowerBoxCount ?? this.newLowerBoxCount,
      newUpperBoxValue: newUpperBoxValue ?? this.newUpperBoxValue,
      newLowerBoxValue: newLowerBoxValue ?? this.newLowerBoxValue,
      testStatus: testStatus ?? this.testStatus,
    );
  }

  @override
  List<Object?> get props => [
        status,
        newUpperBoxCount,
        newLowerBoxCount,
        newUpperBoxValue,
        newLowerBoxValue,
        testStatus,
      ];
}

class BillDispenserError extends BillDispenserState {
  final String message;

  const BillDispenserError(this.message);

  @override
  List<Object?> get props => [message];
}

class BillDispenserSuccess extends BillDispenserState {
  final String message;
  final BillDispenserStatus status;
  final int newUpperBoxCount;
  final int newLowerBoxCount;
  final int newUpperBoxValue;
  final int newLowerBoxValue;

  const BillDispenserSuccess({
    required this.message,
    required this.status,
    required this.newUpperBoxCount,
    required this.newLowerBoxCount,
    required this.newUpperBoxValue,
    required this.newLowerBoxValue,
  });

  @override
  List<Object?> get props => [
        message,
        status,
        newUpperBoxCount,
        newLowerBoxCount,
        newUpperBoxValue,
        newLowerBoxValue,
      ];
}

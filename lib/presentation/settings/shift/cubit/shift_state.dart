// lib/presentation/settings/shift/cubit/shift_state.dart

import 'package:motel/presentation/settings/shift/models/shift_settings.dart';

abstract class ShiftState {}

class ShiftInitial extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftLoaded extends ShiftState {
  final ShiftSettings settings;

  ShiftLoaded(this.settings);
}

class ShiftError extends ShiftState {
  final String message;

  ShiftError(this.message);
}

class ShiftUpdating extends ShiftState {
  final ShiftSettings settings;

  ShiftUpdating(this.settings);
}

class ShiftValidationError extends ShiftState {
  final String message;
  final ShiftSettings settings;

  ShiftValidationError(this.message, this.settings);
}

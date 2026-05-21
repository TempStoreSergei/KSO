// lib/core/di/service_locator.dart
import 'package:motel/core/services/shift_service.dart';
import 'package:motel/data/repositories/shift_repository_impl.dart';
import 'package:motel/domain/usecases/shift/manage_shift_usecase.dart';

class ServiceLocator {
  ManageShiftUseCase get manageShiftUseCase {
    return ManageShiftUseCase(ShiftRepositoryImpl(shiftService: ShiftService.instance));
  }
  
  ShiftService get shiftService => ShiftService.instance;

  T call<T>() {
    if (T == ManageShiftUseCase) {
      return manageShiftUseCase as T;
    }
    if (T == ShiftService) {
      return shiftService as T;
    }
    throw Exception('Type $T not registered in ServiceLocator');
  }
}

final sl = ServiceLocator();

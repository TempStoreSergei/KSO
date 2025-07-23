import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:motel/domain/entities/service_entity.dart';
import 'package:motel/domain/usecases/get_services_usecase.dart';

part 'services_state.dart';

class ServicesCubit extends Cubit<ServicesState> {
  final GetServicesUseCase getServicesUseCase;

  ServicesCubit({required this.getServicesUseCase}) : super(ServicesInitial());

  /// Метод для запуска загрузки услуг.
  Future<void> fetchServices() async {
    try {
      emit(ServicesLoading());
      final services = await getServicesUseCase();
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServicesError('Не удалось загрузить данные: ${e.toString()}'));
    }
  }
}
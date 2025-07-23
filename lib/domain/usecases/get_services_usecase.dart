import 'package:motel/domain/entities/service_entity.dart';
import 'package:motel/domain/repositories/service_repository.dart';

class GetServicesUseCase {
  final ServiceRepository repository;

  GetServicesUseCase(this.repository);

  /// Выполняет сценарий использования: получение списка услуг.
  Future<List<ServiceEntity>> call() async {
    return await repository.getServices();
  }
}
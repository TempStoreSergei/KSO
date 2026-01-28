import 'package:motel/core/api/api_exceptions.dart';
import 'package:motel/data/datasources/service_remote_data_source.dart';
import 'package:motel/domain/entities/service_entity.dart';
import 'package:motel/domain/repositories/service_repository.dart';

/// Конкретная реализация контракта [ServiceRepository].
class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl({required this.remoteDataSource});

  Future<bool> _handleRequest(Future<void> Function() request) async {
    try {
      await request();
      return true;
    } on ApiException catch (e) {
      print('API Ошибка в ServiceRepositoryImpl: $e');
      return false;
    } catch (e) {
      print('Непредвиденная ошибка в ServiceRepositoryImpl: $e');
      return false;
    }
  }

  @override
  Future<List<ServiceEntity>> getServices() async {
    try {
      final serviceModels = await remoteDataSource.getServices();
      return serviceModels;
    } catch (e) {
      print('Ошибка получения услуг: $e');
      return [];
    }
  }

  @override
  Future<bool> createService({required String name, int? price, required int tax, required bool isCountable, required bool isDuration, required String code}) {
    return _handleRequest(() => remoteDataSource.createService(
      name: name,
      price: price,
      tax: tax,
      isCountable: isCountable,
      isDuration: isDuration,
      code: code,
    ));
  }

  @override
  Future<bool> updateService({required String serviceID, required String name, int? price, required int tax, required bool isCountable, required bool isDuration, required String code}) {
    return _handleRequest(() => remoteDataSource.updateService(
      serviceID: serviceID,
      name: name,
      price: price,
      tax: tax,
      isCountable: isCountable,
      isDuration: isDuration,
      code: code,
    ));
  }

  @override
  Future<bool> deleteService({required String serviceID}) {
    return _handleRequest(() => remoteDataSource.deleteService(serviceID: serviceID));
  }
}
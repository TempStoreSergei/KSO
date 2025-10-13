import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/models/service_model.dart';

/// Абстракция для удаленного источника данных об услугах.
abstract class ServiceRemoteDataSource {
  Future<List<ServiceModel>> getServices();
  Future<void> createService({required String name, int? price, required int tax, required bool isCountable, required bool isDuration});
  Future<void> updateService({required String serviceID, required String name, int? price, required int tax, required bool isCountable, required bool isDuration});
  Future<void> deleteService({required String serviceID});
}

/// Реализация удаленного источника данных, использующая ApiClient.
class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final ApiClient apiClient;

  ServiceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ServiceModel>> getServices() async {
    final response = await apiClient.get('/guests/get_services');
    final List<dynamic> servicesData = response['services'] ?? [];
    return servicesData.map((json) => ServiceModel.fromJson(json)).toList();
  }

  @override
  Future<void> createService({required String name, int? price, required int tax, required bool isCountable, required bool isDuration}) async {
    await apiClient.post(
      '/guests/add_services',
      body: {
        'name': name,
        'price': price,
        'tax': tax,
        'isCountable': isCountable,
        'isDuration': isDuration,
      },
    );
  }

  @override
  Future<void> updateService({required String serviceID, required String name, int? price, required int tax, required bool isCountable, required bool isDuration}) async {
    await apiClient.put(
      '/services/update_service',
      body: {
        'id': serviceID,
        'name': name,
        'price': price,
        'tax': tax,
        'isCountable': isCountable,
        'isDuration': isDuration,
      },
    );
  }

  @override
  Future<void> deleteService({required String serviceID}) async {
    await apiClient.delete(
      '/guests/delete_service?service_id=$serviceID',
    );
  }
}
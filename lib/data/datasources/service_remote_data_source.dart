import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/models/service_model.dart';

/// Абстракция для удаленного источника данных об услугах.
abstract class ServiceRemoteDataSource {
  Future<List<ServiceModel>> getServices();
  Future<void> createService({required String name, int? price, required bool isOneTime});
  Future<void> updateService({required String serviceID, required String name, int? price, required bool isOneTime});
  Future<void> deleteService({required String serviceID});
}

/// Реализация удаленного источника данных, использующая ApiClient.
class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final ApiClient apiClient;

  ServiceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ServiceModel>> getServices() async {
    final response = await apiClient.get('/services/get_services');
    final List<dynamic> servicesData = response['servicesData'];
    return servicesData.map((json) => ServiceModel.fromJson(json)).toList();
  }

  @override
  Future<void> createService({required String name, int? price, required bool isOneTime}) async {
    await apiClient.post(
      '/services/create_service',
      body: {
        'serviceName': name,
        'servicePrice': price,
        'serviceOneTime': isOneTime,
      },
    );
  }

  @override
  Future<void> updateService({required String serviceID, required String name, int? price, required bool isOneTime}) async {
    await apiClient.put(
      '/services/update_service',
      body: {
        'serviceID': serviceID,
        'serviceName': name,
        'servicePrice': price,
        'serviceOneTime': isOneTime,
      },
    );
  }

  @override
  Future<void> deleteService({required String serviceID}) async {
    await apiClient.delete(
      '/services/delete_service',
      body: {
        'serviceID': serviceID,
      },
    );
  }
}
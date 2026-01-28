  import 'package:motel/core/api/api_client.dart';

  class GetClientByNumberUseCase {
    final ApiClient _apiClient;

    GetClientByNumberUseCase(this._apiClient);

    Future<String?> call(String phoneNumber) async {
      return await _apiClient.getClientIdByPhone(phoneNumber);
    }
  }
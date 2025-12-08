import 'package:motel/core/api/api_client.dart';

class UpdateTransactionUseCase {
  final ApiClient _apiClient;

  UpdateTransactionUseCase(this._apiClient);

  Future<void> call({
    required int id,
    required String firstName,
    required String lastName,
    required String surname,
    required String roomNumber,
    required String roomType,
    required int building,
  }) async {
    try {
      await _apiClient.put(
        '/transactions/update_transaction',
        body: {
          'id': id,
          'guest': {
            'firstName': firstName,
            'lastName': lastName,
            'surname': surname,
          },
          'room': {
            'number': roomNumber,
            'type': roomType,
            'building': building,
          },
        },
      );
    } catch (e) {
      throw Exception('Не удалось обновить транзакцию: $e');
    }
  }
}
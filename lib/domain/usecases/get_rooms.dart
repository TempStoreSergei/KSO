import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/booking_models.dart';

class GetRooms {
  final ApiClient _apiClient;

  GetRooms(this._apiClient);

  Future<List<Room>> call() async {
    try {
      final response = await _apiClient.get('/guests/get_rooms');

      if (response['rooms'] != null) {
        final List<dynamic> roomsJson = response['rooms'];
        return roomsJson.map((json) => Room(
          id: json['id'].toString(),
          name: json['name'].toString(),
        )).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Не удалось загрузить комнаты: $e');
    }
  }
}

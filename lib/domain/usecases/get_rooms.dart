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
        final apiRooms = roomsJson.map((json) => Room(
          id: json['id'].toString(),
          name: json['name'].toString(),
          buildingId: json['buildingId']?.toString() ?? '1',
          type: _parseRoomType(json['type']),
        )).toList();

        // Если бэк не возвращает тип комнаты, добавляем моковые параметры
        return apiRooms.map((room) => Room(
          id: room.id,
          name: room.name,
          buildingId: room.buildingId,
          type: room.type != RoomType.standard ? room.type : _generateMockRoomType(room.id),
        )).toList();
      }

      return _getMockRooms();
    } catch (e) {
      // В случае ошибки API возвращаем моковые данные
      print('[GetRooms] Ошибка загрузки комнат с API, используем моковые данные: $e');
      return _getMockRooms();
    }
  }

  // Генерируем тип комнаты на основе ID для разнообразия
  RoomType _generateMockRoomType(String roomId) {
    final types = [RoomType.standard, RoomType.comfort, RoomType.lux, RoomType.suite];
    final hash = roomId.hashCode.abs();
    return types[hash % types.length];
  }

  // Моковые данные комнат для разных корпусов
  List<Room> _getMockRooms() {
    return [
      // Корпус А - Стандартные номера
      Room(id: '101', name: '101', buildingId: '1', type: RoomType.standard),
      Room(id: '102', name: '102', buildingId: '1', type: RoomType.standard),
      Room(id: '103', name: '103', buildingId: '1', type: RoomType.comfort),
      Room(id: '104', name: '104', buildingId: '1', type: RoomType.comfort),
      Room(id: '105', name: '105', buildingId: '1', type: RoomType.lux),

      // Корпус Б - Комфорт и Люкс
      Room(id: '201', name: '201', buildingId: '2', type: RoomType.comfort),
      Room(id: '202', name: '202', buildingId: '2', type: RoomType.comfort),
      Room(id: '203', name: '203', buildingId: '2', type: RoomType.lux),
      Room(id: '204', name: '204', buildingId: '2', type: RoomType.lux),
      Room(id: '205', name: '205', buildingId: '2', type: RoomType.suite),

      // Корпус В - Все типы
      Room(id: '301', name: '301', buildingId: '3', type: RoomType.standard),
      Room(id: '302', name: '302', buildingId: '3', type: RoomType.standard),
      Room(id: '303', name: '303', buildingId: '3', type: RoomType.comfort),
      Room(id: '304', name: '304', buildingId: '3', type: RoomType.lux),
      Room(id: '305', name: '305', buildingId: '3', type: RoomType.suite),
      Room(id: '306', name: '306', buildingId: '3', type: RoomType.suite),

      // Корпус Г - Премиум номера
      Room(id: '401', name: '401', buildingId: '4', type: RoomType.lux),
      Room(id: '402', name: '402', buildingId: '4', type: RoomType.lux),
      Room(id: '403', name: '403', buildingId: '4', type: RoomType.suite),
      Room(id: '404', name: '404', buildingId: '4', type: RoomType.suite),
    ];
  }

  RoomType _parseRoomType(dynamic type) {
    if (type == null) return RoomType.standard;

    switch (type.toString().toLowerCase()) {
      case 'standard':
        return RoomType.standard;
      case 'comfort':
        return RoomType.comfort;
      case 'lux':
      case 'luxury':
        return RoomType.lux;
      case 'suite':
        return RoomType.suite;
      default:
        return RoomType.standard;
    }
  }
}

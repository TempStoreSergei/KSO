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
          type: room.type != RoomType.fourBed ? room.type : _generateMockRoomType(room.id),
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
    final types = [RoomType.fourBed, RoomType.sixBed, RoomType.eightBed];
    final hash = roomId.hashCode.abs();
    return types[hash % types.length];
  }

  // Моковые данные комнат для 3 корпусов
  List<Room> _getMockRooms() {
    return [
      // Корпус А - 4-местные номера
      Room(id: '101', name: '101', buildingId: '1', type: RoomType.fourBed),
      Room(id: '102', name: '102', buildingId: '1', type: RoomType.fourBed),
      Room(id: '103', name: '103', buildingId: '1', type: RoomType.sixBed),
      Room(id: '104', name: '104', buildingId: '1', type: RoomType.sixBed),
      Room(id: '105', name: '105', buildingId: '1', type: RoomType.eightBed),

      // Корпус Б - 6 и 8-местные
      Room(id: '201', name: '201', buildingId: '2', type: RoomType.sixBed),
      Room(id: '202', name: '202', buildingId: '2', type: RoomType.sixBed),
      Room(id: '203', name: '203', buildingId: '2', type: RoomType.eightBed),
      Room(id: '204', name: '204', buildingId: '2', type: RoomType.eightBed),
      Room(id: '205', name: '205', buildingId: '2', type: RoomType.eightBed),

      // Корпус В - Все типы
      Room(id: '301', name: '301', buildingId: '3', type: RoomType.fourBed),
      Room(id: '302', name: '302', buildingId: '3', type: RoomType.fourBed),
      Room(id: '303', name: '303', buildingId: '3', type: RoomType.sixBed),
      Room(id: '304', name: '304', buildingId: '3', type: RoomType.eightBed),
      Room(id: '305', name: '305', buildingId: '3', type: RoomType.eightBed),
      Room(id: '306', name: '306', buildingId: '3', type: RoomType.eightBed),
    ];
  }

  RoomType _parseRoomType(dynamic type) {
    if (type == null) return RoomType.fourBed;

    switch (type.toString().toLowerCase()) {
      case '4':
      case 'four':
      case 'fourbed':
        return RoomType.fourBed;
      case '6':
      case 'six':
      case 'sixbed':
        return RoomType.sixBed;
      case '8':
      case 'eight':
      case 'eightbed':
        return RoomType.eightBed;
      default:
        return RoomType.fourBed;
    }
  }
}

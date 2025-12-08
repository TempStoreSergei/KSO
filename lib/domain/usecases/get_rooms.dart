
import 'package:motel/core/api/api_client.dart';
import 'package:motel/data/models/room_model.dart';
import 'package:motel/domain/models/booking_models.dart';
import 'dart:math';

class GetRooms {
  final ApiClient _apiClient;

  GetRooms(this._apiClient);

  Future<Map<String, List<Room>>> call() async {
    try {
      final response = await _apiClient.get('/transactions/get_rooms');
      final Map<String, List<Room>> roomsByBuilding = {};

      if (response != null && response is Map<String, dynamic>) {
        response.forEach((key, value) {
          if (key.startsWith('rooms') && value is List) {
            final buildingId = key.substring('rooms'.length);
            final roomStrings = value.cast<String>();

            // Шаг 1: Определяем максимальное количество мест для каждой комнаты
            final Map<String, int> maxBedsPerRoom = {};
            for (final roomString in roomStrings) {
              final parts = roomString.split('-');
              if (parts.length >= 2) {
                final roomNumber = parts[0];
                final bedNumber = int.tryParse(parts[1]) ?? 0;
                maxBedsPerRoom[roomNumber] = max(maxBedsPerRoom[roomNumber] ?? 0, bedNumber);
              }
            }

            // Шаг 2: Определяем тип комнаты на основе максимального количества мест
            final Map<String, RoomType> roomTypes = {};
            maxBedsPerRoom.forEach((roomNumber, maxBeds) {
              if (maxBeds <= 4) {
                roomTypes[roomNumber] = RoomType.fourBed;
              } else if (maxBeds <= 6) {
                roomTypes[roomNumber] = RoomType.sixBed;
              } else {
                roomTypes[roomNumber] = RoomType.eightBed;
              }
            });

            // Шаг 3: Создаем объекты комнат с правильным типом
            final List<Room> rooms = [];
            for (final roomString in roomStrings) {
              final parts = roomString.split('-');
              if (parts.length >= 2) {
                final roomNumber = parts[0];
                final roomType = roomTypes[roomNumber] ?? RoomType.fourBed; // Тип по умолчанию
                rooms.add(Room(
                  buildingId: buildingId,
                  roomNumber: roomNumber,
                  bedNumber: parts[1],
                  type: roomType,
                ));
              }
            }

            // Шаг 4: Гарантируем уникальность комнат
            final Map<String, Room> uniqueRoomsMap = {};
            for (final room in rooms) {
              uniqueRoomsMap[room.id] = room;
            }
            
            roomsByBuilding[buildingId] = uniqueRoomsMap.values.toList();
          }
        });
      }

      if (roomsByBuilding.isEmpty) {
        // Возвращаем пустую карту, если API ничего не вернул
        return {};
      }

      return roomsByBuilding;
    } catch (e) {
      print('[GetRooms] Ошибка загрузки комнат с API: $e');
      // В случае ошибки возвращаем пустую карту, чтобы избежать моковых данных
      return {};
    }
  }
}

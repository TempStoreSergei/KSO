// ============================================
// lib/presentation/booking/managers/room_input_manager.dart
// ============================================

import 'package:motel/domain/models/booking_models.dart';

/// Менеджер для управления вводом номера комнаты
class RoomInputManager {
  String roomNumberInput = '';
  RoomType? selectedRoomType;
  static const int maxRoomNumberLength = 4;

  /// Обрабатывает нажатие клавиши на numpad
  void handleKeyPress(String key) {
    if (key == 'BACKSPACE') {
      if (roomNumberInput.isNotEmpty) {
        roomNumberInput = roomNumberInput.substring(0, roomNumberInput.length - 1);
      }
    } else if (roomNumberInput.length < maxRoomNumberLength) {
      roomNumberInput += key;
    }
  }

  /// Создает объект Room на основе текущего ввода
  Room? createRoom(Building? selectedBuilding) {
    if (roomNumberInput.isEmpty || selectedRoomType == null) {
      return null;
    }

    return Room(
      id: roomNumberInput,
      name: roomNumberInput,
      buildingId: selectedBuilding?.id ?? '',
      type: selectedRoomType!,
    );
  }

  /// Устанавливает тип комнаты
  void setRoomType(RoomType type) {
    selectedRoomType = type;
  }

  /// Проверяет, валидна ли комната для перехода дальше
  bool isValid() {
    return roomNumberInput.isNotEmpty &&
           selectedRoomType != null &&
           selectedRoomType != RoomType.all;
  }

  /// Сбрасывает состояние
  void reset() {
    roomNumberInput = '';
    selectedRoomType = null;
  }
}

// ============================================
// lib/domain/usecases/calculate_room_price.dart
// ============================================

import 'package:motel/core/api/api_client.dart';

class CalculateRoomPriceUseCase {
  final ApiClient _apiClient;

  CalculateRoomPriceUseCase({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Рассчитывает цену проживания на основе типа комнаты, корпуса и количества дней
  ///
  /// [roomType] - тип комнаты (например, "fourBed", "sixBed", "eightBed")
  /// [roomBuilding] - номер корпуса
  /// [countDays] - количество дней проживания
  ///
  /// Возвращает общую стоимость проживания
  Future<int?> call({
    required String roomType,
    required int roomBuilding,
    required int countDays,
  }) async {
    return await _apiClient.calculateRoomPrice(
      roomType: roomType,
      roomBuilding: roomBuilding,
      countDays: countDays,
    );
  }
}

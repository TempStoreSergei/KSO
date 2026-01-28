import 'package:motel/domain/entities/service_entity.dart';

/// Абстрактный контракт (интерфейс) для работы с данными об услугах.
abstract class ServiceRepository {
  /// Получает список всех услуг с удаленного источника.
  Future<List<ServiceEntity>> getServices();

  /// Создает новую услугу.
  /// Возвращает true в случае успеха.
  Future<bool> createService({
    required String name,
    int? price,
    required int tax,
    required bool isCountable,
    required bool isDuration,
    required String code,
  });

  /// Обновляет существующую услугу.
  /// Возвращает true в случае успеха.
  Future<bool> updateService({
    required String serviceID,
    required String name,
    int? price,
    required int tax,
    required bool isCountable,
    required bool isDuration,
    required String code,
  });

  /// Удаляет услугу по ее ID.
  /// Возвращает true в случае успеха.
  Future<bool> deleteService({required String serviceID});
}
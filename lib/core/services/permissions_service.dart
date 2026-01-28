// lib/core/services/permissions_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:motel/domain/models/permissions_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления правами доступа
class PermissionsService extends ChangeNotifier {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  static const _permissionsKey = 'cached_permissions';
  PermissionsModel? _permissions;

  /// Получает кэшированные права доступа
  PermissionsModel? get permissions => _permissions;

  /// Загружает права доступа из API
  Future<PermissionsModel?> fetchPermissions() async {
    try {
      final response = await ApiClient.instance.get('/system/permissions');
      final permissionsData = response as Map<String, dynamic>;

      _permissions = PermissionsModel.fromJson(permissionsData);

      // Кэшируем права в SharedPreferences
      await _cachePermissions(permissionsData);

      notifyListeners();
      debugPrint('[PermissionsService] Права доступа загружены');
      return _permissions;
    } catch (e) {
      debugPrint('[PermissionsService] Ошибка загрузки прав доступа: $e');

      // Попытка загрузить из кэша
      return await _loadCachedPermissions();
    }
  }

  /// Загружает права доступа из кэша
  Future<PermissionsModel?> _loadCachedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_permissionsKey);

      if (cachedJson != null) {
        final permissionsData = jsonDecode(cachedJson) as Map<String, dynamic>;
        _permissions = PermissionsModel.fromJson(permissionsData);
        notifyListeners();
        debugPrint('[PermissionsService] Загружены права из кэша');
        return _permissions;
      }
    } catch (e) {
      debugPrint('[PermissionsService] Ошибка загрузки прав из кэша: $e');
    }
    return null;
  }

  /// Кэширует права доступа
  Future<void> _cachePermissions(Map<String, dynamic> permissionsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_permissionsKey, jsonEncode(permissionsData));
      debugPrint('[PermissionsService] Права закэшированы');
    } catch (e) {
      debugPrint('[PermissionsService] Ошибка кэширования прав: $e');
    }
  }

  /// Проверяет, имеет ли роль определенное право
  bool hasPermission(String? role, String permission) {
    if (_permissions == null || role == null) {
      // Если прав нет, проверяем только публичные
      return _permissions?.publicPermissions.contains(permission) ?? false;
    }

    return _permissions!.hasPermission(role, permission);
  }

  /// Очищает кэш прав доступа
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_permissionsKey);
      _permissions = null;
      notifyListeners();
      debugPrint('[PermissionsService] Кэш прав очищен');
    } catch (e) {
      debugPrint('[PermissionsService] Ошибка очистки кэша: $e');
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для управления налоговыми настройками
class TaxSettingsService {
  static const String _defaultAccommodationTaxKey = 'default_accommodation_tax';
  static const int _defaultAccommodationTaxValue = 5; // По умолчанию 5%

  /// Получить налоговую ставку по умолчанию для размещения
  static Future<int> getDefaultAccommodationTax() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_defaultAccommodationTaxKey) ?? _defaultAccommodationTaxValue;
  }

  /// Сохранить налоговую ставку по умолчанию для размещения
  static Future<void> setDefaultAccommodationTax(int tax) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultAccommodationTaxKey, tax);
  }
}

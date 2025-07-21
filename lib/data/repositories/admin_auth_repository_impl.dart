// lib/data/repositories/admin_auth_repository_impl.dart
import 'package:motel/core/api/api_client.dart';
import 'package:motel/core/services/token_service.dart';
import '../../domain/repositories/admin_auth_repository.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final TokenService _tokenService = TokenService();

  @override
  Future<bool> login(String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login_admin',
        body: {'adminPassword': password},
      );

      if (response != null && response['token'] != null) {
        final String token = response['token'];
        await _tokenService.saveToken(token);
        print('Успешный вход, токен сохранен.');
        return true;
      }
      return false;

    } catch (e) {
      print('Ошибка входа: $e');
      await _tokenService.deleteToken(); // На всякий случай чистим старый токен
      return false;
    }
  }
}
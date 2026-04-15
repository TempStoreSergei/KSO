// lib/core/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motel/core/navigation/app_navigator.dart';
import 'package:motel/core/services/token_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient._privateConstructor() {
    final envUrl = _readEnvBaseUrlOrNull();
    if (envUrl != null && envUrl.isNotEmpty) {
      _baseUrl = envUrl;
    }
  }
  static final ApiClient instance = ApiClient._privateConstructor();

  String _baseUrl = 'http://localhost';
  final TokenService _tokenService = TokenService();
  Future<bool>? _refreshInFlight;
  
  String get baseUrl => _baseUrl;

  String? _readEnvBaseUrlOrNull() {
    try {
      return dotenv.env['BASE_URL'];
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    // .env всегда в приоритете
    final envUrl = _readEnvBaseUrlOrNull();
    if (envUrl != null && envUrl.isNotEmpty) {
      _baseUrl = envUrl;
      // Синхронизируем в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('BASE_URL', envUrl);
      return;
    }

    // Фоллбэк на сохранённый URL
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('BASE_URL');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('BASE_URL', url);
  }

  Future<Map<String, String>> _getHeaders({Map<String, String>? customHeaders}) async {
    final headers = {
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    final hasAuthorizationHeader = (customHeaders?.keys ?? const <String>[])
        .any((key) => key.toLowerCase() == 'authorization');
    if (!hasAuthorizationHeader) {
      final authorization = await _getAuthorizationValue();
      if (authorization != null) headers['Authorization'] = authorization;
    }

    // Добавляем или перезаписываем кастомные заголовки
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<String?> _getAuthorizationValue() async {
    final token = await _tokenService.getToken();
    if (token == null || token.isEmpty) return null;

    final rawType = await _tokenService.getTokenType();
    final tokenType = (rawType == null || rawType.isEmpty)
        ? 'Bearer'
        : (rawType.toLowerCase() == 'bearer' ? 'Bearer' : rawType);
    return '$tokenType $token';
  }

  bool _isAuthError(http.Response response) {
    return response.statusCode == 401 || response.statusCode == 403;
  }

  bool _isUnauthorized(http.Response response) {
    return response.statusCode == 401;
  }

  bool _shouldAttemptRefresh(String path) {
    return path != '/auth/login' && path != '/auth/refresh';
  }

  Future<bool> _ensureRefreshedAccessToken() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshAccessToken();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
    return future;
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final url = Uri.parse('$_baseUrl/auth/refresh').replace(
        queryParameters: {'refresh_token': refreshToken},
      );
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = decoded.isEmpty ? <String, dynamic>{} : jsonDecode(decoded) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        if (accessToken == null || accessToken.isEmpty) return false;

        await _tokenService.saveToken(accessToken);

        final tokenType = data['token_type'] as String?;
        if (tokenType != null && tokenType.isNotEmpty) {
          await _tokenService.saveTokenType(tokenType);
        }

        final newRefreshToken = data['refresh_token'] as String?;
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _tokenService.saveRefreshToken(newRefreshToken);
        }

        return true;
      }

      if (_isUnauthorized(response)) {
        await _tokenService.clearAuth();
        AppNavigator.popToRoot();
        return false;
      }

      if (_isAuthError(response)) {
        await _tokenService.clearTokens();
      }
    } catch (_) {
      // Игнорируем: refresh может быть недоступен/упал. Обработаем как обычную 401.
    }

    return false;
  }

  Future<http.Response> _sendWithAuthRetry(
    String path,
    Future<http.Response> Function() send,
  ) async {
    final response = await send();
    if (!_shouldAttemptRefresh(path) || !_isUnauthorized(response)) return response;

    final refreshed = await _ensureRefreshedAccessToken();
    if (!refreshed) return response;

    return await send();
  }

  /// GET для абсолютных URL (например, скачивание файлов).
  /// Токен добавляется только если URL на том же хосте, что и `baseUrl`.
  Future<http.Response> getRawUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    final baseUri = Uri.parse(_baseUrl);
    final sameOrigin =
        uri.scheme == baseUri.scheme && uri.host == baseUri.host && uri.port == baseUri.port;

    Future<http.Response> sendOnce() async {
      final requestHeaders = <String, String>{
        if (headers != null) ...headers,
      };

      if (sameOrigin && !requestHeaders.keys.any((k) => k.toLowerCase() == 'authorization')) {
        final authorization = await _getAuthorizationValue();
        if (authorization != null) requestHeaders['Authorization'] = authorization;
      }

      return await http.get(uri, headers: requestHeaders.isEmpty ? null : requestHeaders);
    }

    var response = await sendOnce();
    if (sameOrigin && _isUnauthorized(response) && await _ensureRefreshedAccessToken()) {
      response = await sendOnce();
    }
    return response;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    dynamic responseJson;
    try {
      var url = Uri.parse(_baseUrl + path);

      // Добавляем query parameters если они есть
      if (params != null && params.isNotEmpty) {
        url = url.replace(
          queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
        );
      }

      final response = await _sendWithAuthRetry(
        path,
        () async => http.get(url, headers: await _getHeaders()),
      );
      responseJson = _processResponse(response);
    } catch (e) {
      if (_isNetworkException(e)) {
        throw FetchDataException('Нет интернет-соединения');
      }
      rethrow;
    }
    return responseJson;
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final response = await _sendWithAuthRetry(path, () async {
        final requestHeaders = await _getHeaders(customHeaders: headers);

        // Проверяем Content-Type и кодируем body соответственно
        String requestBody;
        if (requestHeaders['Content-Type'] == 'application/x-www-form-urlencoded') {
          // Кодируем как URL-encoded
          requestBody = body?.entries
                  .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
                  .join('&') ??
              '';
        } else {
          // Кодируем как JSON (по умолчанию)
          requestBody = (body == null) ? '' : jsonEncode(body);
        }

        return await http.post(url, headers: requestHeaders, body: requestBody);
      });

      responseJson = _processResponse(response);
    } catch (e) {
      if (_isNetworkException(e)) {
        throw FetchDataException('Нет интернет-соединения');
      }
      rethrow;
    }
    return responseJson;
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final response = await _sendWithAuthRetry(
        path,
        () async => http.put(url, headers: await _getHeaders(), body: (body == null) ? '' : jsonEncode(body)),
      );
      responseJson = _processResponse(response);
    } catch (e) {
      if (_isNetworkException(e)) {
        throw FetchDataException('Нет интернет-соединения');
      }
      rethrow;
    }
    return responseJson;
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final response = await _sendWithAuthRetry(path, () async {
        final request = http.Request('DELETE', url)
          ..headers.addAll(await _getHeaders())
          ..body = jsonEncode(body);
        return await http.Client()
            .send(request)
            .then((streamedResponse) => http.Response.fromStream(streamedResponse));
      });
      responseJson = _processResponse(response);
    } catch (e) {
      if (_isNetworkException(e)) {
        throw FetchDataException('Нет интернет-соединения');
      }
      rethrow;
    }
    return responseJson;
  }

  Future<dynamic> multipartPost(String path, XFile file) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      Future<http.Response> sendOnce() async {
        final request = http.MultipartRequest('POST', url);
        request.headers['accept'] = 'application/json';

        final authorization = await _getAuthorizationValue();
        if (authorization != null) request.headers['Authorization'] = authorization;

        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes('file_data', await file.readAsBytes(), filename: file.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('file_data', file.path));
        }

        final streamedResponse = await request.send();
        return await http.Response.fromStream(streamedResponse);
      }

      var response = await sendOnce();
      if (_shouldAttemptRefresh(path) && _isUnauthorized(response) && await _ensureRefreshedAccessToken()) {
        response = await sendOnce();
      }
      responseJson = _processResponse(response);
    } catch (e) {
      if (_isNetworkException(e)) {
        throw FetchDataException('Нет интернет-соединения');
      }
      rethrow;
    }
    return responseJson;
  }

  // Метод для расчета цены проживания
  Future<int?> calculateRoomPrice({
    required String roomType,
    required int roomBuilding,
    required int countDays,
  }) async {
    final response = await post('/transactions/calculate_room_price', body: {
      'roomType': roomType,
      'roomBuilding': roomBuilding,
      'countDays': countDays,
    });

    return response['summRoomPrice'];
  }
  
  // Метод для поиска клиента по номеру телефона
  Future<String?> getClientIdByPhone(String phoneNumber) async {
    try {
      final response = await get('/transactions/get_client_by_number', params: {'phoneNumber': phoneNumber});
      if (response != null && response is Map && response.containsKey('client')) {
        return response['client']['guestId'];
      }
      return null;
    } catch (e) {
      // Если 404 или другая ошибка, возвращаем null, чтобы переключиться на ручной ввод
      return null;
    }
  }

  // Метод для выхода (удаление токенов)
  Future<void> logout() async {
    await _tokenService.clearAuth();
  }

  // Метод для получения метрик
  Future<Map<String, dynamic>> getMetrics() async {
    final response = await get('/metrics');
    return response as Map<String, dynamic>;
  }

  // Метод для запуска телеграм бота
  Future<Map<String, dynamic>> startTelegramBot(String token, String chatId) async {
    final response = await post('/notifications/tg/start', body: {'token': token, 'chat': chatId});
    return response as Map<String, dynamic>;
  }

  // Метод для остановки телеграм бота
  Future<Map<String, dynamic>> stopTelegramBot() async {
    final response = await post('/notifications/tg/stop');
    return response as Map<String, dynamic>;
  }

  // Метод для экспорта цен на проживание
  Future<String> exportRoomPrices() async {
    final response = await get('/transactions/export_room_prices');
    return response['url'] as String;
  }

  // Метод для загрузки CSV файла с ценами на проживание
  Future<dynamic> loadRoomPrices(XFile file) async {
    dynamic responseJson;
    try {
      final url = Uri.parse('$_baseUrl/transactions/load_room_prices');
      Future<http.Response> sendOnce() async {
        final request = http.MultipartRequest('POST', url);
        request.headers['accept'] = 'application/json';

        final authorization = await _getAuthorizationValue();
        if (authorization != null) request.headers['Authorization'] = authorization;

        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes('file', await file.readAsBytes(), filename: file.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('file', file.path));
        }

        final streamedResponse = await request.send();
        return await http.Response.fromStream(streamedResponse);
      }

      var response = await sendOnce();
      if (_isUnauthorized(response) && await _ensureRefreshedAccessToken()) {
        response = await sendOnce();
      }
      responseJson = _processResponse(response);
    } catch (e) {
      if (_isNetworkException(e)) {
        throw FetchDataException('Нет интернет-соединения');
      }
      rethrow;
    }
    return responseJson;
  }

  // Метод для экспорта транзакций
  Future<String> exportTransactions() async {
    final response = await get('/transactions/export_transactions');
    return response['url'] as String;
  }

  // Метод для печати чека
  Future<bool> printCheck(Map<String, dynamic> checkData) async {
    try {
      await post('/payments/pay_order', body: checkData);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isNetworkException(Object error) {
    if (error is http.ClientException) {
      return true;
    }

    final message = error.toString();
    return message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('XMLHttpRequest error');
  }

  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        final responseBody = utf8.decode(response.bodyBytes);
        // Если ответ пустой, возвращаем пустой объект
        if (responseBody.isEmpty) {
          return {};
        }
        return jsonDecode(responseBody);
      case 400:
        throw BadRequestException(utf8.decode(response.bodyBytes));
      case 401:
      case 403:
        throw UnauthorisedException(utf8.decode(response.bodyBytes));
      case 500:
      default:
        throw FetchDataException('Ошибка подключения к серверу: ${response.statusCode}');
    }
  }
}

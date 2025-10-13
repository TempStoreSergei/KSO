// lib/core/api/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cookie_jar/cookie_jar.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient._privateConstructor() {
    _cookieJar = CookieJar();
  }
  static final ApiClient instance = ApiClient._privateConstructor();

  final String _baseUrl = dotenv.env['BASE_URL']!;
  late final CookieJar _cookieJar;

  Future<Map<String, String>> _getHeaders({Map<String, String>? customHeaders}) async {
    final headers = {
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };

    // Добавляем cookies из хранилища
    final uri = Uri.parse(_baseUrl);
    final cookies = await _cookieJar.loadForRequest(uri);
    if (cookies.isNotEmpty) {
      headers['Cookie'] = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    }

    // Добавляем или перезаписываем кастомные заголовки
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  void _saveCookies(Uri uri, http.Response response) {
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      final cookies = setCookieHeader.split(',').map((str) {
        return Cookie.fromSetCookieValue(str.trim());
      }).toList();
      _cookieJar.saveFromResponse(uri, cookies);
    }
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

      final response = await http.get(url, headers: await _getHeaders());
      _saveCookies(url, response);
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final requestHeaders = await _getHeaders(customHeaders: headers);

      // Проверяем Content-Type и кодируем body соответственно
      String requestBody;
      if (requestHeaders['Content-Type'] == 'application/x-www-form-urlencoded') {
        // Кодируем как URL-encoded
        requestBody = body?.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}').join('&') ?? '';
      } else {
        // Кодируем как JSON (по умолчанию)
        requestBody = jsonEncode(body);
      }

      final response = await http.post(url, headers: requestHeaders, body: requestBody);
      _saveCookies(url, response);
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final response = await http.put(url, headers: await _getHeaders(), body: jsonEncode(body));
      _saveCookies(url, response);
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final request = http.Request('DELETE', url)
        ..headers.addAll(await _getHeaders())
        ..body = jsonEncode(body);
      final response = await http.Client().send(request).then((streamedResponse) => http.Response.fromStream(streamedResponse));
      _saveCookies(url, response);
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  Future<dynamic> multipartPost(String path, XFile file) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final request = http.MultipartRequest('POST', url);

      request.headers['accept'] = 'application/json';

      // Добавляем cookies
      final cookies = await _cookieJar.loadForRequest(url);
      if (cookies.isNotEmpty) {
        request.headers['Cookie'] = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
      }

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('file_data', await file.readAsBytes(), filename: file.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file_data', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _saveCookies(url, response);
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  // Метод для расчета цены проживания
  Future<int> calculateRoomPrice({
    required String roomType,
    required int roomBuilding,
    required int countDays,
  }) async {
    final response = await post('/guests/calculate_room_price', body: {
      'roomType': roomType,
      'roomBuilding': roomBuilding,
      'countDays': countDays,
    });
    return response['summRoomRrice'] as int;
  }

  // Метод для выхода (очистка cookies)
  Future<void> logout() async {
    await _cookieJar.deleteAll();
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
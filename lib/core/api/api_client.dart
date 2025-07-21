// lib/core/api/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:motel/core/services/token_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  final String _baseUrl = dotenv.env['BASE_URL']!;
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final response = await http.get(url, headers: await _getHeaders());
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final response = await http.post(url, headers: await _getHeaders(), body: jsonEncode(body));
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
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  // --- ИЗМЕНЕНИЕ: Метод теперь принимает XFile ---
  Future<dynamic> multipartPost(String path, XFile file) async {
    dynamic responseJson;
    try {
      final url = Uri.parse(_baseUrl + path);
      final request = http.MultipartRequest('POST', url);

      final token = await _tokenService.getToken();
      request.headers['accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('file_data', await file.readAsBytes(), filename: file.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file_data', file.path));
      }

      final response = await http.Response.fromStream(await request.send());
      responseJson = _processResponse(response);
    } on SocketException {
      throw FetchDataException('Нет интернет-соединения');
    }
    return responseJson;
  }

  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(utf8.decode(response.bodyBytes));
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
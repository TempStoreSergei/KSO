// lib/core/api/api_exceptions.dart
class ApiException implements Exception {
  final String? _message;
  final String? _prefix;

  ApiException([this._message, this._prefix]);

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends ApiException {
  FetchDataException([String? message]) : super(message, "");
}

class BadRequestException extends ApiException {
  BadRequestException([message]) : super(message, "Неверный запрос: ");
}

class UnauthorisedException extends ApiException {
  UnauthorisedException([message]) : super(message, "Не авторизован: ");
}
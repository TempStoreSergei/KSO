import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motel/core/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'telegram_state.dart';

class TelegramCubit extends Cubit<TelegramState> {
  final ApiClient _apiClient;

  TelegramCubit(this._apiClient) : super(TelegramInitial());

  Future<void> checkToken(String token) async {
    try {
      emit(TelegramLoading());
      final response = await http.get(Uri.parse('https://api.telegram.org/bot$token/getMe'));
      if (response.statusCode == 200) {
        emit(TelegramTokenVerified());
      } else {
        emit(const TelegramError('Неверный токен'));
      }
    } catch (e) {
      emit(TelegramError(e.toString()));
    }
  }

  Future<void> startBot(String token, String chatId) async {
    try {
      emit(TelegramLoading());
      final response = await _apiClient.startTelegramBot(token, chatId);
      emit(TelegramSuccess(response['detail']));
    } catch (e) {
      emit(TelegramError(e.toString()));
    }
  }

  Future<void> stopBot() async {
    try {
      emit(TelegramLoading());
      final response = await _apiClient.stopTelegramBot();
      emit(TelegramSuccess(response['detail']));
    } catch (e) {
      emit(TelegramError(e.toString()));
    }
  }
}

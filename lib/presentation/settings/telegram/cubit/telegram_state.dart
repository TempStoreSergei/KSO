import 'package:equatable/equatable.dart';

abstract class TelegramState extends Equatable {
  const TelegramState();

  @override
  List<Object> get props => [];
}

class TelegramInitial extends TelegramState {}

class TelegramLoading extends TelegramState {}

class TelegramTokenVerified extends TelegramState {}

class TelegramLoaded extends TelegramState {
  final String token;
  final String chatId;
  final bool tokenVerified;

  const TelegramLoaded({
    required this.token,
    required this.chatId,
    this.tokenVerified = false,
  });

  @override
  List<Object> get props => [token, chatId, tokenVerified];

  TelegramLoaded copyWith({
    String? token,
    String? chatId,
    bool? tokenVerified,
  }) {
    return TelegramLoaded(
      token: token ?? this.token,
      chatId: chatId ?? this.chatId,
      tokenVerified: tokenVerified ?? this.tokenVerified,
    );
  }
}

class TelegramSuccess extends TelegramState {
  final String message;

  const TelegramSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class TelegramError extends TelegramState {
  final String message;

  const TelegramError(this.message);

  @override
  List<Object> get props => [message];
}

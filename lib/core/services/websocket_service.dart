// lib/core/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:motel/core/services/diagnostic_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  String? _errorMessage;
  bool _isAdminMode = false;
  String? _connectOperationId;

  // Stream controllers для разных типов событий
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<WebSocketConnectionState>.broadcast();

  // Getters
  WebSocketConnectionState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _state == WebSocketConnectionState.connected;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream => _connectionStateController.stream;

  // Получаем WebSocket URL из .env
  String get _wsUrl {
    final baseUrl = dotenv.env['BASE_URL'];
    final uri = Uri.parse(baseUrl!);
    return 'ws://${uri.host}:${uri.port}/ws';
  }

  // Установка режима админки
  void setAdminMode(bool isAdmin) {
    _isAdminMode = isAdmin;
    if (_isAdminMode && isConnected) {
      disconnect();
    }
  }

  // Подключение к WebSocket (теперь без параметра URL)
  Future<void> connect() async {
    // Не подключаемся в режиме админки
    if (_isAdminMode) {
      DiagnosticLogger.info('websocket', 'connect_blocked_admin_mode');
      return;
    }

    if (isConnected) {
      DiagnosticLogger.info('websocket', 'connect_skipped_already_connected');
      return;
    }

    _connectOperationId = DiagnosticLogger.start('websocket', 'connect', data: {'url': _wsUrl});
    _updateState(WebSocketConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      await _channel!.ready;
      _updateState(WebSocketConnectionState.connected);
      if (_connectOperationId != null) {
        DiagnosticLogger.success(_connectOperationId!, data: {'url': _wsUrl});
        _connectOperationId = null;
      }

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _updateState(WebSocketConnectionState.error);
      if (_connectOperationId != null) {
        DiagnosticLogger.failure(_connectOperationId!, e, data: {'url': _wsUrl});
        _connectOperationId = null;
      }
    }
  }

  // Отключение от WebSocket
  void disconnect() {
    DiagnosticLogger.info('websocket', 'disconnect_requested', data: {'state': _state.name});
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _subscription = null;
    _channel = null;
    _updateState(WebSocketConnectionState.disconnected);
  }

  // Отправка сообщения
  void send(Map<String, dynamic> message) {
    if (!isConnected) {
      DiagnosticLogger.info('websocket', 'send_skipped_not_connected', data: {'message': message});
      return;
    }

    try {
      _channel?.sink.add(jsonEncode(message));
      DiagnosticLogger.info('websocket', 'message_sent', data: {'message': message});
    } catch (e) {
      DiagnosticLogger.info('websocket', 'message_send_failed', data: {'message': message, 'error': e.toString()});
    }
  }

  // Обработка входящих сообщений
  void _handleMessage(dynamic data) {
    try {
      final firstDecode = jsonDecode(data);
      final message = firstDecode is String
          ? jsonDecode(firstDecode) as Map<String, dynamic>
          : firstDecode as Map<String, dynamic>;

      DiagnosticLogger.info('websocket', 'message_received', data: {'message': message});

      _messageController.add(message);
    } catch (e, stackTrace) {
      DiagnosticLogger.info(
        'websocket',
        'message_parse_failed',
        data: {'error': e.toString(), 'stackTrace': stackTrace.toString()},
      );
    }
  }

  void _handleError(error) {
    _errorMessage = error.toString();
    _updateState(WebSocketConnectionState.error);
    DiagnosticLogger.info('websocket', 'stream_error', data: {'error': error.toString()});
  }

  // Обработка закрытия соединения
  void _handleDone() {
    _updateState(WebSocketConnectionState.disconnected);
    DiagnosticLogger.info('websocket', 'connection_closed');
  }

  // Обновление состояния
  void _updateState(WebSocketConnectionState newState) {
    _state = newState;
    _connectionStateController.add(newState);
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
    super.dispose();
  }
}

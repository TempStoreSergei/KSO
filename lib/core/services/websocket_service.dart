// lib/core/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class OrderData {
  final String datetime;
  final int sum;
  final int avance;
  final String type;
  final String paymentType;
  final String returnType;
  final List<Map<String, dynamic>> cart;
  final String order;

  OrderData({
    required this.datetime,
    required this.sum,
    required this.avance,
    required this.type,
    required this.paymentType,
    required this.returnType,
    required this.cart,
    required this.order,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      datetime: json['datetime'] ?? '',
      sum: json['sum'] ?? 0,
      avance: json['avance'] ?? 0,
      type: json['type'] ?? '',
      paymentType: json['payment_type'] ?? '',
      returnType: json['return_type'] ?? '',
      cart: List<Map<String, dynamic>>.from(json['cart'] ?? []),
      order: json['order'] ?? '',
    );
  }
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
  final List<OrderData> _allOrders = [];
  List<OrderData> get allOrders => List.unmodifiable(_allOrders);

  // Stream controllers для разных типов событий
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
  final _orderDataController = StreamController<OrderData>.broadcast();

  // Getters
  WebSocketConnectionState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _state == WebSocketConnectionState.connected;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<OrderData> get orderDataStream => _orderDataController.stream;

  // Получаем WebSocket URL из .env
  String get _wsUrl {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.0.99:8005/api/v1';
    final uri = Uri.parse(baseUrl);
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
      debugPrint('WebSocket: подключение заблокировано в режиме админки');
      return;
    }

    if (isConnected) {
      debugPrint('WebSocket: уже подключен');
      return;
    }

    _updateState(WebSocketConnectionState.connecting);

    try {
      debugPrint('WebSocket: подключение к $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      await _channel!.ready;
      _updateState(WebSocketConnectionState.connected);
      debugPrint('WebSocket: успешно подключен к $_wsUrl');

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _updateState(WebSocketConnectionState.error);
      debugPrint('WebSocket: ошибка подключения - $e');
    }
  }

  // Отключение от WebSocket
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close(status.normalClosure);
    _subscription = null;
    _channel = null;
    _updateState(WebSocketConnectionState.disconnected);
    debugPrint('WebSocket: отключен');
  }

  // Отправка сообщения
  void send(Map<String, dynamic> message) {
    if (!isConnected) {
      debugPrint('WebSocket: невозможно отправить сообщение - не подключен');
      return;
    }

    try {
      _channel?.sink.add(jsonEncode(message));
      debugPrint('WebSocket: сообщение отправлено - $message');
    } catch (e) {
      debugPrint('WebSocket: ошибка отправки сообщения - $e');
    }
  }

  // Обработка входящих сообщений
  void _handleMessage(dynamic data) {
    try {
      final firstDecode = jsonDecode(data);
      final message = firstDecode is String
          ? jsonDecode(firstDecode) as Map<String, dynamic>
          : firstDecode as Map<String, dynamic>;

      debugPrint('WebSocket: получено сообщение - $message');

      final eventType = message['event'];

      if (eventType == 'getOrderData') {
        final orderData = OrderData.fromJson(message['data']);

        // ДОБАВЛЯЕМ заказ в список, а не заменяем
        _allOrders.add(orderData);

        _orderDataController.add(orderData);
        debugPrint(
            'WebSocket: получен заказ - ${orderData.order}, сумма: ${orderData
                .sum}');
        debugPrint('WebSocket: всего заказов в списке: ${_allOrders.length}');
      }

      _messageController.add(message);
    } catch (e, stackTrace) {
      debugPrint('WebSocket: ошибка парсинга сообщения - $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _handleError(error) {
    _errorMessage = error.toString();
    _updateState(WebSocketConnectionState.error);
    debugPrint('WebSocket: ошибка - $error');
  }

  void clearOrders() {
    _allOrders.clear();
    notifyListeners();
    debugPrint('WebSocket: список заказов очищен');
  }

  List<Map<String, dynamic>> getAllCartItems() {
    final allItems = <Map<String, dynamic>>[];
    for (final order in _allOrders) {
      allItems.addAll(order.cart);
    }
    return allItems;
  }

  // Обработка закрытия соединения
  void _handleDone() {
    _updateState(WebSocketConnectionState.disconnected);
    debugPrint('WebSocket: соединение закрыто');
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
    _orderDataController.close();
    super.dispose();
  }
}
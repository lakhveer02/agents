import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final websocketClientProvider = Provider<WebSocketClient>((ref) => WebSocketClient());

class WebSocketMessage {
  final String type; // 'message', 'error', 'complete'
  final String content;
  final Map<String, dynamic> metadata;

  WebSocketMessage({
    required this.type,
    required this.content,
    required this.metadata,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? 'message',
      content: json['content'] ?? '',
      metadata: json['metadata'] ?? {},
    );
  }
}

class WebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  bool _intentionalClose = false;
  
  String? _currentClientId;
  String? _baseUrl;

  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _channel != null;

  void connect(String clientId, {String baseUrl = 'ws://localhost:8000'}) {
    _currentClientId = clientId;
    _baseUrl = baseUrl;
    _intentionalClose = false;
    _connect();
  }

  void _connect() {
    if (_channel != null) {
      return; // Already connected
    }

    try {
      final url = '$_baseUrl/ws/chat/$_currentClientId';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _connectionStateController.add(ConnectionState.connected);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (message) {
          try {
            final jsonData = json.decode(message);
            final wsMessage = WebSocketMessage.fromJson(jsonData);
            _messageController.add(wsMessage);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _channel = null;
    _connectionStateController.add(ConnectionState.disconnected);

    if (!_intentionalClose && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff
    
    _connectionStateController.add(ConnectionState.reconnecting);
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      print('Attempting to reconnect... (Attempt $_reconnectAttempts)');
      _connect();
    });
  }

  void sendMessage({
    required String message,
    required String chatType,
    int userId = 1,
    List<Map<String, String>> history = const [],
    String? persona,
    String? context,
  }) {
    if (_channel == null) {
      throw Exception('WebSocket not connected');
    }

    final payload = {
      'message': message,
      'chat_type': chatType,
      'user_id': userId,
      'history': history,
      if (persona != null) 'persona': persona,
      if (context != null) 'context': context,
    };

    _channel!.sink.add(json.encode(payload));
  }

  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connectionStateController.add(ConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}

enum ConnectionState {
  connected,
  disconnected,
  reconnecting,
}

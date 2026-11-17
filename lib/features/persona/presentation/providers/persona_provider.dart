import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/core/api/api_client.dart';
import 'package:agents/core/api/websocket_client.dart' as ws;
import 'dart:async';

final personaProvider = StateNotifierProvider<PersonaNotifier, PersonaState>((ref) {
  return PersonaNotifier(
    ref.read(apiClientProvider),
    ref.read(ws.websocketClientProvider),
  );
});

class PersonaState {
  final bool isLoading;
  final bool isStreaming;
  final String selectedPersona;
  final List<Map<String, String>> messages;
  final String currentStreamingMessage;
  final ws.ConnectionState connectionState;

  PersonaState({
    this.isLoading = false,
    this.isStreaming = false,
    this.selectedPersona = 'mentor',
    this.messages = const [],
    this.currentStreamingMessage = '',
    this.connectionState = ws.ConnectionState.disconnected,
  });

  PersonaState copyWith({
    bool? isLoading,
    bool? isStreaming,
    String? selectedPersona,
    List<Map<String, String>>? messages,
    String? currentStreamingMessage,
    ws.ConnectionState? connectionState,
  }) {
    return PersonaState(
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      selectedPersona: selectedPersona ?? this.selectedPersona,
      messages: messages ?? this.messages,
      currentStreamingMessage: currentStreamingMessage ?? this.currentStreamingMessage,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class PersonaNotifier extends StateNotifier<PersonaState> {
  final ApiClient _apiClient;
  final ws.WebSocketClient _wsClient;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;

  PersonaNotifier(this._apiClient, this._wsClient) : super(PersonaState()) {
    _initWebSocket();
  }

  void _initWebSocket() {
    _wsClient.connect('persona_client');
    
    _connectionSubscription = _wsClient.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });

    _messageSubscription = _wsClient.messageStream.listen((message) {
      if (message.type == 'message') {
        state = state.copyWith(
          currentStreamingMessage: state.currentStreamingMessage + message.content,
        );
      } else if (message.type == 'complete') {
        final completeMessage = {
          'role': 'assistant',
          'content': state.currentStreamingMessage,
        };
        state = state.copyWith(
          isStreaming: false,
          messages: [...state.messages, completeMessage],
          currentStreamingMessage: '',
        );
      } else if (message.type == 'error') {
        state = state.copyWith(
          isStreaming: false,
        );
      }
    });
  }

  void selectPersona(String persona) {
    state = state.copyWith(
      selectedPersona: persona,
      messages: [],
      currentStreamingMessage: '',
    );
  }

  void sendMessage(String text) {
    if (!_wsClient.isConnected) {
      return;
    }

    final userMessage = {'role': 'user', 'content': text};
    state = state.copyWith(
      isStreaming: true,
      messages: [...state.messages, userMessage],
      currentStreamingMessage: '',
    );

    try {
      _wsClient.sendMessage(
        message: text,
        chatType: 'persona',
        persona: state.selectedPersona,
        history: state.messages,
      );
    } catch (e) {
      state = state.copyWith(isStreaming: false);
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

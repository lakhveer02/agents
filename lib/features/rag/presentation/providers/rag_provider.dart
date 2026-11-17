import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/core/api/api_client.dart';
import 'package:agents/core/api/websocket_client.dart' as ws;
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:async';

final ragProvider = StateNotifierProvider<RagNotifier, RagState>((ref) {
  return RagNotifier(
    ref.read(apiClientProvider),
    ref.read(ws.websocketClientProvider),
  );
});

class RagState {
  final bool isLoading;
  final bool isStreaming;
  final String? error;
  final List<Map<String, dynamic>> messages;
  final String currentStreamingMessage;
  final List<String>? currentSources;
  final ws.ConnectionState connectionState;

  RagState({
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.messages = const [],
    this.currentStreamingMessage = '',
    this.currentSources,
    this.connectionState = ws.ConnectionState.disconnected,
  });

  RagState copyWith({
    bool? isLoading,
    bool? isStreaming,
    bool clearError = false,
    String? error,
    List<Map<String, dynamic>>? messages,
    String? currentStreamingMessage,
    List<String>? currentSources,
    ws.ConnectionState? connectionState,
  }) {
    return RagState(
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      messages: messages ?? this.messages,
      currentStreamingMessage: currentStreamingMessage ?? this.currentStreamingMessage,
      currentSources: currentSources ?? this.currentSources,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class RagNotifier extends StateNotifier<RagState> {
  final ApiClient _apiClient;
  final ws.WebSocketClient _wsClient;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;

  RagNotifier(this._apiClient, this._wsClient) : super(RagState()) {
    _initWebSocket();
  }

  void _initWebSocket() {
    _wsClient.connect('rag_client');
    
    _connectionSubscription = _wsClient.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });

    _messageSubscription = _wsClient.messageStream.listen((message) {
      if (message.type == 'message') {
        // Append chunk to current streaming message
        state = state.copyWith(
          currentStreamingMessage: state.currentStreamingMessage + message.content,
          currentSources: message.metadata['sources'] != null
              ? List<String>.from(message.metadata['sources'])
              : state.currentSources,
        );
      } else if (message.type == 'complete') {
        // Finalize the message
        final completeMessage = {
          'role': 'assistant',
          'content': state.currentStreamingMessage,
          'sources': state.currentSources,
        };
        state = state.copyWith(
          isStreaming: false,
          messages: [...state.messages, completeMessage],
          currentStreamingMessage: '',
          currentSources: null,
        );
      } else if (message.type == 'error') {
        state = state.copyWith(
          isStreaming: false,
          error: message.content,
        );
      }
    });
  }

  Future<void> uploadPdf(File file) async {
    state = state.copyWith(isLoading: true);
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      await _apiClient.post('/rag/upload-pdf', data: formData);
      state = state.copyWith(
        isLoading: false,
        messages: [
          ...state.messages,
          {
            'role': 'assistant',
            'content': 'PDF $fileName uploaded and indexed successfully! You can now ask questions about it.',
          }
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> ingestUrl(String url) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiClient.post('/rag/url-ingest', data: {'url': url});
      state = state.copyWith(
        isLoading: false,
        messages: [
          ...state.messages,
          {
            'role': 'assistant',
            'content': 'URL $url ingested and indexed successfully!',
          }
        ],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void query(String text) {
    if (!_wsClient.isConnected) {
      state = state.copyWith(error: 'WebSocket not connected');
      return;
    }

    // Add user message
    final userMessage = {'role': 'user', 'content': text};
    state = state.copyWith(
      isStreaming: true,
      messages: [...state.messages, userMessage],
      currentStreamingMessage: '',
      clearError: true,
    );

    // Send via WebSocket
    try {
      _wsClient.sendMessage(
        message: text,
        chatType: 'rag',
        history: state.messages
            .where((m) => m['role'] != null)
            .map((m) => {
                  'role': m['role'] as String,
                  'content': m['content'] as String,
                })
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        error: e.toString(),
      );
    }
  }

  void stopStreaming() {
    if (state.isStreaming && state.currentStreamingMessage.isNotEmpty) {
      // Save partial message
      final partialMessage = {
        'role': 'assistant',
        'content': state.currentStreamingMessage + ' [stopped]',
        'sources': state.currentSources,
      };
      state = state.copyWith(
        isStreaming: false,
        messages: [...state.messages, partialMessage],
        currentStreamingMessage: '',
      );
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

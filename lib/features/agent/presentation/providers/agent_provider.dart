import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/core/api/api_client.dart';
import 'package:agents/core/api/websocket_client.dart' as ws;
import 'dart:async';

final agentProvider = StateNotifierProvider<AgentNotifier, AgentState>((ref) {
  return AgentNotifier(
    ref.read(apiClientProvider),
    ref.read(ws.websocketClientProvider),
  );
});

class AgentState {
  final bool isLoading;
  final bool isStreaming;
  final String? result;
  final List<String> logs;
  final String currentStreamingLog;
  final ws.ConnectionState connectionState;

  AgentState({
    this.isLoading = false,
    this.isStreaming = false,
    this.result,
    this.logs = const [],
    this.currentStreamingLog = '',
    this.connectionState = ws.ConnectionState.disconnected,
  });

  AgentState copyWith({
    bool? isLoading,
    bool? isStreaming,
    String? result,
    List<String>? logs,
    String? currentStreamingLog,
    ws.ConnectionState? connectionState,
  }) {
    return AgentState(
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      result: result ?? this.result,
      logs: logs ?? this.logs,
      currentStreamingLog: currentStreamingLog ?? this.currentStreamingLog,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

class AgentNotifier extends StateNotifier<AgentState> {
  final ApiClient _apiClient;
  final ws.WebSocketClient _wsClient;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;

  AgentNotifier(this._apiClient, this._wsClient) : super(AgentState()) {
    _initWebSocket();
  }

  void _initWebSocket() {
    _wsClient.connect('agent_client');
    
    _connectionSubscription = _wsClient.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });

    _messageSubscription = _wsClient.messageStream.listen((message) {
      if (message.type == 'message') {
        state = state.copyWith(
          currentStreamingLog: state.currentStreamingLog + message.content,
        );
      } else if (message.type == 'complete') {
        state = state.copyWith(
          isStreaming: false,
          result: state.currentStreamingLog,
          logs: [
            ...state.logs,
            'Agent Reasoning:\n${state.currentStreamingLog}',
          ],
          currentStreamingLog: '',
        );
      } else if (message.type == 'error') {
        state = state.copyWith(
          isStreaming: false,
          logs: [...state.logs, 'Error: ${message.content}'],
        );
      }
    });
  }

  void executeCommand(String command, {String context = ''}) {
    if (!_wsClient.isConnected) {
      state = state.copyWith(
        logs: [...state.logs, 'Error: WebSocket not connected'],
      );
      return;
    }

    state = state.copyWith(
      isStreaming: true,
      logs: [...state.logs, '> $command'],
      currentStreamingLog: '',
    );

    try {
      _wsClient.sendMessage(
        message: command,
        chatType: 'agent',
        context: context,
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        logs: [...state.logs, 'Error: $e'],
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/core/api/api_client.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  return VoiceNotifier(ref.read(apiClientProvider));
});

class VoiceState {
  final bool isListening;
  final bool isProcessing;
  final String userText;
  final String aiText;

  VoiceState({this.isListening = false, this.isProcessing = false, this.userText = '', this.aiText = ''});
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  final ApiClient _apiClient;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceNotifier(this._apiClient) : super(VoiceState());

  Future<void> startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      state = VoiceState(isListening: true, userText: state.userText, aiText: state.aiText);
      _speech.listen(onResult: (result) {
        state = VoiceState(isListening: state.isListening, userText: result.recognizedWords, aiText: state.aiText);
      });
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = VoiceState(isListening: false, isProcessing: true, userText: state.userText, aiText: state.aiText);
    _processVoice();
  }

  Future<void> _processVoice() async {
    try {
      // For simplicity, we'll just send the text to a voice process endpoint
      // In a real app, you might send the actual audio file for STT on backend
      final response = await _apiClient.post('/voice/process', data: {'text': state.userText});
      final aiResponse = response.data['ai_text'];
      state = VoiceState(isProcessing: false, userText: state.userText, aiText: aiResponse);
      _speak(aiResponse);
    } catch (e) {
      state = VoiceState(isProcessing: false, userText: state.userText, aiText: 'Error processing voice');
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }
}

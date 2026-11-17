import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agents/core/api/api_client.dart';

final ecommerceProvider = StateNotifierProvider<EcommerceNotifier, EcommerceState>((ref) {
  return EcommerceNotifier(ref.read(apiClientProvider));
});

class EcommerceState {
  final bool isLoading;
  final List<String> recommendations;
  final List<String> memories;

  EcommerceState({this.isLoading = false, this.recommendations = const [], this.memories = const []});
}

class EcommerceNotifier extends StateNotifier<EcommerceState> {
  final ApiClient _apiClient;

  EcommerceNotifier(this._apiClient) : super(EcommerceState()) {
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    state = EcommerceState(isLoading: true, recommendations: state.recommendations, memories: state.memories);
    try {
      final response = await _apiClient.get('/memory/retrieve', queryParameters: {'query': 'shopping preferences'});
      final memories = List<String>.from(response.data['memories']);
      state = EcommerceState(isLoading: false, recommendations: state.recommendations, memories: memories);
      _generateRecommendations(memories);
    } catch (e) {
      state = EcommerceState(isLoading: false, recommendations: state.recommendations, memories: state.memories);
    }
  }

  Future<void> savePreference(String preference) async {
    try {
      await _apiClient.post('/memory/store', data: {'content': preference});
      _loadMemories();
    } catch (e) {
      // Handle error
    }
  }

  void _generateRecommendations(List<String> memories) {
    // Simple logic: if memory contains 'shoes', recommend shoes
    List<String> recs = [];
    if (memories.any((m) => m.contains('shoes'))) {
      recs.addAll(['Nike Air Max', 'Adidas Ultraboost', 'Puma RS-X']);
    } else {
      recs.addAll(['iPhone 15', 'MacBook Pro', 'Sony WH-1000XM5']);
    }
    state = EcommerceState(isLoading: false, recommendations: recs, memories: memories);
  }
}

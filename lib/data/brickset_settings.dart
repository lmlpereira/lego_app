import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/brickset_service.dart';

const _chaveApiKey = 'brickset_api_key';

/// Instância partilhada do SharedPreferences (carregada uma única vez).
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// API key do Brickset guardada no dispositivo. `null` enquanto não há
/// nenhuma configurada, ou enquanto o SharedPreferences ainda está a
/// carregar.
final bricksetApiKeyProvider =
StateNotifierProvider<BricksetApiKeyNotifier, AsyncValue<String?>>((ref) {
  return BricksetApiKeyNotifier(ref);
});

class BricksetApiKeyNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref ref;

  BricksetApiKeyNotifier(this.ref) : super(const AsyncValue.loading()) {
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = AsyncValue.data(prefs.getString(_chaveApiKey));
  }

  Future<void> guardar(String apiKey) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_chaveApiKey, apiKey.trim());
    state = AsyncValue.data(apiKey.trim());
  }

  Future<void> limpar() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_chaveApiKey);
    state = const AsyncValue.data(null);
  }
}

/// Serviço do Brickset, já com a API key atual. `null` se ainda não houver
/// key configurada — a UI deve tratar esse caso (ver [_temApiKeyProvider]).
final bricksetServiceProvider = Provider<BricksetService?>((ref) {
  final apiKey = ref.watch(bricksetApiKeyProvider).value;
  if (apiKey == null || apiKey.isEmpty) return null;
  final service = BricksetService(apiKey: apiKey);
  ref.onDispose(service.dispose);
  return service;
});
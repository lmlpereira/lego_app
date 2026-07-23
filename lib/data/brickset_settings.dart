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

  /// Como ler `state.value`, mas espera o carregamento do disco terminar
  /// primeiro em vez de assumir "ainda a null" = "sem chave guardada".
  ///
  /// Sem isto, código que faz `ref.read(bricksetApiKeyProvider).value`
  /// logo a seguir a abrir a app (ex: ao clicar em "pesquisar Brickset"
  /// no ecrã de adicionar set) pode apanhar o provider ainda em
  /// `AsyncValue.loading()` — mesmo havendo uma chave guardada — e
  /// reportar incorretamente que não há nenhuma configurada.
  Future<String?> obterQuandoPronto() async {
    if (!state.isLoading) return state.value;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final valor = prefs.getString(_chaveApiKey);
    // Só atualiza o state se ainda estiver a "loading" — se _carregar()
    // já tiver terminado entretanto (chamadas concorrentes), não há
    // problema em sobrepor com o mesmo valor de qualquer forma.
    if (state.isLoading) state = AsyncValue.data(valor);
    return valor;
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

/// Versão assíncrona de [bricksetServiceProvider]: espera o carregamento
/// da chave a partir do disco terminar antes de responder, em vez de
/// arriscar apanhar `AsyncValue.loading()` e concluir "sem chave" por
/// engano. Usa esta função (em vez de `ref.read(bricksetServiceProvider)`)
/// em qualquer sítio que decida "avisar o utilizador que falta a API key"
/// — sítios que só leem o valor uma vez (ex: ao clicar num botão) são os
/// mais suscetíveis a apanhar o provider ainda a carregar.
Future<BricksetService?> obterBricksetServiceQuandoPronto(WidgetRef ref) async {
  final apiKey = await ref.read(bricksetApiKeyProvider.notifier).obterQuandoPronto();
  if (apiKey == null || apiKey.isEmpty) return null;
  return BricksetService(apiKey: apiKey);
}
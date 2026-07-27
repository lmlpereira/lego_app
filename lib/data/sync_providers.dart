import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/sync_service.dart';
import 'auth_providers.dart';
import 'providers.dart';
import 'repositories/auth_repository.dart';

enum SyncStatus { parado, aSincronizar, sucesso, erro }

class SyncState {
  final SyncStatus status;
  final DateTime? ultimaSincronizacao;
  final String? erro;

  const SyncState({this.status = SyncStatus.parado, this.ultimaSincronizacao, this.erro});
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncService(db: db);
});

/// Contagem reativa de sets por enviar para o utilizador atual — usada
/// para mostrar um badge/indicador nas Definições. `0` sem sessão.
final pendenteSyncProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(utilizadorAtualProvider).value?.uid;
  if (uid == null || uid.isEmpty) return Stream.value(0);
  return ref.watch(databaseProvider).watchContagemPendenteEnvio(uid);
});

/// Controla QUANDO a sincronização acontece — nunca é preciso chamar
/// isto diretamente para o disparar automaticamente, só para ler o
/// estado ou pedir uma sincronização manual (ver [sincronizarAgora]):
/// - Login novo (ou app reaberta já com sessão) -> sincroniza logo.
/// - Rede volta a ficar disponível -> sincroniza (só há algo a fazer
///   quando há alterações pendentes ou o Firestore tem coisas novas).
/// - Botão "Sincronizar agora" -> chama [sincronizarAgora] diretamente.
///
/// É criado uma única vez (ver AuthGate, que faz `ref.watch` disto logo
/// no arranque da app) e vive durante toda a sessão da app.
final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(ref);
});

class SyncController extends StateNotifier<SyncState> {
  final Ref ref;
  ProviderSubscription<AsyncValue<AppUser?>>? _authListener;
  StreamSubscription<List<ConnectivityResult>>? _conectividadeSub;
  bool _aSincronizar = false;

  SyncController(this.ref) : super(const SyncState()) {
    _authListener = ref.listen<AsyncValue<AppUser?>>(utilizadorAtualProvider, (anterior, atual) {
      final uidAnterior = anterior?.value?.uid;
      final uidAtual = atual.value?.uid;
      if (uidAtual != null && uidAtual.isNotEmpty && uidAtual != uidAnterior) {
        sincronizarAgora();
      }
    });

    // connectivity_plus >= 6 emite uma List<ConnectivityResult> (podes
    // estar ligado por wifi E dados ao mesmo tempo); "sem rede" só é
    // verdade se TODOS os resultados forem `none`.
    _conectividadeSub = Connectivity().onConnectivityChanged.listen((resultados) {
      final semRede = resultados.every((r) => r == ConnectivityResult.none);
      if (!semRede) sincronizarAgora();
    });
  }

  /// Pode ser chamado a qualquer momento (ex: botão "Sincronizar agora").
  /// Não faz nada se já houver uma sincronização em curso, ou se não
  /// houver sessão ativa.
  Future<void> sincronizarAgora() async {
    if (_aSincronizar) return;
    final uid = ref.read(utilizadorAtualProvider).value?.uid;
    if (uid == null || uid.isEmpty) return;

    _aSincronizar = true;
    state = SyncState(status: SyncStatus.aSincronizar, ultimaSincronizacao: state.ultimaSincronizacao);
    try {
      final resultado = await ref.read(syncServiceProvider).sincronizar(uid);
      state = SyncState(status: SyncStatus.sucesso, ultimaSincronizacao: resultado.quando);
    } on SyncException catch (e) {
      state = SyncState(
        status: SyncStatus.erro,
        ultimaSincronizacao: state.ultimaSincronizacao,
        erro: e.message,
      );
    } catch (e) {
      state = SyncState(
        status: SyncStatus.erro,
        ultimaSincronizacao: state.ultimaSincronizacao,
        erro: '$e',
      );
    } finally {
      _aSincronizar = false;
    }
  }

  @override
  void dispose() {
    _authListener?.close();
    _conectividadeSub?.cancel();
    super.dispose();
  }
}

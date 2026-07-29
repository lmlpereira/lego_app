import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lego_app/data/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_providers.dart';

/// Chave usada tanto no SharedPreferences (cache local, para visitantes
/// sem sessão e para aplicar o idioma instantaneamente no arranque) como
/// no campo homónimo do documento `users/{uid}` no Firestore (fonte de
/// verdade quando há sessão ativa, para a preferência acompanhar a
/// pessoa entre dispositivos).
const _kChaveIdioma = 'idioma';

/// `null` = sem preferência explícita — a app segue o idioma do
/// telemóvel (ver `supportedLocales`/`localeResolutionCallback` no
/// MaterialApp).
final localeControllerProvider = StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController(ref);
});

class LocaleController extends StateNotifier<Locale?> {
  final Ref ref;
  ProviderSubscription<AsyncValue<AppUser?>>? _authListener;

  LocaleController(this.ref) : super(null) {
    _carregarPreferenciaLocal();

    // Quando há sessão com um idioma já guardado no Firestore, esse
    // valor é a fonte de verdade (ex: a pessoa mudou de idioma noutro
    // aparelho) — sobrepõe-se ao que estava só em cache local.
    _authListener = ref.listen<AsyncValue<AppUser?>>(utilizadorAtualProvider, (anterior, atual) {
      final idiomaRemoto = atual.value?.idioma;
      if (idiomaRemoto != null && idiomaRemoto.isNotEmpty) {
        _aplicarLocal(idiomaRemoto, guardarNaCloud: false);
      }
    });

    ref.onDispose(() => _authListener?.close());
  }

  Future<void> _carregarPreferenciaLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_kChaveIdioma);
    if (guardado != null && guardado.isNotEmpty && mounted) {
      state = Locale(guardado);
    }
  }

  /// Muda o idioma da app. Aplica-se de imediato (independentemente de
  /// sessão) e fica guardado localmente; se houver sessão ativa, é
  /// também gravado no Firestore para acompanhar a pessoa entre
  /// dispositivos.
  Future<void> definirIdioma(String idioma) async {
    await _aplicarLocal(idioma, guardarNaCloud: true);
  }

  Future<void> _aplicarLocal(String idioma, {required bool guardarNaCloud}) async {
    if (mounted) state = Locale(idioma);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChaveIdioma, idioma);

    if (!guardarNaCloud) return;
    final uid = ref.read(utilizadorAtualProvider).value?.uid;
    if (uid == null || uid.isEmpty) return; // Visitante — só fica local.

    try {
      await ref.read(authRepositoryProvider).atualizarIdioma(idioma);
    } catch (_) {
      // Falha a sincronizar com a cloud não deve impedir a mudança de
      // idioma local — a próxima escrita bem-sucedida (ou o login
      // seguinte) volta a tentar.
    }
  }
}

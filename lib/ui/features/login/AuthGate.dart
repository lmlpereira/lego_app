import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth_providers.dart';
import '../../../main.dart';
import '../splash/splash_screen.dart';
import 'login_screen.dart';

/// Decide, de forma reativa, o que mostrar consoante o estado de sessão:
/// - a carregar (primeiro frame, antes do Firebase responder) -> Splash
/// - sem sessão -> LoginScreen
/// - com sessão -> HomeShell
///
/// Nunca navegamos manualmente para a HomeShell depois de um login —
/// isto observa o stream e troca sozinho assim que a sessão muda (login,
/// registo, ou logout, em qualquer ecrã).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utilizadorAsync = ref.watch(utilizadorAtualProvider);

    return utilizadorAsync.when(
      data: (user) => user == null ? const LegoLoginScreen() : const HomeShell(),
      loading: () => const SplashScreen(),
      // Em caso de erro a ler o estado de sessão, mostra o login em vez
      // de deixar a app presa no splash para sempre.
      error: (e, _) => const LegoLoginScreen(),
    );
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories/auth_repository.dart';
import 'repositories/firebase_auth_repository.dart';

/// Trocar de provedor de autenticação no futuro é mudar só esta linha —
/// mesmo princípio do setsRepositoryProvider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Utilizador atual, reativo ao estado de sessão. `null` = sem sessão.
/// A UI (AuthGate, HomeShell, etc.) observa isto para decidir o que
/// mostrar.
final utilizadorAtualProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});
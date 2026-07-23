/// Modelo de domínio simples para o utilizador autenticado — a UI nunca
/// depende diretamente de `firebase_auth.User`, tal como o LegoSet nunca
/// depende diretamente das classes geradas pelo Drift.
class AppUser {
  final String uid;
  final String? email;
  final String? username;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.email,
    this.username,
    this.photoUrl,
  });
}

/// Erro de autenticação com uma mensagem já pronta a mostrar ao
/// utilizador (traduzida/simplificada a partir dos códigos do Firebase).
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Contrato que a UI usa. Hoje só existe FirebaseAuthRepository, mas
/// mantém-se como interface pela mesma razão do SetsRepository: se um
/// dia quiseres outro provedor de autenticação, troca-se só aqui.
abstract class AuthRepository {
  /// Emite o utilizador atual sempre que o estado de sessão muda
  /// (login, logout, ou app reaberta com sessão persistida).
  Stream<AppUser?> watchUser();

  AppUser? get utilizadorAtual;

  Future<AppUser> registarComEmail({
    required String email,
    required String password,
    required String username,
  });

  Future<AppUser> entrarComEmail({
    required String email,
    required String password,
  });

  /// Abre o seletor de conta Google e autentica. Lança [AuthException]
  /// (não erro genérico) se o utilizador cancelar o seletor.
  Future<AppUser> entrarComGoogle();

  Future<void> repporPassword(String email);

  Future<void> terminarSessao();
}
/// Modelo de domínio simples para o utilizador autenticado — a UI nunca
/// depende diretamente de `firebase_auth.User`, tal como o LegoSet nunca
/// depende diretamente das classes geradas pelo Drift.
///
/// [username] só fica preenchido depois de o perfil estar completo no
/// Firestore (ver users/{uid}). É este campo que o AuthGate usa para
/// decidir se ainda falta pedir o username — nomeadamente logo a seguir
/// a um primeiro login por Google, que não dá username nenhum.
class AppUser {
  final String uid;
  final String? email;
  final String? username;
  final String? nome;
  final DateTime? dataNascimento;
  final String? idLegoInsiders;
  final String? sexo;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.email,
    this.username,
    this.nome,
    this.dataNascimento,
    this.idLegoInsiders,
    this.sexo,
    this.photoUrl,
  });

  /// Perfil ainda não tem username escolhido — falta o passo de
  /// completar o perfil (novo registo por email já trata disto no
  /// próprio registo; só fica pendente para contas Google novas).
  bool get perfilIncompleto => username == null || username!.isEmpty;
}

/// Erro de autenticação com uma mensagem já pronta a mostrar ao
/// utilizador (traduzida/simplificada a partir dos códigos do Firebase,
/// ou de validações próprias como "username já em uso").
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

  /// [username] tem de ser único — ver implementação para a garantia
  /// (transação Firestore + reserva em users_index/usernames).
  Future<AppUser> registarComEmail({
    required String email,
    required String password,
    required String username,
    required String nome,
    DateTime? dataNascimento,
    String? idLegoInsiders,
    String? sexo,
  });

  Future<AppUser> entrarComEmail({
    required String email,
    required String password,
  });

  /// Abre o seletor de conta Google e autentica. Lança [AuthException]
  /// (não erro genérico) se o utilizador cancelar o seletor. Não cria o
  /// perfil sozinho — o Google não dá um username, por isso o utilizador
  /// tem sempre de passar por [completarPerfil] da primeira vez.
  Future<AppUser> entrarComGoogle();

  /// Usado depois de um primeiro login por Google (ou qualquer conta sem
  /// perfil ainda) para escolher o username e preencher os restantes
  /// dados. Requer sessão já ativa.
  Future<AppUser> completarPerfil({
    required String username,
    required String nome,
    DateTime? dataNascimento,
    String? idLegoInsiders,
    String? sexo,
  });

  Future<AppUser> atualizarPerfil({
    required String nome,
    DateTime? dataNascimento,
    String? idLegoInsiders,
    String? sexo,
  });

  Future<void> repporPassword(String email);

  Future<void> terminarSessao();
}
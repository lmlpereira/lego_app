import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import 'auth_repository.dart';

// TODO: substitui por estes valores reais, tirados da Firebase Console:
// Authentication -> Sign-in method -> Google -> "Web SDK configuration"
// -> "Web client ID". É o mesmo valor nos dois campos abaixo em muitos
// casos, EXCETO o _iosClientId, que vem do GoogleService-Info.plist
// (campo CLIENT_ID) e é diferente do web client ID.
const _webClientId = '422232460298-j0erahv437955nq9cqagjo22voqfjqd8.apps.googleusercontent.com';
const _iosClientId = 'PREENCHE-COM-O-TEU-IOS-CLIENT-ID.apps.googleusercontent.com';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;
  bool _googleSignInPronto = false;

  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
  // A partir da v7, GoogleSignIn() (construtor) foi removido — só
  // existe a instância singleton GoogleSignIn.instance.
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// A v7 do google_sign_in exige um passo de inicialização explícito,
  /// que só pode ser chamado uma vez — daí o `_googleSignInPronto` para
  /// não repetir se `entrarComGoogle` for chamado várias vezes.
  Future<void> _garantirGoogleSignInInicializado() async {
    if (_googleSignInPronto) return;
    await _googleSignIn.initialize(
      clientId: Platform.isIOS ? _iosClientId : null,
      serverClientId: _webClientId,
    );
    _googleSignInPronto = true;
  }

  @override
  Stream<AppUser?> watchUser() {
    return _auth.authStateChanges().asyncExpand((fbUser) {
      if (fbUser == null) {
        // 🔹 Se não há login, emite um evento null imediatamente
        return Stream.value(null);
      }

      // Se há login, escuta as alterações no documento do Firestore
      return _db.collection('users').doc(fbUser.uid).snapshots().map((snapshot) {
        if (!snapshot.exists) return AppUser(uid: fbUser.uid, email: fbUser.email);

        final dados = snapshot.data();
        final dataNascimento = dados?['dataNascimento'];

        return AppUser(
          uid: fbUser.uid,
          email: fbUser.email,
          username: dados?['username'] as String?,
          nome: dados?['nome'] as String?,
          dataNascimento: dataNascimento is Timestamp ? dataNascimento.toDate() : null,
          idLegoInsiders: dados?['idLegoInsiders'] as String?,
          sexo: dados?['sexo'] as String?,
          photoUrl: fbUser.photoURL,
        );
      });
    });
  }

  @override
  AppUser? get utilizadorAtual {
    final u = _auth.currentUser;
    if (u == null) return null;
    // Versão síncrona e "rápida" (sem ir ao Firestore) — usada só onde
    // não é prático esperar; a fonte de verdade continua a ser
    // watchUser()/_paraAppUser, que lê o perfil completo.
    return AppUser(uid: u.uid, email: u.email);
  }

  /// Lê o perfil completo do Firestore. [username] fica `null` se ainda
  /// não existir doc de perfil — é o sinal que o AuthGate usa para saber
  /// que falta completar o registo (ex: primeiro login por Google).
  Future<AppUser> _paraAppUser(fb.User? user) async {
    if (user == null) return const AppUser(uid: '');
    final perfil = await _db.collection('users').doc(user.uid).get();
    final dados = perfil.data();
    final dataNascimento = dados?['dataNascimento'];

    return AppUser(
      uid: user.uid,
      email: user.email,
      username: dados?['username'] as String?,
      nome: dados?['nome'] as String?,
      dataNascimento: dataNascimento is Timestamp ? dataNascimento.toDate() : null,
      idLegoInsiders: dados?['idLegoInsiders'] as String?,
      sexo: dados?['sexo'] as String?,
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<AppUser> registarComEmail({
    required String email,
    required String password,
    required String username,
    required String nome,
    DateTime? dataNascimento,
    String? idLegoInsiders,
    String? sexo,
  }) async {
    // Verificação rápida ANTES de criar a conta — evita criar uma conta
    // Firebase Auth só para a apagar logo a seguir por o username já
    // estar ocupado. Não é a garantia definitiva contra corrida (essa é
    // a transação em _reservarUsername), só poupa o caso comum.
    final usernameKey = username.trim().toLowerCase();
    final jaExiste = (await _db.collection('usernames').doc(usernameKey).get()).exists;
    if (jaExiste) {
      throw AuthException('Esse nome de utilizador já está em uso.');
    }

    fb.UserCredential? credencial;
    try {
      credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credencial.user!;
      await user.updateDisplayName(nome.trim());

      await _reservarUsername(
        uid: user.uid,
        usernameKey: usernameKey,
        dadosPerfil: {
          'username': username.trim(),
          'nome': nome.trim(),
          'email': user.email,
          'dataNascimento':
          dataNascimento != null ? Timestamp.fromDate(dataNascimento) : null,
          'idLegoInsiders': _vazioParaNull(idLegoInsiders),
          'sexo': sexo,
          'criadoEm': FieldValue.serverTimestamp(),
        },
      );

      return AppUser(
        uid: user.uid,
        email: user.email,
        username: username.trim(),
        nome: nome.trim(),
        dataNascimento: dataNascimento,
        idLegoInsiders: _vazioParaNull(idLegoInsiders),
        sexo: sexo,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mensagemErro(e.code));
    } on AuthException {
      // Perdemos a corrida do username depois de já termos criado a
      // conta (duas pessoas a registar o mesmo username ao mesmo
      // tempo) — apaga a conta Auth para não deixar um utilizador
      // "fantasma" sem perfil associado.
      await credencial?.user?.delete();
      rethrow;
    }
  }

  @override
  Future<AppUser> entrarComEmail({required String email, required String password}) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _paraAppUser(credencial.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mensagemErro(e.code));
    }
  }

  @override
  Future<AppUser> entrarComGoogle() async {
    await _garantirGoogleSignInInicializado();

    late final GoogleSignInAccount conta;
    try {
      // authenticate() substitui o antigo signIn() — já não devolve
      // null, lança GoogleSignInException para TODOS os casos de falha
      // (cancelado, erro de configuração, sem play services, etc.), por
      // isso é essencial distinguir os códigos, não assumir "cancelado"
      // para tudo como o código anterior fazia.
      conta = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Início de sessão cancelado.');
      }
      throw AuthException(_mensagemErroGoogle(e));
    }

    try {
      // authentication deixou de ser Future (é síncrono na v7); o
      // accessToken deixou de vir daqui — é um passo de autorização à
      // parte (authorizationClient), separado da autenticação.
      final idToken = conta.authentication.idToken;
      final autorizacao =
      await conta.authorizationClient.authorizeScopes(['email', 'profile']);

      final credencial = fb.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: autorizacao.accessToken,
      );
      final resultado = await _auth.signInWithCredential(credencial);

      // De propósito, NÃO criamos aqui um perfil automático com o nome
      // da conta Google como username — precisa de ser único e
      // escolhido pela pessoa. O AuthGate vê username==null e encaminha
      // para o CompleteProfileScreen.
      return await _paraAppUser(resultado.user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mensagemErro(e.code));
    } on GoogleSignInException catch (e) {
      throw AuthException(_mensagemErroGoogle(e));
    }
  }

  @override
  Future<AppUser> completarPerfil({
    required String username,
    required String nome,
    DateTime? dataNascimento,
    String? idLegoInsiders,
    String? sexo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sem sessão ativa.');

    final usernameKey = username.trim().toLowerCase();
    final jaExiste = (await _db.collection('usernames').doc(usernameKey).get()).exists;
    if (jaExiste) {
      throw AuthException('Esse nome de utilizador já está em uso.');
    }

    await user.updateDisplayName(nome.trim());
    await _reservarUsername(
      uid: user.uid,
      usernameKey: usernameKey,
      dadosPerfil: {
        'username': username.trim(),
        'nome': nome.trim(),
        'email': user.email,
        'dataNascimento':
        dataNascimento != null ? Timestamp.fromDate(dataNascimento) : null,
        'idLegoInsiders': _vazioParaNull(idLegoInsiders),
        'sexo': sexo,
        'criadoEm': FieldValue.serverTimestamp(),
      },
    );

    return _paraAppUser(user);
  }



  @override
  Future<AppUser> atualizarPerfil({
    required String nome,
    DateTime? dataNascimento,
    String? idLegoInsiders,
    String? sexo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Sem sessão ativa.');

    final batch = _db.batch();
    final userDocRef = _db.collection('users').doc(user.uid);
    final Map<String, dynamic> updatesFirestore = {};

    // 1. Atualizar Display Name (no Firebase Auth e no Map do Firestore)
    if (nome.trim().isNotEmpty) {
      await user.updateDisplayName(nome.trim());
      updatesFirestore['nome'] = nome.trim();
    }

    // 2. ID Insiders (_vazioParaNull converte "" em null para atualizar/limpar o campo)
    updatesFirestore['idLegoInsiders'] = _vazioParaNull(idLegoInsiders);

    // 3. Data de Nascimento (Converter explicitamente para Timestamp)
    updatesFirestore['dataNascimento'] =
    dataNascimento != null ? Timestamp.fromDate(dataNascimento) : null;

    // 4. Sexo
    updatesFirestore['sexo'] = sexo;

    // 5. Data de atualização
    updatesFirestore['updatedAt'] = FieldValue.serverTimestamp();

    // Executar a escrita em batch
    batch.set(userDocRef, updatesFirestore, SetOptions(merge: true));
    await batch.commit();

    return _paraAppUser(user);
  }

  @override
  Future<void> repporPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mensagemErro(e.code));
    }
  }

  @override
  Future<void> terminarSessao() async {
    // Termina sessão nos dois sítios — se só terminares no Firebase, o
    // Google Sign-In continua com a conta escolhida em memória, e a
    // próxima tentativa de login reentra automaticamente sem mostrar o
    // seletor de conta. `isSignedIn()` foi removido na v7 (a lib deixou
    // de rastrear "utilizador atual" sozinha) — signOut() é seguro de
    // chamar mesmo que não haja sessão Google ativa.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignora — pode falhar se nunca chegou a inicializar/autenticar
      // com o Google nesta sessão, o que não é um erro relevante aqui.
    }
    await _auth.signOut();
  }

  /// Reserva o username e grava o perfil de forma atómica: um documento
  /// em `usernames/{usernameKey}` (a "fechadura" que garante unicidade —
  /// Firestore não permite dois `set` concorrentes criarem o mesmo doc
  /// dentro de uma transação) e o perfil em `users/{uid}`.
  ///
  /// [usernameKey] é o username em minúsculas — a unicidade ignora
  /// maiúsculas/minúsculas (evita "João" e "joao" coexistirem).
  Future<void> _reservarUsername({
    required String uid,
    required String usernameKey,
    required Map<String, dynamic> dadosPerfil,
  }) async {
    final usernameRef = _db.collection('usernames').doc(usernameKey);
    final perfilRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final usernameSnap = await tx.get(usernameRef);
      if (usernameSnap.exists) {
        throw AuthException('Esse nome de utilizador já está em uso.');
      }
      tx.set(usernameRef, {'uid': uid});
      tx.set(perfilRef, dadosPerfil, SetOptions(merge: true));
    });
  }

  String? _vazioParaNull(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Traduz os códigos de erro específicos do google_sign_in v7. Mantido
  /// à parte de [_mensagemErro] porque são exceções de um pacote
  /// diferente (GoogleSignInException, não FirebaseAuthException).
  String _mensagemErroGoogle(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Início de sessão cancelado.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Início de sessão interrompido. Tenta novamente.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Configuração do Google Sign-In incompleta '
            '(falta o serverClientId ou o SHA-1 no Firebase). '
            'Isto é um erro de configuração da app, não do utilizador.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'O provedor Google não está ativado no Firebase.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Não foi possível mostrar o seletor de conta Google.';
      default:
        return 'Erro ao entrar com Google: ${e.code}'
            '${e.description != null ? ' — ${e.description}' : ''}';
    }
  }

  String _mensagemErro(String codigo) {
    switch (codigo) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou palavra-passe incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este email.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'weak-password':
        return 'Palavra-passe demasiado fraca (mínimo 6 caracteres).';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Tenta novamente daqui a pouco.';
      case 'network-request-failed':
        return 'Sem ligação à internet.';
      case 'requires-recent-login':
        return 'Por segurança, tens de voltar a entrar antes desta ação.';
      default:
        return 'Erro de autenticação ($codigo).';
    }
  }


}
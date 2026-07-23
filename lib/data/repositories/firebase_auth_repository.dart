import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lego_app/data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Stream<AppUser?> watchUser() {
    return _auth.authStateChanges().asyncMap(_paraAppUser);
  }

  @override
  AppUser? get utilizadorAtual {
    final u = _auth.currentUser;
    if (u == null) return null;
    return AppUser(
      uid: u.uid,
      email: u.email,
      username: u.displayName,
      photoUrl: u.photoURL,
    );
  }

  Future<AppUser> _paraAppUser(fb.User? user) async {
    if (user == null) return const AppUser(uid: '');
    final perfil = await _db.collection('users').doc(user.uid).get();
    return AppUser(
      uid: user.uid,
      email: user.email,
      username: (perfil.data()?['username'] as String?) ?? user.displayName,
      photoUrl: user.photoURL,
    );
  }

  @override
  Future<AppUser> registarComEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credencial.user!;
      await user.updateDisplayName(username.trim());
      await _guardarPerfil(user.uid, email: user.email, username: username.trim());
      return AppUser(uid: user.uid, email: user.email, username: username.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mensagemErro(e.code));
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
    try {
      // 1. Inicializa o plugin do Google Sign-In
      await _googleSignIn.initialize();

      // 2. Autentica e obtém a conta do utilizador (Identity/ID Token)
      final conta = await _googleSignIn.authenticate();

      // 3. Pede autorização para os escopos e obtém o Access Token (Novo na v7+)
      final authorization = await conta.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      // 4. Obtém o idToken
      final auth = await conta.authentication;

      // 5. Cria a credencial para o Firebase usando o idToken e o novo accessToken
      final credencial = fb.GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: auth.idToken,
      );

      final resultado = await _auth.signInWithCredential(credencial);
      final user = resultado.user!;

      final perfilExiste = (await _db.collection('users').doc(user.uid).get()).exists;
      if (!perfilExiste) {
        await _guardarPerfil(
          user.uid,
          email: user.email,
          username: user.displayName ?? conta.displayName,
        );
      }

      return await _paraAppUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mensagemErro(e.code));
    } catch (e) {
      throw AuthException('Início de sessão cancelado ou falhou.');
    }
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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> _guardarPerfil(String uid, {String? email, String? username}) {
    return _db.collection('users').doc(uid).set({
      'email': email,
      'username': username,
      'criadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      default:
        return 'Erro de autenticação ($codigo).';
    }
  }
}
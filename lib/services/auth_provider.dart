import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';

// Provider de autenticação: única camada que conversa com o FirebaseAuth e
// com o Google Sign-In. Os erros do FirebaseAuthException são propagados
// para o AuthBloc, que decide como mostrá-los.
class AuthProvider {
  static final AuthProvider _instancia = AuthProvider._();
  factory AuthProvider() => _instancia;
  AuthProvider._();

  final _auth = FirebaseAuth.instance;
  Future<void>? _googleInicializado;

  Stream<User?> get streamUsuario => _auth.authStateChanges();

  Future<void> entrarComEmail(String email, String senha) {
    return _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> cadastrarComEmail(String email, String senha) {
    return _auth.createUserWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> entrarComGoogle() async {
    // Na web o google_sign_in 7.x não suporta authenticate(); o popup do
    // próprio Firebase faz o mesmo fluxo.
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    // No google_sign_in 7.x o initialize() deve rodar uma única vez.
    await (_googleInicializado ??= GoogleSignIn.instance.initialize());
    final conta = await GoogleSignIn.instance.authenticate();
    final credencial = GoogleAuthProvider.credential(
      idToken: conta.authentication.idToken,
    );
    await _auth.signInWithCredential(credencial);
  }

  Future<void> sair() async {
    await _auth.signOut();
    if (kIsWeb) return;
    await (_googleInicializado ??= GoogleSignIn.instance.initialize());
    await GoogleSignIn.instance.signOut();
  }
}

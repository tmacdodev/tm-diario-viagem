import 'package:firebase_auth/firebase_auth.dart';

// Eventos do AuthBloc. Os quatro primeiros vêm da View; UsuarioAlterado é
// disparado pelo próprio Bloc a cada emissão do stream do FirebaseAuth.
abstract class AuthEvent {
  const AuthEvent();
}

class EntrarComEmailSolicitado extends AuthEvent {
  final String email;
  final String senha;
  const EntrarComEmailSolicitado(this.email, this.senha);
}

class CadastroSolicitado extends AuthEvent {
  final String email;
  final String senha;
  const CadastroSolicitado(this.email, this.senha);
}

class EntrarComGoogleSolicitado extends AuthEvent {
  const EntrarComGoogleSolicitado();
}

class SairSolicitado extends AuthEvent {
  const SairSolicitado();
}

class UsuarioAlterado extends AuthEvent {
  final User? usuario;
  const UsuarioAlterado(this.usuario);
}

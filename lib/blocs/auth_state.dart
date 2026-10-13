// Estados do AuthBloc: carregando (inicial ou durante uma chamada),
// autenticado, não autenticado ou erro (com mensagem amigável).
abstract class AuthState {
  const AuthState();
}

class AuthCarregando extends AuthState {
  const AuthCarregando();
}

class AuthAutenticado extends AuthState {
  final String uid;
  final String? email;
  const AuthAutenticado(this.uid, this.email);
}

class AuthNaoAutenticado extends AuthState {
  const AuthNaoAutenticado();
}

class AuthErro extends AuthState {
  final String mensagem;
  const AuthErro(this.mensagem);
}

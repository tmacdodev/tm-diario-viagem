import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_provider.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// Bloc de autenticação. Assina o stream do AuthProvider no construtor e
// converte cada emissão em UsuarioAlterado, que é quem decide entre
// AuthAutenticado e AuthNaoAutenticado. Login/cadastro/Google só emitem
// carregando e erro: o sucesso chega pelo stream.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthProvider _provider;
  late final StreamSubscription _inscricao;

  AuthBloc({AuthProvider? provider})
    : _provider = provider ?? AuthProvider(),
      super(const AuthCarregando()) {
    on<UsuarioAlterado>(
      (evento, emit) => emit(
        evento.usuario == null
            ? const AuthNaoAutenticado()
            : AuthAutenticado(evento.usuario!.uid, evento.usuario!.email),
      ),
    );
    on<EntrarComEmailSolicitado>(
      (evento, emit) => _executar(
        emit,
        () => _provider.entrarComEmail(evento.email, evento.senha),
      ),
    );
    on<CadastroSolicitado>(
      (evento, emit) => _executar(
        emit,
        () => _provider.cadastrarComEmail(evento.email, evento.senha),
      ),
    );
    on<EntrarComGoogleSolicitado>(
      (evento, emit) => _executar(emit, _provider.entrarComGoogle),
    );
    on<SairSolicitado>((evento, emit) => _executar(emit, _provider.sair));

    _inscricao = _provider.streamUsuario.listen(
      (usuario) => add(UsuarioAlterado(usuario)),
      onError: (_) => add(const UsuarioAlterado(null)),
    );
  }

  Future<void> _executar(
    Emitter<AuthState> emit,
    Future<void> Function() acao,
  ) async {
    emit(const AuthCarregando());
    try {
      await acao();
      // Se o stream já tiver emitido antes deste ponto, o estado final
      // (autenticado/não autenticado) já foi definido por UsuarioAlterado.
      if (state is AuthCarregando) {
        final usuario = FirebaseAuth.instance.currentUser;
        emit(
          usuario == null
              ? const AuthNaoAutenticado()
              : AuthAutenticado(usuario.uid, usuario.email),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        emit(const AuthNaoAutenticado());
        return;
      }
      emit(AuthErro(_traduzir(e)));
      emit(const AuthNaoAutenticado());
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled &&
          e.code != GoogleSignInExceptionCode.interrupted) {
        emit(const AuthErro('Não foi possível entrar com o Google.'));
      }
      emit(const AuthNaoAutenticado());
    } catch (_) {
      emit(const AuthErro('Ocorreu um erro inesperado. Tente novamente.'));
      emit(const AuthNaoAutenticado());
    }
  }

  String _traduzir(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha é muito fraca (mínimo de 6 caracteres).';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Falha na autenticação (${e.code}).';
    }
  }

  @override
  Future<void> close() {
    _inscricao.cancel();
    return super.close();
  }
}

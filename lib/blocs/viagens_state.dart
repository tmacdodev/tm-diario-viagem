import '../models/viagem.dart';

// Estado do ViagensBloc: a lista mais recente de viagens, se ainda está
// carregando a primeira vez, e uma mensagem de erro (se der algo errado).
class ViagensState {
  final List<Viagem> viagens;
  final bool carregando;
  final String? erro;

  const ViagensState({
    this.viagens = const [],
    this.carregando = true,
    this.erro,
  });

  ViagensState copyWith({
    List<Viagem>? viagens,
    bool? carregando,
    String? erro,
  }) {
    return ViagensState(
      viagens: viagens ?? this.viagens,
      carregando: carregando ?? this.carregando,
      erro: erro,
    );
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/viagem_provider.dart';
import 'viagens_event.dart';
import 'viagens_state.dart';

// Bloc da lista de viagens. É o Bloc que assina a stream do Provider (no
// construtor) e vai disparando eventos para si mesmo a cada atualização —
// a View só usa BlocBuilder para desenhar o ViagensState mais recente.
class ViagensBloc extends Bloc<ViagensEvent, ViagensState> {
  final ViagemProvider _provider;
  late final StreamSubscription _inscricao;

  ViagensBloc({ViagemProvider? provider})
    : _provider = provider ?? ViagemProvider(),
      super(const ViagensState()) {
    on<ViagensAtualizadas>(
      (evento, emit) => emit(
        state.copyWith(viagens: evento.viagens, carregando: false, erro: null),
      ),
    );
    on<ErroAoCarregarViagens>(
      (evento, emit) =>
          emit(state.copyWith(carregando: false, erro: evento.mensagem)),
    );

    _inscricao = _provider.streamViagens().listen(
      (viagens) => add(ViagensAtualizadas(viagens)),
      onError: (erro) => add(ErroAoCarregarViagens(erro.toString())),
    );
  }

  @override
  close() {
    _inscricao.cancel();
    return super.close();
  }
}

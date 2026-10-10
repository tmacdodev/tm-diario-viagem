import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/compra_dolar_provider.dart';
import '../services/viagem_provider.dart';
import 'detalhe_viagem_event.dart';
import 'detalhe_viagem_state.dart';

// Bloc da tela de detalhe: assina, ao mesmo tempo, a stream do documento da
// viagem e a stream das compras de dólar dela (ambas vindas dos Providers),
// e vai montando um único DetalheViagemState.
class DetalheViagemBloc extends Bloc<DetalheViagemEvent, DetalheViagemState> {
  final ViagemProvider _viagemProvider;
  final CompraDolarProvider _compraProvider;
  late final StreamSubscription _inscricaoViagem;
  late final StreamSubscription _inscricaoCompras;

  DetalheViagemBloc({
    required String viagemId,
    ViagemProvider? viagemProvider,
    CompraDolarProvider? compraProvider,
  }) : _viagemProvider = viagemProvider ?? ViagemProvider(),
       _compraProvider = compraProvider ?? CompraDolarProvider(),
       super(const DetalheViagemState()) {
    on<ViagemAtualAtualizada>(
      (evento, emit) => emit(state.copyWith(viagem: evento.viagem)),
    );
    on<ComprasAtualizadas>(
      (evento, emit) => emit(state.copyWith(compras: evento.compras)),
    );
    on<ErroNoDetalhe>(
      (evento, emit) => emit(state.copyWith(erro: evento.mensagem)),
    );

    _inscricaoViagem = _viagemProvider
        .streamViagemPorId(viagemId)
        .listen(
          (viagem) => add(ViagemAtualAtualizada(viagem)),
          onError: (erro) => add(ErroNoDetalhe(erro.toString())),
        );
    _inscricaoCompras = _compraProvider
        .streamCompras(viagemId)
        .listen((compras) => add(ComprasAtualizadas(compras)));
  }

  @override
  close() {
    _inscricaoViagem.cancel();
    _inscricaoCompras.cancel();
    return super.close();
  }
}

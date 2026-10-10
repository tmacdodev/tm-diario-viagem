import '../models/compra_dolar.dart';
import '../models/viagem.dart';

// Estado do DetalheViagemBloc: a viagem em si (null até a primeira
// atualização chegar), a lista de compras de dólar e um possível erro.
class DetalheViagemState {
  final Viagem? viagem;
  final List<CompraDolar> compras;
  final String? erro;

  const DetalheViagemState({this.viagem, this.compras = const [], this.erro});

  DetalheViagemState copyWith({
    Viagem? viagem,
    List<CompraDolar>? compras,
    String? erro,
  }) {
    return DetalheViagemState(
      viagem: viagem ?? this.viagem,
      compras: compras ?? this.compras,
      erro: erro,
    );
  }
}

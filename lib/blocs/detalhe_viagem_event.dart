import '../models/compra_dolar.dart';
import '../models/viagem.dart';

// Eventos do DetalheViagemBloc. Assim como no ViagensBloc, quem dispara
// esses eventos é o próprio Bloc, a cada atualização vinda do Provider.
abstract class DetalheViagemEvent {
  const DetalheViagemEvent();
}

class ViagemAtualAtualizada extends DetalheViagemEvent {
  final Viagem viagem;
  const ViagemAtualAtualizada(this.viagem);
}

class ComprasAtualizadas extends DetalheViagemEvent {
  final List<CompraDolar> compras;
  const ComprasAtualizadas(this.compras);
}

class ErroNoDetalhe extends DetalheViagemEvent {
  final String mensagem;
  const ErroNoDetalhe(this.mensagem);
}

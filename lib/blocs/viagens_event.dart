import '../models/viagem.dart';

// Eventos que o ViagensBloc sabe processar. Esses dois eventos nunca são
// disparados pela View — quem dispara é o próprio Bloc, toda vez que o
// Provider emite um novo valor na stream do Firestore.
abstract class ViagensEvent {
  const ViagensEvent();
}

class ViagensAtualizadas extends ViagensEvent {
  final List<Viagem> viagens;
  const ViagensAtualizadas(this.viagens);
}

class ErroAoCarregarViagens extends ViagensEvent {
  final String mensagem;
  const ErroAoCarregarViagens(this.mensagem);
}

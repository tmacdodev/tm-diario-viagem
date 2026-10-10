import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/mensagem_chat.dart';
import 'chat_bot_event.dart';
import 'chat_bot_provider.dart';
import 'chat_bot_state.dart';

// Bloc do "assistente de viagem": recebe o evento da View (add) e emite
// novos estados (emit) para o BlocBuilder reconstruir a tela.
//
// O Bloc em si NUNCA busca a dica sozinho — ele só repassa a pergunta para
// o ChatBotProvider e espera a resposta. Essa separação é proposital: se
// amanhã o Provider passar a chamar uma API de verdade, o Bloc continua
// exatamente igual.
class ChatBotBloc extends Bloc<ChatBotEvent, ChatBotState> {
  final ChatBotProvider _provider;

  ChatBotBloc({ChatBotProvider? provider})
    : _provider = provider ?? ChatBotProvider(),
      super(const ChatBotState()) {
    on<PerguntaEnviada>(_aoReceberPergunta);
  }

  void _aoReceberPergunta(PerguntaEnviada evento, Emitter<ChatBotState> emit) {
    final mensagemUsuario = MensagemChat(
      texto: evento.pergunta,
      doUsuario: true,
    );
    final resposta = _provider.buscarDica(evento.pergunta);
    final mensagemBot = MensagemChat(texto: resposta, doUsuario: false);

    emit(
      state.copyWith(
        mensagens: [...state.mensagens, mensagemUsuario, mensagemBot],
      ),
    );
  }
}
